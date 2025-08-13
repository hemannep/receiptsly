// lib/core/constants/routes.dart

/// Application route paths
class Routes {
  Routes._(); // Private constructor to prevent instantiation

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String phoneVerification = '/phone-verification';

  // Onboarding Routes
  static const String onboarding = '/onboarding';
  static const String businessSetup = '/onboarding/business-setup';
  static const String taxSettings = '/onboarding/tax-settings';
  static const String chatIntegration = '/onboarding/chat-integration';

  // Main App Routes
  static const String dashboard = '/dashboard';

  // Receipt Routes
  static const String receipts = '/receipts';
  static const String receiptCamera = '/receipts/camera';
  static const String receiptDetail = '/receipts/:receiptId';
  static const String receiptEdit = '/receipts/:receiptId/edit';
  static const String bulkUpload = '/receipts/bulk-upload';

  // Invoice Routes
  static const String invoices = '/invoices';
  static const String createInvoice = '/invoices/create';
  static const String invoiceDetail = '/invoices/:invoiceId';
  static const String invoicePreview = '/invoices/:invoiceId/preview';
  static const String invoiceTemplates = '/invoices/templates';
  static const String paymentTracking = '/invoices/payment-tracking';

  // Client Routes
  static const String clients = '/clients';
  static const String addClient = '/clients/add';
  static const String clientDetail = '/clients/:clientId';

  // Report Routes
  static const String reports = '/reports';
  static const String expenseReport = '/reports/expense';
  static const String incomeReport = '/reports/income';
  static const String taxEstimate = '/reports/tax-estimate';
  static const String exportReport = '/reports/export';

  // Settings Routes
  static const String settings = '/settings';
  static const String profileSettings = '/settings/profile';
  static const String businessSettings = '/settings/business';
  static const String integrationSettings = '/settings/integrations';
  static const String subscription = '/settings/subscription';
  static const String syncSettings = '/settings/sync';

  /// Get all defined routes
  static List<String> get allRoutes => [
    splash,
    login,
    register,
    forgotPassword,
    phoneVerification,
    onboarding,
    businessSetup,
    taxSettings,
    chatIntegration,
    dashboard,
    receipts,
    receiptCamera,
    receiptDetail,
    receiptEdit,
    bulkUpload,
    invoices,
    createInvoice,
    invoiceDetail,
    invoicePreview,
    invoiceTemplates,
    paymentTracking,
    clients,
    addClient,
    clientDetail,
    reports,
    expenseReport,
    incomeReport,
    taxEstimate,
    exportReport,
    settings,
    profileSettings,
    businessSettings,
    integrationSettings,
    subscription,
    syncSettings,
  ];

  /// Check if route is a public route (doesn't require authentication)
  static bool isPublicRoute(String route) {
    const publicRoutes = [
      splash,
      login,
      register,
      forgotPassword,
      phoneVerification,
    ];
    return publicRoutes.contains(route) ||
        publicRoutes.any((publicRoute) => route.startsWith(publicRoute));
  }

  /// Check if route is an onboarding route
  static bool isOnboardingRoute(String route) {
    return route.startsWith(onboarding);
  }

  /// Check if route is a main app route (requires completed onboarding)
  static bool isMainAppRoute(String route) {
    const mainAppRoutes = [
      dashboard,
      receipts,
      invoices,
      clients,
      reports,
      settings,
    ];
    return mainAppRoutes.any((mainRoute) => route.startsWith(mainRoute));
  }

  /// Get route with parameters replaced
  static String buildRoute(String route, Map<String, String> params) {
    String builtRoute = route;
    params.forEach((key, value) {
      builtRoute = builtRoute.replaceAll(':$key', value);
    });
    return builtRoute;
  }

  /// Extract route parameters from path
  static Map<String, String> extractParams(
    String routePattern,
    String actualPath,
  ) {
    final params = <String, String>{};
    final patternSegments = routePattern.split('/');
    final pathSegments = actualPath.split('/');

    if (patternSegments.length != pathSegments.length) {
      return params;
    }

    for (int i = 0; i < patternSegments.length; i++) {
      final pattern = patternSegments[i];
      final path = pathSegments[i];

      if (pattern.startsWith(':')) {
        final paramName = pattern.substring(1);
        params[paramName] = path;
      }
    }

    return params;
  }
}

