// lib/services/sync/sync_scheduler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncTrigger {
  manual,
  automatic,
  periodic,
  onConnectivity,
  onAppResume,
  onDataChange,
  onBatteryOptimal,
}

enum SyncCondition {
  always,
  wifiOnly,
  batteryOptimal,
  deviceIdle,
  userActive,
  offPeakHours,
}

class SyncSchedule {
  final String id;
  final String name;
  final Duration interval;
  final List<SyncCondition> conditions;
  final SyncTrigger trigger;
  final bool isEnabled;
  final DateTime? nextScheduledTime;
  final int priority;
  final Map<String, dynamic> metadata;

  SyncSchedule({
    required this.id,
    required this.name,
    required this.interval,
    required this.conditions,
    required this.trigger,
    this.isEnabled = true,
    this.nextScheduledTime,
    this.priority = 1,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'interval_ms': interval.inMilliseconds,
      'conditions': conditions.map((c) => c.index).toList(),
      'trigger': trigger.index,
      'is_enabled': isEnabled,
      'next_scheduled_time': nextScheduledTime?.millisecondsSinceEpoch,
      'priority': priority,
      'metadata': metadata,
    };
  }

  factory SyncSchedule.fromMap(Map<String, dynamic> map) {
    return SyncSchedule(
      id: map['id'],
      name: map['name'],
      interval: Duration(milliseconds: map['interval_ms']),
      conditions: (map['conditions'] as List)
          .map((index) => SyncCondition.values[index])
          .toList(),
      trigger: SyncTrigger.values[map['trigger']],
      isEnabled: map['is_enabled'] ?? true,
      nextScheduledTime: map['next_scheduled_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['next_scheduled_time'])
          : null,
      priority: map['priority'] ?? 1,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  SyncSchedule copyWith({
    String? id,
    String? name,
    Duration? interval,
    List<SyncCondition>? conditions,
    SyncTrigger? trigger,
    bool? isEnabled,
    DateTime? nextScheduledTime,
    int? priority,
    Map<String, dynamic>? metadata,
  }) {
    return SyncSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      interval: interval ?? this.interval,
      conditions: conditions ?? this.conditions,
      trigger: trigger ?? this.trigger,
      isEnabled: isEnabled ?? this.isEnabled,
      nextScheduledTime: nextScheduledTime ?? this.nextScheduledTime,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }
}

class SyncScheduler {
  static const String _prefsKey = 'sync_schedules';
  static const Duration _defaultInterval = Duration(minutes: 15);
  static const Duration _minInterval = Duration(minutes: 1);
  static const Duration _maxInterval = Duration(hours: 24);

  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, SyncSchedule> _schedules = {};

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _conditionCheckTimer;

  final StreamController<SyncTrigger> _syncTriggerController =
      StreamController<SyncTrigger>.broadcast();
  final StreamController<List<SyncSchedule>> _schedulesController =
      StreamController<List<SyncSchedule>>.broadcast();

  Stream<SyncTrigger> get syncTriggerStream => _syncTriggerController.stream;
  Stream<List<SyncSchedule>> get schedulesStream => _schedulesController.stream;

  bool _isInitialized = false;
  bool _isAppInForeground = true;
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  BatteryState _currentBatteryState = BatteryState.unknown;

  // Initialize the scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadSchedules();
      await _setupConnectivityMonitoring();
      await _setupBatteryMonitoring();
      await _setupConditionChecking();
      await _createDefaultSchedules();

      _isInitialized = true;
      debugPrint('SyncScheduler: Initialized successfully');

      // Start all enabled schedules
      await _startAllSchedules();
    } catch (e) {
      debugPrint('SyncScheduler: Initialization failed - $e');
      throw SyncSchedulerException('Failed to initialize sync scheduler: $e');
    }
  }

  // Create default sync schedules
  Future<void> _createDefaultSchedules() async {
    if (_schedules.isEmpty) {
      // Automatic sync on connectivity
      await addSchedule(
        SyncSchedule(
          id: 'auto_connectivity',
          name: 'Auto Sync on Connectivity',
          interval: Duration.zero,
          conditions: [SyncCondition.wifiOnly],
          trigger: SyncTrigger.onConnectivity,
          priority: 3,
        ),
      );

      // Periodic background sync
      await addSchedule(
        SyncSchedule(
          id: 'periodic_background',
          name: 'Periodic Background Sync',
          interval: const Duration(minutes: 30),
          conditions: [SyncCondition.batteryOptimal, SyncCondition.deviceIdle],
          trigger: SyncTrigger.periodic,
          priority: 2,
        ),
      );

      // Manual sync (always available)
      await addSchedule(
        SyncSchedule(
          id: 'manual_sync',
          name: 'Manual Sync',
          interval: Duration.zero,
          conditions: [SyncCondition.always],
          trigger: SyncTrigger.manual,
          priority: 5,
        ),
      );

      // App resume sync
      await addSchedule(
        SyncSchedule(
          id: 'app_resume',
          name: 'Sync on App Resume',
          interval: Duration.zero,
          conditions: [SyncCondition.always],
          trigger: SyncTrigger.onAppResume,
          priority: 4,
        ),
      );

      // Data change sync
      await addSchedule(
        SyncSchedule(
          id: 'data_change',
          name: 'Sync on Data Change',
          interval: const Duration(minutes: 5),
          conditions: [SyncCondition.userActive],
          trigger: SyncTrigger.onDataChange,
          priority: 4,
        ),
      );
    }
  }

  // Add a new sync schedule
  Future<void> addSchedule(SyncSchedule schedule) async {
    _schedules[schedule.id] = schedule;
    await _saveSchedules();

    if (schedule.isEnabled) {
      await _startSchedule(schedule);
    }

    _schedulesController.add(_schedules.values.toList());
    debugPrint('SyncScheduler: Added schedule ${schedule.name}');
  }

  // Update existing schedule
  Future<void> updateSchedule(SyncSchedule schedule) async {
    if (!_schedules.containsKey(schedule.id)) {
      throw SyncSchedulerException('Schedule ${schedule.id} not found');
    }

    await _stopSchedule(schedule.id);
    _schedules[schedule.id] = schedule;
    await _saveSchedules();

    if (schedule.isEnabled) {
      await _startSchedule(schedule);
    }

    _schedulesController.add(_schedules.values.toList());
    debugPrint('SyncScheduler: Updated schedule ${schedule.name}');
  }

  // Remove schedule
  Future<void> removeSchedule(String scheduleId) async {
    await _stopSchedule(scheduleId);
    _schedules.remove(scheduleId);
    await _saveSchedules();

    _schedulesController.add(_schedules.values.toList());
    debugPrint('SyncScheduler: Removed schedule $scheduleId');
  }

  // Enable/disable schedule
  Future<void> toggleSchedule(String scheduleId, bool enabled) async {
    final schedule = _schedules[scheduleId];
    if (schedule == null) {
      throw SyncSchedulerException('Schedule $scheduleId not found');
    }

    final updatedSchedule = schedule.copyWith(isEnabled: enabled);
    await updateSchedule(updatedSchedule);
  }

  // Trigger manual sync
  Future<void> triggerManualSync() async {
    debugPrint('SyncScheduler: Manual sync triggered');
    _syncTriggerController.add(SyncTrigger.manual);
  }

  // Trigger sync on app resume
  Future<void> onAppResume() async {
    _isAppInForeground = true;

    final resumeSchedules = _schedules.values.where(
      (s) => s.trigger == SyncTrigger.onAppResume && s.isEnabled,
    );

    for (final schedule in resumeSchedules) {
      if (await _checkConditions(schedule.conditions)) {
        debugPrint('SyncScheduler: App resume sync triggered');
        _syncTriggerController.add(SyncTrigger.onAppResume);
        break;
      }
    }
  }

  // Trigger sync on app pause
  Future<void> onAppPause() async {
    _isAppInForeground = false;
  }

  // Trigger sync on data change
  Future<void> onDataChange() async {
    final dataChangeSchedules = _schedules.values.where(
      (s) => s.trigger == SyncTrigger.onDataChange && s.isEnabled,
    );

    for (final schedule in dataChangeSchedules) {
      if (await _checkConditions(schedule.conditions)) {
        debugPrint('SyncScheduler: Data change sync triggered');
        _syncTriggerController.add(SyncTrigger.onDataChange);
        break;
      }
    }
  }

  // Get all schedules
  List<SyncSchedule> getSchedules() {
    return _schedules.values.toList();
  }

  // Get schedule by ID
  SyncSchedule? getSchedule(String id) {
    return _schedules[id];
  }

  // Get next scheduled sync time
  DateTime? getNextScheduledTime() {
    final enabledSchedules = _schedules.values.where(
      (s) => s.isEnabled && s.nextScheduledTime != null,
    );

    if (enabledSchedules.isEmpty) return null;

    return enabledSchedules
        .map((s) => s.nextScheduledTime!)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  // Private methods

  Future<void> _startAllSchedules() async {
    for (final schedule in _schedules.values) {
      if (schedule.isEnabled) {
        await _startSchedule(schedule);
      }
    }
  }

  Future<void> _startSchedule(SyncSchedule schedule) async {
    await _stopSchedule(schedule.id);

    switch (schedule.trigger) {
      case SyncTrigger.periodic:
        await _startPeriodicSchedule(schedule);
        break;
      case SyncTrigger.automatic:
        await _startAutomaticSchedule(schedule);
        break;
      default:
        // Other triggers are event-based and don't need timers
        break;
    }
  }

  Future<void> _startPeriodicSchedule(SyncSchedule schedule) async {
    final timer = Timer.periodic(schedule.interval, (timer) async {
      if (await _checkConditions(schedule.conditions)) {
        debugPrint(
          'SyncScheduler: Periodic sync triggered for ${schedule.name}',
        );
        _syncTriggerController.add(SyncTrigger.periodic);
      }
    });

    _activeTimers[schedule.id] = timer;

    // Update next scheduled time
    final nextTime = DateTime.now().add(schedule.interval);
    final updatedSchedule = schedule.copyWith(nextScheduledTime: nextTime);
    _schedules[schedule.id] = updatedSchedule;
  }

  Future<void> _startAutomaticSchedule(SyncSchedule schedule) async {
    // Automatic schedules use adaptive intervals based on usage patterns
    final adaptiveInterval = await _calculateAdaptiveInterval(schedule);

    final timer = Timer.periodic(adaptiveInterval, (timer) async {
      if (await _checkConditions(schedule.conditions)) {
        debugPrint(
          'SyncScheduler: Automatic sync triggered for ${schedule.name}',
        );
        _syncTriggerController.add(SyncTrigger.automatic);

        // Recalculate interval for next cycle
        final newInterval = await _calculateAdaptiveInterval(schedule);
        if (newInterval != adaptiveInterval) {
          await _restartSchedule(schedule.id);
        }
      }
    });

    _activeTimers[schedule.id] = timer;
  }

  Future<void> _stopSchedule(String scheduleId) async {
    final timer = _activeTimers.remove(scheduleId);
    timer?.cancel();
  }

  Future<void> _restartSchedule(String scheduleId) async {
    final schedule = _schedules[scheduleId];
    if (schedule != null && schedule.isEnabled) {
      await _stopSchedule(scheduleId);
      await _startSchedule(schedule);
    }
  }

  Future<bool> _checkConditions(List<SyncCondition> conditions) async {
    for (final condition in conditions) {
      if (!await _checkSingleCondition(condition)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _checkSingleCondition(SyncCondition condition) async {
    switch (condition) {
      case SyncCondition.always:
        return true;

      case SyncCondition.wifiOnly:
        return _currentConnectivity == ConnectivityResult.wifi;

      case SyncCondition.batteryOptimal:
        return await _isBatteryOptimal();

      case SyncCondition.deviceIdle:
        return await _isDeviceIdle();

      case SyncCondition.userActive:
        return _isAppInForeground;

      case SyncCondition.offPeakHours:
        return _isOffPeakHours();
    }
  }

  Future<bool> _isBatteryOptimal() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final isCharging = _currentBatteryState == BatteryState.charging;

      // Consider battery optimal if charging or level > 30%
      return isCharging || batteryLevel > 30;
    } catch (e) {
      debugPrint('SyncScheduler: Error checking battery - $e');
      return true; // Default to true if we can't check
    }
  }

  Future<bool> _isDeviceIdle() async {
    try {
      // Check if device has been idle for a certain period
      // This is a simplified implementation
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt('last_user_activity') ?? 0;
      final idleThreshold =
          DateTime.now().millisecondsSinceEpoch - (5 * 60 * 1000); // 5 minutes

      return lastActivity < idleThreshold;
    } catch (e) {
      debugPrint('SyncScheduler: Error checking device idle - $e');
      return false;
    }
  }

  bool _isOffPeakHours() {
    final now = DateTime.now();
    final hour = now.hour;

    // Consider off-peak hours as 10 PM to 6 AM
    return hour >= 22 || hour <= 6;
  }

  Future<Duration> _calculateAdaptiveInterval(SyncSchedule schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseInterval = schedule.interval;

      // Get usage patterns
      final syncFrequency = prefs.getInt('sync_frequency_${schedule.id}') ?? 1;
      final lastSyncSuccess =
          prefs.getBool('last_sync_success_${schedule.id}') ?? true;
      final consecutiveFailures =
          prefs.getInt('consecutive_failures_${schedule.id}') ?? 0;

      // Adjust interval based on patterns
      var multiplier = 1.0;

      // Increase frequency for high-usage schedules
      if (syncFrequency > 10) {
        multiplier *= 0.7; // 30% faster
      } else if (syncFrequency < 3) {
        multiplier *= 1.5; // 50% slower
      }

      // Exponential backoff for failures
      if (!lastSyncSuccess && consecutiveFailures > 0) {
        multiplier *= pow(2, min(consecutiveFailures, 5)).toDouble();
      }

      // Apply battery-based adjustments
      if (!await _isBatteryOptimal()) {
        multiplier *= 2.0; // Sync less frequently on low battery
      }

      // Calculate final interval
      final adaptiveInterval = Duration(
        milliseconds: (baseInterval.inMilliseconds * multiplier).round(),
      );

      // Ensure interval is within bounds
      if (adaptiveInterval < _minInterval) return _minInterval;
      if (adaptiveInterval > _maxInterval) return _maxInterval;

      return adaptiveInterval;
    } catch (e) {
      debugPrint('SyncScheduler: Error calculating adaptive interval - $e');
      return schedule.interval;
    }
  }

  Future<void> _setupConnectivityMonitoring() async {
    _currentConnectivity =
        (await _connectivity.checkConnectivity()) as ConnectivityResult;

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
              (ConnectivityResult result) async {
                    final previousConnectivity = _currentConnectivity;
                    _currentConnectivity = result;

                    // Trigger connectivity-based syncs
                    if (result != ConnectivityResult.none &&
                        previousConnectivity == ConnectivityResult.none) {
                      await _onConnectivityRestored();
                    }
                  }
                  as void Function(List<ConnectivityResult> event)?,
            )
            as StreamSubscription<ConnectivityResult>?;
  }

  Future<void> _setupBatteryMonitoring() async {
    try {
      _currentBatteryState = await _battery.batteryState;

      _batterySubscription = _battery.onBatteryStateChanged.listen((
        BatteryState state,
      ) {
        _currentBatteryState = state;

        // Trigger battery-optimal syncs when charging starts
        if (state == BatteryState.charging) {
          _onBatteryOptimal();
        }
      });
    } catch (e) {
      debugPrint('SyncScheduler: Battery monitoring setup failed - $e');
    }
  }

  Future<void> _setupConditionChecking() async {
    // Check conditions periodically
    _conditionCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _checkPendingConditions(),
    );
  }

