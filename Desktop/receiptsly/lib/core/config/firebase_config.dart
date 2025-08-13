// lib/core/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'environment.dart';
import 'app_config.dart';

/// Firebase configuration and initialization for Receiptsly
/// Handles environment-specific Firebase setup and service configuration
class FirebaseConfig {
  static FirebaseConfig? _instance;
  static FirebaseConfig get instance =>
      _instance ??= FirebaseConfig._internal();

  FirebaseConfig._internal();

  // Firebase service instances
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  FirebaseMessaging? _messaging;
  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  FirebasePerformance? _performance;

  bool _isInitialized = false;

  // Environment-specific Firebase options
  static const Map<Environment, FirebaseOptions> _firebaseOptions = {
    Environment.development: FirebaseOptions(
      apiKey: 'AIzaSyDEV-your-dev-api-key',
      authDomain: 'receiptsly-dev.firebaseapp.com',
      projectId: 'receiptsly-dev',
      storageBucket: 'receiptsly-dev.appspot.com',
      messagingSenderId: '123456789012',
      appId: '1:123456789012:android:dev-app-id',
      measurementId: 'G-DEV-MEASUREMENT-ID',
    ),
    Environment.staging: FirebaseOptions(
      apiKey: 'AIzaSySTAGING-your-staging-api-key',
      authDomain: 'receiptsly-staging.firebaseapp.com',
      projectId: 'receiptsly-staging',
      storageBucket: 'receiptsly-staging.appspot.com',
      messagingSenderId: '123456789013',
      appId: '1:123456789013:android:staging-app-id',
      measurementId: 'G-STAGING-MEASUREMENT-ID',
    ),
    Environment.production: FirebaseOptions(
      apiKey: 'AIzaSyPROD-your-production-api-key',
      authDomain: 'receiptsly.firebaseapp.com',
      projectId: 'receiptsly-prod',
      storageBucket: 'receiptsly-prod.appspot.com',
      messagingSenderId: '123456789014',
      appId: '1:123456789014:android:prod-app-id',
      measurementId: 'G-PROD-MEASUREMENT-ID',
    ),
  };

  // Collection names for different environments
  static const Map<Environment, Map<String, String>> _collectionNames = {
    Environment.development: {
      'users': 'users_dev',
      'receipts': 'receipts_dev',
      'invoices': 'invoices_dev',
      'clients': 'clients_dev',
      'categories': 'categories_dev',
      'subscriptions': 'subscriptions_dev',
      'analytics': 'analytics_dev',
    },
    Environment.staging: {
      'users': 'users_staging',
      'receipts': 'receipts_staging',
      'invoices': 'invoices_staging',
      'clients': 'clients_staging',
      'categories': 'categories_staging',
      'subscriptions': 'subscriptions_staging',
      'analytics': 'analytics_staging',
    },
    Environment.production: {
      'users': 'users',
      'receipts': 'receipts',
      'invoices': 'invoices',
      'clients': 'clients',
      'categories': 'categories',
      'subscriptions': 'subscriptions',
      'analytics': 'analytics',
    },
  };

  // Storage bucket paths for different environments
  static const Map<Environment, Map<String, String>> _storagePaths = {
    Environment.development: {
      'receipts': 'dev/receipts',
      'invoices': 'dev/invoices',
      'avatars': 'dev/avatars',
      'exports': 'dev/exports',
    },
    Environment.staging: {
      'receipts': 'staging/receipts',
      'invoices': 'staging/invoices',
      'avatars': 'staging/avatars',
      'exports': 'staging/exports',
    },
    Environment.production: {
      'receipts': 'receipts',
      'invoices': 'invoices',
      'avatars': 'avatars',
      'exports': 'exports',
    },
  };

  /// Initialize Firebase with environment-specific configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final environment = AppConfig.instance.environment;
      final options = _firebaseOptions[environment];

      if (options == null) {
        throw Exception(
          'Firebase options not found for environment: ${environment.name}',
        );
      }

