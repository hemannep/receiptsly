// lib/services/notification/local_notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

enum NotificationType {
  receiptProcessed,
  invoiceDue,
  paymentReceived,
  syncComplete,
  syncFailed,
  expenseReminder,
  backupReminder,
  subscriptionExpiring,
  reportReady,
  clientUpdate,
}

enum NotificationPriority { min, low, normal, high, max }

class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool requiresAuth;
  final Map<String, dynamic>? payload;

  NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.requiresAuth = false,
    this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'requiresAuth': requiresAuth,
      'payload': payload,
    };
  }

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      id: map['id'],
      title: map['title'],
      icon: map['icon'],
      requiresAuth: map['requiresAuth'] ?? false,
      payload: map['payload'],
    );
  }
}

class NotificationData {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? iconPath;
  final NotificationPriority priority;
  final DateTime scheduledTime;
  final List<NotificationAction> actions;
  final Map<String, dynamic> payload;
  final bool isRecurring;
  final Duration? recurringInterval;
  final int? maxRecurringCount;
  final String? channelId;
  final String? sound;
  final bool enableVibration;
  final bool enableLights;
  final String? color;
  final String? category;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.iconPath,
    this.priority = NotificationPriority.normal,
    required this.scheduledTime,
    this.actions = const [],
    this.payload = const {},
    this.isRecurring = false,
    this.recurringInterval,
    this.maxRecurringCount,
    this.channelId,
    this.sound,
    this.enableVibration = true,
    this.enableLights = true,
    this.color,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'iconPath': iconPath,
      'priority': priority.index,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'actions': actions.map((a) => a.toMap()).toList(),
      'payload': payload,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval?.inMilliseconds,
      'maxRecurringCount': maxRecurringCount,
      'channelId': channelId,
      'sound': sound,
      'enableVibration': enableVibration,
      'enableLights': enableLights,
      'color': color,
      'category': category,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      id: map['id'],
      type: NotificationType.values[map['type']],
      title: map['title'],
      body: map['body'],
      imageUrl: map['imageUrl'],
      iconPath: map['iconPath'],
      priority: NotificationPriority.values[map['priority'] ?? 2],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime']),
      actions: (map['actions'] as List? ?? [])
          .map((a) => NotificationAction.fromMap(a))
          .toList(),
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      isRecurring: map['isRecurring'] ?? false,
      recurringInterval: map['recurringInterval'] != null
          ? Duration(milliseconds: map['recurringInterval'])
          : null,
      maxRecurringCount: map['maxRecurringCount'],
      channelId: map['channelId'],
      sound: map['sound'],
      enableVibration: map['enableVibration'] ?? true,
      enableLights: map['enableLights'] ?? true,
      color: map['color'],
      category: map['category'],
    );
  }
}

class LocalNotificationService {
  static const String _prefsKey = 'pending_notifications';
  static const String _settingsKey = 'notification_settings';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationResponse> _responseController =
      StreamController<NotificationResponse>.broadcast();
  final StreamController<NotificationData> _notificationController =
      StreamController<NotificationData>.broadcast();

  Stream<NotificationResponse> get responseStream => _responseController.stream;
  Stream<NotificationData> get notificationStream =>
      _notificationController.stream;

  bool _isInitialized = false;
  Map<String, NotificationData> _pendingNotifications = {};
  Map<String, dynamic> _settings = {};

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize notification plugin
      await _initializePlugin();

      // Load saved notifications and settings
      await _loadPendingNotifications();
      await _loadSettings();

