// lib/core/router/route_guards.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/routes.dart';
import '../../data/models/user/user_model.dart';

// Mock provider declarations - these should be replaced with actual implementations
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  return AuthStateNotifier();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  // Mock implementation - replace with actual user data fetching
  return null;
});

// Mock classes - replace with actual implementations
class AuthState {
  final bool isAuthenticated;
  final bool isEmailVerified;

  const AuthState({
    required this.isAuthenticated,
    this.isEmailVerified = false,
  });
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState(isAuthenticated: false));
}

class UserModel {
  final bool hasCompletedOnboarding;
  final bool hasActiveSubscription;
  final Subscription subscription;
  final BusinessType businessType;
  final List<UserRole> roles;

  const UserModel({
    required this.hasCompletedOnboarding,
    required this.hasActiveSubscription,
    required this.subscription,
    required this.businessType,
    required this.roles,
  });
}

class Subscription {
  final int monthlyReceiptCount;
  final int monthlyLimit;

  const Subscription({
    required this.monthlyReceiptCount,
    required this.monthlyLimit,
  });
}

enum UserRole { admin, user, premium }

enum BusinessType { freelancer, smallBusiness, corporation }

/// Base class for route guards
abstract class RouteGuard {
  /// Check if user has access to the given route
  /// Returns null if access is granted, or redirect path if access is denied
  String? checkAccess(String currentRoute);

  /// Get the default redirect route when access is denied
  String get defaultRedirectRoute;

  /// Check if the route should be guarded
  bool shouldGuard(String route);
}

/// Authentication route guard
class AuthGuard implements RouteGuard {
  final Ref ref;

  AuthGuard(this.ref);

