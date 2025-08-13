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

import 'app.dart';
import 'core/config/environment.dart';
import 'core/config/app_config.dart';
import 'core/errors/error_handler.dart';
import 'core/utils/logger.dart';
import 'services/local/local_storage_service.dart';
import 'services/local/secure_storage_service.dart';
import 'services/notification/local_notification_service.dart';
import 'services/firebase/firebase_service.dart';
import 'firebase_options.dart';

/// Global error handler for background Firebase messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  AppLogger.info('Background message received: ${message.messageId}');

  // Handle background notification
  await LocalNotificationService.instance.showNotification(
    title: message.notification?.title ?? 'Receiptsly',
    body: message.notification?.body ?? 'New notification',
    payload: message.data.toString(),
  );
}

/// Main application entry point
Future<void> main() async {
  // Ensure Flutter binding is initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash screen until app is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize error handling
  await _initializeErrorHandling();

  // Initialize core services
  await _initializeCoreServices();

  // Initialize Firebase
  await _initializeFirebase();

  // Initialize local storage
  await _initializeLocalStorage();

  // Initialize notifications
  await _initializeNotifications();

  // Configure system UI
  await _configureSystemUI();

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
      AppLogger.error('Uncaught error', error: error, stackTrace: stackTrace);
      ErrorHandler.handleError(error, stackTrace);
    },
  );
}

/// Initialize error handling and logging
Future<void> _initializeErrorHandling() async {
  try {
    // Initialize logger
    AppLogger.initialize();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Report to Crashlytics in production
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Platform error', error: error, stackTrace: stack);

      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }

      return true;
    };

    AppLogger.info('Error handling initialized');
  } catch (e) {
    debugPrint('Failed to initialize error handling: $e');
  }
}

/// Initialize core application services
Future<void> _initializeCoreServices() async {
  try {
    // Set app configuration based on environment
    AppConfig.setEnvironment(
      kDebugMode ? Environment.development : Environment.production,
    );

    AppLogger.info('Core services initialized');
  } catch (e) {
    AppLogger.error('Failed to initialize core services', error: e);
    rethrow;
  }
}

/// Initialize Firebase services
Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase services
    await FirebaseService.instance.initialize();

    // Set up Crashlytics
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Set user identifier for crash reports
      await FirebaseCrashlytics.instance.setUserIdentifier('anonymous');
    }

    // Initialize Analytics
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    AppLogger.info('Firebase initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Firebase', error: e);
    rethrow;
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

    AppLogger.info('Local storage initialized');
  } catch (e) {
    AppLogger.error('Failed to initialize local storage', error: e);
    rethrow;
  }
}

/// Initialize notification services
Future<void> _initializeNotifications() async {
  try {
    await LocalNotificationService.instance.initialize();
    AppLogger.info('Notifications initialized');
  } catch (e) {
    AppLogger.error('Failed to initialize notifications', error: e);
    // Don't rethrow - notifications are not critical for app startup
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

    // Configure status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    AppLogger.info('System UI configured');
  } catch (e) {
    AppLogger.error('Failed to configure system UI', error: e);
    // Don't rethrow - UI configuration failures shouldn't prevent app startup
  }
}

/// Riverpod state observer for debugging
class _RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      AppLogger.debug(
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
      AppLogger.debug(
        'Provider added: ${provider.name ?? provider.runtimeType} '
        'with value $value',
      );
    }
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    if (kDebugMode) {
      AppLogger.debug(
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
    AppLogger.error(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