/// Application route names for type-safe navigation
class RouteNames {
  RouteNames._(); // Private constructor to prevent instantiation

  // Auth Route Names
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String phoneVerification = 'phoneVerification';

  // Onboarding Route Names
  static const String onboarding = 'onboarding';
  static const String businessSetup = 'businessSetup';
  static const String taxSettings = 'taxSettings';
  static const String chatIntegration = 'chatIntegration';

  // Main App Route Names
  static const String dashboard = 'dashboard';

  // Receipt Route Names
  static const String receipts = 'receipts';
  static const String receiptCamera = 'receiptCamera';
  static const String receiptDetail = 'receiptDetail';
  static const String receiptEdit = 'receiptEdit';
  static const String bulkUpload = 'bulkUpload';

  // Invoice Route Names
  static const String invoices = 'invoices';
  static const String createInvoice = 'createInvoice';
  static const String invoiceDetail = 'invoiceDetail';
  static const String invoicePreview = 'invoicePreview';
  static const String invoiceTemplates = 'invoiceTemplates';
  static const String paymentTracking = 'paymentTracking';

  // Client Route Names
  static const String clients = 'clients';
  static const String addClient = 'addClient';
  static const String clientDetail = 'clientDetail';

  // Report Route Names
  static const String reports = 'reports';
  static const String expenseReport = 'expenseReport';
  static const String incomeReport = 'incomeReport';
  static const String taxEstimate = 'taxEstimate';
  static const String exportReport = 'exportReport';

  // Settings Route Names
  static const String settings = 'settings';
  static const String profileSettings = 'profileSettings';
  static const String businessSettings = 'businessSettings';
  static const String integrationSettings = 'integrationSettings';
  static const String subscription = 'subscription';
  static const String syncSettings = 'syncSettings';

  /// Get all defined route names
  static List<String> get allRouteNames => [
    splash,
    login,
    register,
    forgotPassword,
    phoneVerification,
    onboarding,
    businessSetup,
    taxSettings,
    chatIntegration,
    dashboard,
    receipts,
    receiptCamera,
    receiptDetail,
    receiptEdit,
    bulkUpload,
    invoices,
    createInvoice,
    invoiceDetail,
    invoicePreview,
    invoiceTemplates,
    paymentTracking,
    clients,
    addClient,
    clientDetail,
    reports,
    expenseReport,
    incomeReport,
    taxEstimate,
    exportReport,
    settings,
    profileSettings,
    businessSettings,
    integrationSettings,
    subscription,
    syncSettings,
  ];

  /// Get route path by name
  static String getRouteByName(String name) {
    switch (name) {
      case splash:
        return Routes.splash;
      case login:
        return Routes.login;
      case register:
        return Routes.register;
      case forgotPassword:
        return Routes.forgotPassword;
      case phoneVerification:
        return Routes.phoneVerification;
      case onboarding:
        return Routes.onboarding;
      case businessSetup:
        return Routes.businessSetup;
      case taxSettings:
        return Routes.taxSettings;
      case chatIntegration:
        return Routes.chatIntegration;
      case dashboard:
        return Routes.dashboard;
      case receipts:
        return Routes.receipts;
      case receiptCamera:
        return Routes.receiptCamera;
      case receiptDetail:
        return Routes.receiptDetail;
      case receiptEdit:
        return Routes.receiptEdit;
      case bulkUpload:
        return Routes.bulkUpload;
      case invoices:
        return Routes.invoices;
      case createInvoice:
        return Routes.createInvoice;
      case invoiceDetail:
        return Routes.invoiceDetail;
      case invoicePreview:
        return Routes.invoicePreview;
      case invoiceTemplates:
        return Routes.invoiceTemplates;
      case paymentTracking:
        return Routes.paymentTracking;
      case clients:
        return Routes.clients;
      case addClient:
        return Routes.addClient;
      case clientDetail:
        return Routes.clientDetail;
      case reports:
        return Routes.reports;
      case expenseReport:
        return Routes.expenseReport;
      case incomeReport:
        return Routes.incomeReport;
      case taxEstimate:
        return Routes.taxEstimate;
      case exportReport:
        return Routes.exportReport;
      case settings:
        return Routes.settings;
      case profileSettings:
        return Routes.profileSettings;
      case businessSettings:
        return Routes.businessSettings;
      case integrationSettings:
        return Routes.integrationSettings;
      case subscription:
        return Routes.subscription;
      case syncSettings:
        return Routes.syncSettings;
      default:
        throw ArgumentError('Unknown route name: $name');
    }
  }

