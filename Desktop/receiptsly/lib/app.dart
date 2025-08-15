// lib/app.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'core/errors/error_handler.dart';

// Providers
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/providers/connectivity_provider.dart';

// Widgets
import 'presentation/widgets/common/app_loader.dart';
import 'presentation/widgets/common/app_snackbar.dart';

// Services
import 'services/notification/local_notification_service.dart';
import 'services/sync/sync_service.dart';
import 'services/firebase/analytics_service.dart';

/// Main application widget
class ReceiptslyApp extends ConsumerStatefulWidget {
  const ReceiptslyApp({super.key});

  @override
  ConsumerState<ReceiptslyApp> createState() => _ReceiptslyAppState();
}

class _ReceiptslyAppState extends ConsumerState<ReceiptslyApp>
    with WidgetsBindingObserver {
  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _analyticsObserver;
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  /// Initialize application-wide services and listeners
  Future<void> _initializeApp() async {
    try {
      // Add lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize analytics if enabled
      if (AppConfig.instance.isAnalyticsEnabled) {
        _analytics = FirebaseAnalytics.instance;
        _analyticsObserver = FirebaseAnalyticsObserver(analytics: _analytics);
        _analyticsService = AnalyticsService(_analytics);

        // Set default analytics parameters
        await _analytics.setDefaultEventParameters({
          'app_version': AppConfig.instance.formattedVersion,
          'environment': AppConfig.instance.environmentName,
          'platform': defaultTargetPlatform.name,
        });
      }

      // Set up Firebase Messaging listeners
      if (AppConfig.instance.isPushNotificationsEnabled) {
        await _setupFirebaseMessaging();
      }

      // Initialize connectivity monitoring
      _initializeConnectivityMonitoring();

      // Initialize sync service
      _initializeSyncService();

      // Set up error reporting
      _setupErrorReporting();

      // Remove splash screen after initialization
      _removeSplashScreen();

      // Log app initialization
      await _logAppInitialization();

      AppLogger.logInfo('✅ App initialization completed successfully');
    } catch (e, stackTrace) {
      AppLogger.LogError(
        '❌ App initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'App Initialization');
    }
  }

  /// Set up Firebase Messaging for push notifications
  Future<void> _setupFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.logInfo(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle initial message when app is opened from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get FCM token for this device
      final token = await messaging.getToken();
      if (token != null) {
        AppLogger.logInfo('FCM Token obtained: ${token.substring(0, 20)}...');
        // Store token for sending targeted notifications
        ref.read(appStateProvider.notifier).setFCMToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        AppLogger.logInfo('FCM Token refreshed');
        ref.read(appStateProvider.notifier).setFCMToken(newToken);
      });
    } catch (e, stackTrace) {
      AppLogger.LogError(
        'Failed to setup Firebase Messaging',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle foreground push notifications
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.logInfo('Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      // Show in-app notification
      LocalNotificationService.instance.showNotification(
        title: notification.title ?? 'Receiptsly',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );

      // Track notification received
      if (AppConfig.instance.isAnalyticsEnabled) {
        _analyticsService.logEvent(
          'notification_received',
          parameters: {
            'type': message.data['type'] ?? 'unknown',
            'message_id': message.messageId ?? 'unknown',
          },
        );
      }
    }
  }

  /// Handle notification tap actions
  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.logInfo('Message opened app: ${message.messageId}');

    final data = message.data;

    // Track notification opened
    if (AppConfig.instance.isAnalyticsEnabled) {
      _analyticsService.logEvent(
        'notification_opened',
        parameters: {
          'type': data['type'] ?? 'unknown',
          'message_id': message.messageId ?? 'unknown',
        },
      );
    }

    // Navigate based on notification type
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'receipt_processed':
          if (data.containsKey('receiptId')) {
            ref
                .read(appRouterProvider)
                .pushNamed(
                  '/receipt-detail',
                  pathParameters: {'id': data['receiptId']},
                );
          }
          break;
        case 'invoice_paid':
          if (data.containsKey('invoiceId')) {
            ref
                .read(appRouterProvider)
                .pushNamed(
                  '/invoice-detail',
                  pathParameters: {'id': data['invoiceId']},
                );
          }
          break;
        case 'sync_conflict':
          ref.read(appRouterProvider).pushNamed('/sync-conflicts');
          break;
        case 'payment_failed':
          ref.read(appRouterProvider).pushNamed('/billing');
          break;
        case 'subscription_expiring':
          ref.read(appRouterProvider).pushNamed('/subscription');
          break;
        default:
          ref.read(appRouterProvider).pushNamed('/dashboard');
      }
    }
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectivityProvider.notifier).startMonitoring();
    });
  }

  /// Initialize sync service
  void _initializeSyncService() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppConfig.instance.isOfflineModeEnabled) {
        ref.read(syncServiceProvider).initialize();
      }
    });
  }

  /// Set up error reporting for production
  void _setupErrorReporting() {
    if (AppConfig.instance.isCrashlyticsEnabled && !kDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  /// Remove splash screen after app is ready
  void _removeSplashScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
        AppLogger.debug('Splash screen removed');
      } catch (e) {
        AppLogger.warning('Failed to remove splash screen', error: e);
      }
    });
  }

  /// Log app initialization for analytics
  Future<void> _logAppInitialization() async {
    if (AppConfig.instance.isAnalyticsEnabled) {
      await _analyticsService.logEvent(
        'app_initialized',
        parameters: {
          'environment': AppConfig.instance.environmentName,
          'app_version': AppConfig.instance.formattedVersion,
          'platform': defaultTargetPlatform.name,
          'debug_mode': kDebugMode,
          'offline_mode_enabled': AppConfig.instance.isOfflineModeEnabled,
          'analytics_enabled': AppConfig.instance.isAnalyticsEnabled,
          'crashlytics_enabled': AppConfig.instance.isCrashlyticsEnabled,
        },
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.logInfo('📱 App lifecycle state changed: ${state.name}');

    // Track app lifecycle events
    if (AppConfig.instance.isAnalyticsEnabled) {
      _analyticsService.logEvent(
        'app_lifecycle_change',
        parameters: {
          'state': state.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }

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

  /// Handle app resume
  void _onAppResumed() {
    AppLogger.debug('📱 App resumed - updating state and syncing');

    // Update app state
    ref.read(appStateProvider.notifier).setAppInForeground(true);

    // Trigger sync if connected and enabled
    _triggerSyncIfNeeded();

    // Check for app updates
    _checkForUpdates();

    // Refresh authentication state
    ref.read(authStateProvider.notifier).refreshAuthState();
  }

  /// Handle app pause
  void _onAppPaused() {
    AppLogger.debug('📱 App paused - saving state');

    // Update app state
    ref.read(appStateProvider.notifier).setAppInForeground(false);

    // Pause sync operations
    if (AppConfig.instance.isOfflineModeEnabled) {
      ref.read(syncServiceProvider).pauseSync();
    }

    // Clear sensitive data from memory if configured
    ref.read(appStateProvider.notifier).clearSensitiveData();

    // Save current app state
    ref.read(appStateProvider.notifier).saveState();
  }

  /// Handle app inactive (e.g., during phone call)
  void _onAppInactive() {
    AppLogger.debug('📱 App inactive');
    // Handle app becoming inactive
  }

  /// Handle app hidden (iOS specific)
  void _onAppHidden() {
    AppLogger.debug('📱 App hidden');
    // Handle app being hidden
  }

  /// Handle app termination
  void _onAppDetached() {
    AppLogger.logInfo('📱 App detached - performing cleanup');
    _cleanup();
  }

  /// Trigger sync when app comes to foreground
  void _triggerSyncIfNeeded() {
    if (!AppConfig.instance.isOfflineModeEnabled) return;

    final connectivityState = ref.read(connectivityProvider);
    final authState = ref.read(authStateProvider);

    if (connectivityState.isConnected && authState.isAuthenticated) {
      final syncService = ref.read(syncServiceProvider);
      final lastSyncTime = ref.read(appStateProvider).lastSyncTime;
      final now = DateTime.now();

      // Sync if last sync was more than configured interval ago
      if (lastSyncTime == null ||
          now.difference(lastSyncTime).inMilliseconds >
              AppConfig.instance.autoSyncInterval) {
        syncService.startSync();
      }
    }
  }

  /// Check for app updates
  void _checkForUpdates() {
    final currentVersion = AppConfig.instance.appVersion;

    // Check if force update is required
    if (AppConfig.instance.isForceUpdateRequired(currentVersion)) {
      _showForceUpdateDialog();
    }
    // Check if optional update is available
    else if (!AppConfig.instance.isVersionSupported(currentVersion)) {
      _showOptionalUpdateDialog();
    }
  }

  /// Show force update dialog
  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
          'A critical update is available. Please update to continue using Receiptsly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Open app store for update
              _openAppStore();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Show optional update dialog
  void _showOptionalUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
          'A new version of Receiptsly is available with improvements and bug fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppStore();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Open app store for update
  void _openAppStore() {
    // TODO: Implement deep linking to app store
    // You would use url_launcher to open the appropriate store
    AppLogger.logInfo('Opening app store for update');

    if (AppConfig.instance.isAnalyticsEnabled) {
      _analyticsService.logEvent(
        'app_store_opened',
        parameters: {'reason': 'update'},
      );
    }
  }

  /// Cleanup resources
  void _cleanup() {
    try {
      WidgetsBinding.instance.removeObserver(this);

      if (AppConfig.instance.isOfflineModeEnabled) {
        ref.read(syncServiceProvider).dispose();
      }

      AppLogger.logInfo('🧹 App cleanup completed');
    } catch (e) {
      AppLogger.LogError('❌ Error during app cleanup', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch app state and theme
    final appState = ref.watch(appStateProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      // App Metadata
      title: AppConstants.appName,
      debugShowCheckedModeBanner: AppConfig.instance.isDebugModeEnabled,

      // Routing
      routerConfig: ref.watch(appRouterProvider),

      // Theme Configuration
      theme: AppTheme.lightTheme(
        experimental: AppConfig.instance.isExperimentalUIEnabled,
      ),
      darkTheme: AppTheme.darkTheme(
        experimental: AppConfig.instance.isExperimentalUIEnabled,
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppConstants.supportedLocales,
      locale: Locale(appState.languageCode),

      // Analytics (only if enabled)
      navigatorObservers: [
        if (AppConfig.instance.isAnalyticsEnabled) _analyticsObserver,
      ],

      // Error Handling
      builder: (context, child) {
        // Global error boundary
        ErrorWidget.builder = (FlutterErrorDetails details) {
          if (kDebugMode) {
            return ErrorWidget(details.exception);
          }
          return _buildProductionErrorWidget(details);
        };

        return _AppBuilder(child: child ?? const SizedBox.shrink());
      },

      // Keyboard Shortcuts (for desktop/web)
      shortcuts: _buildKeyboardShortcuts(),
      actions: _buildKeyboardActions(context),
    );
  }

  /// Build error widget for production
  Widget _buildProductionErrorWidget(FlutterErrorDetails details) {
    // Log error to crashlytics
    if (AppConfig.instance.isCrashlyticsEnabled) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }

    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again or restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to navigate to home
                    ref.read(appRouterProvider).go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Home'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Error Details'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          details.toString(),
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

  /// Build keyboard shortcuts for desktop/web
  Map<ShortcutActivator, Intent> _buildKeyboardShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          const CreateReceiptIntent(),
      const SingleActivator(LogicalKeyboardKey.keyI, control: true):
          const CreateInvoiceIntent(),
      const SingleActivator(LogicalKeyboardKey.keyS, control: true):
          const SyncDataIntent(),
      const SingleActivator(LogicalKeyboardKey.slash, control: true):
          const ShowSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.keyD, control: true):
          const ShowDashboardIntent(),
      const SingleActivator(LogicalKeyboardKey.keyR, control: true):
          const ShowReportsIntent(),
      const SingleActivator(LogicalKeyboardKey.keyC, control: true):
          const ShowClientsIntent(),
    };
  }

  /// Build keyboard actions for shortcuts
  Map<Type, Action<Intent>> _buildKeyboardActions(BuildContext context) {
    return {
      CreateReceiptIntent: CallbackAction<CreateReceiptIntent>(
        onInvoke: (_) {
          ref.read(appRouterProvider).pushNamed('/receipt-camera');
          if (AppConfig.instance.isAnalyticsEnabled) {
            _analyticsService.logEvent(
              'keyboard_shortcut_used',
              parameters: {'action': 'create_receipt'},
            );
          }
          return null;
        },
      ),
      CreateInvoiceIntent: CallbackAction<CreateInvoiceIntent>(
        onInvoke: (_) {
          ref.read(appRouterProvider).pushNamed('/create-invoice');
          if (AppConfig.instance.isAnalyticsEnabled) {
            _analyticsService.logEvent(
              'keyboard_shortcut_used',
              parameters: {'action': 'create_invoice'},
            );
          }
          return null;
        },
      ),
      SyncDataIntent: CallbackAction<SyncDataIntent>(
        onInvoke: (_) {
          if (AppConfig.instance.isOfflineModeEnabled) {
            ref.read(syncServiceProvider).startSync();
            if (AppConfig.instance.isAnalyticsEnabled) {
              _analyticsService.logEvent(
                'manual_sync_triggered',
                parameters: {'method': 'keyboard_shortcut'},
              );
            }
          }
          return null;
        },
      ),
      ShowSearchIntent: CallbackAction<ShowSearchIntent>(
        onInvoke: (_) {
          ref.read(appRouterProvider).pushNamed('/search');
          return null;
        },
      ),
      ShowDashboardIntent: CallbackAction<ShowDashboardIntent>(
        onInvoke: (_) {
          ref.read(appRouterProvider).go('/dashboard');
          return null;
        },
      ),
      ShowReportsIntent: CallbackAction<ShowReportsIntent>(
        onInvoke: (_) {
          ref.read(appRouterProvider).pushNamed('/reports');
          return null;
        },
      ),
      ShowClientsIntent: CallbackAction<ShowClientsIntent>(
        onInvoke: (_) {
          ref.read(appRouterProvider).pushNamed('/clients');
          return null;
        },
      ),
    };
  }
}

/// App builder wrapper for global features
class _AppBuilder extends ConsumerWidget {
  const _AppBuilder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for global app state
    final appState = ref.watch(appStateProvider);
    final syncState = ref.watch(syncProvider);
    final connectivityState = ref.watch(connectivityProvider);

    return MediaQuery(
      // Ensure text scale factor doesn't exceed accessibility limits
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 2.0),
      ),
      child: Stack(
        children: [
          // Main app content
          child,

          // Global loading overlay
          if (appState.isLoading) const _GlobalLoadingOverlay(),

          // Sync status indicator
          if (AppConfig.instance.isOfflineModeEnabled && syncState.isSyncing)
            const _SyncStatusIndicator(),

          // Connectivity banner
          if (!connectivityState.isConnected) const _OfflineBanner(),

          // Update banner (if available)
          Consumer(
            builder: (context, ref, _) {
              final appState = ref.watch(appStateProvider);
              if (appState.updateAvailable && !appState.forceUpdate) {
                return const _UpdateBanner();
              }
              return const SizedBox.shrink();
            },
          ),

          // Global snackbar manager
          const _GlobalSnackbar(),
        ],
      ),
    );
  }
}

/// Global loading overlay
class _GlobalLoadingOverlay extends StatelessWidget {
  const _GlobalLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: AppLoader(size: LoaderSize.large, message: 'Loading...'),
      ),
    );
  }
}