      // Create notification channels
      await _createNotificationChannels();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('LocalNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('LocalNotificationService: Initialization failed - $e');
      throw NotificationException(
        'Failed to initialize notification service: $e',
      );
    }
  }

  // Initialize the plugin with platform-specific settings
  Future<void> _initializePlugin() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Default channel
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'default',
              'Default',
              description: 'Default notification channel',
              importance: Importance.defaultImportance,
            ),
          );

      // High priority channel for urgent notifications
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'urgent',
              'Urgent',
              description: 'Urgent notifications',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              enableLights: true,
            ),
          );

      // Receipt processing channel
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'receipts',
              'Receipt Processing',
              description: 'Receipt processing notifications',
              importance: Importance.defaultImportance,
              playSound: false,
            ),
          );

      // Invoice reminders channel
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'invoices',
              'Invoice Reminders',
              description: 'Invoice due date reminders',
              importance: Importance.high,
              playSound: true,
            ),
          );

      // Sync notifications channel
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'sync',
              'Sync Status',
              description: 'Data synchronization notifications',
              importance: Importance.low,
              playSound: false,
            ),
          );
    }
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Request exact alarm permission for Android 12+
      final exactAlarmPermission = await androidPlugin
          ?.requestExactAlarmsPermission();

      // Request notification permission for Android 13+
      final notificationPermission = await androidPlugin
          ?.requestNotificationsPermission();

      return (exactAlarmPermission ?? true) && (notificationPermission ?? true);
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: false,
      );

      return result ?? false;
    }

    return true;
  }

  // Schedule a notification
  Future<void> scheduleNotification(NotificationData notification) async {
    if (!_isInitialized) {
      throw NotificationException('Notification service not initialized');
    }

    try {
      // Save notification data
      _pendingNotifications[notification.id] = notification;
      await _savePendingNotifications();

      // Download image if needed
      String? imagePath;
      if (notification.imageUrl != null) {
        imagePath = await _downloadImage(notification.imageUrl!);
      }

      // Prepare notification details
      final notificationDetails = await _buildNotificationDetails(
        notification,
        imagePath,
      );

      if (notification.isRecurring && notification.recurringInterval != null) {
        await _scheduleRecurringNotification(notification, notificationDetails);
      } else {
        await _scheduleSingleNotification(notification, notificationDetails);
      }

      debugPrint(
        'LocalNotificationService: Scheduled notification ${notification.id}',
      );
    } catch (e) {
      debugPrint(
        'LocalNotificationService: Failed to schedule notification - $e',
      );
      throw NotificationException('Failed to schedule notification: $e');
    }
  }

  // Schedule a single notification
  Future<void> _scheduleSingleNotification(
    NotificationData notification,
    NotificationDetails notificationDetails,
  ) async {
    final scheduledDate = tz.TZDateTime.from(
      notification.scheduledTime,
      tz.local,
    );

    await _notifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      scheduledDate,
      notificationDetails,
      payload: jsonEncode(notification.payload),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  // Schedule a recurring notification
  Future<void> _scheduleRecurringNotification(
    NotificationData notification,
    NotificationDetails notificationDetails,
  ) async {
    var currentTime = notification.scheduledTime;
    final interval = notification.recurringInterval!;
    final maxCount = notification.maxRecurringCount ?? 10;

    for (int i = 0; i < maxCount; i++) {
      if (currentTime.isBefore(DateTime.now())) {
        currentTime = currentTime.add(interval);
        continue;
      }

      final scheduledDate = tz.TZDateTime.from(currentTime, tz.local);
      final notificationId = notification.id.hashCode + i;

      await _notifications.zonedSchedule(
        notificationId,
        notification.title,
        notification.body,
        scheduledDate,
        notificationDetails,
        payload: jsonEncode({
          ...notification.payload,
          'recurrence_index': i,
          'original_id': notification.id,
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      currentTime = currentTime.add(interval);
    }
  }

  // Build platform-specific notification details
  Future<NotificationDetails> _buildNotificationDetails(
    NotificationData notification,
    String? imagePath,
  ) async {
    // Android details
    final androidDetails = AndroidNotificationDetails(
      notification.channelId ?? _getDefaultChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: _mapPriorityToImportance(notification.priority),
      priority: _mapPriorityToAndroidPriority(notification.priority),
      sound: notification.sound != null
          ? RawResourceAndroidNotificationSound(notification.sound!)
          : null,
      enableVibration: notification.enableVibration,
      enableLights: notification.enableLights,
      color: notification.color != null
          ? Color(
              int.parse(notification.color!.substring(1), radix: 16) +
                  0xFF000000,
            )
          : null,
      largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
      styleInformation: imagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              contentTitle: notification.title,
              summaryText: notification.body,
            )
          : BigTextStyleInformation(
              notification.body,
              contentTitle: notification.title,
            ),
      actions: notification.actions
          .map(
            (action) => AndroidNotificationAction(
              action.id,
              action.title,
              icon: action.icon != null
                  ? DrawableResourceAndroidBitmap(action.icon!)
                  : null,
              inputs: action.requiresAuth
                  ? [
                      const AndroidNotificationActionInput(
                        label: 'Enter password',
                        allowFreeFormInput: true,
                      ),
                    ]
                  : null,
            ),
          )
          .toList(),
      category: notification.category != null
          ? AndroidNotificationCategory.values.firstWhere(
              (cat) => cat.name == notification.category,
              orElse: () => AndroidNotificationCategory.message,
            )
          : null,
      fullScreenIntent: notification.priority == NotificationPriority.max,
      ongoing: notification.type == NotificationType.syncComplete,
      autoCancel: true,
      showWhen: true,
      when: notification.scheduledTime.millisecondsSinceEpoch,
    );

    // iOS details
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: notification.sound != null ? notification.sound! : null,
      badgeNumber: await _getNextBadgeNumber(),
      attachments: imagePath != null
          ? [DarwinNotificationAttachment(imagePath)]
          : null,
      categoryIdentifier: notification.category,
      threadIdentifier: notification.type.name,
      subtitle: _getNotificationSubtitle(notification.type),
      interruptionLevel: _mapPriorityToInterruptionLevel(notification.priority),
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // Show immediate notification
  Future<void> showNotification(NotificationData notification) async {
    if (!_isInitialized) {
      throw NotificationException('Notification service not initialized');
    }

    try {
      String? imagePath;
      if (notification.imageUrl != null) {
        imagePath = await _downloadImage(notification.imageUrl!);
      }

      final notificationDetails = await _buildNotificationDetails(
        notification,
        imagePath,
      );

      await _notifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(notification.payload),
      );

      _notificationController.add(notification);
      debugPrint(
        'LocalNotificationService: Showed notification ${notification.id}',
      );
    } catch (e) {
      debugPrint('LocalNotificationService: Failed to show notification - $e');
      throw NotificationException('Failed to show notification: $e');
    }
  }

  // Cancel notification
  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
    _pendingNotifications.remove(id);
    await _savePendingNotifications();
    debugPrint('LocalNotificationService: Cancelled notification $id');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _pendingNotifications.clear();
    await _savePendingNotifications();
    debugPrint('LocalNotificationService: Cancelled all notifications');
  }

  // Get pending notifications
  List<PendingNotificationRequest> getPendingNotifications() {
    return _notifications.pendingNotificationRequests()
        as List<PendingNotificationRequest>;
  }

  // Get notification settings
  Map<String, dynamic> getSettings() {
    return Map<String, dynamic>.from(_settings);
  }

  // Update notification settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    _settings.addAll(settings);
    await _saveSettings();
    debugPrint('LocalNotificationService: Updated settings');
  }

  // Check if notifications are enabled for a type
  bool isNotificationTypeEnabled(NotificationType type) {
    return _settings['${type.name}_enabled'] ?? true;
  }

  // Enable/disable notification type
  Future<void> setNotificationTypeEnabled(
    NotificationType type,
    bool enabled,
  ) async {
    _settings['${type.name}_enabled'] = enabled;
    await _saveSettings();

    if (!enabled) {
      // Cancel existing notifications of this type
      final toCancel = _pendingNotifications.values
          .where((n) => n.type == type)
          .map((n) => n.id)
          .toList();

      for (final id in toCancel) {
        await cancelNotification(id);
      }
    }
  }

  // Create quick notification methods for common types
  Future<void> showReceiptProcessedNotification({
    required String receiptId,
    required String vendorName,
    required double amount,
    String? imageUrl,
  }) async {
    final notification = NotificationData(
      id: 'receipt_$receiptId',
      type: NotificationType.receiptProcessed,
      title: 'Receipt Processed',
      body:
          'Receipt from $vendorName (\${amount.toStringAsFixed(2)}) has been processed',
      imageUrl: imageUrl,
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.normal,
      actions: [
        NotificationAction(
          id: 'view_receipt',
          title: 'View Receipt',
          payload: {'receiptId': receiptId},
        ),
        NotificationAction(
          id: 'edit_receipt',
          title: 'Edit',
          payload: {'receiptId': receiptId},
        ),
      ],
      payload: {'receiptId': receiptId, 'type': 'receipt_processed'},
    );

    if (isNotificationTypeEnabled(NotificationType.receiptProcessed)) {
      await showNotification(notification);
    }
  }

  Future<void> showInvoiceDueNotification({
    required String invoiceId,
    required String clientName,
    required double amount,
    required DateTime dueDate,
  }) async {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final urgency = daysUntilDue <= 1
        ? 'urgent'
        : daysUntilDue <= 7
        ? 'soon'
        : '';

    final notification = NotificationData(
      id: 'invoice_due_$invoiceId',
      type: NotificationType.invoiceDue,
      title: 'Invoice Due ${urgency.isNotEmpty ? urgency.toUpperCase() : ''}',
      body:
          'Invoice for $clientName (\${amount.toStringAsFixed(2)}) is due ${_formatDueDate(dueDate)}',
      scheduledTime: DateTime.now(),
      priority: daysUntilDue <= 1
          ? NotificationPriority.high
          : NotificationPriority.normal,
      actions: [
        NotificationAction(
          id: 'view_invoice',
          title: 'View Invoice',
          payload: {'invoiceId': invoiceId},
        ),
        NotificationAction(
          id: 'send_reminder',
          title: 'Send Reminder',
          payload: {'invoiceId': invoiceId},
        ),
      ],
      payload: {'invoiceId': invoiceId, 'type': 'invoice_due'},
    );

    if (isNotificationTypeEnabled(NotificationType.invoiceDue)) {
      await showNotification(notification);
    }
  }

  Future<void> showPaymentReceivedNotification({
    required String invoiceId,
    required String clientName,
    required double amount,
  }) async {
    final notification = NotificationData(
      id: 'payment_$invoiceId',
      type: NotificationType.paymentReceived,
      title: 'Payment Received! 💰',
      body: 'Received \${amount.toStringAsFixed(2)} from $clientName',
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.high,
      sound: 'payment_received.wav',
      actions: [
        NotificationAction(
          id: 'view_payment',
          title: 'View Details',
          payload: {'invoiceId': invoiceId},
        ),
      ],
      payload: {'invoiceId': invoiceId, 'type': 'payment_received'},
    );

    if (isNotificationTypeEnabled(NotificationType.paymentReceived)) {
      await showNotification(notification);
    }
  }

  Future<void> showSyncCompleteNotification({
    required int itemsProcessed,
    required Duration duration,
  }) async {
    final notification = NotificationData(
      id: 'sync_complete_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.syncComplete,
      title: 'Sync Complete',
      body: 'Synced $itemsProcessed items in ${duration.inSeconds} seconds',
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.low,
      payload: {'type': 'sync_complete', 'items': itemsProcessed},
    );

    if (isNotificationTypeEnabled(NotificationType.syncComplete)) {
      await showNotification(notification);
    }
  }

  Future<void> showSyncFailedNotification({
    required String error,
    required int retryCount,
  }) async {
    final notification = NotificationData(
      id: 'sync_failed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.syncFailed,
      title: 'Sync Failed',
      body: retryCount > 0
          ? 'Sync failed after $retryCount attempts. Tap to retry.'
          : 'Sync failed. Tap to retry.',
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.normal,
      actions: [
        NotificationAction(
          id: 'retry_sync',
          title: 'Retry Now',
          payload: {'action': 'retry_sync'},
        ),
        NotificationAction(
          id: 'view_error',
          title: 'View Error',
          payload: {'error': error},
        ),
      ],
      payload: {
        'type': 'sync_failed',
        'error': error,
        'retryCount': retryCount,
      },
    );

    if (isNotificationTypeEnabled(NotificationType.syncFailed)) {
      await showNotification(notification);
    }
  }

  // Schedule expense reminder notifications
  Future<void> scheduleExpenseReminder({
    required DateTime reminderTime,
    required String message,
  }) async {
    final notification = NotificationData(
      id: 'expense_reminder_${reminderTime.millisecondsSinceEpoch}',
      type: NotificationType.expenseReminder,
      title: 'Expense Reminder',
      body: message,
      scheduledTime: reminderTime,
      priority: NotificationPriority.normal,
      isRecurring: true,
      recurringInterval: const Duration(days: 1),
      maxRecurringCount: 30,
      actions: [
        NotificationAction(
          id: 'add_expense',
          title: 'Add Expense',
          payload: {'action': 'add_expense'},
        ),
        NotificationAction(
          id: 'snooze',
          title: 'Snooze 1h',
          payload: {'action': 'snooze', 'duration': 3600},
        ),
      ],
      payload: {'type': 'expense_reminder'},
    );

    if (isNotificationTypeEnabled(NotificationType.expenseReminder)) {
      await scheduleNotification(notification);
    }
  }

  // Helper methods
  String _getDefaultChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessed:
        return 'receipts';
      case NotificationType.invoiceDue:
      case NotificationType.paymentReceived:
        return 'invoices';
      case NotificationType.syncComplete:
      case NotificationType.syncFailed:
        return 'sync';
      case NotificationType.subscriptionExpiring:
        return 'urgent';
      default:
        return 'default';
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessed:
        return 'Receipt Processing';
      case NotificationType.invoiceDue:
      case NotificationType.paymentReceived:
        return 'Invoice Reminders';
      case NotificationType.syncComplete:
      case NotificationType.syncFailed:
        return 'Sync Status';
      case NotificationType.expenseReminder:
        return 'Expense Reminders';
      case NotificationType.backupReminder:
        return 'Backup Reminders';
      case NotificationType.subscriptionExpiring:
        return 'Subscription Alerts';
      case NotificationType.reportReady:
        return 'Report Notifications';
      case NotificationType.clientUpdate:
        return 'Client Updates';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessed:
        return 'Notifications when receipts are processed';
      case NotificationType.invoiceDue:
        return 'Reminders for invoice due dates';
      case NotificationType.paymentReceived:
        return 'Notifications when payments are received';
      case NotificationType.syncComplete:
        return 'Data sync completion notifications';
      case NotificationType.syncFailed:
        return 'Data sync failure notifications';
      case NotificationType.expenseReminder:
        return 'Reminders to log expenses';
      case NotificationType.backupReminder:
        return 'Reminders to backup data';
      case NotificationType.subscriptionExpiring:
        return 'Subscription expiration alerts';
      case NotificationType.reportReady:
        return 'Report generation notifications';
      case NotificationType.clientUpdate:
        return 'Client-related update notifications';
    }
  }

  String? _getNotificationSubtitle(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessed:
        return 'Receiptsly';
      case NotificationType.invoiceDue:
        return 'Invoice Reminder';
      case NotificationType.paymentReceived:
        return 'Payment Alert';
      default:
        return null;
    }
  }

  Importance _mapPriorityToImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Importance.min;
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }

  Priority _mapPriorityToAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  InterruptionLevel _mapPriorityToInterruptionLevel(
    NotificationPriority priority,
  ) {
    switch (priority) {
      case NotificationPriority.min:
      case NotificationPriority.low:
        return InterruptionLevel.passive;
      case NotificationPriority.normal:
        return InterruptionLevel.active;
      case NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case NotificationPriority.max:
        return InterruptionLevel.critical;
    }
  }

  Future<int> _getNextBadgeNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('badge_number') ?? 0;
    final next = current + 1;
    await prefs.setInt('badge_number', next);
    return next;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'tomorrow';
    if (difference == -1) return 'yesterday';
    if (difference < 0) return '${difference.abs()} days ago';
    return 'in $difference days';
  }

  Future<String?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final fileName = imageUrl.split('/').last;
        final file = File('${documentsDir.path}/notifications/$fileName');

        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      }
    } catch (e) {
      debugPrint('LocalNotificationService: Failed to download image - $e');
    }
    return null;
  }

  // Notification response handlers
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // Handle iOS foreground notifications (older versions)
    debugPrint(
      'LocalNotificationService: Received local notification - $title',
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _responseController.add(response);
    _handleNotificationResponse(response);
  }

  static void _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response,
  ) {
    // Handle background notification responses
    debugPrint(
      'LocalNotificationService: Background response - ${response.actionId}',
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    try {
      final payload = response.payload != null
          ? jsonDecode(response.payload!) as Map<String, dynamic>
          : <String, dynamic>{};

      debugPrint(
        'LocalNotificationService: Handling response - ${response.actionId ?? 'tap'}',
      );

      // Handle different action types
      switch (response.actionId) {
        case 'view_receipt':
          _handleViewReceipt(payload);
          break;
        case 'edit_receipt':
          _handleEditReceipt(payload);
          break;
        case 'view_invoice':
          _handleViewInvoice(payload);
          break;
        case 'send_reminder':
          _handleSendReminder(payload);
          break;
        case 'retry_sync':
          _handleRetrySync(payload);
          break;
        case 'add_expense':
          _handleAddExpense(payload);
          break;
        case 'snooze':
          _handleSnooze(payload);
          break;
        default:
          _handleDefaultTap(payload);
      }
    } catch (e) {
      debugPrint('LocalNotificationService: Error handling response - $e');
    }
  }

  void _handleViewReceipt(Map<String, dynamic> payload) {
    // Navigate to receipt view
    debugPrint(
      'LocalNotificationService: View receipt ${payload['receiptId']}',
    );
  }

  void _handleEditReceipt(Map<String, dynamic> payload) {
    // Navigate to receipt edit
    debugPrint(
      'LocalNotificationService: Edit receipt ${payload['receiptId']}',
    );
  }

  void _handleViewInvoice(Map<String, dynamic> payload) {
    // Navigate to invoice view
    debugPrint(
      'LocalNotificationService: View invoice ${payload['invoiceId']}',
    );
  }

  void _handleSendReminder(Map<String, dynamic> payload) {
    // Send invoice reminder
    debugPrint(
      'LocalNotificationService: Send reminder for ${payload['invoiceId']}',
    );
  }

  void _handleRetrySync(Map<String, dynamic> payload) {
    // Trigger sync retry
    debugPrint('LocalNotificationService: Retry sync');
  }

  void _handleAddExpense(Map<String, dynamic> payload) {
    // Navigate to add expense
    debugPrint('LocalNotificationService: Add expense');
  }

  void _handleSnooze(Map<String, dynamic> payload) {
    // Snooze notification
    final duration = payload['duration'] as int? ?? 3600; // 1 hour default
    debugPrint('LocalNotificationService: Snooze for ${duration}s');
  }

  void _handleDefaultTap(Map<String, dynamic> payload) {
    // Handle default notification tap
    debugPrint('LocalNotificationService: Default tap - ${payload['type']}');
  }

  // Data persistence methods
  Future<void> _loadPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_prefsKey);

      if (notificationsJson != null) {
        final notificationsList = jsonDecode(notificationsJson) as List;

        for (final notificationMap in notificationsList) {
          final notification = NotificationData.fromMap(notificationMap);
          _pendingNotifications[notification.id] = notification;
        }

        debugPrint(
          'LocalNotificationService: Loaded ${_pendingNotifications.length} pending notifications',
        );
      }
    } catch (e) {
      debugPrint('LocalNotificationService: Error loading notifications - $e');
    }
  }

  Future<void> _savePendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsList = _pendingNotifications.values
          .map((n) => n.toMap())
          .toList();
      final notificationsJson = jsonEncode(notificationsList);

      await prefs.setString(_prefsKey, notificationsJson);
    } catch (e) {
      debugPrint('LocalNotificationService: Error saving notifications - $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        _settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
      } else {
        // Default settings
        _settings = {
          for (final type in NotificationType.values)
            '${type.name}_enabled': true,
        };
      }
    } catch (e) {
      debugPrint('LocalNotificationService: Error loading settings - $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings);
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('LocalNotificationService: Error saving settings - $e');
    }
  }

  // Cleanup and disposal
  Future<void> dispose() async {
    await _responseController.close();
    await _notificationController.close();
    _isInitialized = false;
    debugPrint('LocalNotificationService: Disposed');
  }
}

// Custom exception for notification service errors
class NotificationException implements Exception {
  final String message;

  NotificationException(this.message);

  @override
  String toString() => 'NotificationException: $message';
}
