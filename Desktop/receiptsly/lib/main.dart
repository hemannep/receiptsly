// lib/main.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Core configurations
import 'core/config/environment.dart';
import 'core/config/app_config.dart';
import 'core/config/stripe_config.dart';

// Error handling and logging
import 'core/errors/error_handler.dart';
import 'core/utils/logger.dart';

// Services
import 'services/local/local_storage_service.dart';
import 'services/local/secure_storage_service.dart';
import 'services/notification/local_notification_service.dart';
import 'services/firebase/firebase_service.dart';

// App and Firebase options
import 'app.dart';
import 'firebase_options.dart';

/// Global error handler for background Firebase messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    AppLogger.logInfo('Background message received: ${message.messageId}');

    // Handle background notification
    await LocalNotificationService.instance.showNotification(
      title: message.notification?.title ?? 'Receiptsly',
      body: message.notification?.body ?? 'New notification',
      payload: message.data.toString(),
    );
  } catch (e) {
    AppLogger.LogError('Failed to handle background message', error: e);
  }
}

/// Main application entry point
Future<void> main() async {
  // Ensure Flutter binding is initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash screen until app is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize error handling first
  await _initializeErrorHandling();

  // Initialize core services
  await _initializeCoreServices();

  // Initialize Firebase
  await _initializeFirebase();

  // Initialize Stripe (after Firebase)
  await _initializeStripe();

  // Initialize local storage
  await _initializeLocalStorage();

  // Initialize notifications
  await _initializeNotifications();

  // Configure system UI
  await _configureSystemUI();

  // Remove splash screen
  FlutterNativeSplash.remove();

  // Run the app with error boundary
  runZonedGuarded<Future<void>>(
    () async {
      runApp(
        ProviderScope(
          observers: [if (kDebugMode) _RiverpodLogger()],
          child: const ReceiptslyApp(),
        ),
      );
    },
    (error, stackTrace) {
      AppLogger.LogError(
        'Uncaught error',
        error: error,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(error, stackTrace);
    },
  );
}

/// Initialize error handling and logging
Future<void> _initializeErrorHandling() async {
  try {
    // Initialize logger first
    AppLogger.initialize();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.LogError(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Report to Crashlytics in production
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        // Show error details in debug mode
        FlutterError.presentError(details);
      }
    };

    // Handle platform errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.LogError('Platform error', error: error, stackTrace: stack);

      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }

      return true;
    };

    AppLogger.logInfo('✅ Error handling initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize error handling: $e');
  }
}

/// Initialize core application services
Future<void> _initializeCoreServices() async {
  try {
    // Detect environment
    final environment = _detectEnvironment();

    AppLogger.logInfo('🌍 Detected environment: ${environment.name}');

    // Initialize environment configuration
    EnvironmentConfig.instance.initialize(environment);

    // Initialize app configuration
    await AppConfig.instance.initialize(environment: environment);

    // Validate configurations
    if (!AppConfig.instance.validateConfiguration()) {
      throw Exception('Invalid app configuration');
    }

    AppLogger.logInfo('✅ Core services initialized');
    AppLogger.logInfo(
      '📱 App: ${AppConfig.instance.appName} v${AppConfig.instance.formattedVersion}',
    );
    AppLogger.logInfo('🌐 API: ${AppConfig.instance.apiBaseUrl}');
    AppLogger.logInfo('🏠 Web: ${AppConfig.instance.webAppUrl}');
  } catch (e) {
    AppLogger.LogError('❌ Failed to initialize core services', error: e);
    rethrow;
  }
}

/// Detect environment from build configuration
Environment _detectEnvironment() {
  // Check for build-time environment variables
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: '');

  if (environment.isNotEmpty) {
    switch (environment.toLowerCase()) {
      case 'development':
      case 'dev':
        return Environment.development;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'production':
      case 'prod':
        return Environment.production;
    }
  }

  if (flavor.isNotEmpty) {
    switch (flavor.toLowerCase()) {
      case 'development':
      case 'dev':
        return Environment.development;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'production':
      case 'prod':
        return Environment.production;
    }
  }

  // Check debug mode as fallback
  if (kDebugMode) {
    return Environment.development;
  }

  return Environment.production;
}

/// Initialize Firebase services
Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase services
    await FirebaseService.instance.initialize();

    // Configure Crashlytics based on environment
    if (AppConfig.instance.isCrashlyticsEnabled && !kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Set user identifier for better crash tracking
      await FirebaseCrashlytics.instance.setUserIdentifier(
        'anonymous_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Set custom keys for debugging
      await FirebaseCrashlytics.instance.setCustomKey(
        'environment',
        AppConfig.instance.environmentName,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'app_version',
        AppConfig.instance.formattedVersion,
      );

      AppLogger.logInfo('✅ Firebase Crashlytics initialized');
    }

    // Configure Analytics based on environment
    if (AppConfig.instance.isAnalyticsEnabled) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        !kDebugMode,
      );

      // Set default analytics parameters
      await FirebaseAnalytics.instance.setDefaultEventParameters({
        'environment': AppConfig.instance.environmentName,
        'app_version': AppConfig.instance.formattedVersion,
        'platform': Platform.operatingSystem,
      });

      AppLogger.logInfo('✅ Firebase Analytics initialized');
    }

    // Set up background message handler for push notifications
    if (AppConfig.instance.isPushNotificationsEnabled) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      AppLogger.logInfo('✅ Firebase Messaging background handler set');
    }

    AppLogger.logInfo('✅ Firebase initialized successfully');
  } catch (e) {
    AppLogger.LogError('❌ Failed to initialize Firebase', error: e);
    rethrow;
  }
}