  @override
  String? checkAccess(String currentRoute) {
    // Skip guard for public routes
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final authState = ref.read(authStateProvider);

    // If user is not authenticated, redirect to login
    if (!authState.isAuthenticated) {
      return Routes.login;
    }

    // If user is authenticated but email not verified
    if (!authState.isEmailVerified &&
        !_isEmailVerificationRoute(currentRoute)) {
      return Routes.phoneVerification;
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.login;

  @override
  bool shouldGuard(String route) {
    // List of public routes that don't require authentication
    const publicRoutes = [
      Routes.splash,
      Routes.login,
      Routes.register,
      Routes.forgotPassword,
      Routes.phoneVerification,
    ];

    return !publicRoutes.any((publicRoute) => route.startsWith(publicRoute));
  }

  bool _isEmailVerificationRoute(String route) {
    return route == Routes.phoneVerification;
  }
}

/// Onboarding route guard
class OnboardingGuard implements RouteGuard {
  final Ref ref;

  OnboardingGuard(this.ref);

  @override
  String? checkAccess(String currentRoute) {
    // Skip guard for routes that don't require onboarding
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final authState = ref.read(authStateProvider);
    final userState = ref.read(currentUserProvider);

    // Must be authenticated to check onboarding
    if (!authState.isAuthenticated) {
      return null; // AuthGuard will handle this
    }

    // Check if user has completed onboarding
    final user = userState.value;
    if (user != null && !user.hasCompletedOnboarding) {
      return Routes.onboarding;
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.onboarding;

  @override
  bool shouldGuard(String route) {
    // Routes that don't require onboarding completion
    const nonOnboardingRoutes = [
      Routes.splash,
      Routes.login,
      Routes.register,
      Routes.forgotPassword,
      Routes.phoneVerification,
      Routes.onboarding,
    ];

    return !nonOnboardingRoutes.any((route) => route.startsWith(route));
  }
}

/// Subscription route guard
class SubscriptionGuard implements RouteGuard {
  final Ref ref;

  SubscriptionGuard(this.ref);

  @override
  String? checkAccess(String currentRoute) {
    // Skip guard for routes that don't require subscription
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final userState = ref.read(currentUserProvider);
    final user = userState.value;

    if (user == null) {
      return null; // Other guards will handle this
    }

    // Check if user has active subscription for premium features
    if (_isPremiumRoute(currentRoute) && !user.hasActiveSubscription) {
      return '${Routes.settings}/subscription';
    }

    // Check monthly limits for free users
    if (!user.hasActiveSubscription && _isLimitedRoute(currentRoute)) {
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      // Check receipt upload limit
      if (currentRoute.contains('receipt') && currentRoute.contains('camera')) {
        final monthlyReceipts = user.subscription.monthlyReceiptCount;
        if (monthlyReceipts >= user.subscription.monthlyLimit) {
          return '${Routes.settings}/subscription';
        }
      }
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => '${Routes.settings}/subscription';

  @override
  bool shouldGuard(String route) {
    // All authenticated routes should be checked for subscription
    return !route.startsWith(Routes.splash) &&
        !route.startsWith(Routes.login) &&
        !route.startsWith(Routes.register);
  }

  bool _isPremiumRoute(String route) {
    // Routes that require premium subscription
    const premiumRoutes = [
      '/reports/export',
      '/invoices/templates',
      '/settings/integrations',
      '/receipts/bulk-upload',
    ];

    return premiumRoutes.any((premiumRoute) => route.contains(premiumRoute));
  }

  bool _isLimitedRoute(String route) {
    // Routes that have usage limits for free users
    const limitedRoutes = ['/receipts/camera', '/invoices/create'];

    return limitedRoutes.any((limitedRoute) => route.contains(limitedRoute));
  }
}

/// Role-based access control guard
class RoleGuard implements RouteGuard {
  final Ref ref;
  final List<UserRole> allowedRoles;

  RoleGuard(this.ref, this.allowedRoles);

  @override
  String? checkAccess(String currentRoute) {
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final userState = ref.read(currentUserProvider);
    final user = userState.value;

    if (user == null) {
      return null; // Other guards will handle this
    }

    // Check if user has any of the required roles
    final hasRequiredRole = allowedRoles.any(
      (role) => user.roles.contains(role),
    );

    if (!hasRequiredRole) {
      return Routes.dashboard; // Redirect to dashboard if access denied
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.dashboard;

  @override
  bool shouldGuard(String route) {
    // This would be configured per route
    return true;
  }
}

/// Business type access guard
class BusinessTypeGuard implements RouteGuard {
  final Ref ref;
  final List<BusinessType> allowedBusinessTypes;

  BusinessTypeGuard(this.ref, this.allowedBusinessTypes);

  @override
  String? checkAccess(String currentRoute) {
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final userState = ref.read(currentUserProvider);
    final user = userState.value;

    if (user == null) {
      return null;
    }

    // Check if user's business type is allowed
    if (!allowedBusinessTypes.contains(user.businessType)) {
      return Routes.dashboard;
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.dashboard;

  @override
  bool shouldGuard(String route) {
    // Configure which routes need business type checking
    const businessTypeRoutes = ['/reports/tax-estimate', '/settings/business'];

    return businessTypeRoutes.any((btRoute) => route.contains(btRoute));
  }
}

/// Feature flag guard
class FeatureGuard implements RouteGuard {
  final Ref ref;
  final String featureFlag;

  FeatureGuard(this.ref, this.featureFlag);

  @override
  String? checkAccess(String currentRoute) {
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final featureState = ref.read(featureFlagsProvider);

    // Check if feature is enabled
    if (!featureState.isEnabled(featureFlag)) {
      return Routes.dashboard;
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.dashboard;

  @override
  bool shouldGuard(String route) {
    // This would be configured based on the feature
    return true;
  }
}

/// Time-based access guard
class TimeBasedGuard implements RouteGuard {
  final Ref ref;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeBasedGuard(this.ref, this.startTime, this.endTime);

  @override
  String? checkAccess(String currentRoute) {
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final now = TimeOfDay.now();

    // Check if current time is within allowed range
    if (!_isTimeInRange(now, startTime, endTime)) {
      return Routes.dashboard;
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.dashboard;

  @override
  bool shouldGuard(String route) {
    // Configure which routes have time restrictions
    return false; // Implement based on requirements
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day range
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight range
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// Device-based access guard
class DeviceGuard implements RouteGuard {
  final Ref ref;
  final List<String> allowedDeviceIds;

  DeviceGuard(this.ref, this.allowedDeviceIds);

  @override
  String? checkAccess(String currentRoute) {
    if (!shouldGuard(currentRoute)) {
      return null;
    }

    final deviceState = ref.read(deviceInfoProvider);
    final deviceId = deviceState.value?.deviceId;

    if (deviceId == null || !allowedDeviceIds.contains(deviceId)) {
      return Routes.login; // Force re-authentication
    }

    return null;
  }

  @override
  String get defaultRedirectRoute => Routes.login;

  @override
  bool shouldGuard(String route) {
    // Configure which routes need device verification
    const secureRoutes = ['/settings/business', '/reports/export'];

    return secureRoutes.any((secureRoute) => route.contains(secureRoute));
  }
}

/// Composite guard that combines multiple guards
class CompositeGuard implements RouteGuard {
  final List<RouteGuard> guards;

  CompositeGuard(this.guards);

  @override
  String? checkAccess(String currentRoute) {
    // Check all guards in order
    for (final guard in guards) {
      final result = guard.checkAccess(currentRoute);
      if (result != null) {
        return result; // First guard that denies access wins
      }
    }
    return null;
  }

  @override
  String get defaultRedirectRoute => guards.first.defaultRedirectRoute;

  @override
  bool shouldGuard(String route) {
    return guards.any((guard) => guard.shouldGuard(route));
  }
}

/// Guard configuration for different environments
class GuardConfiguration {
  /// Get guards for development environment
  static List<RouteGuard> getDevelopmentGuards(Ref ref) {
    return [
      AuthGuard(ref),
      OnboardingGuard(ref),
      // Skip subscription checks in development
    ];
  }

  /// Get guards for staging environment
  static List<RouteGuard> getStagingGuards(Ref ref) {
    return [AuthGuard(ref), OnboardingGuard(ref), SubscriptionGuard(ref)];
  }

  /// Get guards for production environment
  static List<RouteGuard> getProductionGuards(Ref ref) {
    return [
      AuthGuard(ref),
      OnboardingGuard(ref),
      SubscriptionGuard(ref),
      // Additional security guards for production
    ];
  }
}

/// Guard manager for easier management
class GuardManager {
  final List<RouteGuard> _guards = [];

  /// Add a guard
  void addGuard(RouteGuard guard) {
    _guards.add(guard);
  }

  /// Remove a guard
  void removeGuard(RouteGuard guard) {
    _guards.remove(guard);
  }

  /// Check access across all guards
  String? checkAccess(String currentRoute) {
    for (final guard in _guards) {
      final result = guard.checkAccess(currentRoute);
      if (result != null) {
        if (kDebugMode) {
          debugPrint(
            'Access denied by ${guard.runtimeType} for route: $currentRoute',
          );
          debugPrint('Redirecting to: $result');
        }
        return result;
      }
    }
    return null;
  }

  /// Clear all guards
  void clearGuards() {
    _guards.clear();
  }

  /// Get all active guards
  List<RouteGuard> get activeGuards => List.unmodifiable(_guards);
}

// Riverpod providers
final authGuardProvider = Provider<AuthGuard>((ref) {
  return AuthGuard(ref);
});

final onboardingGuardProvider = Provider<OnboardingGuard>((ref) {
  return OnboardingGuard(ref);
});

final subscriptionGuardProvider = Provider<SubscriptionGuard>((ref) {
  return SubscriptionGuard(ref);
});

final guardManagerProvider = Provider<GuardManager>((ref) {
  final manager = GuardManager();

  // Add guards based on environment
  final guards = GuardConfiguration.getProductionGuards(ref);
  for (final guard in guards) {
    manager.addGuard(guard);
  }

  return manager;
});

// Mock providers for features not yet implemented
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags();
});

final deviceInfoProvider = FutureProvider<DeviceInfo?>((ref) async {
  // Mock implementation
  return DeviceInfo(deviceId: 'mock-device-id');
});

final onboardingStateProvider =
    StateNotifierProvider<OnboardingStateNotifier, OnboardingState>((ref) {
      return OnboardingStateNotifier();
    });

// Mock classes
class FeatureFlags {
  bool isEnabled(String flag) => true; // Mock implementation
}

class DeviceInfo {
  final String deviceId;
  DeviceInfo({required this.deviceId});
}

class OnboardingState {
  final bool isCompleted;
  OnboardingState({required this.isCompleted});
}

class OnboardingStateNotifier extends StateNotifier<OnboardingState> {
  OnboardingStateNotifier() : super(OnboardingState(isCompleted: false));
}
