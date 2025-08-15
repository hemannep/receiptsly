// lib/core/config/app_config.dart
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'environment.dart';

/// Central configuration class for the Receiptsly app
/// Manages app-wide settings, feature flags, and environment-specific configurations
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._internal();

  AppConfig._internal();

  // App Information
  late PackageInfo _packageInfo;

  // Environment
  Environment _environment = Environment.development;
  late EnvironmentConfig _environmentConfig;

  // Feature Flags
  static const Map<String, bool> _featureFlags = {
    'enableOfflineMode': true,
    'enableChatBots': true,
    'enableAdvancedOCR': true,
    'enablePushNotifications': true,
    'enableAnalytics': true,
    'enableCrashlytics': true,
    'enablePremiumFeatures': true,
    'enableExperimentalUI': false,
    'enableBetaFeatures': false,
    'enableDebugMode': kDebugMode,
  };

  // API Configuration
  static const Map<String, int> _apiConfig = {
    'connectTimeout': 30000, // 30 seconds
    'receiveTimeout': 30000, // 30 seconds
    'sendTimeout': 30000, // 30 seconds
    'maxRetries': 3,
    'retryDelay': 1000, // 1 second
  };

  // Cache Configuration
  static const Map<String, dynamic> _cacheConfig = {
    'maxCacheSize': 100 * 1024 * 1024, // 100MB
    'defaultCacheDuration': 24 * 60 * 60 * 1000, // 24 hours in milliseconds
    'imageCacheDuration': 7 * 24 * 60 * 60 * 1000, // 7 days
    'apiCacheDuration': 5 * 60 * 1000, // 5 minutes
  };

  // Sync Configuration
  static const Map<String, dynamic> _syncConfig = {
    'autoSyncInterval': 15 * 60 * 1000, // 15 minutes
    'batchSize': 50,
    'maxSyncRetries': 5,
    'conflictResolutionStrategy': 'lastWriteWins', // 'lastWriteWins' | 'manual'
    'enableBackgroundSync': true,
  };

  // File Upload Configuration
  static const Map<String, dynamic> _uploadConfig = {
    'maxFileSize': 10 * 1024 * 1024, // 10MB
    'allowedImageTypes': ['jpg', 'jpeg', 'png', 'webp'],
    'allowedDocumentTypes': ['pdf', 'doc', 'docx'],
    'compressionQuality': 0.8,
    'maxImageResolution': 2048,
  };

  // OCR Configuration
  static const Map<String, dynamic> _ocrConfig = {
    'confidenceThreshold': 0.7,
    'maxRetries': 2,
    'enableCloudOCR': true,
    'enableOnDeviceOCR': true,
    'fallbackToCloud': true,
    'supportedLanguages': ['en', 'es', 'fr', 'de', 'it'],
  };

  // Subscription Limits
  static const Map<String, Map<String, dynamic>> _subscriptionLimits = {
    'free': {
      'maxReceipts': 50,
      'maxInvoices': 10,
      'maxClients': 5,
      'maxStorageGB': 1,
      'exportFormats': ['pdf'],
      'advancedFeatures': false,
    },
    'basic': {
      'maxReceipts': 500,
      'maxInvoices': 100,
      'maxClients': 25,
      'maxStorageGB': 5,
      'exportFormats': ['pdf', 'csv', 'excel'],
      'advancedFeatures': true,
    },
    'premium': {
      'maxReceipts': -1, // unlimited
      'maxInvoices': -1, // unlimited
      'maxClients': -1, // unlimited
      'maxStorageGB': 50,
      'exportFormats': ['pdf', 'csv', 'excel', 'json'],
      'advancedFeatures': true,
    },
  };

  // Security Configuration
  static const Map<String, dynamic> _securityConfig = {
    'enableBiometric': true,
    'sessionTimeout': 30 * 60 * 1000, // 30 minutes
    'maxLoginAttempts': 5,
    'lockoutDuration': 15 * 60 * 1000, // 15 minutes
    'enableEncryption': true,
    'encryptionAlgorithm': 'AES-256',
  };

  /// Initialize the app configuration
  Future<void> initialize({Environment? environment}) async {
    // Set environment first
    if (environment != null) {
      _environment = environment;
    } else {
      // Auto-detect environment
      _environment = _detectEnvironment();
    }

    // Initialize environment config
    _environmentConfig = EnvironmentConfig.instance;
    _environmentConfig.initialize(_environment);

    // Initialize package info
    _packageInfo = await PackageInfo.fromPlatform();

    // Log initialization in debug mode
    if (kDebugMode) {
      print('🚀 AppConfig initialized');
      print('📱 App: ${_packageInfo.appName} v${_packageInfo.version}');
      print('🌍 Environment: ${_environment.name}');
      print('🏗️ Build: ${_packageInfo.buildNumber}');
      print('🌐 API Base URL: ${apiBaseUrl}');
    }
  }

  /// Auto-detect environment from build configuration
  Environment _detectEnvironment() {
    if (kDebugMode) {
      return Environment.development;
    }

    // Check package name for environment detection
    // This is a placeholder - implement based on your build configuration
    const packageName = String.fromEnvironment(
      'PACKAGE_NAME',
      defaultValue: '',
    );

    if (packageName.contains('.dev')) {
      return Environment.development;
    } else if (packageName.contains('.staging')) {
      return Environment.staging;
    }

    return Environment.production;
  }

  // Getters for app information
  String get appName => _packageInfo.appName;
  String get appVersion => _packageInfo.version;
  String get buildNumber => _packageInfo.buildNumber;
  String get packageName => _packageInfo.packageName;
  Environment get environment => _environment;

  // Environment-based getters that delegate to EnvironmentConfig
  String get apiBaseUrl => _environmentConfig.getApiBaseUrl();
  String get webAppUrl => _environmentConfig.getWebAppUrl();
  String get environmentName => _environmentConfig.getEnvironmentName();

  // Feature flag getters (combines local and environment flags)
  bool isFeatureEnabled(String feature) {
    // Check environment-specific flags first, then fall back to local flags
    return _environmentConfig.isFeatureEnabled(feature) ||
        (_featureFlags[feature] ?? false);
  }

  bool get isOfflineModeEnabled => isFeatureEnabled('enableOfflineMode');
  bool get isChatBotsEnabled => isFeatureEnabled('enableChatBots');
  bool get isAdvancedOCREnabled => isFeatureEnabled('enableAdvancedOCR');
  bool get isPushNotificationsEnabled =>
      isFeatureEnabled('enablePushNotifications');
  bool get isAnalyticsEnabled => isFeatureEnabled('enableAnalytics');
  bool get isCrashlyticsEnabled => isFeatureEnabled('enableCrashlytics');
  bool get isPremiumFeaturesEnabled =>
      isFeatureEnabled('enablePremiumFeatures');
  bool get isExperimentalUIEnabled => isFeatureEnabled('enableExperimentalUI');
  bool get isBetaFeaturesEnabled => isFeatureEnabled('enableBetaFeatures');
  bool get isDebugModeEnabled => isFeatureEnabled('enableDebugMode');

  // API configuration getters
  int get connectTimeout => _apiConfig['connectTimeout']!;
  int get receiveTimeout => _apiConfig['receiveTimeout']!;
  int get sendTimeout => _apiConfig['sendTimeout']!;
  int get maxRetries => _apiConfig['maxRetries']!;
  int get retryDelay => _apiConfig['retryDelay']!;

  // Cache configuration getters
  int get maxCacheSize => _cacheConfig['maxCacheSize']!;
  int get defaultCacheDuration => _cacheConfig['defaultCacheDuration']!;
  int get imageCacheDuration => _cacheConfig['imageCacheDuration']!;
  int get apiCacheDuration => _cacheConfig['apiCacheDuration']!;

  // Sync configuration getters
  int get autoSyncInterval => _syncConfig['autoSyncInterval']!;
  int get syncBatchSize => _syncConfig['batchSize']!;
  int get maxSyncRetries => _syncConfig['maxSyncRetries']!;
  String get conflictResolutionStrategy =>
      _syncConfig['conflictResolutionStrategy']!;
  bool get isBackgroundSyncEnabled => _syncConfig['enableBackgroundSync']!;

  // File upload configuration getters
  int get maxFileSize => _uploadConfig['maxFileSize']!;
  List<String> get allowedImageTypes =>
      List<String>.from(_uploadConfig['allowedImageTypes']!);
  List<String> get allowedDocumentTypes =>
      List<String>.from(_uploadConfig['allowedDocumentTypes']!);
  double get compressionQuality => _uploadConfig['compressionQuality']!;
  int get maxImageResolution => _uploadConfig['maxImageResolution']!;

  // OCR configuration getters
  double get ocrConfidenceThreshold => _ocrConfig['confidenceThreshold']!;
  int get ocrMaxRetries => _ocrConfig['maxRetries']!;
  bool get isCloudOCREnabled => _ocrConfig['enableCloudOCR']!;
  bool get isOnDeviceOCREnabled => _ocrConfig['enableOnDeviceOCR']!;
  bool get shouldFallbackToCloud => _ocrConfig['fallbackToCloud']!;
  List<String> get supportedOCRLanguages =>
      List<String>.from(_ocrConfig['supportedLanguages']!);

  // Security configuration getters
  bool get isBiometricEnabled => _securityConfig['enableBiometric']!;
  int get sessionTimeout => _securityConfig['sessionTimeout']!;
  int get maxLoginAttempts => _securityConfig['maxLoginAttempts']!;
  int get lockoutDuration => _securityConfig['lockoutDuration']!;
  bool get isEncryptionEnabled => _securityConfig['enableEncryption']!;
  String get encryptionAlgorithm => _securityConfig['encryptionAlgorithm']!;

  // Subscription limit getters
  Map<String, dynamic> getSubscriptionLimits(String plan) {
    return Map<String, dynamic>.from(
      _subscriptionLimits[plan] ?? _subscriptionLimits['free']!,
    );
  }

  int getMaxReceipts(String plan) =>
      getSubscriptionLimits(plan)['maxReceipts'] ?? 50;
  int getMaxInvoices(String plan) =>
      getSubscriptionLimits(plan)['maxInvoices'] ?? 10;
  int getMaxClients(String plan) =>
      getSubscriptionLimits(plan)['maxClients'] ?? 5;
  int getMaxStorageGB(String plan) =>
      getSubscriptionLimits(plan)['maxStorageGB'] ?? 1;

  List<String> getExportFormats(String plan) => List<String>.from(
    getSubscriptionLimits(plan)['exportFormats'] ?? ['pdf'],
  );

  bool hasAdvancedFeatures(String plan) =>
      getSubscriptionLimits(plan)['advancedFeatures'] ?? false;

  // Environment checks (delegate to EnvironmentConfig)
  bool get isProduction => _environmentConfig.isProduction;
  bool get isDevelopment => _environmentConfig.isDevelopment;
  bool get isStaging => _environmentConfig.isStaging;

  /// Get formatted app version string
  String get formattedVersion => '${appVersion}+${buildNumber}';

  /// Get environment-specific configuration
  T getEnvironmentConfig<T>(T dev, T staging, T prod) {
    return _environmentConfig.getEnvironmentValue<T>(dev, staging, prod);
  }

  /// Check if a file extension is allowed for upload
  bool isFileTypeAllowed(String extension, {bool isImage = true}) {
    final allowedTypes = isImage ? allowedImageTypes : allowedDocumentTypes;
    return allowedTypes.contains(extension.toLowerCase());
  }

  /// Check if file size is within limits
  bool isFileSizeValid(int sizeInBytes) {
    return sizeInBytes <= maxFileSize;
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get user-friendly environment name
  String get environmentDisplayName {
    switch (_environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Get API endpoint URL
  String getApiEndpoint(String endpoint) {
    return _environmentConfig.getFullApiUrl(endpoint);
  }

  /// Get all API endpoints
  Map<String, String> getAllApiEndpoints() {
    return _environmentConfig.getAllApiEndpoints();
  }

  /// Get database configuration
  Map<String, dynamic> getDatabaseConfig() {
    return _environmentConfig.getDatabaseConfig();
  }

  /// Get security configuration
  Map<String, dynamic> getSecurityConfig() {
    return _environmentConfig.getSecurityConfig();
  }

  /// Get network configuration
  Map<String, dynamic> getNetworkConfig() {
    return _environmentConfig.getNetworkConfig();
  }

  /// Get cache configuration
  Map<String, dynamic> getCacheConfiguration() {
    return _environmentConfig.getCacheConfig();
  }

  /// Get logging configuration
  Map<String, dynamic> getLoggingConfig() {
    return _environmentConfig.getLoggingConfig();
  }

  /// Get retry configuration
  Map<String, int> getRetryConfig() {
    return _environmentConfig.getRetryConfig();
  }

  /// Get timeout for specific operation
  Duration getTimeout(String type) {
    return _environmentConfig.getTimeout(type);
  }

  /// Check if feature is supported in current environment
  bool supportsFeature(String feature) {
    return _environmentConfig.supportsFeature(feature);
  }

  /// Validate current configuration
  bool validateConfiguration() {
    return _environmentConfig.validateConfiguration();
  }

  /// Get all feature flags (combines local and environment flags)
  Map<String, bool> getAllFeatureFlags() {
    final envFlags = _environmentConfig.getAllFeatureFlags();
    final combinedFlags = Map<String, bool>.from(_featureFlags);

    // Environment flags override local flags
    combinedFlags.addAll(envFlags);

    return combinedFlags;
  }

  /// Check if app should use mock data
  bool get shouldUseMockData => _environmentConfig.isMockDataEnabled();

  /// Check if test payments are enabled
  bool get shouldUseTestPayments => _environmentConfig.isTestPaymentsEnabled();

  /// Check if logging is enabled
  bool get shouldEnableLogging => _environmentConfig.isLoggingEnabled();

  /// Get log level
  String get logLevel => _environmentConfig.getLogLevel();

  /// Debug information for troubleshooting
  Map<String, dynamic> get debugInfo => {
    'appName': appName,
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'packageName': packageName,
    'environment': environmentName,
    'isDebugMode': isDebugModeEnabled,
    'featureFlags': getAllFeatureFlags(),
    'platform': defaultTargetPlatform.name,
    'apiBaseUrl': apiBaseUrl,
    'webAppUrl': webAppUrl,
    'databaseConfig': getDatabaseConfig(),
    'securityConfig': getSecurityConfig(),
    'networkConfig': getNetworkConfig(),
    'cacheConfig': getCacheConfiguration(),
    'loggingConfig': getLoggingConfig(),
    'environmentConfig': _environmentConfig.getDebugInfo(),
  };

  get certificateFingerprints => null;

  /// Reset configuration to defaults (useful for testing)
  void reset() {
    _environment = Environment.development;
    _environmentConfig.initialize(_environment);

    if (kDebugMode) {
      print('🔄 AppConfig reset to defaults');
    }
  }

  /// Update environment and reinitialize
  Future<void> updateEnvironment(Environment newEnvironment) async {
    if (_environment != newEnvironment) {
      _environment = newEnvironment;
      _environmentConfig.initialize(_environment);

      if (kDebugMode) {
        print('🔄 Environment updated to: ${newEnvironment.name}');
        print('🌐 New API Base URL: ${apiBaseUrl}');
      }
    }
  }

  /// Get environment-specific Firebase options
  Map<String, dynamic> getFirebaseOptions() {
    // This would typically return environment-specific Firebase configuration
    // For now, returning a placeholder structure
    return getEnvironmentConfig(
      // Development
      {
        'apiKey': 'dev-api-key',
        'authDomain': 'receiptsly-dev.firebaseapp.com',
        'projectId': 'receiptsly-dev',
        'storageBucket': 'receiptsly-dev.appspot.com',
        'messagingSenderId': '123456789',
        'appId': '1:123456789:web:abc123',
        'measurementId': 'G-DEV123',
      },
      // Staging
      {
        'apiKey': 'staging-api-key',
        'authDomain': 'receiptsly-staging.firebaseapp.com',
        'projectId': 'receiptsly-staging',
        'storageBucket': 'receiptsly-staging.appspot.com',
        'messagingSenderId': '987654321',
        'appId': '1:987654321:web:def456',
        'measurementId': 'G-STAGING456',
      },
      // Production
      {
        'apiKey': 'prod-api-key',
        'authDomain': 'receiptsly.firebaseapp.com',
        'projectId': 'receiptsly-prod',
        'storageBucket': 'receiptsly.appspot.com',
        'messagingSenderId': '555555555',
        'appId': '1:555555555:web:ghi789',
        'measurementId': 'G-PROD789',
      },
    );
  }

  /// Get environment-specific app constants
  Map<String, dynamic> getAppConstants() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'environment': environmentName,
      'minSupportedVersion': getEnvironmentConfig('1.0.0', '1.0.0', '1.0.0'),
      'forceUpdateVersion': getEnvironmentConfig('0.9.0', '0.9.0', '0.9.0'),
      'supportEmail': 'support@receiptsly.app',
      'privacyPolicyUrl': '${webAppUrl}/privacy',
      'termsOfServiceUrl': '${webAppUrl}/terms',
      'helpUrl': '${webAppUrl}/help',
      'feedbackUrl': '${webAppUrl}/feedback',
    };
  }

  /// Check if app version is supported
  bool isVersionSupported(String currentVersion) {
    final constants = getAppConstants();
    final minVersion = constants['minSupportedVersion'] as String;

    // Simple version comparison - in production, use a proper version comparison library
    return _compareVersions(currentVersion, minVersion) >= 0;
  }

  /// Check if force update is required
  bool isForceUpdateRequired(String currentVersion) {
    final constants = getAppConstants();
    final forceUpdateVersion = constants['forceUpdateVersion'] as String;

    return _compareVersions(currentVersion, forceUpdateVersion) < 0;
  }

  /// Simple version comparison (replace with proper library in production)
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    final maxLength = [
      v1Parts.length,
      v2Parts.length,
    ].reduce((a, b) => a > b ? a : b);

    // Pad shorter version with zeros
    while (v1Parts.length < maxLength) v1Parts.add(0);
    while (v2Parts.length < maxLength) v2Parts.add(0);

    for (int i = 0; i < maxLength; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }

    return 0;
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    if (kDebugMode) {
      print('🧹 AppConfig disposed');
    }
  }

  @override
  String toString() {
    return 'AppConfig(environment: $environmentName, version: $formattedVersion)';
  }
}
