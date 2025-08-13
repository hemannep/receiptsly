// lib/services/firebase/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/config/environment.dart';

/// Core Firebase service for initialization and configuration
/// Manages Firebase app lifecycle and global settings
class FirebaseService {
  static FirebaseService? _instance;
  late FirebaseApp _app;
  late FirebaseMessaging _messaging;
  late FirebaseCrashlytics _crashlytics;
  late FirebasePerformance _performance;
  late FirebaseRemoteConfig _remoteConfig;

  bool _isInitialized = false;
  Map<String, dynamic> _remoteConfigValues = {};
  String? _fcmToken;

  // Singleton pattern
  FirebaseService._();

  static FirebaseService getInstance() {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Firebase already initialized');
      return;
    }

    try {
      debugPrint('Initializing Firebase...');

      // Initialize Firebase app
      _app = await Firebase.initializeApp(
        name: 'receiptsly',
        options: _getFirebaseOptions(),
      );

      // Initialize core services
      await _initializeCrashlytics();
      await _initializeMessaging();
      await _initializePerformance();
      await _initializeRemoteConfig();

      // Setup global error handling
      _setupGlobalErrorHandling();

      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Get Firebase options based on environment
  FirebaseOptions _getFirebaseOptions() {
    final config = AppConfig.firebaseOptions;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return FirebaseOptions(
        apiKey: config['apiKey'],
        appId: config['appId'],
        messagingSenderId: config['messagingSenderId'],
        projectId: config['projectId'],
        storageBucket: config['storageBucket'],
        authDomain: config['authDomain'],
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return FirebaseOptions(
        apiKey: config['apiKey'],
        appId: config['appId'],
        messagingSenderId: config['messagingSenderId'],
        projectId: config['projectId'],
        storageBucket: config['storageBucket'],
        authDomain: config['authDomain'],
        iosBundleId: 'com.receiptsly.app',
        iosClientId: config['iosClientId'],
      );
    } else {
      // Web configuration
      return FirebaseOptions(
        apiKey: config['apiKey'],
        appId: config['appId'],
        messagingSenderId: config['messagingSenderId'],
        projectId: config['projectId'],
        storageBucket: config['storageBucket'],
        authDomain: config['authDomain'],
        measurementId: config['measurementId'],
      );
    }
  }

  /// Initialize Crashlytics
  Future<void> _initializeCrashlytics() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable crash collection in release mode
      if (kReleaseMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
      } else {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
      }

      // Set user identifier
      await _crashlytics.setUserIdentifier(
        'user_${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint('Crashlytics initialized');
    } catch (e) {
      debugPrint('Error initializing Crashlytics: $e');
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeMessaging() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission for iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _requestIOSPermissions();
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        // Update token on server
        _updateTokenOnServer(newToken);
      });

      // Setup message handlers
      _setupMessageHandlers();