/// Sync status indicator
class _SyncStatusIndicator extends ConsumerWidget {
  const _SyncStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: Material(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Syncing ${syncState.pendingItems} items',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Offline connectivity banner
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.orange,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.cloud_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'You\'re offline. Data will sync when connection is restored.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Update available banner
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 32,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'New version available! Tap to update.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(appStateProvider.notifier).dismissUpdateBanner();
                },
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Global snackbar manager
class _GlobalSnackbar extends ConsumerWidget {
  const _GlobalSnackbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AppSnackbarState>(appSnackbarProvider, (previous, next) {
      if (next.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackbar.build(
            message: next.message,
            type: next.type,
            action: next.action,
          ),
        );

        // Clear the message after showing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appSnackbarProvider.notifier).clear();
        });
      }
    });

    return const SizedBox.shrink();
  }
}

// Intent classes for keyboard shortcuts
class CreateReceiptIntent extends Intent {
  const CreateReceiptIntent();
}

class CreateInvoiceIntent extends Intent {
  const CreateInvoiceIntent();
}

class SyncDataIntent extends Intent {
  const SyncDataIntent();
}

class ShowSearchIntent extends Intent {
  const ShowSearchIntent();
}

class ShowDashboardIntent extends Intent {
  const ShowDashboardIntent();
}