      // Initialize Firebase
      await Firebase.initializeApp(options: options);

      // Initialize services
      await _initializeServices();

      _isInitialized = true;

      if (kDebugMode) {
        print('🔥 Firebase initialized for ${environment.name}');
        print('📊 Project ID: ${options.projectId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Initialize Firebase services with specific configurations
  Future<void> _initializeServices() async {
    final environment = AppConfig.instance.environment;

    // Initialize Auth
    _auth = FirebaseAuth.instance;
    await _configureAuth();

    // Initialize Firestore
    _firestore = FirebaseFirestore.instance;
    await _configureFirestore();

    // Initialize Storage
    _storage = FirebaseStorage.instance;
    await _configureStorage();

    // Initialize Messaging (if push notifications enabled)
    if (AppConfig.instance.isPushNotificationsEnabled) {
      _messaging = FirebaseMessaging.instance;
      await _configureMessaging();
    }

    // Initialize Analytics (if analytics enabled)
    if (AppConfig.instance.isAnalyticsEnabled) {
      _analytics = FirebaseAnalytics.instance;
      await _configureAnalytics();
    }

    // Initialize Crashlytics (if crashlytics enabled)
    if (AppConfig.instance.isCrashlyticsEnabled) {
      _crashlytics = FirebaseCrashlytics.instance;
      await _configureCrashlytics();
    }

    // Initialize Performance (not in debug mode)
    if (!kDebugMode) {
      _performance = FirebasePerformance.instance;
      await _configurePerformance();
    }
  }

  /// Configure Firebase Auth
  Future<void> _configureAuth() async {
    if (_auth == null) return;

    // Set language code
    await _auth!.setLanguageCode('en');

    // Configure auth settings
    await _auth!.setPersistence(Persistence.LOCAL);

    if (kDebugMode) {
      print('🔐 Firebase Auth configured');
    }
  }

  /// Configure Firestore
  Future<void> _configureFirestore() async {
    if (_firestore == null) return;

    // Configure Firestore settings
    final settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      ignoreUndefinedProperties: false,
    );

    _firestore!.settings = settings;

    // Enable network (useful for testing)
    if (AppConfig.instance.isDevelopment) {
      await _firestore!.enableNetwork();
    }

    if (kDebugMode) {
      print('🗃️ Firestore configured with persistence enabled');
    }
  }

  /// Configure Firebase Storage
  Future<void> _configureStorage() async {
    if (_storage == null) return;

    // Configure maximum operation retry time
    _storage!.setMaxOperationRetryTime(const Duration(seconds: 30));
    _storage!.setMaxUploadRetryTime(const Duration(minutes: 5));
    _storage!.setMaxDownloadRetryTime(const Duration(minutes: 5));

    if (kDebugMode) {
      print('📁 Firebase Storage configured');
    }
  }

  /// Configure Firebase Messaging
  Future<void> _configureMessaging() async {
    if (_messaging == null) return;

    // Request notification permissions
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('🔔 Push notifications permission granted');
      }
    }

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📱 Foreground message received: ${message.notification?.title}');
      }
      // Handle foreground messages
    });

    // Configure background message handling
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (kDebugMode) {
      print('💬 Firebase Messaging configured');
    }
  }

  /// Configure Firebase Analytics
  Future<void> _configureAnalytics() async {
    if (_analytics == null) return;

    // Enable analytics collection
    await _analytics!.setAnalyticsCollectionEnabled(true);

    // Set default event parameters
    await _analytics!.setDefaultEventParameters({
      'app_version': AppConfig.instance.appVersion,
      'environment': AppConfig.instance.environmentName,
    });

    if (kDebugMode) {
      print('📈 Firebase Analytics configured');
    }
  }

  /// Configure Firebase Crashlytics
  Future<void> _configureCrashlytics() async {
    if (_crashlytics == null) return;

    // Enable crashlytics collection
    await _crashlytics!.setCrashlyticsCollectionEnabled(true);

    // Set custom keys
    await _crashlytics!.setCustomKey(
      'environment',
      AppConfig.instance.environmentName,
    );
    await _crashlytics!.setCustomKey(
      'app_version',
      AppConfig.instance.appVersion,
    );

    // Configure Flutter error handling
    FlutterError.onError = (errorDetails) {
      _crashlytics!.recordFlutterFatalError(errorDetails);
    };

    // Configure platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics!.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      print('💥 Firebase Crashlytics configured');
    }
  }

  /// Configure Firebase Performance
  Future<void> _configurePerformance() async {
    if (_performance == null) return;

    // Enable performance monitoring
    await _performance!.setPerformanceCollectionEnabled(true);

    if (kDebugMode) {
      print('⚡ Firebase Performance configured');
    }
  }

  // Service getters
  FirebaseAuth get auth {
    _ensureInitialized();
    return _auth!;
  }

  FirebaseFirestore get firestore {
    _ensureInitialized();
    return _firestore!;
  }

  FirebaseStorage get storage {
    _ensureInitialized();
    return _storage!;
  }

  FirebaseMessaging? get messaging {
    _ensureInitialized();
    return _messaging;
  }

  FirebaseAnalytics? get analytics {
    _ensureInitialized();
    return _analytics;
  }

  FirebaseCrashlytics? get crashlytics {
    _ensureInitialized();
    return _crashlytics;
  }

  FirebasePerformance? get performance {
    _ensureInitialized();
    return _performance;
  }

  // Helper methods
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'Firebase not initialized. Call FirebaseConfig.instance.initialize() first.',
      );
    }
  }

  /// Get collection name for current environment
  String getCollectionName(String collection) {
    final environment = AppConfig.instance.environment;
    return _collectionNames[environment]?[collection] ?? collection;
  }

  /// Get storage path for current environment
  String getStoragePath(String path) {
    final environment = AppConfig.instance.environment;
    return _storagePaths[environment]?[path] ?? path;
  }

  /// Get Firestore collection reference
  CollectionReference getCollection(String collection) {
    return firestore.collection(getCollectionName(collection));
  }

  /// Get Storage reference
  Reference getStorageRef(String path) {
    return storage.ref().child(getStoragePath(path));
  }

  /// Log analytics event
  Future<void> logEvent(String name, [Map<String, Object?>? parameters]) async {
    if (analytics != null) {
      await analytics!.logEvent(
        name: name,
        parameters: parameters == null
            ? null
            : parameters.map((k, v) => MapEntry(k, v as Object)),
      );
    }
  }

  /// Log custom error to Crashlytics
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    if (crashlytics != null) {
      await crashlytics!.recordError(exception, stackTrace, fatal: fatal);
    }
  }

  /// Set user identifier for analytics and crashlytics
  Future<void> setUserId(String userId) async {
    await Future.wait([
      if (analytics != null) analytics!.setUserId(id: userId),
      if (crashlytics != null) crashlytics!.setUserIdentifier(userId),
    ]);
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, String> properties) async {
    if (analytics != null) {
      for (final entry in properties.entries) {
        await analytics!.setUserProperty(name: entry.key, value: entry.value);
      }
    }

    if (crashlytics != null) {
      for (final entry in properties.entries) {
        await crashlytics!.setCustomKey(entry.key, entry.value);
      }
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    if (messaging != null) {
      return await messaging!.getToken();
    }
    return null;
  }

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    if (messaging != null) {
      await messaging!.subscribeToTopic(topic);
    }
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (messaging != null) {
      await messaging!.unsubscribeFromTopic(topic);
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Get current project ID
  String? get projectId {
    final environment = AppConfig.instance.environment;
    return _firebaseOptions[environment]?.projectId;
  }

  /// Get current storage bucket
  String? get storageBucket {
    final environment = AppConfig.instance.environment;
    return _firebaseOptions[environment]?.storageBucket;
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print('📱 Background message received: ${message.notification?.title}');
  }

  // Handle background messages
}
