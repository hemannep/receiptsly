import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:receiptsly/presentation/providers/sync_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

// App Theme Mode Provider
final appThemeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
      return ThemeModeNotifier();
    });

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[themeIndex];
  }

  void setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

// App Locale Provider
final appLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en', 'US')) {
    _loadLocale();
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    final countryCode = prefs.getString('country_code') ?? 'US';
    state = Locale(languageCode, countryCode);
  }

  void setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('country_code', locale.countryCode!);
    }
  }
}

// App Navigation State
class AppNavigationState {
  final int currentIndex;
  final String currentRoute;
  final Map<String, dynamic> routeParams;

  const AppNavigationState({
    this.currentIndex = 0,
    this.currentRoute = '/dashboard',
    this.routeParams = const {},
  });

  AppNavigationState copyWith({
    int? currentIndex,
    String? currentRoute,
    Map<String, dynamic>? routeParams,
  }) {
    return AppNavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      currentRoute: currentRoute ?? this.currentRoute,
      routeParams: routeParams ?? this.routeParams,
    );
  }
}

// App Navigation Notifier
class AppNavigationNotifier extends StateNotifier<AppNavigationState> {
  AppNavigationNotifier() : super(const AppNavigationState());

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setCurrentRoute(String route, {Map<String, dynamic>? params}) {
    state = state.copyWith(currentRoute: route, routeParams: params ?? {});
  }
}

// App Navigation Provider
final appNavigationProvider =
    StateNotifierProvider<AppNavigationNotifier, AppNavigationState>((ref) {
      return AppNavigationNotifier();
    });

// App Loading State
class AppLoadingState {
  final bool isLoading;
  final String? loadingMessage;
  final double? progress;

  const AppLoadingState({
    this.isLoading = false,
    this.loadingMessage,
    this.progress,
  });

  AppLoadingState copyWith({
    bool? isLoading,
    String? loadingMessage,
    double? progress,
  }) {
    return AppLoadingState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      progress: progress ?? this.progress,
    );
  }
}

// App Loading Notifier
class AppLoadingNotifier extends StateNotifier<AppLoadingState> {
  AppLoadingNotifier() : super(const AppLoadingState());

  void showLoading({String? message, double? progress}) {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: message,
      progress: progress,
    );
  }

  void hideLoading() {
    state = const AppLoadingState();
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }
}

// App Loading Provider
final appLoadingProvider =
    StateNotifierProvider<AppLoadingNotifier, AppLoadingState>((ref) {
      return AppLoadingNotifier();
    });

// App Error State
class AppErrorState {
  final bool hasError;
  final String? errorMessage;
  final String? errorCode;
  final StackTrace? stackTrace;

  const AppErrorState({
    this.hasError = false,
    this.errorMessage,
    this.errorCode,
    this.stackTrace,
  });

  AppErrorState copyWith({
    bool? hasError,
    String? errorMessage,
    String? errorCode,
    StackTrace? stackTrace,
  }) {
    return AppErrorState(
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

// App Error Notifier
class AppErrorNotifier extends StateNotifier<AppErrorState> {
  AppErrorNotifier() : super(const AppErrorState());

  void showError({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) {
    state = AppErrorState(
      hasError: true,
      errorMessage: message,
      errorCode: code,
      stackTrace: stackTrace,
    );
  }

  void clearError() {
    state = const AppErrorState();
  }
}

// App Error Provider
final appErrorProvider = StateNotifierProvider<AppErrorNotifier, AppErrorState>(
  (ref) {
    return AppErrorNotifier();
  },
);

// App Preferences State
class AppPreferences {
  final String currency;
  final String dateFormat;
  final String timeFormat;
  final bool showOnboarding;
  final bool enableNotifications;
  final bool enableBiometrics;
  final String defaultCategory;
  final bool autoBackup;

  const AppPreferences({
    this.currency = 'USD',
    this.dateFormat = 'MM/dd/yyyy',
    this.timeFormat = '12h',
    this.showOnboarding = true,
    this.enableNotifications = true,
    this.enableBiometrics = false,
    this.defaultCategory = 'General',
    this.autoBackup = true,
  });

  AppPreferences copyWith({
    String? currency,
    String? dateFormat,
    String? timeFormat,
    bool? showOnboarding,
    bool? enableNotifications,
    bool? enableBiometrics,
    String? defaultCategory,
    bool? autoBackup,
  }) {
    return AppPreferences(
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      showOnboarding: showOnboarding ?? this.showOnboarding,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      autoBackup: autoBackup ?? this.autoBackup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'showOnboarding': showOnboarding,
      'enableNotifications': enableNotifications,
      'enableBiometrics': enableBiometrics,
      'defaultCategory': defaultCategory,
      'autoBackup': autoBackup,
    };
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      currency: json['currency'] ?? 'USD',
      dateFormat: json['dateFormat'] ?? 'MM/dd/yyyy',
      timeFormat: json['timeFormat'] ?? '12h',
      showOnboarding: json['showOnboarding'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      enableBiometrics: json['enableBiometrics'] ?? false,
      defaultCategory: json['defaultCategory'] ?? 'General',
      autoBackup: json['autoBackup'] ?? true,
    );
  }
}

// App Preferences Notifier
class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier() : super(const AppPreferences()) {
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString('app_preferences');
    if (prefsJson != null) {
      final prefsMap = Map<String, dynamic>.from(jsonDecode(prefsJson) as Map);
      state = AppPreferences.fromJson(prefsMap);
    }
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_preferences', jsonEncode(state.toJson()));
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency);
    _savePreferences();
  }

  void updateDateFormat(String format) {
    state = state.copyWith(dateFormat: format);
    _savePreferences();
  }

  void updateTimeFormat(String format) {
    state = state.copyWith(timeFormat: format);
    _savePreferences();
  }

  void setOnboardingCompleted() {
    state = state.copyWith(showOnboarding: false);
    _savePreferences();
  }

  void updateNotifications(bool enabled) {
    state = state.copyWith(enableNotifications: enabled);
    _savePreferences();
  }

  void updateBiometrics(bool enabled) {
    state = state.copyWith(enableBiometrics: enabled);
    _savePreferences();
  }

  void updateDefaultCategory(String category) {
    state = state.copyWith(defaultCategory: category);
    _savePreferences();
  }

  void updateAutoBackup(bool enabled) {
    state = state.copyWith(autoBackup: enabled);
    _savePreferences();
  }
}

// App Preferences Provider
final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>((ref) {
      return AppPreferencesNotifier();
    });

// App Version Provider
final appVersionProvider = Provider<String>((ref) {
  return AppConstants.appVersion;
});

// App Build Number Provider
final appBuildNumberProvider = Provider<String>((ref) {
  return AppConstants.buildNumber;
});

// Device Info Provider
final deviceInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Implementation would use device_info_plus package
  return {
    'platform': 'iOS', // or 'Android'
    'version': '15.0',
    'model': 'iPhone 12',
    'isPhysicalDevice': true,
  };
});

// Network Status Provider
final networkStatusProvider = Provider<bool>((ref) {
  return ref.watch(isOnlineProvider);
});

// App Lifecycle State Provider
final appLifecycleProvider = StreamProvider<AppLifecycleState>((ref) {
  return WidgetsBinding.instance.lifecycle?.asBroadcastStream() ??
      Stream.value(AppLifecycleState.resumed);
});
