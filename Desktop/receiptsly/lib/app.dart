// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'core/errors/error_handler.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/widgets/common/app_loader.dart';
import 'presentation/widgets/common/app_snackbar.dart';
import 'services/notification/local_notification_service.dart';
import 'services/sync/sync_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize application-wide services and listeners
  Future<void> _initializeApp() async {
    try {
      // Add lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize analytics
      _analytics = FirebaseAnalytics.instance;
      _analyticsObserver = FirebaseAnalyticsObserver(analytics: _analytics);

      // Set up Firebase Messaging listeners
      _setupFirebaseMessaging();

      // Initialize sync service
      _initializeSyncService();

      // Remove splash screen after initialization
      _removeSplashScreen();

      AppLogger.info('App initialization completed');
    } catch (e) {
      AppLogger.error('App initialization failed', error: e);
      ErrorHandler.handleError(e, StackTrace.current);
    }
  }

  /// Set up Firebase Messaging for push notifications
  void _setupFirebaseMessaging() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('Message opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Request notification permissions
    _requestNotificationPermissions();
  }

  /// Handle foreground push notifications
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // Show in-app notification
      LocalNotificationService.instance.showNotification(
        title: notification.title ?? 'Receiptsly',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap actions
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

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
        default:
          ref.read(appRouterProvider).pushNamed('/dashboard');
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    AppLogger.info(
      'Notification permission status: ${settings.authorizationStatus}',
    );
  }

  /// Initialize sync service
  void _initializeSyncService() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).initialize();
    });
  }

  /// Remove splash screen after app is ready
  void _removeSplashScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.info('App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        ref.read(appStateProvider.notifier).setAppInForeground(true);
        _triggerSyncIfNeeded();
        break;
      case AppLifecycleState.paused:
        // App is in background
        ref.read(appStateProvider.notifier).setAppInForeground(false);
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _handleAppTerminated();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., during phone call)
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  /// Trigger sync when app comes to foreground
  void _triggerSyncIfNeeded() {
    final connectivityState = ref.read(connectivityProvider);
    if (connectivityState.isConnected) {
      ref.read(syncServiceProvider).startSync();
    }
  }

  /// Handle app being paused
  void _handleAppPaused() {
    // Pause sync operations
    ref.read(syncServiceProvider).pauseSync();

    // Clear sensitive data from memory if needed
    ref.read(appStateProvider.notifier).clearSensitiveData();
  }

  /// Handle app termination
  void _handleAppTerminated() {
    // Clean up resources
    ref.read(syncServiceProvider).dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch app state and theme
    final appState = ref.watch(appStateProvider);
    final isDarkMode = appState.isDarkMode;

    return MaterialApp.router(
      // App Metadata
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Routing
      routerConfig: ref.watch(appRouterProvider),

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppConstants.supportedLocales,
      locale: Locale(appState.languageCode),

      // Analytics
      navigatorObservers: [_analyticsObserver],

      // Error Handling
      builder: (context, child) {
        return _AppBuilder(child: child ?? const SizedBox.shrink());
      },

      // Shortcuts
      shortcuts: _buildKeyboardShortcuts(),
      actions: _buildKeyboardActions(context),
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
    };
  }

  /// Build keyboard actions for shortcuts
  Map<Type, Action<Intent>> _buildKeyboardActions(BuildContext context) {
    return {
      CreateReceiptIntent: CallbackAction<CreateReceiptIntent>(
        onInvoke: (_) =>
            ref.read(appRouterProvider).pushNamed('/receipt-camera'),
      ),
      CreateInvoiceIntent: CallbackAction<CreateInvoiceIntent>(
        onInvoke: (_) =>
            ref.read(appRouterProvider).pushNamed('/create-invoice'),
      ),
      SyncDataIntent: CallbackAction<SyncDataIntent>(
        onInvoke: (_) => ref.read(syncServiceProvider).startSync(),
      ),
      ShowSearchIntent: CallbackAction<ShowSearchIntent>(
        onInvoke: (_) => ref.read(appRouterProvider).pushNamed('/search'),
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
          if (syncState.isSyncing) const _SyncStatusIndicator(),

          // Connectivity banner
          Consumer(
            builder: (context, ref, _) {
              final connectivity = ref.watch(connectivityProvider);
              if (!connectivity.isConnected) {
                return const _OfflineBanner();
              }
              return const SizedBox.shrink();
            },
          ),

          // Global snackbar
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
