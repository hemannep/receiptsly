// lib/core/config/environment.dart
import 'package:flutter/foundation.dart';

/// Environment enumeration for different deployment stages
enum Environment { development, staging, production }

/// Environment configuration and utilities for Receiptsly
/// Manages environment-specific settings and configurations
class EnvironmentConfig {
  static EnvironmentConfig? _instance;
  static EnvironmentConfig get instance =>
      _instance ??= EnvironmentConfig._internal();

  EnvironmentConfig._internal();

  // Current environment (defaults to development)
  Environment _currentEnvironment = Environment.development;

  // Environment-specific configurations
  static const Map<Environment, Map<String, dynamic>> _environmentConfigs = {
    Environment.development: {
      'name': 'Development',
      'apiBaseUrl': 'http://localhost:5001/receiptsly-dev/us-central1',
      'webAppUrl': 'http://localhost:3000',
      'enableLogging': true,
      'enableDebugMode': true,
      'enableMockData': true,
      'enableTestPayments': true,
      'logLevel': 'debug',
      'cacheTimeout': 5000, // 5 seconds for quick testing
      'enableHotReload': true,
      'enablePerformanceOverlay': true,
      'enableInspector': true,
      'enableAsserts': true,
      'enableServiceExtensions': true,
    },
    Environment.staging: {
      'name': 'Staging',
      'apiBaseUrl': 'https://staging-api.receiptsly.app',
      'webAppUrl': 'https://staging.receiptsly.app',
      'enableLogging': true,
      'enableDebugMode': false,
      'enableMockData': false,
      'enableTestPayments': true,
      'logLevel': 'info',
      'cacheTimeout': 300000, // 5 minutes
      'enableHotReload': false,
      'enablePerformanceOverlay': false,
      'enableInspector': false,
      'enableAsserts': true,
      'enableServiceExtensions': false,
    },
    Environment.production: {
      'name': 'Production',
      'apiBaseUrl': 'https://api.receiptsly.app',
      'webAppUrl': 'https://receiptsly.app',
      'enableLogging': false,
      'enableDebugMode': false,
      'enableMockData': false,
      'enableTestPayments': false,
      'logLevel': 'error',
      'cacheTimeout': 3600000, // 1 hour
      'enableHotReload': false,
      'enablePerformanceOverlay': false,
      'enableInspector': false,
      'enableAsserts': false,
      'enableServiceExtensions': false,
    },
  };

  // API endpoints for different environments
  static const Map<Environment, Map<String, String>> _apiEndpoints = {
    Environment.development: {
      'auth': '/auth',
      'users': '/users',
      'receipts': '/receipts',
      'invoices': '/invoices',
      'clients': '/clients',
      'ocr': '/ocr',
      'sync': '/sync',
      'exports': '/exports',
      'analytics': '/analytics',
      'payments': '/payments',
      'webhooks': '/webhooks',
    },
    Environment.staging: {
      'auth': '/v1/auth',
      'users': '/v1/users',
      'receipts': '/v1/receipts',
      'invoices': '/v1/invoices',
      'clients': '/v1/clients',
      'ocr': '/v1/ocr',
      'sync': '/v1/sync',
      'exports': '/v1/exports',
      'analytics': '/v1/analytics',
      'payments': '/v1/payments',
      'webhooks': '/v1/webhooks',
    },
    Environment.production: {
      'auth': '/v1/auth',
      'users': '/v1/users',
      'receipts': '/v1/receipts',
      'invoices': '/v1/invoices',
      'clients': '/v1/clients',
      'ocr': '/v1/ocr',
      'sync': '/v1/sync',
      'exports': '/v1/exports',
      'analytics': '/v1/analytics',
      'payments': '/v1/payments',
      'webhooks': '/v1/webhooks',
    },
  };

