// lib/services/notification/push_notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

enum PushNotificationTopic {
  allUsers,
  premiumUsers,
  invoiceReminders,
  receiptUpdates,
  syncNotifications,
  systemAnnouncements,
  securityAlerts,
  featureUpdates,
}

enum MessagePriority { normal, high }

class PushNotificationData {
  final String messageId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? icon;
  final String? sound;
  final String? clickAction;
  final MessagePriority priority;
  final DateTime receivedAt;
  final bool isBackground;
  final RemoteMessage originalMessage;

  PushNotificationData({
    required this.messageId,
    required this.title,
    required this.body,
    required this.data,
    this.imageUrl,
    this.icon,
    this.sound,
    this.clickAction,
    this.priority = MessagePriority.normal,
    required this.receivedAt,
    required this.isBackground,
    required this.originalMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'title': title,
      'body': body,
      'data': data,
      'imageUrl': imageUrl,
      'icon': icon,
      'sound': sound,
      'clickAction': clickAction,
      'priority': priority.index,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
      'isBackground': isBackground,
    };
  }

  factory PushNotificationData.fromMap(Map<String, dynamic> map) {
    return PushNotificationData(
      messageId: map['messageId'],
      title: map['title'],
      body: map['body'],
      data: Map<String, dynamic>.from(map['data']),
      imageUrl: map['imageUrl'],
      icon: map['icon'],
      sound: map['sound'],
      clickAction: map['clickAction'],
      priority: MessagePriority.values[map['priority'] ?? 0],
      receivedAt: DateTime.fromMillisecondsSinceEpoch(map['receivedAt']),
      isBackground: map['isBackground'] ?? false,
      originalMessage:
          map['originalMessage'], // This would need custom serialization
    );
  }

  factory PushNotificationData.fromRemoteMessage(
    RemoteMessage message, {
    bool isBackground = false,
  }) {
    final notification = message.notification;
    return PushNotificationData(
      messageId: message.messageId ?? '',
      title: notification?.title ?? '',
      body: notification?.body ?? '',
      data: message.data,
      imageUrl:
          notification?.android?.imageUrl ?? notification?.apple?.imageUrl,
      icon: notification?.android?.icon,
      sound: notification?.android?.sound ?? notification?.apple?.sound?.name,
      clickAction: notification?.android?.clickAction,
      priority: message.priority == Priority.high
          ? MessagePriority.high
          : MessagePriority.normal,
      receivedAt: DateTime.now(),
      isBackground: isBackground,
      originalMessage: message,
    );
  }
}

class PushNotificationService {
  static const String _prefsKey = 'push_notification_settings';
  static const String _messageHistoryKey = 'push_message_history';
  static const String _tokenKey = 'fcm_token';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<PushNotificationData> _messageController =
      StreamController<PushNotificationData>.broadcast();
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  Stream<PushNotificationData> get messageStream => _messageController.stream;
  Stream<String> get tokenStream => _tokenController.stream;

  bool _isInitialized = false;
  String? _currentToken;
  Map<String, dynamic> _settings = {};
  List<PushNotificationData> _messageHistory = [];

  // Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Load settings and history
      await _loadSettings();
      await _loadMessageHistory();

      // Setup message handlers
      _setupMessageHandlers();

      // Get and store FCM token
      await _setupToken();

      // Setup token refresh listener
      _setupTokenRefresh();