      debugPrint('Firebase Messaging initialized');
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  /// Request iOS permissions for notifications
  Future<void> _requestIOSPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      debugPrint(
        'iOS notification permission: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('Error requesting iOS permissions: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle message when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleMessage(message, MessageLocation.foreground);
    });

    // Handle message when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'App opened from background via message: ${message.messageId}',
      );
      _handleMessage(message, MessageLocation.background);
    });

    // Handle message when app is opened from terminated state
    FirebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          'App opened from terminated state via message: ${message.messageId}',
        );
        _handleMessage(message, MessageLocation.terminated);
      }
    });
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message, MessageLocation location) {
    try {
      final data = message.data;
      final notification = message.notification;

      debugPrint('Message data: $data');
      debugPrint(
        'Message notification: ${notification?.title} - ${notification?.body}',
      );

      // Process message based on type
      final messageType = data['type'] ?? 'general';

      switch (messageType) {
        case 'receipt_processed':
          _handleReceiptProcessedMessage(data);
          break;
        case 'invoice_paid':
          _handleInvoicePaidMessage(data);
          break;
        case 'sync_completed':
          _handleSyncCompletedMessage(data);
          break;
        case 'reminder':
          _handleReminderMessage(data);
          break;
        default:
          _handleGeneralMessage(data);
      }

      // Track message analytics
      _trackMessageAnalytics(messageType, location);
    } catch (e) {
      debugPrint('Error handling message: $e');
      recordError(e, StackTrace.current, 'Message handling error');
    }
  }

  /// Handle receipt processed message
  void _handleReceiptProcessedMessage(Map<String, dynamic> data) {
    // Notify UI to refresh receipt data
    // Could use EventBus or similar to communicate with UI
    debugPrint('Receipt processed: ${data['receipt_id']}');
  }

  /// Handle invoice paid message
  void _handleInvoicePaidMessage(Map<String, dynamic> data) {
    debugPrint('Invoice paid: ${data['invoice_id']}');
  }

  /// Handle sync completed message
  void _handleSyncCompletedMessage(Map<String, dynamic> data) {
    debugPrint('Sync completed: ${data['sync_id']}');
  }

  /// Handle reminder message
  void _handleReminderMessage(Map<String, dynamic> data) {
    debugPrint('Reminder: ${data['reminder_type']}');
  }

  /// Handle general message
  void _handleGeneralMessage(Map<String, dynamic> data) {
    debugPrint('General message received');
  }

  /// Update FCM token on server
  void _updateTokenOnServer(String token) {
    // Implementation would update the token on your backend
    debugPrint('Updating FCM token on server: $token');
  }

  /// Track message analytics
  void _trackMessageAnalytics(String messageType, MessageLocation location) {
    try {
      // Track with Firebase Analytics if needed
      debugPrint('Message analytics: $messageType from $location');
    } catch (e) {
      debugPrint('Error tracking message analytics: $e');
    }
  }

  /// Initialize Firebase Performance
  Future<void> _initializePerformance() async {
    try {
      _performance = FirebasePerformance.instance;

      // Enable performance monitoring in release mode
      if (kReleaseMode) {
        await _performance.setPerformanceCollectionEnabled(true);
      } else {
        await _performance.setPerformanceCollectionEnabled(false);
      }

      // Start app start trace
      final trace = _performance.newTrace('app_start');
      await trace.start();

      // Stop trace after a delay (you'd do this when app is ready)
      Future.delayed(const Duration(seconds: 2), () async {
        await trace.stop();
      });

      debugPrint('Firebase Performance initialized');
    } catch (e) {
      debugPrint('Error initializing Firebase Performance: $e');
    }
  }

  /// Initialize Remote Config
  Future<void> _initializeRemoteConfig() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set minimum fetch interval
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 5)
              : const Duration(hours: 1),
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults(_getDefaultRemoteConfigValues());

      // Fetch and activate
      await _fetchAndActivateConfig();

      debugPrint('Firebase Remote Config initialized');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
    }
  }

  /// Get default remote config values
  Map<String, dynamic> _getDefaultRemoteConfigValues() {
    return {
      'feature_ocr_enabled': true,
      'feature_whatsapp_enabled': true,
      'feature_telegram_enabled': true,
      'max_receipt_size_mb': 10,
      'max_receipts_per_month_free': 50,
      'ocr_confidence_threshold': 0.7,
      'sync_interval_minutes': 15,
      'maintenance_mode': false,
      'force_update_version': '0.0.0',
      'api_timeout_seconds': 30,
      'cache_duration_hours': 24,
      'backup_enabled': true,
      'analytics_enabled': true,
      'crash_reporting_enabled': true,
    };
  }

  /// Fetch and activate remote config
  Future<void> _fetchAndActivateConfig() async {
    try {
      final success = await _remoteConfig.fetchAndActivate();
      if (success) {
        _updateLocalConfigValues();
        debugPrint('Remote config fetched and activated');
      } else {
        debugPrint('Remote config fetch failed or no new values');
      }
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
    }
  }

  /// Update local config values
  void _updateLocalConfigValues() {
    try {
      final keys = _remoteConfig.getAll().keys;
      for (final key in keys) {
        final value = _remoteConfig.getValue(key);
        switch (value.valueType) {
          case ValueType.valueBool:
            _remoteConfigValues[key] = value.asBool();
            break;
          case ValueType.valueDouble:
            _remoteConfigValues[key] = value.asDouble();
            break;
          case ValueType.valueInt:
            _remoteConfigValues[key] = value.asInt();
            break;
          case ValueType.valueString:
            _remoteConfigValues[key] = value.asString();
            break;
          default:
            _remoteConfigValues[key] = value.asString();
        }
      }
      debugPrint(
        'Local config values updated: ${_remoteConfigValues.length} values',
      );
    } catch (e) {
      debugPrint('Error updating local config values: $e');
    }
  }

  /// Setup global error handling
  void _setupGlobalErrorHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(details.exception, details.stack, 'Flutter framework error');
    };

    // Catch errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, 'Platform dispatcher error');
      return true;
    };
  }

  // Public Methods

  /// Get Firebase app instance
  FirebaseApp get app => _app;

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Get remote config value
  T getRemoteConfig<T>(String key, T defaultValue) {
    try {
      return _remoteConfigValues[key] as T? ?? defaultValue;
    } catch (e) {
      debugPrint('Error getting remote config value for $key: $e');
      return defaultValue;
    }
  }

  /// Check if feature is enabled via remote config
  bool isFeatureEnabled(String featureName) {
    return getRemoteConfig<bool>('feature_${featureName}_enabled', false);
  }

  /// Record error to Crashlytics
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack,
    String reason, {
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) async {
    try {
      if (!_isInitialized) return;

      debugPrint('Recording error: $reason - $exception');

      // Add additional context
      await _crashlytics.setCustomKey('reason', reason);
      await _crashlytics.setCustomKey(
        'timestamp',
        DateTime.now().toIso8601String(),
      );

      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Record the error
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Error recording to Crashlytics: $e');
    }
  }

  /// Log custom event
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (!_isInitialized) return;

      debugPrint('Logging event: $eventName with parameters: $parameters');

      // Log to crashlytics for debugging
      await _crashlytics.log('Event: $eventName - $parameters');
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Set user identifier
  Future<void> setUserId(String userId) async {
    try {
      if (!_isInitialized) return;

      await _crashlytics.setUserIdentifier(userId);
      debugPrint('User ID set: $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  /// Set custom user data
  Future<void> setUserData({
    String? email,
    String? name,
    String? plan,
    Map<String, dynamic>? customData,
  }) async {
    try {
      if (!_isInitialized) return;

      if (email != null) {
        await _crashlytics.setCustomKey('user_email', email);
      }
      if (name != null) {
        await _crashlytics.setCustomKey('user_name', name);
      }
      if (plan != null) {
        await _crashlytics.setCustomKey('user_plan', plan);
      }

      if (customData != null) {
        for (final entry in customData.entries) {
          await _crashlytics.setCustomKey(
            'custom_${entry.key}',
            entry.value.toString(),
          );
        }
      }

      debugPrint('User data set');
    } catch (e) {
      debugPrint('Error setting user data: $e');
    }
  }

  /// Start performance trace
  Trace startTrace(String traceName) {
    try {
      return _performance.newTrace(traceName);
    } catch (e) {
      debugPrint('Error starting trace: $e');
      // Return a dummy trace that does nothing
      return _DummyTrace();
    }
  }

  /// Start HTTP metric
  HttpMetric startHttpMetric(String url, HttpMethod method) {
    try {
      return _performance.newHttpMetric(url, method);
    } catch (e) {
      debugPrint('Error starting HTTP metric: $e');
      // Return a dummy metric that does nothing
      return _DummyHttpMetric();
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Check if app needs update
  bool shouldForceUpdate(String currentVersion) {
    final forceUpdateVersion = getRemoteConfig<String>(
      'force_update_version',
      '0.0.0',
    );
    return _compareVersions(currentVersion, forceUpdateVersion) < 0;
  }

  /// Compare version strings
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part < v2Part) return -1;
      if (v1Part > v2Part) return 1;
    }

    return 0;
  }

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode =>
      getRemoteConfig<bool>('maintenance_mode', false);

  /// Get API timeout
  Duration get apiTimeout =>
      Duration(seconds: getRemoteConfig<int>('api_timeout_seconds', 30));

  /// Get cache duration
  Duration get cacheDuration =>
      Duration(hours: getRemoteConfig<int>('cache_duration_hours', 24));

  /// Get sync interval
  Duration get syncInterval =>
      Duration(minutes: getRemoteConfig<int>('sync_interval_minutes', 15));

  /// Get OCR confidence threshold
  double get ocrConfidenceThreshold =>
      getRemoteConfig<double>('ocr_confidence_threshold', 0.7);

  /// Get max receipt size in MB
  int get maxReceiptSizeMB => getRemoteConfig<int>('max_receipt_size_mb', 10);

  /// Get max receipts per month for free plan
  int get maxReceiptsPerMonthFree =>
      getRemoteConfig<int>('max_receipts_per_month_free', 50);

  /// Refresh remote config
  Future<void> refreshRemoteConfig() async {
    try {
      await _fetchAndActivateConfig();
      debugPrint('Remote config refreshed');
    } catch (e) {
      debugPrint('Error refreshing remote config: $e');
    }
  }

  /// Get device info for crash reporting
  Future<void> setDeviceInfo(Map<String, dynamic> deviceInfo) async {
    try {
      for (final entry in deviceInfo.entries) {
        await _crashlytics.setCustomKey(
          'device_${entry.key}',
          entry.value.toString(),
        );
      }
      debugPrint('Device info set for crash reporting');
    } catch (e) {
      debugPrint('Error setting device info: $e');
    }
  }

  /// Test crash reporting (debug only)
  Future<void> testCrash() async {
    if (kDebugMode) {
      await _crashlytics.crash();
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    try {
      await _crashlytics.setUserIdentifier('');
      await setUserData(); // Clear all user data
      debugPrint('User data cleared');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _instance = null;
  }
}

/// Enum for message locations
enum MessageLocation { foreground, background, terminated }

/// Dummy trace implementation for error cases
class _DummyTrace implements Trace {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void incrementMetric(String metricName, int value) {}

  @override
  void putAttribute(String attributeName, String value) {}

  @override
  void putMetric(String metricName, int value) {}

  @override
  void removeAttribute(String attributeName) {}

  @override
  Map<String, String> getAttributes() => {};

  @override
  int getMetric(String metricName) => 0;
}

/// Dummy HTTP metric implementation for error cases
class _DummyHttpMetric implements HttpMetric {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void putAttribute(String attributeName, String value) {}

  @override
  void removeAttribute(String attributeName) {}

  @override
  Map<String, String> getAttributes() => {};

  @override
  set httpResponseCode(int? httpResponseCode) {}

  @override
  set requestPayloadSize(int? requestPayloadSize) {}

  @override
  set responseContentType(String? responseContentType) {}

  @override
  set responsePayloadSize(int? responsePayloadSize) {}
}