class ShowReportsIntent extends Intent {
  const ShowReportsIntent();
}

class ShowClientsIntent extends Intent {
  const ShowClientsIntent();
}

/// Analytics service for tracking app events
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  /// Log custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);

      if (kDebugMode) {
        AppLogger.debugLog('📊 Analytics event: $name', extra: parameters);
      }
    } catch (e) {
      AppLogger.LogError('Failed to log analytics event', error: e);
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );

      if (kDebugMode) {
        AppLogger.debugLog('📱 Screen view: $screenName');
      }
    } catch (e) {
      AppLogger.LogError('Failed to log screen view', error: e);
    }
  }

  /// Log user login
  Future<void> logLogin({String? loginMethod}) async {
    await logEvent(
      'login',
      parameters: {
        'method': loginMethod ?? 'email',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log user signup
  Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent(
      'sign_up',
      parameters: {
        'method': signUpMethod ?? 'email',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log purchase event
  Future<void> logPurchase({
    required String currency,
    required double value,
    String? itemId,
    String? itemName,
  }) async {
    await logEvent(
      'purchase',
      parameters: {
        'currency': currency,
        'value': value,
        if (itemId != null) 'item_id': itemId,
        if (itemName != null) 'item_name': itemName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log subscription event
  Future<void> logSubscription({
    required String planId,
    required String currency,
    required double value,
    String? period,
  }) async {
    await logEvent(
      'subscription',
      parameters: {
        'plan_id': planId,
        'currency': currency,
        'value': value,
        if (period != null) 'period': period,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log receipt processing
  Future<void> logReceiptProcessed({
    required String receiptId,
    required String method,
    bool successful = true,
    double? amount,
    String? currency,
  }) async {
    await logEvent(
      'receipt_processed',
      parameters: {
        'receipt_id': receiptId,
        'method': method, // 'camera', 'gallery', 'chatbot'
        'successful': successful,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log invoice creation
  Future<void> logInvoiceCreated({
    required String invoiceId,
    required double amount,
    required String currency,
    int? itemCount,
  }) async {
    await logEvent(
      'invoice_created',
      parameters: {
        'invoice_id': invoiceId,
        'amount': amount,
        'currency': currency,
        if (itemCount != null) 'item_count': itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log export action
  Future<void> logExport({
    required String type, // 'pdf', 'csv', 'excel'
    required String dataType, // 'receipts', 'invoices', 'reports'
    int? itemCount,
  }) async {
    await logEvent(
      'export_data',
      parameters: {
        'export_type': type,
        'data_type': dataType,
        if (itemCount != null) 'item_count': itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log sync operation
  Future<void> logSync({
    required String type, // 'manual', 'automatic', 'background'
    required bool successful,
    int? itemsSynced,
    String? error,
  }) async {
    await logEvent(
      'sync_operation',
      parameters: {
        'sync_type': type,
        'successful': successful,
        if (itemsSynced != null) 'items_synced': itemsSynced,
        if (error != null) 'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log feature usage
  Future<void> logFeatureUsage({
    required String feature,
    Map<String, Object>? context,
  }) async {
    await logEvent(
      'feature_used',
      parameters: {
        'feature': feature,
        ...?context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log error events
  Future<void> logError({
    required String errorType,
    required String message,
    String? context,
  }) async {
    await logEvent(
      'app_error',
      parameters: {
        'error_type': errorType,
        'message': message,
        if (context != null) 'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log performance metrics
  Future<void> logPerformance({
    required String operation,
    required int durationMs,
    Map<String, Object>? metadata,
  }) async {
    await logEvent(
      'performance_metric',
      parameters: {
        'operation': operation,
        'duration_ms': durationMs,
        ...?metadata,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? subscriptionPlan,
    String? country,
    String? language,
    bool? isPremium,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }

      await _analytics.setUserProperty(
        name: 'user_type',
        value: userType ?? 'unknown',
      );

      await _analytics.setUserProperty(
        name: 'subscription_plan',
        value: subscriptionPlan ?? 'free',
      );

      if (country != null) {
        await _analytics.setUserProperty(name: 'country', value: country);
      }

      if (language != null) {
        await _analytics.setUserProperty(name: 'language', value: language);
      }

      if (isPremium != null) {
        await _analytics.setUserProperty(
          name: 'is_premium',
          value: isPremium.toString(),
        );
      }

      if (kDebugMode) {
        AppLogger.debugLog('👤 User properties updated');
      }
    } catch (e) {
      AppLogger.LogError('Failed to set user properties', error: e);
    }
  }

  /// Log conversion events
  Future<void> logConversion({
    required String conversionType,
    required double value,
    String? currency,
    Map<String, Object>? metadata,
  }) async {
    await logEvent(
      'conversion',
      parameters: {
        'conversion_type': conversionType,
        'value': value,
        if (currency != null) 'currency': currency,
        ...?metadata,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log user engagement
  Future<void> logEngagement({
    required String action,
    String? screen,
    Map<String, Object>? context,
  }) async {
    await logEvent(
      'user_engagement',
      parameters: {
        'action': action,
        if (screen != null) 'screen': screen,
        ...?context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log business metrics
  Future<void> logBusinessMetric({
    required String metric,
    required double value,
    String? unit,
    Map<String, Object>? metadata,
  }) async {
    await logEvent(
      'business_metric',
      parameters: {
        'metric': metric,
        'value': value,
        if (unit != null) 'unit': unit,
        ...?metadata,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