  // Database configurations for different environments
  static const Map<Environment, Map<String, dynamic>> _databaseConfigs = {
    Environment.development: {
      'name': 'receiptsly_dev.db',
      'version': 1,
      'enableWAL': true,
      'enableForeignKeys': true,
      'pageSize': 4096,
      'cacheSize': 2000,
      'busyTimeout': 30000,
      'enableAutoVacuum': true,
    },
    Environment.staging: {
      'name': 'receiptsly_staging.db',
      'version': 1,
      'enableWAL': true,
      'enableForeignKeys': true,
      'pageSize': 4096,
      'cacheSize': 5000,
      'busyTimeout': 30000,
      'enableAutoVacuum': true,
    },
    Environment.production: {
      'name': 'receiptsly.db',
      'version': 1,
      'enableWAL': true,
      'enableForeignKeys': true,
      'pageSize': 4096,
      'cacheSize': 10000,
      'busyTimeout': 30000,
      'enableAutoVacuum': true,
    },
  };

  // Security configurations for different environments
  static const Map<Environment, Map<String, dynamic>> _securityConfigs = {
    Environment.development: {
      'enableSSL': false,
      'enableCertificatePinning': false,
      'enableTokenEncryption': false,
      'enableBiometric': false,
      'sessionTimeout': 24 * 60 * 60 * 1000, // 24 hours for development
      'enableDebugCertificates': true,
      'allowSelfSignedCertificates': true,
    },
    Environment.staging: {
      'enableSSL': true,
      'enableCertificatePinning': false,
      'enableTokenEncryption': true,
      'enableBiometric': true,
      'sessionTimeout': 8 * 60 * 60 * 1000, // 8 hours
      'enableDebugCertificates': false,
      'allowSelfSignedCertificates': false,
    },
    Environment.production: {
      'enableSSL': true,
      'enableCertificatePinning': true,
      'enableTokenEncryption': true,
      'enableBiometric': true,
      'sessionTimeout': 4 * 60 * 60 * 1000, // 4 hours
      'enableDebugCertificates': false,
      'allowSelfSignedCertificates': false,
    },
  };

  // Feature flags for different environments
  static const Map<Environment, Map<String, bool>> _featureFlags = {
    Environment.development: {
      'enableOfflineMode': true,
      'enableChatBots': true,
      'enableAdvancedOCR': true,
      'enablePushNotifications': false, // Disabled for dev to avoid spam
      'enableAnalytics': false, // Disabled for dev
      'enableCrashlytics': false, // Disabled for dev
      'enableBetaFeatures': true,
      'enableExperimentalUI': true,
      'enableMockPayments': true,
      'enableDevTools': true,
      'enablePremiumFeatures': true,
      'enableDebugMode': true,
    },
    Environment.staging: {
      'enableOfflineMode': true,
      'enableChatBots': true,
      'enableAdvancedOCR': true,
      'enablePushNotifications': true,
      'enableAnalytics': true,
      'enableCrashlytics': true,
      'enableBetaFeatures': true,
      'enableExperimentalUI': false,
      'enableMockPayments': true,
      'enableDevTools': false,
      'enablePremiumFeatures': true,
      'enableDebugMode': false,
    },
    Environment.production: {
      'enableOfflineMode': true,
      'enableChatBots': true,
      'enableAdvancedOCR': true,
      'enablePushNotifications': true,
      'enableAnalytics': true,
      'enableCrashlytics': true,
      'enableBetaFeatures': false,
      'enableExperimentalUI': false,
      'enableMockPayments': false,
      'enableDevTools': false,
      'enablePremiumFeatures': true,
      'enableDebugMode': false,
    },
  };

  /// Initialize environment configuration
  void initialize(Environment environment) {
    _currentEnvironment = environment;

    if (kDebugMode) {
      print('🌍 Environment initialized: ${environment.name}');
      print('🔧 Configuration: ${getEnvironmentName()}');
      print('🌐 API Base URL: ${getApiBaseUrl()}');
      print('🏠 Web App URL: ${getWebAppUrl()}');
    }
  }

  /// Get current environment
  Environment get currentEnvironment => _currentEnvironment;

  /// Set current environment
  void setEnvironment(Environment environment) {
    _currentEnvironment = environment;

    if (kDebugMode) {
      print('🔄 Environment changed to: ${environment.name}');
    }
  }