      _isInitialized = true;
      debugPrint('PushNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('PushNotificationService: Initialization failed - $e');
      throw PushNotificationException(
        'Failed to initialize push notification service: $e',
      );
    }
  }

  // Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'PushNotificationService: Permission status - ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw PushNotificationException('Push notification permissions denied');
    }

    return settings;
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Handle app launch from terminated state
    _handleAppLaunchFromMessage();
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('PushNotificationService: Foreground message received');

    final notificationData = PushNotificationData.fromRemoteMessage(
      message,
      isBackground: false,
    );

    _processMessage(notificationData);
  }

  // Handle message tap (background)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('PushNotificationService: Message tapped from background');

    final notificationData = PushNotificationData.fromRemoteMessage(
      message,
      isBackground: true,
    );

    _processMessage(notificationData);
    _handleMessageAction(notificationData);
  }

  // Handle app launch from terminated state
  void _handleAppLaunchFromMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('PushNotificationService: App launched from message');

        final notificationData = PushNotificationData.fromRemoteMessage(
          message,
          isBackground: true,
        );

        _processMessage(notificationData);
        _handleMessageAction(notificationData);
      }
    });
  }

  // Process incoming message
  void _processMessage(PushNotificationData notificationData) {
    try {
      // Add to message history
      _messageHistory.insert(0, notificationData);

      // Keep only last 100 messages
      if (_messageHistory.length > 100) {
        _messageHistory = _messageHistory.take(100).toList();
      }

      // Save to local storage
      _saveMessageHistory();

      // Check if message type is enabled
      final messageType = notificationData.data['type'] as String?;
      if (messageType != null && !_isMessageTypeEnabled(messageType)) {
        debugPrint(
          'PushNotificationService: Message type $messageType is disabled',
        );
        return;
      }

      // Emit message to listeners
      _messageController.add(notificationData);

      // Track message analytics
      _trackMessageAnalytics(notificationData);

      debugPrint(
        'PushNotificationService: Processed message ${notificationData.messageId}',
      );
    } catch (e) {
      debugPrint('PushNotificationService: Error processing message - $e');
    }
  }

  // Handle message action based on type
  void _handleMessageAction(PushNotificationData notificationData) {
    final action = notificationData.data['action'] as String?;
    final type = notificationData.data['type'] as String?;

    switch (action ?? type) {
      case 'receipt_processed':
        _handleReceiptProcessedAction(notificationData);
        break;
      case 'invoice_due':
        _handleInvoiceDueAction(notificationData);
        break;
      case 'payment_received':
        _handlePaymentReceivedAction(notificationData);
        break;
      case 'sync_complete':
        _handleSyncCompleteAction(notificationData);
        break;
      case 'backup_reminder':
        _handleBackupReminderAction(notificationData);
        break;
      case 'feature_update':
        _handleFeatureUpdateAction(notificationData);
        break;
      case 'security_alert':
        _handleSecurityAlertAction(notificationData);
        break;
      default:
        _handleDefaultAction(notificationData);
    }
  }

  // Setup FCM token
  Future<void> _setupToken() async {
    try {
      _currentToken = await _messaging.getToken();

      if (_currentToken != null) {
        await _storeToken(_currentToken!);
        await _registerTokenWithServer(_currentToken!);
        _tokenController.add(_currentToken!);

        debugPrint('PushNotificationService: FCM Token - $_currentToken');
      }
    } catch (e) {
      debugPrint('PushNotificationService: Error setting up token - $e');
    }
  }

  // Setup token refresh listener
  void _setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _storeToken(token);
      await _registerTokenWithServer(token);
      _tokenController.add(token);

      debugPrint('PushNotificationService: Token refreshed - $token');
    });
  }

  // Register token with server
  Future<void> _registerTokenWithServer(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint(
          'PushNotificationService: No authenticated user for token registration',
        );
        return;
      }

      final deviceInfo = await _getDeviceInfo();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(_getDeviceId())
          .set({
            'fcmToken': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'deviceInfo': deviceInfo,
            'lastUpdated': FieldValue.serverTimestamp(),
            'isActive': true,
          }, SetOptions(merge: true));

      debugPrint('PushNotificationService: Token registered with server');
    } catch (e) {
      debugPrint('PushNotificationService: Error registering token - $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(PushNotificationTopic topic) async {
    try {
      await _messaging.subscribeToTopic(topic.name);

      // Update local settings
      _settings['topics'] ??= <String, bool>{};
      _settings['topics'][topic.name] = true;
      await _saveSettings();

      debugPrint('PushNotificationService: Subscribed to topic ${topic.name}');
    } catch (e) {
      debugPrint('PushNotificationService: Error subscribing to topic - $e');
      throw PushNotificationException('Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(PushNotificationTopic topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic.name);

      // Update local settings
      _settings['topics'] ??= <String, bool>{};
      _settings['topics'][topic.name] = false;
      await _saveSettings();

      debugPrint(
        'PushNotificationService: Unsubscribed from topic ${topic.name}',
      );
    } catch (e) {
      debugPrint(
        'PushNotificationService: Error unsubscribing from topic - $e',
      );
      throw PushNotificationException('Failed to unsubscribe from topic: $e');
    }
  }

  // Get current FCM token
  String? getCurrentToken() {
    return _currentToken;
  }

  // Get message history
  List<PushNotificationData> getMessageHistory() {
    return List.unmodifiable(_messageHistory);
  }

  // Clear message history
  Future<void> clearMessageHistory() async {
    _messageHistory.clear();
    await _saveMessageHistory();
    debugPrint('PushNotificationService: Message history cleared');
  }

  // Get unread message count
  int getUnreadMessageCount() {
    return _messageHistory
        .where((msg) => _settings['read_messages']?[msg.messageId] != true)
        .length;
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    _settings['read_messages'] ??= <String, bool>{};
    _settings['read_messages'][messageId] = true;
    await _saveSettings();
  }

  // Mark all messages as read
  Future<void> markAllMessagesAsRead() async {
    _settings['read_messages'] ??= <String, bool>{};
    for (final message in _messageHistory) {
      _settings['read_messages'][message.messageId] = true;
    }
    await _saveSettings();
  }

  // Enable/disable message type
  Future<void> setMessageTypeEnabled(String messageType, bool enabled) async {
    _settings['message_types'] ??= <String, bool>{};
    _settings['message_types'][messageType] = enabled;
    await _saveSettings();

    debugPrint(
      'PushNotificationService: Message type $messageType ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  // Check if message type is enabled
  bool _isMessageTypeEnabled(String messageType) {
    return _settings['message_types']?[messageType] ?? true;
  }

  // Get notification settings
  Map<String, dynamic> getSettings() {
    return Map<String, dynamic>.from(_settings);
  }

  // Update settings
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings.addAll(newSettings);
    await _saveSettings();
  }

  // Send message to user (admin function)
  Future<void> sendMessageToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    try {
      // Get user's FCM tokens
      final userDevices = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .where('isActive', isEqualTo: true)
          .get();

      if (userDevices.docs.isEmpty) {
        throw PushNotificationException('No active devices found for user');
      }

      // Send to all user devices
      for (final device in userDevices.docs) {
        final token = device.data()['fcmToken'] as String?;
        if (token != null) {
          await _sendToToken(
            token: token,
            title: title,
            body: body,
            data: data ?? {},
            imageUrl: imageUrl,
            priority: priority,
          );
        }
      }

      debugPrint('PushNotificationService: Message sent to user $userId');
    } catch (e) {
      debugPrint('PushNotificationService: Error sending message to user - $e');
      throw PushNotificationException('Failed to send message: $e');
    }
  }

  // Send message to topic
  Future<void> sendMessageToTopic({
    required PushNotificationTopic topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    try {
      await _sendToTopic(
        topic: topic.name,
        title: title,
        body: body,
        data: data ?? {},
        imageUrl: imageUrl,
        priority: priority,
      );

      debugPrint(
        'PushNotificationService: Message sent to topic ${topic.name}',
      );
    } catch (e) {
      debugPrint(
        'PushNotificationService: Error sending message to topic - $e',
      );
      throw PushNotificationException('Failed to send message to topic: $e');
    }
  }

  // Private helper methods

  Future<void> _sendToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    // This would typically be done server-side using Firebase Admin SDK
    // For demo purposes, we'll show the structure
    final message = {
      'token': token,
      'notification': {'title': title, 'body': body, 'image': imageUrl},
      'data': data.map((key, value) => MapEntry(key, value.toString())),
      'android': {
        'priority': priority == MessagePriority.high ? 'high' : 'normal',
        'notification': {
          'channelId': 'default',
          'priority': priority == MessagePriority.high ? 'high' : 'default',
          'defaultSound': true,
          'defaultVibrateTimings': true,
        },
      },
      'apns': {
        'headers': {
          'apns-priority': priority == MessagePriority.high ? '10' : '5',
        },
        'payload': {
          'aps': {
            'alert': {'title': title, 'body': body},
            'sound': 'default',
            'badge': 1,
          },
        },
      },
    };

    debugPrint('PushNotificationService: Would send message: $message');
  }

  Future<void> _sendToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    // This would typically be done server-side using Firebase Admin SDK
    final message = {
      'topic': topic,
      'notification': {'title': title, 'body': body, 'image': imageUrl},
      'data': data.map((key, value) => MapEntry(key, value.toString())),
      'android': {
        'priority': priority == MessagePriority.high ? 'high' : 'normal',
      },
      'apns': {
        'headers': {
          'apns-priority': priority == MessagePriority.high ? '10' : '5',
        },
      },
    };

    debugPrint('PushNotificationService: Would send topic message: $message');
  }

  void _handleReceiptProcessedAction(PushNotificationData notification) {
    final receiptId = notification.data['receiptId'] as String?;
    if (receiptId != null) {
      // Navigate to receipt detail
      debugPrint('PushNotificationService: Navigate to receipt $receiptId');
    }
  }

  void _handleInvoiceDueAction(PushNotificationData notification) {
    final invoiceId = notification.data['invoiceId'] as String?;
    if (invoiceId != null) {
      // Navigate to invoice detail
      debugPrint('PushNotificationService: Navigate to invoice $invoiceId');
    }
  }

  void _handlePaymentReceivedAction(PushNotificationData notification) {
    final invoiceId = notification.data['invoiceId'] as String?;
    if (invoiceId != null) {
      // Navigate to payment confirmation
      debugPrint(
        'PushNotificationService: Show payment confirmation for $invoiceId',
      );
    }
  }

  void _handleSyncCompleteAction(PushNotificationData notification) {
    // Show sync results
    debugPrint('PushNotificationService: Show sync results');
  }

  void _handleBackupReminderAction(PushNotificationData notification) {
    // Navigate to backup settings
    debugPrint('PushNotificationService: Navigate to backup settings');
  }

  void _handleFeatureUpdateAction(PushNotificationData notification) {
    final updateUrl = notification.data['updateUrl'] as String?;
    if (updateUrl != null) {
      // Open update URL
      debugPrint('PushNotificationService: Open update URL $updateUrl');
    }
  }

  void _handleSecurityAlertAction(PushNotificationData notification) {
    // Navigate to security settings
    debugPrint('PushNotificationService: Navigate to security settings');
  }

  void _handleDefaultAction(PushNotificationData notification) {
    // Default action - open app
    debugPrint(
      'PushNotificationService: Default action for ${notification.messageId}',
    );
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'appVersion': '1.0.0', // Get from package info
      'deviceModel': await _getDeviceModel(),
    };
  }

  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        // Get Android device model
        return 'Android Device';
      } else if (Platform.isIOS) {
        // Get iOS device model
        return 'iOS Device';
      }
    } catch (e) {
      debugPrint('PushNotificationService: Error getting device model - $e');
    }
    return 'Unknown Device';
  }

  String _getDeviceId() {
    // Generate a consistent device ID
    final deviceInfo =
        '${Platform.operatingSystem}_${Platform.operatingSystemVersion}';
    final bytes = utf8.encode(deviceInfo);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  void _trackMessageAnalytics(PushNotificationData notification) {
    try {
      // Track message analytics
      final analytics = {
        'messageId': notification.messageId,
        'title': notification.title,
        'type': notification.data['type'],
        'receivedAt': notification.receivedAt.toIso8601String(),
        'isBackground': notification.isBackground,
        'priority': notification.priority.name,
      };

      debugPrint('PushNotificationService: Analytics - $analytics');

      // Send to analytics service
      // AnalyticsService.track('push_notification_received', analytics);
    } catch (e) {
      debugPrint('PushNotificationService: Error tracking analytics - $e');
    }
  }

  Future<void> _storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('PushNotificationService: Error storing token - $e');
    }
  }

  Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('PushNotificationService: Error getting stored token - $e');
      return null;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);

      if (settingsJson != null) {
        _settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
      } else {
        // Default settings
        _settings = {
          'message_types': <String, bool>{},
          'topics': <String, bool>{},
          'read_messages': <String, bool>{},
        };
      }

      debugPrint('PushNotificationService: Loaded settings');
    } catch (e) {
      debugPrint('PushNotificationService: Error loading settings - $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings);
      await prefs.setString(_prefsKey, settingsJson);
    } catch (e) {
      debugPrint('PushNotificationService: Error saving settings - $e');
    }
  }

  Future<void> _loadMessageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_messageHistoryKey);

      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List;
        _messageHistory = historyList
            .map((item) => PushNotificationData.fromMap(item))
            .toList();
      }

      debugPrint(
        'PushNotificationService: Loaded ${_messageHistory.length} messages from history',
      );
    } catch (e) {
      debugPrint('PushNotificationService: Error loading message history - $e');
    }
  }

  Future<void> _saveMessageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = _messageHistory.map((msg) => msg.toMap()).toList();
      final historyJson = jsonEncode(historyList);
      await prefs.setString(_messageHistoryKey, historyJson);
    } catch (e) {
      debugPrint('PushNotificationService: Error saving message history - $e');
    }
  }

  // Cleanup when user logs out
  Future<void> onUserLogout() async {
    try {
      // Unsubscribe from all topics
      for (final topic in PushNotificationTopic.values) {
        try {
          await _messaging.unsubscribeFromTopic(topic.name);
        } catch (e) {
          debugPrint(
            'PushNotificationService: Error unsubscribing from ${topic.name} - $e',
          );
        }
      }

      // Clear local data
      _currentToken = null;
      _messageHistory.clear();
      _settings.clear();

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_prefsKey);
      await prefs.remove(_messageHistoryKey);

      debugPrint('PushNotificationService: Cleanup completed for user logout');
    } catch (e) {
      debugPrint('PushNotificationService: Error during logout cleanup - $e');
    }
  }

  // Delete token from server when app is uninstalled or user deletes account
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('devices')
            .doc(_getDeviceId())
            .delete();
      }

      debugPrint('PushNotificationService: Token deleted');
    } catch (e) {
      debugPrint('PushNotificationService: Error deleting token - $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _messageController.close();
    await _tokenController.close();
    _isInitialized = false;
    debugPrint('PushNotificationService: Disposed');
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'PushNotificationService: Background message received - ${message.messageId}',
  );

  // Handle background message processing
  // This could include showing local notifications, updating local database, etc.

  try {
    final notificationData = PushNotificationData.fromRemoteMessage(
      message,
      isBackground: true,
    );

    // Store message in local storage for when app is opened
    final prefs = await SharedPreferences.getInstance();
    final existingMessages = prefs.getStringList('background_messages') ?? [];
    existingMessages.add(jsonEncode(notificationData.toMap()));

    // Keep only last 50 background messages
    if (existingMessages.length > 50) {
      existingMessages.removeRange(0, existingMessages.length - 50);
    }

    await prefs.setStringList('background_messages', existingMessages);

    debugPrint('PushNotificationService: Background message processed');
  } catch (e) {
    debugPrint(
      'PushNotificationService: Error processing background message - $e',
    );
  }
}

// Custom exception for push notification service errors
class PushNotificationException implements Exception {
  final String message;

  PushNotificationException(this.message);

  @override
  String toString() => 'PushNotificationException: $message';
}