  /// Get route name by path
  static String? getNameByRoute(String route) {
    // Remove parameters from route for matching
    String cleanRoute = route.replaceAllMapped(
      RegExp(r'/[^/]+'),
      (match) =>
          match.group(0)!.contains(':') ? match.group(0)! : match.group(0)!,
    );

    switch (cleanRoute) {
      case Routes.splash:
        return splash;
      case Routes.login:
        return login;
      case Routes.register:
        return register;
      case Routes.forgotPassword:
        return forgotPassword;
      case Routes.phoneVerification:
        return phoneVerification;
      case Routes.onboarding:
        return onboarding;
      case Routes.businessSetup:
        return businessSetup;
      case Routes.taxSettings:
        return taxSettings;
      case Routes.chatIntegration:
        return chatIntegration;
      case Routes.dashboard:
        return dashboard;
      case Routes.receipts:
        return receipts;
      case Routes.receiptCamera:
        return receiptCamera;
      case Routes.receiptDetail:
        return receiptDetail;
      case Routes.receiptEdit:
        return receiptEdit;
      case Routes.bulkUpload:
        return bulkUpload;
      case Routes.invoices:
        return invoices;
      case Routes.createInvoice:
        return createInvoice;
      case Routes.invoiceDetail:
        return invoiceDetail;
      case Routes.invoicePreview:
        return invoicePreview;
      case Routes.invoiceTemplates:
        return invoiceTemplates;
      case Routes.paymentTracking:
        return paymentTracking;
      case Routes.clients:
        return clients;
      case Routes.addClient:
        return addClient;
      case Routes.clientDetail:
        return clientDetail;
      case Routes.reports:
        return reports;
      case Routes.expenseReport:
        return expenseReport;
      case Routes.incomeReport:
        return incomeReport;
      case Routes.taxEstimate:
        return taxEstimate;
      case Routes.exportReport:
        return exportReport;
      case Routes.settings:
        return settings;
      case Routes.profileSettings:
        return profileSettings;
      case Routes.businessSettings:
        return businessSettings;
      case Routes.integrationSettings:
        return integrationSettings;
      case Routes.subscription:
        return subscription;
      case Routes.syncSettings:
        return syncSettings;
      default:
        return null;
    }
  }
}

/// Route validation utilities
class RouteValidator {
  /// Validate if route exists
  static bool isValidRoute(String route) {
    return Routes.allRoutes.contains(route) ||
        Routes.allRoutes.any(
          (validRoute) => _matchesPattern(validRoute, route),
        );
  }

  /// Check if route matches pattern (for parameterized routes)
  static bool _matchesPattern(String pattern, String route) {
    final patternSegments = pattern.split('/');
    final routeSegments = route.split('/');

    if (patternSegments.length != routeSegments.length) {
      return false;
    }

    for (int i = 0; i < patternSegments.length; i++) {
      final patternSegment = patternSegments[i];
      final routeSegment = routeSegments[i];

      // If pattern segment is a parameter, it matches any value
      if (patternSegment.startsWith(':')) {
        continue;
      }

      // Otherwise, segments must match exactly
      if (patternSegment != routeSegment) {
        return false;
      }
    }

    return true;
  }

  /// Validate route name
  static bool isValidRouteName(String name) {
    return RouteNames.allRouteNames.contains(name);
  }

  /// Get route type
  static RouteType getRouteType(String route) {
    if (Routes.isPublicRoute(route)) {
      return RouteType.public;
    } else if (Routes.isOnboardingRoute(route)) {
      return RouteType.onboarding;
    } else if (Routes.isMainAppRoute(route)) {
      return RouteType.authenticated;
    } else {
      return RouteType.unknown;
    }
  }
}

/// Route type enumeration
enum RouteType { public, onboarding, authenticated, unknown }

/// Route configuration for different features
class RouteConfig {
  final String route;
  final String name;
  final bool requiresAuth;
  final bool requiresOnboarding;
  final bool requiresSubscription;
  final List<String>? requiredRoles;
  final Map<String, dynamic>? metadata;