  Future<void> _onConnectivityRestored() async {
    final connectivitySchedules = _schedules.values.where(
      (s) => s.trigger == SyncTrigger.onConnectivity && s.isEnabled,
    );

    for (final schedule in connectivitySchedules) {
      if (await _checkConditions(schedule.conditions)) {
        debugPrint('SyncScheduler: Connectivity sync triggered');
        _syncTriggerController.add(SyncTrigger.onConnectivity);
        break;
      }
    }
  }

  Future<void> _onBatteryOptimal() async {
    final batterySchedules = _schedules.values.where(
      (s) => s.trigger == SyncTrigger.onBatteryOptimal && s.isEnabled,
    );

    for (final schedule in batterySchedules) {
      if (await _checkConditions(schedule.conditions)) {
        debugPrint('SyncScheduler: Battery optimal sync triggered');
        _syncTriggerController.add(SyncTrigger.onBatteryOptimal);
        break;
      }
    }
  }

  Future<void> _checkPendingConditions() async {
    // Check if any schedules with unmet conditions can now be triggered
    for (final schedule in _schedules.values) {
      if (!schedule.isEnabled) continue;

      if (schedule.trigger == SyncTrigger.automatic &&
          await _checkConditions(schedule.conditions)) {
        // Check if enough time has passed since last check
        final lastCheck = schedule.metadata['last_condition_check'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (lastCheck == null ||
            (now - lastCheck) >= schedule.interval.inMilliseconds) {
          _syncTriggerController.add(SyncTrigger.automatic);

          // Update last check time
          final updatedSchedule = schedule.copyWith(
            metadata: {...schedule.metadata, 'last_condition_check': now},
          );
          _schedules[schedule.id] = updatedSchedule;
        }
      }
    }
  }

  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString(_prefsKey);

      if (schedulesJson != null) {
        final schedulesList = jsonDecode(schedulesJson) as List;

        for (final scheduleMap in schedulesList) {
          final schedule = SyncSchedule.fromMap(scheduleMap);
          _schedules[schedule.id] = schedule;
        }

        debugPrint('SyncScheduler: Loaded ${_schedules.length} schedules');
      }
    } catch (e) {
      debugPrint('SyncScheduler: Error loading schedules - $e');
    }
  }

  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesList = _schedules.values.map((s) => s.toMap()).toList();
      final schedulesJson = jsonEncode(schedulesList);

      await prefs.setString(_prefsKey, schedulesJson);
      debugPrint('SyncScheduler: Saved ${_schedules.length} schedules');
    } catch (e) {
      debugPrint('SyncScheduler: Error saving schedules - $e');
    }
  }

  // Record sync metrics for adaptive scheduling
  Future<void> recordSyncMetrics({
    required String scheduleId,
    required bool success,
    required Duration duration,
    required int itemsProcessed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update frequency counter
      final currentFreq = prefs.getInt('sync_frequency_$scheduleId') ?? 0;
      await prefs.setInt('sync_frequency_$scheduleId', currentFreq + 1);

      // Update success/failure tracking
      await prefs.setBool('last_sync_success_$scheduleId', success);

      if (success) {
        await prefs.setInt('consecutive_failures_$scheduleId', 0);
      } else {
        final currentFailures =
            prefs.getInt('consecutive_failures_$scheduleId') ?? 0;
        await prefs.setInt(
          'consecutive_failures_$scheduleId',
          currentFailures + 1,
        );
      }

      // Record performance metrics
      await prefs.setInt(
        'last_sync_duration_$scheduleId',
        duration.inMilliseconds,
      );
      await prefs.setInt('last_sync_items_$scheduleId', itemsProcessed);
      await prefs.setInt(
        'last_sync_time_$scheduleId',
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint(
        'SyncScheduler: Recorded metrics for $scheduleId - success: $success, duration: ${duration.inSeconds}s',
      );
    } catch (e) {
      debugPrint('SyncScheduler: Error recording metrics - $e');
    }
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = <String, dynamic>{};

      for (final schedule in _schedules.values) {
        final scheduleStats = <String, dynamic>{
          'frequency': prefs.getInt('sync_frequency_${schedule.id}') ?? 0,
          'lastSuccess':
              prefs.getBool('last_sync_success_${schedule.id}') ?? false,
          'consecutiveFailures':
              prefs.getInt('consecutive_failures_${schedule.id}') ?? 0,
          'lastDuration':
              prefs.getInt('last_sync_duration_${schedule.id}') ?? 0,
          'lastItemCount': prefs.getInt('last_sync_items_${schedule.id}') ?? 0,
          'lastSyncTime': prefs.getInt('last_sync_time_${schedule.id}') ?? 0,
        };

        stats[schedule.id] = scheduleStats;
      }

      return stats;
    } catch (e) {
      debugPrint('SyncScheduler: Error getting statistics - $e');
      return {};
    }
  }

  // Optimize schedules based on usage patterns
  Future<void> optimizeSchedules() async {
    try {
      final stats = await getSyncStatistics();
      bool hasChanges = false;

      for (final schedule in _schedules.values) {
        final scheduleStats = stats[schedule.id] as Map<String, dynamic>?;
        if (scheduleStats == null) continue;

        final frequency = scheduleStats['frequency'] as int;
        final consecutiveFailures = scheduleStats['consecutiveFailures'] as int;

        // Disable underused schedules
        if (frequency < 5 &&
            schedule.isEnabled &&
            schedule.trigger == SyncTrigger.periodic) {
          final optimizedSchedule = schedule.copyWith(isEnabled: false);
          _schedules[schedule.id] = optimizedSchedule;
          hasChanges = true;
          debugPrint(
            'SyncScheduler: Disabled underused schedule ${schedule.name}',
          );
        }

        // Adjust intervals for frequently failing schedules
        if (consecutiveFailures > 3 && schedule.isEnabled) {
          final newInterval = Duration(
            milliseconds: (schedule.interval.inMilliseconds * 1.5).round(),
          );

          if (newInterval <= _maxInterval) {
            final optimizedSchedule = schedule.copyWith(interval: newInterval);
            _schedules[schedule.id] = optimizedSchedule;
            hasChanges = true;
            debugPrint(
              'SyncScheduler: Increased interval for failing schedule ${schedule.name}',
            );
          }
        }
      }

      if (hasChanges) {
        await _saveSchedules();
        await _startAllSchedules();
        _schedulesController.add(_schedules.values.toList());
      }
    } catch (e) {
      debugPrint('SyncScheduler: Error optimizing schedules - $e');
    }
  }

  // Get recommended schedule settings based on device capabilities
  Future<Map<String, dynamic>> getRecommendedSettings() async {
    try {
      final recommendations = <String, dynamic>{};

      // Check device capabilities
      final isLowEndDevice = await _isLowEndDevice();
      final batteryLevel = await _battery.batteryLevel;

      if (isLowEndDevice) {
        recommendations['maxConcurrentSyncs'] = 1;
        recommendations['preferredInterval'] = const Duration(hours: 1);
        recommendations['enableAdaptiveSync'] = false;
      } else {
        recommendations['maxConcurrentSyncs'] = 3;
        recommendations['preferredInterval'] = const Duration(minutes: 15);
        recommendations['enableAdaptiveSync'] = true;
      }

      if (batteryLevel < 20) {
        recommendations['batteryOptimizedMode'] = true;
        recommendations['wifiOnlyMode'] = true;
      }

      return recommendations;
    } catch (e) {
      debugPrint('SyncScheduler: Error getting recommendations - $e');
      return {};
    }
  }

  Future<bool> _isLowEndDevice() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Consider devices with less than 3GB RAM as low-end
        return (androidInfo.systemFeatures.length < 100); // Simplified check
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Consider older iOS devices as low-end
        final model = iosInfo.model.toLowerCase();
        return model.contains('6') || model.contains('se');
      }

      return false;
    } catch (e) {
      debugPrint('SyncScheduler: Error checking device capabilities - $e');
      return false;
    }
  }

  // Dispose all resources
  Future<void> dispose() async {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    _conditionCheckTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _batterySubscription?.cancel();

    await _syncTriggerController.close();
    await _schedulesController.close();

    _isInitialized = false;
    debugPrint('SyncScheduler: Disposed');
  }
}

// Custom exception for sync scheduler errors
class SyncSchedulerException implements Exception {
  final String message;

  SyncSchedulerException(this.message);

  @override
  String toString() => 'SyncSchedulerException: $message';
}
