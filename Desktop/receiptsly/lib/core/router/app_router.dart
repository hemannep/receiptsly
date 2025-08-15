// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/phone_verification_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/business_setup_screen.dart';
import '../../presentation/screens/onboarding/tax_settings_screen.dart';
import '../../presentation/screens/onboarding/chat_integration_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/receipt/receipt_list_screen.dart';
import '../../presentation/screens/receipt/receipt_camera_screen.dart';
import '../../presentation/screens/receipt/receipt_detail_screen.dart';
import '../../presentation/screens/receipt/receipt_edit_screen.dart';
import '../../presentation/screens/receipt/bulk_upload_screen.dart';
import '../../presentation/screens/invoice/invoice_list_screen.dart';
import '../../presentation/screens/invoice/create_invoice_screen.dart';
import '../../presentation/screens/invoice/invoice_detail_screen.dart';
import '../../presentation/screens/invoice/invoice_preview_screen.dart';
import '../../presentation/screens/invoice/invoice_templates_screen.dart';
import '../../presentation/screens/invoice/payment_tracking_screen.dart';
import '../../presentation/screens/client/client_list_screen.dart';
import '../../presentation/screens/client/client_detail_screen.dart';
import '../../presentation/screens/client/add_client_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/reports/expense_report_screen.dart';
import '../../presentation/screens/reports/income_report_screen.dart';
import '../../presentation/screens/reports/tax_estimate_screen.dart';
import '../../presentation/screens/reports/export_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/profile_settings_screen.dart';
import '../../presentation/screens/settings/business_settings_screen.dart';
import 'package:flutter/material.dart' as material;
import '../../presentation/screens/settings/integration_settings_screen.dart';
import '../../presentation/screens/settings/subscription_screen.dart';
import '../../presentation/screens/settings/sync_settings_screen.dart';
import '../../presentation/widgets/layouts/bottom_navigation.dart';
import '../constants/routes.dart';
import '../errors/exceptions.dart';
import 'route_guards.dart';
import 'route_transitions.dart';

/// Route transition types
enum RouteTransitionType { slide, fade, scale, none }