  const RouteConfig({
    required this.route,
    required this.name,
    this.requiresAuth = true,
    this.requiresOnboarding = true,
    this.requiresSubscription = false,
    this.requiredRoles,
    this.metadata,
  });

  static const List<RouteConfig> allConfigs = [
    // Public routes
    RouteConfig(
      route: Routes.splash,
      name: RouteNames.splash,
      requiresAuth: false,
      requiresOnboarding: false,
    ),
    RouteConfig(
      route: Routes.login,
      name: RouteNames.login,
      requiresAuth: false,
      requiresOnboarding: false,
    ),
    RouteConfig(
      route: Routes.register,
      name: RouteNames.register,
      requiresAuth: false,
      requiresOnboarding: false,
    ),

    // Onboarding routes
    RouteConfig(
      route: Routes.onboarding,
      name: RouteNames.onboarding,
      requiresAuth: true,
      requiresOnboarding: false,
    ),

    // Main app routes
    RouteConfig(
      route: Routes.dashboard,
      name: RouteNames.dashboard,
      requiresAuth: true,
      requiresOnboarding: true,
    ),
    RouteConfig(
      route: Routes.receipts,
      name: RouteNames.receipts,
      requiresAuth: true,
      requiresOnboarding: true,
    ),

    // Premium routes
    RouteConfig(
      route: Routes.invoiceTemplates,
      name: RouteNames.invoiceTemplates,
      requiresAuth: true,
      requiresOnboarding: true,
      requiresSubscription: true,
    ),
    RouteConfig(
      route: Routes.exportReport,
      name: RouteNames.exportReport,
      requiresAuth: true,
      requiresOnboarding: true,
      requiresSubscription: true,
    ),
  ];

  /// Get configuration for route
  static RouteConfig? getConfigForRoute(String route) {
    return allConfigs.cast<RouteConfig?>().firstWhere(
      (config) => config?.route == route,
      orElse: () => null,
    );
  }

  /// Get configuration for route name
  static RouteConfig? getConfigForRouteName(String name) {
    return allConfigs.cast<RouteConfig?>().firstWhere(
      (config) => config?.name == name,
      orElse: () => null,
    );
  }
}

/// Route analytics helper
class RouteAnalyticsHelper {
  static const Map<String, String> _routeCategories = {
    Routes.splash: 'app_lifecycle',
    Routes.login: 'authentication',
    Routes.register: 'authentication',
    Routes.forgotPassword: 'authentication',
    Routes.phoneVerification: 'authentication',
    Routes.onboarding: 'onboarding',
    Routes.businessSetup: 'onboarding',
    Routes.taxSettings: 'onboarding',
    Routes.chatIntegration: 'onboarding',
    Routes.dashboard: 'main_app',
    Routes.receipts: 'receipts',
    Routes.receiptCamera: 'receipts',
    Routes.receiptDetail: 'receipts',
    Routes.receiptEdit: 'receipts',
    Routes.bulkUpload: 'receipts',
    Routes.invoices: 'invoices',
    Routes.createInvoice: 'invoices',
    Routes.invoiceDetail: 'invoices',
    Routes.invoicePreview: 'invoices',
    Routes.invoiceTemplates: 'invoices',
    Routes.paymentTracking: 'invoices',
    Routes.clients: 'clients',
    Routes.addClient: 'clients',
    Routes.clientDetail: 'clients',
    Routes.reports: 'reports',
    Routes.expenseReport: 'reports',
    Routes.incomeReport: 'reports',
    Routes.taxEstimate: 'reports',
    Routes.exportReport: 'reports',
    Routes.settings: 'settings',
    Routes.profileSettings: 'settings',
    Routes.businessSettings: 'settings',
    Routes.integrationSettings: 'settings',
    Routes.subscription: 'settings',
    Routes.syncSettings: 'settings',
  };

  /// Get category for route
  static String getCategoryForRoute(String route) {
    return _routeCategories[route] ?? 'unknown';
  }

  /// Get routes by category
  static List<String> getRoutesByCategory(String category) {
    return _routeCategories.entries
        .where((entry) => entry.value == category)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all categories
  static List<String> getAllCategories() {
    return _routeCategories.values.toSet().toList();
  }
}