  /// Auto-detect environment from build configuration
  Environment detectEnvironment() {
    // In a real app, you might detect this from:
    // - Build flavors
    // - Compilation flags
    // - Environment variables
    // - Package name suffixes

    if (kDebugMode) {
      return Environment.development;
    }

    // You can add more sophisticated detection logic here
    // For example, checking package name or build configuration

    return Environment.production;
  }

  // Environment configuration getters
  String getEnvironmentName() {
    return _environmentConfigs[_currentEnvironment]?['name'] ?? 'Unknown';
  }

  String getApiBaseUrl() {
    return _environmentConfigs[_currentEnvironment]?['apiBaseUrl'] ?? '';
  }

  String getWebAppUrl() {
    return _environmentConfigs[_currentEnvironment]?['webAppUrl'] ?? '';
  }

  bool isLoggingEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableLogging'] ?? false;
  }

  bool isDebugModeEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableDebugMode'] ??
        false;
  }

  bool isMockDataEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableMockData'] ?? false;
  }

  bool isTestPaymentsEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableTestPayments'] ??
        false;
  }

  String getLogLevel() {
    return _environmentConfigs[_currentEnvironment]?['logLevel'] ?? 'error';
  }

  int getCacheTimeout() {
    return _environmentConfigs[_currentEnvironment]?['cacheTimeout'] ?? 3600000;
  }

  bool isHotReloadEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableHotReload'] ??
        false;
  }

  bool isPerformanceOverlayEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enablePerformanceOverlay'] ??
        false;
  }

  bool isInspectorEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableInspector'] ??
        false;
  }

  bool areAssertsEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableAsserts'] ?? false;
  }

  bool areServiceExtensionsEnabled() {
    return _environmentConfigs[_currentEnvironment]?['enableServiceExtensions'] ??
        false;
  }

  // API endpoint getters
  String getApiEndpoint(String endpoint) {
    final endpoints = _apiEndpoints[_currentEnvironment] ?? {};
    return endpoints[endpoint] ?? '';
  }

  String getFullApiUrl(String endpoint) {
    return '${getApiBaseUrl()}${getApiEndpoint(endpoint)}';
  }

  Map<String, String> getAllApiEndpoints() {
    return Map<String, String>.from(_apiEndpoints[_currentEnvironment] ?? {});
  }

  // Database configuration getters
  String getDatabaseName() {
    return _databaseConfigs[_currentEnvironment]?['name'] ?? 'receiptsly.db';
  }

  int getDatabaseVersion() {
    return _databaseConfigs[_currentEnvironment]?['version'] ?? 1;
  }

  bool isDatabaseWALEnabled() {
    return _databaseConfigs[_currentEnvironment]?['enableWAL'] ?? true;
  }

  bool areForeignKeysEnabled() {
    return _databaseConfigs[_currentEnvironment]?['enableForeignKeys'] ?? true;
  }

  int getDatabasePageSize() {
    return _databaseConfigs[_currentEnvironment]?['pageSize'] ?? 4096;
  }

  int getDatabaseCacheSize() {
    return _databaseConfigs[_currentEnvironment]?['cacheSize'] ?? 5000;
  }

  int getDatabaseBusyTimeout() {
    return _databaseConfigs[_currentEnvironment]?['busyTimeout'] ?? 30000;
  }

  bool isDatabaseAutoVacuumEnabled() {
    return _databaseConfigs[_currentEnvironment]?['enableAutoVacuum'] ?? true;
  }

  Map<String, dynamic> getDatabaseConfig() {
    return Map<String, dynamic>.from(
      _databaseConfigs[_currentEnvironment] ?? {},
    );
  }

  // Security configuration getters
  bool isSSLEnabled() {
    return _securityConfigs[_currentEnvironment]?['enableSSL'] ?? true;
  }

  bool isCertificatePinningEnabled() {
    return _securityConfigs[_currentEnvironment]?['enableCertificatePinning'] ??
        false;
  }

  bool isTokenEncryptionEnabled() {
    return _securityConfigs[_currentEnvironment]?['enableTokenEncryption'] ??
        true;
  }

  bool isBiometricEnabled() {
    return _securityConfigs[_currentEnvironment]?['enableBiometric'] ?? true;
  }

  int getSessionTimeout() {
    return _securityConfigs[_currentEnvironment]?['sessionTimeout'] ??
        4 * 60 * 60 * 1000;
  }

  bool areDebugCertificatesEnabled() {
    return _securityConfigs[_currentEnvironment]?['enableDebugCertificates'] ??
        false;
  }

  bool areSelfSignedCertificatesAllowed() {
    return _securityConfigs[_currentEnvironment]?['allowSelfSignedCertificates'] ??
        false;
  }

  Map<String, dynamic> getSecurityConfig() {
    return Map<String, dynamic>.from(
      _securityConfigs[_currentEnvironment] ?? {},
    );
  }

  // Feature flag getters
  bool isFeatureEnabled(String feature) {
    return _featureFlags[_currentEnvironment]?[feature] ?? false;
  }

  bool isOfflineModeEnabled() {
    return isFeatureEnabled('enableOfflineMode');
  }

  bool areChatBotsEnabled() {
    return isFeatureEnabled('enableChatBots');
  }

  bool isAdvancedOCREnabled() {
    return isFeatureEnabled('enableAdvancedOCR');
  }

  bool arePushNotificationsEnabled() {
    return isFeatureEnabled('enablePushNotifications');
  }

  bool isAnalyticsEnabled() {
    return isFeatureEnabled('enableAnalytics');
  }

  bool isCrashlyticsEnabled() {
    return isFeatureEnabled('enableCrashlytics');
  }

  bool areBetaFeaturesEnabled() {
    return isFeatureEnabled('enableBetaFeatures');
  }

  bool isExperimentalUIEnabled() {
    return isFeatureEnabled('enableExperimentalUI');
  }

  bool areMockPaymentsEnabled() {
    return isFeatureEnabled('enableMockPayments');
  }

  bool areDevToolsEnabled() {
    return isFeatureEnabled('enableDevTools');
  }

  bool arePremiumFeaturesEnabled() {
    return isFeatureEnabled('enablePremiumFeatures');
  }

  Map<String, bool> getAllFeatureFlags() {
    return Map<String, bool>.from(_featureFlags[_currentEnvironment] ?? {});
  }

  // Environment checks
  bool get isDevelopment => _currentEnvironment == Environment.development;
  bool get isStaging => _currentEnvironment == Environment.staging;
  bool get isProduction => _currentEnvironment == Environment.production;

  bool get isDebugEnvironment => isDevelopment || isStaging;
  bool get isReleaseEnvironment => isProduction;

  // Utility methods
  T getEnvironmentValue<T>(T development, T staging, T production) {
    switch (_currentEnvironment) {
      case Environment.development:
        return development;
      case Environment.staging:
        return staging;
      case Environment.production:
        return production;
    }
  }

  /// Get configuration value by key
  T? getConfigValue<T>(String key) {
    return _environmentConfigs[_currentEnvironment]?[key] as T?;
  }

  /// Get all environment configuration
  Map<String, dynamic> getAllConfig() {
    return Map<String, dynamic>.from(
      _environmentConfigs[_currentEnvironment] ?? {},
    );
  }

  /// Check if current environment supports a specific feature
  bool supportsFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'hot_reload':
        return isDevelopment;
      case 'debug_tools':
        return isDevelopment || isStaging;
      case 'performance_monitoring':
        return isStaging || isProduction;
      case 'crash_reporting':
        return isStaging || isProduction;
      case 'analytics':
        return isStaging || isProduction;
      case 'push_notifications':
        return isStaging || isProduction;
      default:
        return isFeatureEnabled(
          'enable${feature.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join('')}',
        );
    }
  }

  /// Get environment-specific timeout values
  Duration getTimeout(String type) {
    switch (type.toLowerCase()) {
      case 'api':
        return Duration(milliseconds: getEnvironmentValue(5000, 15000, 30000));
      case 'cache':
        return Duration(milliseconds: getCacheTimeout());
      case 'session':
        return Duration(milliseconds: getSessionTimeout());
      case 'sync':
        return Duration(milliseconds: getEnvironmentValue(10000, 30000, 60000));
      default:
        return const Duration(seconds: 30);
    }
  }

  /// Get environment-specific retry configurations
  Map<String, int> getRetryConfig() {
    return getEnvironmentValue(
      // Development
      {
        'maxRetries': 2,
        'initialDelay': 1000,
        'maxDelay': 5000,
        'backoffMultiplier': 2,
      },
      // Staging
      {
        'maxRetries': 3,
        'initialDelay': 1000,
        'maxDelay': 10000,
        'backoffMultiplier': 2,
      },
      // Production
      {
        'maxRetries': 5,
        'initialDelay': 1000,
        'maxDelay': 30000,
        'backoffMultiplier': 2,
      },
    );
  }

  /// Get environment-specific logging configuration
  Map<String, dynamic> getLoggingConfig() {
    return {
      'enabled': isLoggingEnabled(),
      'level': getLogLevel(),
      'enableConsole': isDevelopment,
      'enableFile': isStaging || isProduction,
      'enableRemote': isProduction,
      'maxFileSize': getEnvironmentValue(
        10 * 1024 * 1024,
        50 * 1024 * 1024,
        100 * 1024 * 1024,
      ), // 10MB, 50MB, 100MB
      'maxFiles': getEnvironmentValue(3, 5, 10),
    };
  }

  /// Get environment-specific cache configuration
  Map<String, dynamic> getCacheConfig() {
    return {
      'maxSize': getEnvironmentValue(
        50 * 1024 * 1024,
        100 * 1024 * 1024,
        200 * 1024 * 1024,
      ), // 50MB, 100MB, 200MB
      'defaultTTL': getCacheTimeout(),
      'enablePersistence': true,
      'enableCompression': isProduction,
      'enableEncryption': isTokenEncryptionEnabled(),
    };
  }

  /// Get environment-specific network configuration
  Map<String, dynamic> getNetworkConfig() {
    return {
      'connectTimeout': getTimeout('api').inMilliseconds,
      'receiveTimeout': getTimeout('api').inMilliseconds,
      'sendTimeout': getTimeout('api').inMilliseconds,
      'enableSSL': isSSLEnabled(),
      'enableCertificatePinning': isCertificatePinningEnabled(),
      'allowSelfSignedCertificates': areSelfSignedCertificatesAllowed(),
      'enableRetry': true,
      'maxRetries': getRetryConfig()['maxRetries'],
      'retryDelay': getRetryConfig()['initialDelay'],
    };
  }

  /// Validate environment configuration
  bool validateConfiguration() {
    try {
      // Check if all required configurations are present
      final config = _environmentConfigs[_currentEnvironment];
      if (config == null) return false;

      // Validate required fields
      final requiredFields = ['name', 'apiBaseUrl', 'webAppUrl'];
      for (final field in requiredFields) {
        if (!config.containsKey(field) ||
            config[field] == null ||
            config[field].toString().isEmpty) {
          if (kDebugMode) {
            print('❌ Missing required configuration field: $field');
          }
          return false;
        }
      }

      // Validate API endpoints
      final endpoints = _apiEndpoints[_currentEnvironment];
      if (endpoints == null || endpoints.isEmpty) {
        if (kDebugMode) {
          print('❌ Missing API endpoints configuration');
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ Environment configuration validation passed');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Environment configuration validation failed: $e');
      }
      return false;
    }
  }

  /// Get debug information about current environment
  Map<String, dynamic> getDebugInfo() {
    return {
      'environment': _currentEnvironment.name,
      'environmentName': getEnvironmentName(),
      'apiBaseUrl': getApiBaseUrl(),
      'webAppUrl': getWebAppUrl(),
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'isProduction': isProduction,
      'isDebugMode': isDebugModeEnabled(),
      'isLoggingEnabled': isLoggingEnabled(),
      'featureFlags': getAllFeatureFlags(),
      'databaseConfig': getDatabaseConfig(),
      'securityConfig': getSecurityConfig(),
      'networkConfig': getNetworkConfig(),
      'cacheConfig': getCacheConfig(),
      'loggingConfig': getLoggingConfig(),
    };
  }

  @override
  String toString() {
    return 'EnvironmentConfig(environment: ${_currentEnvironment.name}, name: ${getEnvironmentName()})';
  }
}