/// Application router configuration
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static GlobalKey<NavigatorState> get shellNavigatorKey => _shellNavigatorKey;

  /// Create router configuration
  static GoRouter createRouter(WidgetRef ref) {
    final authGuard = ref.watch(authGuardProvider);
    final onboardingGuard = ref.watch(onboardingGuardProvider);
    final subscriptionGuard = ref.watch(subscriptionGuardProvider);

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: Routes.splash,
      debugLogDiagnostics: true,
      errorBuilder: (context, state) => _buildErrorPage(context, state),
      redirect: (context, state) => _handleGlobalRedirects(context, state, ref),
      refreshListenable: _createRefreshListenable(ref),
      routes: [
        // Splash Route
        GoRoute(
          path: Routes.splash,
          name: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Authentication Routes
        GoRoute(
          path: Routes.login,
          name: RouteNames.login,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            child: const LoginScreen(),
            settings: state,
          ),
        ),
        GoRoute(
          path: Routes.register,
          name: RouteNames.register,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            child: const RegisterScreen(),
            settings: state,
          ),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          name: RouteNames.forgotPassword,
          pageBuilder: (context, state) => RouteTransitions.fadeIn(
            child: const ForgotPasswordScreen(),
            settings: state,
          ),
        ),
        GoRoute(
          path: Routes.phoneVerification,
          name: RouteNames.phoneVerification,
          builder: (context, state) {
            final phoneNumber = state.extra as String?;
            return PhoneVerificationScreen(phoneNumber: phoneNumber);
          },
        ),

        // Onboarding Routes
        GoRoute(
          path: Routes.onboarding,
          name: RouteNames.onboarding,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            child: const OnboardingScreen(),
            settings: state,
          ),
          routes: [
            GoRoute(
              path: 'business-setup',
              name: RouteNames.businessSetup,
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                child: const BusinessSetupScreen(),
                settings: state,
              ),
            ),
            GoRoute(
              path: 'tax-settings',
              name: RouteNames.taxSettings,
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                child: const TaxSettingsScreen(),
                settings: state,
              ),
            ),
            GoRoute(
              path: 'chat-integration',
              name: RouteNames.chatIntegration,
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                child: const ChatIntegrationScreen(),
                settings: state,
              ),
            ),
          ],
        ),

        // Main App Shell with Bottom Navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return BottomNavigationShell(child: child);
          },
          routes: [
            // Dashboard Route
            GoRoute(
              path: Routes.dashboard,
              name: RouteNames.dashboard,
              pageBuilder: (context, state) => RouteTransitions.fadeIn(
                child: const DashboardScreen(),
                settings: state,
              ),
            ),

            // Receipts Routes
            GoRoute(
              path: Routes.receipts,
              name: RouteNames.receipts,
              pageBuilder: (context, state) => RouteTransitions.fadeIn(
                child: const ReceiptListScreen(),
                settings: state,
              ),
              routes: [
                GoRoute(
                  path: 'camera',
                  name: RouteNames.receiptCamera,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromBottom(
                        child: const ReceiptCameraScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'bulk-upload',
                  name: RouteNames.bulkUpload,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const BulkUploadScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: ':receiptId',
                  name: RouteNames.receiptDetail,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final receiptId = state.pathParameters['receiptId']!;
                    return RouteTransitions.slideFromRight(
                      child: ReceiptDetailScreen(receiptId: receiptId),
                      settings: state,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: RouteNames.receiptEdit,
                      pageBuilder: (context, state) {
                        final receiptId = state.pathParameters['receiptId']!;
                        return RouteTransitions.slideFromRight(
                          child: ReceiptEditScreen(receiptId: receiptId),
                          settings: state,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Invoices Routes
            GoRoute(
              path: Routes.invoices,
              name: RouteNames.invoices,
              pageBuilder: (context, state) => RouteTransitions.fadeIn(
                child: const InvoiceListScreen(),
                settings: state,
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.createInvoice,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const CreateInvoiceScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'templates',
                  name: RouteNames.invoiceTemplates,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const InvoiceTemplatesScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'payment-tracking',
                  name: RouteNames.paymentTracking,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const PaymentTrackingScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: ':invoiceId',
                  name: RouteNames.invoiceDetail,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final invoiceId = state.pathParameters['invoiceId']!;
                    return RouteTransitions.slideFromRight(
                      child: InvoiceDetailScreen(invoiceId: invoiceId),
                      settings: state,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'preview',
                      name: RouteNames.invoicePreview,
                      pageBuilder: (context, state) {
                        final invoiceId = state.pathParameters['invoiceId']!;
                        return RouteTransitions.slideFromRight(
                          child: InvoicePreviewScreen(invoiceId: invoiceId),
                          settings: state,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Clients Routes
            GoRoute(
              path: Routes.clients,
              name: RouteNames.clients,
              pageBuilder: (context, state) => RouteTransitions.fadeIn(
                child: const ClientListScreen(),
                settings: state,
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  name: RouteNames.addClient,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const AddClientScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: ':clientId',
                  name: RouteNames.clientDetail,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final clientId = state.pathParameters['clientId']!;
                    return RouteTransitions.slideFromRight(
                      child: ClientDetailScreen(clientId: clientId),
                      settings: state,
                    );
                  },
                ),
              ],
            ),

            // Reports Routes
            GoRoute(
              path: Routes.reports,
              name: RouteNames.reports,
              pageBuilder: (context, state) => RouteTransitions.fadeIn(
                child: const ReportsScreen(),
                settings: state,
              ),
              routes: [
                GoRoute(
                  path: 'expense',
                  name: RouteNames.expenseReport,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const ExpenseReportScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'income',
                  name: RouteNames.incomeReport,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const IncomeReportScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'tax-estimate',
                  name: RouteNames.taxEstimate,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const TaxEstimateScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'export',
                  name: RouteNames.exportReport,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const ExportScreen(),
                        settings: state,
                      ),
                ),
              ],
            ),

            // Settings Routes
            GoRoute(
              path: Routes.settings,
              name: RouteNames.settings,
              pageBuilder: (context, state) => RouteTransitions.fadeIn(
                child: const SettingsScreen(),
                settings: state,
              ),
              routes: [
                GoRoute(
                  path: 'profile',
                  name: RouteNames.profileSettings,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const ProfileSettingsScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'business',
                  name: RouteNames.businessSettings,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const BusinessSettingsScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'integrations',
                  name: RouteNames.integrationSettings,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const IntegrationSettingsScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'subscription',
                  name: RouteNames.subscription,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const SubscriptionScreen(),
                        settings: state,
                      ),
                ),
                GoRoute(
                  path: 'sync',
                  name: RouteNames.syncSettings,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideFromRight(
                        child: const SyncSettingsScreen(),
                        settings: state,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Handle global redirects
  static String? _handleGlobalRedirects(
    BuildContext context,
    GoRouterState state,
    WidgetRef ref,
  ) {
    final currentLocation = state.fullPath ?? state.matchedLocation;
    final authGuard = ref.read(authGuardProvider);
    final onboardingGuard = ref.read(onboardingGuardProvider);

    // Skip redirects for splash screen
    if (currentLocation == Routes.splash) {
      return null;
    }

    // Check authentication
    final authRedirect = authGuard.checkAccess(currentLocation);
    if (authRedirect != null) {
      return authRedirect;
    }

    // Check onboarding completion
    final onboardingRedirect = onboardingGuard.checkAccess(currentLocation);
    if (onboardingRedirect != null) {
      return onboardingRedirect;
    }

    return null;
  }

  /// Create refresh listenable for router
  static Listenable _createRefreshListenable(WidgetRef ref) {
    // Create a simple notifier that can be used to refresh the router
    return ChangeNotifier();
  }

  /// Build error page
  static Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return ErrorScreen(
      error: state.error?.toString() ?? 'Unknown navigation error',
      onRetry: () => context.go(Routes.dashboard),
    );
  }
}

/// Error screen widget
class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      body: material.Center(
        child: material.Padding(
          padding: const material.EdgeInsets.all(24.0),
          child: material.Column(
            mainAxisAlignment: material.MainAxisAlignment.center,
            children: [
              const material.Icon(
                material.Icons.error_outline,
                size: 64,
                color: material.Colors.red,
              ),
              const material.SizedBox(height: 16),
              const material.Text(
                'Navigation Error',
                style: material.TextStyle(
                  fontSize: 24,
                  fontWeight: material.FontWeight.bold,
                ),
              ),
              const material.SizedBox(height: 8),
              material.Text(
                error,
                textAlign: material.TextAlign.center,
                style: const material.TextStyle(
                  fontSize: 16,
                  color: material.Colors.grey,
                ),
              ),
              const material.SizedBox(height: 24),
              if (onRetry != null)
                material.ElevatedButton(
                  onPressed: onRetry,
                  child: const material.Text('Go to Dashboard'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation Shell Widget
class BottomNavigationShell extends StatelessWidget {
  final Widget child;

  const BottomNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const BottomNavigation());
  }
}

/// Router helper methods
extension AppRouterExtension on GoRouter {
  /// Navigate to route with optional parameters
  void navigateToRoute(
    String routeName, {
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    String path = _getRoutePathByName(routeName);

    // Replace path parameters
    if (pathParameters != null) {
      pathParameters.forEach((key, value) {
        path = path.replaceAll(':$key', value);
      });
    }

    // Add query parameters
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final uri = Uri.parse(path);
      final newUri = uri.replace(queryParameters: queryParameters);
      path = newUri.toString();
    }

    if (extra != null) {
      go(path, extra: extra);
    } else {
      go(path);
    }
  }

  /// Push route with optional parameters
  void pushRoute(
    String routeName, {
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    String path = _getRoutePathByName(routeName);

    if (pathParameters != null) {
      pathParameters.forEach((key, value) {
        path = path.replaceAll(':$key', value);
      });
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final uri = Uri.parse(path);
      final newUri = uri.replace(queryParameters: queryParameters);
      path = newUri.toString();
    }

    if (extra != null) {
      push(path, extra: extra);
    } else {
      push(path);
    }
  }

  /// Get route path by name
  String _getRoutePathByName(String routeName) {
    switch (routeName) {
      case RouteNames.splash:
        return Routes.splash;
      case RouteNames.login:
        return Routes.login;
      case RouteNames.register:
        return Routes.register;
      case RouteNames.forgotPassword:
        return Routes.forgotPassword;
      case RouteNames.phoneVerification:
        return Routes.phoneVerification;
      case RouteNames.onboarding:
        return Routes.onboarding;
      case RouteNames.dashboard:
        return Routes.dashboard;
      case RouteNames.receipts:
        return Routes.receipts;
      case RouteNames.receiptCamera:
        return '${Routes.receipts}/camera';
      case RouteNames.receiptDetail:
        return '${Routes.receipts}/:receiptId';
      case RouteNames.receiptEdit:
        return '${Routes.receipts}/:receiptId/edit';
      case RouteNames.bulkUpload:
        return '${Routes.receipts}/bulk-upload';
      case RouteNames.invoices:
        return Routes.invoices;
      case RouteNames.createInvoice:
        return '${Routes.invoices}/create';
      case RouteNames.invoiceDetail:
        return '${Routes.invoices}/:invoiceId';
      case RouteNames.invoicePreview:
        return '${Routes.invoices}/:invoiceId/preview';
      case RouteNames.invoiceTemplates:
        return '${Routes.invoices}/templates';
      case RouteNames.paymentTracking:
        return '${Routes.invoices}/payment-tracking';
      case RouteNames.clients:
        return Routes.clients;
      case RouteNames.addClient:
        return '${Routes.clients}/add';
      case RouteNames.clientDetail:
        return '${Routes.clients}/:clientId';
      case RouteNames.reports:
        return Routes.reports;
      case RouteNames.expenseReport:
        return '${Routes.reports}/expense';
      case RouteNames.incomeReport:
        return '${Routes.reports}/income';
      case RouteNames.taxEstimate:
        return '${Routes.reports}/tax-estimate';
      case RouteNames.exportReport:
        return '${Routes.reports}/export';
      case RouteNames.settings:
        return Routes.settings;
      case RouteNames.profileSettings:
        return '${Routes.settings}/profile';
      case RouteNames.businessSettings:
        return '${Routes.settings}/business';
      case RouteNames.integrationSettings:
        return '${Routes.settings}/integrations';
      case RouteNames.subscription:
        return '${Routes.settings}/subscription';
      case RouteNames.syncSettings:
        return '${Routes.settings}/sync';
      default:
        throw CustomAppException(message: 'Unknown route name: $routeName');
    }
  }
}

/// Custom Application Exception
class CustomAppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const CustomAppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'CustomAppException: $message';
}

/// Navigation service for easier navigation throughout the app
class NavigationService {
  static GoRouter? _router;

  static void initialize(GoRouter router) {
    _router = router;
  }

  static GoRouter get router {
    if (_router == null) {
      throw Exception(
        'NavigationService not initialized. Call initialize() first.',
      );
    }
    return _router!;
  }

  // Quick navigation methods
  static void goToLogin() => router.go(Routes.login);
  static void goToRegister() => router.go(Routes.register);
  static void goToDashboard() => router.go(Routes.dashboard);
  static void goToReceipts() => router.go(Routes.receipts);
  static void goToInvoices() => router.go(Routes.invoices);
  static void goToClients() => router.go(Routes.clients);
  static void goToReports() => router.go(Routes.reports);
  static void goToSettings() => router.go(Routes.settings);

  // Navigation with parameters
  static void goToReceiptDetail(String receiptId) {
    router.navigateToRoute(
      RouteNames.receiptDetail,
      pathParameters: {'receiptId': receiptId},
    );
  }

  static void goToInvoiceDetail(String invoiceId) {
    router.navigateToRoute(
      RouteNames.invoiceDetail,
      pathParameters: {'invoiceId': invoiceId},
    );
  }

  static void goToClientDetail(String clientId) {
    router.navigateToRoute(
      RouteNames.clientDetail,
      pathParameters: {'clientId': clientId},
    );
  }

  // Push navigation methods
  static void pushReceiptCamera() {
    router.pushRoute(RouteNames.receiptCamera);
  }

  static void pushCreateInvoice() {
    router.pushRoute(RouteNames.createInvoice);
  }

  static void pushAddClient() {
    router.pushRoute(RouteNames.addClient);
  }

  static void pushReceiptEdit(String receiptId) {
    router.pushRoute(
      RouteNames.receiptEdit,
      pathParameters: {'receiptId': receiptId},
    );
  }

  static void pushInvoicePreview(String invoiceId) {
    router.pushRoute(
      RouteNames.invoicePreview,
      pathParameters: {'invoiceId': invoiceId},
    );
  }

  // Back navigation
  static void goBack() {
    if (router.canPop()) {
      router.pop();
    } else {
      goToDashboard();
    }
  }

  // Check if can go back
  static bool canGoBack() => router.canPop();

  // Get current location
  static String getCurrentLocation() {
    return router.routerDelegate.currentConfiguration.last.matchedLocation;
  }

  // Check if currently on route
  static bool isCurrentRoute(String routePath) {
    return getCurrentLocation() == routePath;
  }

  // Clear navigation stack and go to route
  static void clearAndGoTo(String routePath) {
    router.go(routePath);
  }

  // Navigate with custom transition
  static void navigateWithTransition(
    String routePath, {
    RouteTransitionType transitionType = RouteTransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Object? extra,
  }) {
    router.push(routePath, extra: extra);
  }
}

/// Route analytics service
class RouteAnalytics {
  static final Map<String, int> _routeVisits = {};
  static final Map<String, DateTime> _routeTimestamps = {};
  static final List<String> _navigationHistory = [];

  /// Track route visit
  static void trackRouteVisit(String routePath) {
    _routeVisits[routePath] = (_routeVisits[routePath] ?? 0) + 1;
    _routeTimestamps[routePath] = DateTime.now();
    _navigationHistory.add(routePath);

    // Keep history limited to last 50 entries
    if (_navigationHistory.length > 50) {
      _navigationHistory.removeAt(0);
    }
  }

  /// Get route visit count
  static int getRouteVisitCount(String routePath) {
    return _routeVisits[routePath] ?? 0;
  }

  /// Get most visited routes
  static List<MapEntry<String, int>> getMostVisitedRoutes({int limit = 10}) {
    final entries = _routeVisits.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get navigation history
  static List<String> getNavigationHistory() {
    return List.unmodifiable(_navigationHistory);
  }

  /// Get last visit time for route
  static DateTime? getLastVisitTime(String routePath) {
    return _routeTimestamps[routePath];
  }

  /// Clear analytics data
  static void clearAnalytics() {
    _routeVisits.clear();
    _routeTimestamps.clear();
    _navigationHistory.clear();
  }

  /// Get analytics summary
  static Map<String, dynamic> getAnalyticsSummary() {
    return {
      'totalRoutes': _routeVisits.length,
      'totalVisits': _routeVisits.values.fold(0, (sum, count) => sum + count),
      'mostVisited': getMostVisitedRoutes(limit: 5),
      'recentHistory': _navigationHistory.take(10).toList(),
    };
  }
}

// Riverpod providers
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref as WidgetRef);
});

final navigationServiceProvider = Provider<NavigationService>((ref) {
  final router = ref.watch(appRouterProvider);
  NavigationService.initialize(router);
  return NavigationService();
});

final currentRouteProvider = Provider<String>((ref) {
  final router = ref.watch(appRouterProvider);
  return router.routerDelegate.currentConfiguration.last.matchedLocation;
});

// Required Routes and RouteNames classes that need to be defined elsewhere
class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String phoneVerification = '/phone-verification';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String receipts = '/receipts';
  static const String invoices = '/invoices';
  static const String clients = '/clients';
  static const String reports = '/reports';
  static const String settings = '/settings';
}

class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String phoneVerification = 'phoneVerification';
  static const String onboarding = 'onboarding';
  static const String businessSetup = 'businessSetup';
  static const String taxSettings = 'taxSettings';
  static const String chatIntegration = 'chatIntegration';
  static const String dashboard = 'dashboard';
  static const String receipts = 'receipts';
  static const String receiptCamera = 'receiptCamera';
  static const String receiptDetail = 'receiptDetail';
  static const String receiptEdit = 'receiptEdit';
  static const String bulkUpload = 'bulkUpload';
  static const String invoices = 'invoices';
  static const String createInvoice = 'createInvoice';
  static const String invoiceDetail = 'invoiceDetail';
  static const String invoicePreview = 'invoicePreview';
  static const String invoiceTemplates = 'invoiceTemplates';
  static const String paymentTracking = 'paymentTracking';
  static const String clients = 'clients';
  static const String addClient = 'addClient';
  static const String clientDetail = 'clientDetail';
  static const String reports = 'reports';
  static const String expenseReport = 'expenseReport';
  static const String incomeReport = 'incomeReport';
  static const String taxEstimate = 'taxEstimate';
  static const String exportReport = 'exportReport';
  static const String settings = 'settings';
  static const String profileSettings = 'profileSettings';
  static const String businessSettings = 'businessSettings';
  static const String integrationSettings = 'integrationSettings';
  static const String subscription = 'subscription';
  static const String syncSettings = 'syncSettings';
}