/// Initialize Stripe payment processing
Future<void> _initializeStripe() async {
  try {
    await StripeConfig.instance.initialize();

    // Validate Stripe configuration
    if (!StripeConfig.instance.validateConfiguration()) {
      throw Exception('Invalid Stripe configuration');
    }

    AppLogger.logInfo('✅ Stripe initialized successfully');
    AppLogger.logInfo('💳 Test mode: ${StripeConfig.instance.isTestMode}');
  } catch (e) {
    AppLogger.LogError('❌ Failed to initialize Stripe', error: e);

    // Don't rethrow in development - app can work without Stripe
    if (AppConfig.instance.isProduction) {
      rethrow;
    } else {
      AppLogger.LogWarning('⚠️ Continuing without Stripe in development mode');
    }
  }
}

/// Initialize local storage services
Future<void> _initializeLocalStorage() async {
  try {
    // Get application documents directory
    final appDocumentDir = await getApplicationDocumentsDirectory();

    // Initialize Hive for local storage
    await Hive.initFlutter(appDocumentDir.path);

    // Initialize storage services
    await LocalStorageService.instance.initialize();
    await SecureStorageService.instance.initialize();

    AppLogger.logInfo('✅ Local storage initialized');
  } catch (e) {
    AppLogger.LogError('❌ Failed to initialize local storage', error: e);
    rethrow;
  }
}

/// Initialize notification services
Future<void> _initializeNotifications() async {
  try {
    if (AppConfig.instance.isPushNotificationsEnabled) {
      await LocalNotificationService.instance.initialize();
      AppLogger.logInfo('✅ Notifications initialized');
    } else {
      AppLogger.logInfo('📴 Notifications disabled');
    }
  } catch (e) {
    AppLogger.LogError('❌ Failed to initialize notifications', error: e);
    // Don't rethrow - notifications are not critical for app startup
    AppLogger.LogWarning('⚠️ Continuing without notifications');
  }
}

/// Configure system UI appearance
Future<void> _configureSystemUI() async {
  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    AppLogger.logInfo('✅ System UI configured');
  } catch (e) {
    AppLogger.LogError('❌ Failed to configure system UI', error: e);
    // Don't rethrow - UI configuration failures shouldn't prevent app startup
    AppLogger.LogWarning('⚠️ Continuing with default system UI');
  }
}

/// Riverpod state observer for debugging and monitoring
class _RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      AppLogger.debugLog(
        'Provider updated: ${provider.name ?? provider.runtimeType} '
        'from $previousValue to $newValue',
      );
    }
  }

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      AppLogger.debugLog(
        'Provider added: ${provider.name ?? provider.runtimeType} '
        'with value $value',
      );
    }
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    if (kDebugMode) {
      AppLogger.debugLog(
        'Provider disposed: ${provider.name ?? provider.runtimeType}',
      );
    }
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.LogError(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );

    // Report provider failures to Crashlytics in production
    if (!kDebugMode && AppConfig.instance.isCrashlyticsEnabled) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Provider failure: ${provider.name ?? provider.runtimeType}',
      );
    }
  }
}

/// Application lifecycle observer for cleanup and state management
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.logInfo('📱 App lifecycle state changed to: ${state.name}');

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }

  void _onAppResumed() {
    AppLogger.debugLog(
      '📱 App resumed - checking for updates and syncing data',
    );
    // Trigger any necessary background tasks when app resumes
  }

  void _onAppPaused() {
    AppLogger.debugLog('📱 App paused - saving state');
    // Save any pending data or state
  }

  void _onAppInactive() {
    AppLogger.debugLog('📱 App inactive');
    // Handle app becoming inactive (e.g., phone call, notification panel)
  }

  void _onAppHidden() {
    AppLogger.debugLog('📱 App hidden');
    // Handle app being hidden (iOS specific)
  }

  void _onAppDetached() {
    AppLogger.logInfo('📱 App detached - performing cleanup');
    _cleanup();
  }

  /// Cleanup resources when app is being terminated
  void _cleanup() {
    try {
      AppConfig.instance.dispose();
      StripeConfig.instance.dispose();
      LocalStorageService.instance.dispose();
      SecureStorageService.instance.dispose();

      AppLogger.logInfo('🧹 App cleanup completed');
    } catch (e) {
      AppLogger.LogError('❌ Error during app cleanup', error: e);
    }
  }
}

/// Global error widget for production builds
class GlobalErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const GlobalErrorWidget({Key? key, required this.error, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We apologize for the inconvenience. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      onRetry ??
                      () {
                        SystemNavigator.pop();
                      },
                  child: const Text('Restart App'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Error Details'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          error,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
