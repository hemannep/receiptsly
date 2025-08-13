import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/sync/sync_service.dart';
import '../../core/errors/failures.dart';

// Connectivity Provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Is Online Provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(connectivityProvider);
  return connectivityState.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// Sync Status Provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).syncStatus;
});

// Sync State Notifier
class SyncStateNotifier extends StateNotifier<AsyncValue<SyncState>> {
  final SyncService _syncService;

  SyncStateNotifier(this._syncService)
    : super(const AsyncValue.data(SyncState())) {
    _init();
  }

  void _init() {
    _syncService.syncStatus.listen(
      (status) {
        state = AsyncValue.data(
          SyncState(
            isSyncing: status.isSyncing,
            pendingItems: status.pendingItems,
            lastSyncTime: status.lastSyncTime,
            error: status.error,
          ),
        );
      },
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
  }

  // Manual Sync
  Future<void> manualSync() async {
    try {
      await _syncService.manualSync();
    } catch (error) {
      state = AsyncValue.error(
        SyncFailure('Manual sync failed'),
        StackTrace.current,
      );
    }
  }

  // Clear Sync Queue
  Future<void> clearSyncQueue() async {
    try {
      await _syncService.clearSyncQueue();
    } catch (error) {
      state = AsyncValue.error(
        SyncFailure('Failed to clear sync queue'),
        StackTrace.current,
      );
    }
  }

  // Retry Failed Syncs
  Future<void> retryFailedSyncs() async {
    try {
      await _syncService.retryFailedSyncs();
    } catch (error) {
      state = AsyncValue.error(
        SyncFailure('Failed to retry syncs'),
        StackTrace.current,
      );
    }
  }
}

// Sync State Model
class SyncState {
  final bool isSyncing;
  final int pendingItems;
  final DateTime? lastSyncTime;
  final String? error;

  const SyncState({
    this.isSyncing = false,
    this.pendingItems = 0,
    this.lastSyncTime,
    this.error,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingItems,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingItems: pendingItems ?? this.pendingItems,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error ?? this.error,
    );
  }
}

// Sync State Provider
final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, AsyncValue<SyncState>>((ref) {
      return SyncStateNotifier(ref.watch(syncServiceProvider));
    });

// Offline Queue Provider
final offlineQueueProvider = StreamProvider<List<OfflineAction>>((ref) {
  return ref.watch(syncServiceProvider).offlineQueue;
});

// Conflict Resolution Provider
final conflictResolutionProvider = StreamProvider<List<ConflictItem>>((ref) {
  return ref.watch(syncServiceProvider).conflicts;
});

// Sync Settings State
class SyncSettings {
  final bool autoSync;
  final bool syncOnWifiOnly;
  final int syncInterval; // minutes
  final bool backgroundSync;

  const SyncSettings({
    this.autoSync = true,
    this.syncOnWifiOnly = false,
    this.syncInterval = 15,
    this.backgroundSync = true,
  });

  SyncSettings copyWith({
    bool? autoSync,
    bool? syncOnWifiOnly,
    int? syncInterval,
    bool? backgroundSync,
  }) {
    return SyncSettings(
      autoSync: autoSync ?? this.autoSync,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      syncInterval: syncInterval ?? this.syncInterval,
      backgroundSync: backgroundSync ?? this.backgroundSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSync': autoSync,
      'syncOnWifiOnly': syncOnWifiOnly,
      'syncInterval': syncInterval,
      'backgroundSync': backgroundSync,
    };
  }

  factory SyncSettings.fromJson(Map<String, dynamic> json) {
    return SyncSettings(
      autoSync: json['autoSync'] ?? true,
      syncOnWifiOnly: json['syncOnWifiOnly'] ?? false,
      syncInterval: json['syncInterval'] ?? 15,
      backgroundSync: json['backgroundSync'] ?? true,
    );
  }
}

// Sync Settings Notifier
class SyncSettingsNotifier extends StateNotifier<SyncSettings> {
  final SyncService _syncService;

  SyncSettingsNotifier(this._syncService) : super(const SyncSettings()) {
    _loadSettings();
  }

  void _loadSettings() async {
    final settings = await _syncService.getSyncSettings();
    state = settings;
  }

  void updateAutoSync(bool enabled) async {
    state = state.copyWith(autoSync: enabled);
    await _syncService.updateSyncSettings(state);
  }

  void updateSyncOnWifiOnly(bool enabled) async {
    state = state.copyWith(syncOnWifiOnly: enabled);
    await _syncService.updateSyncSettings(state);
  }

  void updateSyncInterval(int interval) async {
    state = state.copyWith(syncInterval: interval);
    await _syncService.updateSyncSettings(state);
  }

  void updateBackgroundSync(bool enabled) async {
    state = state.copyWith(backgroundSync: enabled);
    await _syncService.updateSyncSettings(state);
  }
}

// Sync Settings Provider
final syncSettingsProvider =
    StateNotifierProvider<SyncSettingsNotifier, SyncSettings>((ref) {
      return SyncSettingsNotifier(ref.watch(syncServiceProvider));
    });
