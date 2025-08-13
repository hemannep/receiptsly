// lib/core/constants/storage_keys.dart

/// Storage key constants for Receiptsly
/// Contains all keys used for local storage, secure storage, and shared preferences
class StorageKeys {
  // Private constructor to prevent instantiation
  StorageKeys._();

  /// ==================== SHARED PREFERENCES KEYS ====================

  /// User Session & Authentication
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String isLoggedIn = 'is_logged_in';
  static const String lastLoginTime = 'last_login_time';
  static const String loginAttempts = 'login_attempts';
  static const String accountLockoutTime = 'account_lockout_time';
  static const String biometricEnabled = 'biometric_enabled';
  static const String pinEnabled = 'pin_enabled';
  static const String autoLoginEnabled = 'auto_login_enabled';

  /// User Profile Data
  static const String userProfile = 'user_profile';
  static const String userName = 'user_name';
  static const String businessName = 'business_name';
  static const String businessType = 'business_type';
  static const String userCountry = 'user_country';
  static const String userCurrency = 'user_currency';
  static const String userAvatar = 'user_avatar';
  static const String userPhone = 'user_phone';
  static const String phoneVerified = 'phone_verified';
  static const String emailVerified = 'email_verified';

  /// App Settings & Preferences
  static const String appTheme = 'app_theme';
  static const String isDarkMode = 'is_dark_mode';
  static const String selectedLanguage = 'selected_language';
  static const String defaultCurrency = 'default_currency';
  static const String dateFormat = 'date_format';
  static const String timeFormat = 'time_format';
  static const String firstTimeUser = 'first_time_user';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String appVersion = 'app_version';
  static const String lastAppUpdate = 'last_app_update';

  /// Notification Settings
  static const String pushNotificationsEnabled = 'push_notifications_enabled';
  static const String emailNotificationsEnabled = 'email_notifications_enabled';
  static const String receiptProcessedNotifications =
      'receipt_processed_notifications';
  static const String invoiceReminderNotifications =
      'invoice_reminder_notifications';
  static const String syncNotifications = 'sync_notifications';
  static const String marketingNotifications = 'marketing_notifications';
  static const String fcmToken = 'fcm_token';
  static const String notificationPermissionRequested =
      'notification_permission_requested';

  /// Sync & Offline Settings
  static const String autoSyncEnabled = 'auto_sync_enabled';
  static const String syncInterval = 'sync_interval';
  static const String lastSyncTime = 'last_sync_time';
  static const String offlineModeEnabled = 'offline_mode_enabled';
  static const String syncOnWifiOnly = 'sync_on_wifi_only';
  static const String backgroundSyncEnabled = 'background_sync_enabled';
  static const String syncConflictResolution = 'sync_conflict_resolution';

  /// Camera & OCR Settings
  static const String cameraPermissionGranted = 'camera_permission_granted';
  static const String autoFlashEnabled = 'auto_flash_enabled';
  static const String imageQuality = 'image_quality';
  static const String autoOcrProcessing = 'auto_ocr_processing';
  static const String ocrConfidenceThreshold = 'ocr_confidence_threshold';
  static const String manualReviewRequired = 'manual_review_required';

  /// Receipt Settings
  static const String defaultReceiptCategory = 'default_receipt_category';
  static const String autoCategorizationEnabled = 'auto_categorization_enabled';
  static const String receiptRetentionPeriod = 'receipt_retention_period';
  static const String duplicateDetectionEnabled = 'duplicate_detection_enabled';
  static const String receiptNumbering = 'receipt_numbering';

  /// Invoice Settings
  static const String defaultInvoiceTemplate = 'default_invoice_template';
  static const String invoiceNumberPrefix = 'invoice_number_prefix';
  static const String nextInvoiceNumber = 'next_invoice_number';
  static const String defaultPaymentTerms = 'default_payment_terms';
  static const String defaultTaxRate = 'default_tax_rate';
  static const String autoSendInvoices = 'auto_send_invoices';
  static const String invoiceReminderDays = 'invoice_reminder_days';

  /// Integration Settings
  static const String whatsappConnected = 'whatsapp_connected';
  static const String telegramConnected = 'telegram_connected';
  static const String whatsappPhoneNumber = 'whatsapp_phone_number';
  static const String telegramUsername = 'telegram_username';
  static const String chatBotEnabled = 'chat_bot_enabled';
  static const String autoProcessChatReceipts = 'auto_process_chat_receipts';

  /// Subscription & Billing
  static const String subscriptionPlan = 'subscription_plan';
  static const String subscriptionStatus = 'subscription_status';
  static const String subscriptionExpiry = 'subscription_expiry';
  static const String monthlyReceiptCount = 'monthly_receipt_count';
  static const String monthlyInvoiceCount = 'monthly_invoice_count';
  static const String lastBillingDate = 'last_billing_date';
  static const String paymentMethodId = 'payment_method_id';

  /// Analytics & Performance
  static const String analyticsEnabled = 'analytics_enabled';
  static const String crashReportingEnabled = 'crash_reporting_enabled';
  static const String performanceMonitoringEnabled =
      'performance_monitoring_enabled';
  static const String usageStatsEnabled = 'usage_stats_enabled';

  /// Feature Flags
  static const String betaFeaturesEnabled = 'beta_features_enabled';
  static const String advancedReportsEnabled = 'advanced_reports_enabled';
  static const String bulkUploadEnabled = 'bulk_upload_enabled';
  static const String exportFeaturesEnabled = 'export_features_enabled';

  /// Debug & Development
  static const String debugModeEnabled = 'debug_mode_enabled';
  static const String verboseLoggingEnabled = 'verbose_logging_enabled';
  static const String networkLoggingEnabled = 'network_logging_enabled';
  static const String developmentEnvironment = 'development_environment';

  /// ==================== SECURE STORAGE KEYS ====================

  /// Sensitive Authentication Data
  static const String secureAccessToken = 'secure_access_token';
  static const String secureRefreshToken = 'secure_refresh_token';
  static const String biometricKey = 'biometric_key';
  static const String pinCode = 'pin_code';
  static const String encryptionKey = 'encryption_key';
  static const String deviceId = 'device_id';

  /// API Keys & Secrets
  static const String stripePublishableKey = 'stripe_publishable_key';
  static const String firebaseApiKey = 'firebase_api_key';
  static const String visionApiKey = 'vision_api_key';
  static const String whatsappApiKey = 'whatsapp_api_key';
  static const String telegramBotToken = 'telegram_bot_token';

  /// Payment Information
  static const String lastFourCardDigits = 'last_four_card_digits';
  static const String cardBrand = 'card_brand';
  static const String billingAddress = 'billing_address';
  static const String customerId = 'customer_id';

  /// Backup & Recovery
  static const String backupEncryptionKey = 'backup_encryption_key';
  static const String recoveryCode = 'recovery_code';
  static const String backupMetadata = 'backup_metadata';

  /// ==================== LOCAL DATABASE KEYS ====================

  /// SQLite Table Names
  static const String receiptsTable = 'receipts';
  static const String invoicesTable = 'invoices';
  static const String clientsTable = 'clients';
  static const String categoriesTable = 'categories';
  static const String syncQueueTable = 'sync_queue';
  static const String conflictsTable = 'conflicts';
  static const String cacheTable = 'cache';
  static const String settingsTable = 'settings';
  static const String logsTable = 'logs';

  /// Cache Keys
  static const String userDataCache = 'user_data_cache';
  static const String receiptsCache = 'receipts_cache';
  static const String invoicesCache = 'invoices_cache';
  static const String clientsCache = 'clients_cache';
  static const String categoriesCache = 'categories_cache';
  static const String reportsCache = 'reports_cache';
  static const String templatesCache = 'templates_cache';
  static const String imageCache = 'image_cache';

  /// Sync Queue Keys
  static const String pendingReceiptUploads = 'pending_receipt_uploads';
  static const String pendingInvoiceSends = 'pending_invoice_sends';
  static const String pendingProfileUpdates = 'pending_profile_updates';
  static const String pendingCategoryChanges = 'pending_category_changes';
  static const String pendingClientUpdates = 'pending_client_updates';

  /// ==================== TEMPORARY STORAGE KEYS ====================

  /// Session Data
  static const String currentSession = 'current_session';
  static const String sessionStartTime = 'session_start_time';
  static const String lastActivityTime = 'last_activity_time';
  static const String sessionToken = 'session_token';

  /// Temporary Form Data
  static const String draftReceipt = 'draft_receipt';
  static const String draftInvoice = 'draft_invoice';
  static const String draftClient = 'draft_client';
  static const String tempImagePath = 'temp_image_path';
  static const String ocrTempResult = 'ocr_temp_result';

  /// Upload Progress
  static const String uploadProgress = 'upload_progress';
  static const String currentUploadId = 'current_upload_id';
  static const String uploadQueue = 'upload_queue';
  static const String failedUploads = 'failed_uploads';

  /// Navigation State
  static const String lastVisitedPage = 'last_visited_page';
  static const String navigationStack = 'navigation_stack';
  static const String bottomNavIndex = 'bottom_nav_index';

  /// Search & Filter State
  static const String lastSearchQuery = 'last_search_query';
  static const String searchHistory = 'search_history';
  static const String appliedFilters = 'applied_filters';
  static const String sortPreferences = 'sort_preferences';

  /// ==================== MIGRATION & VERSIONING KEYS ====================

  /// Data Migration
  static const String databaseVersion = 'database_version';
  static const String lastMigrationRun = 'last_migration_run';
  static const String migrationInProgress = 'migration_in_progress';
  static const String backupBeforeMigration = 'backup_before_migration';

  /// App Updates
  static const String pendingAppUpdate = 'pending_app_update';
  static const String updateNotificationShown = 'update_notification_shown';
  static const String forceUpdateRequired = 'force_update_required';
  static const String lastUpdateCheck = 'last_update_check';

  /// ==================== ERROR & LOGGING KEYS ====================

  /// Error Tracking
  static const String lastError = 'last_error';
  static const String errorCount = 'error_count';
  static const String crashReports = 'crash_reports';
  static const String errorLogs = 'error_logs';

  /// Performance Metrics
  static const String performanceMetrics = 'performance_metrics';
  static const String appLaunchTime = 'app_launch_time';
  static const String averageResponseTime = 'average_response_time';
  static const String memoryUsage = 'memory_usage';

  /// ==================== HELPER METHODS ====================

  /// Get user-specific key
  static String getUserKey(String baseKey, String userId) {
    return '${baseKey}_$userId';
  }

  /// Get timestamped key
  static String getTimestampedKey(String baseKey) {
    return '${baseKey}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get versioned key
  static String getVersionedKey(String baseKey, String version) {
    return '${baseKey}_v$version';
  }

  /// Get environment-specific key
  static String getEnvironmentKey(String baseKey, String environment) {
    return '${baseKey}_$environment';
  }

  /// Check if key is user-specific
  static bool isUserSpecificKey(String key) {
    return key.contains(userId) ||
        key.contains(userProfile) ||
        key.contains(userEmail) ||
        key.contains(userName);
  }

  /// Check if key is sensitive
  static bool isSensitiveKey(String key) {
    const sensitiveKeys = [
      accessToken,
      refreshToken,
      pinCode,
      biometricKey,
      encryptionKey,
      secureAccessToken,
      secureRefreshToken,
      stripePublishableKey,
      whatsappApiKey,
      telegramBotToken,
    ];
    return sensitiveKeys.contains(key);
  }

  /// Get cache key with expiry
  static String getCacheKeyWithExpiry(String key, Duration expiry) {
    final expiryTime = DateTime.now().add(expiry).millisecondsSinceEpoch;
    return '${key}_expires_$expiryTime';
  }

  /// Extract expiry time from cache key
  static DateTime? getExpiryFromCacheKey(String key) {
    final parts = key.split('_expires_');
    if (parts.length == 2) {
      final timestamp = int.tryParse(parts.last);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    return null;
  }

  /// Check if cache key is expired
  static bool isCacheKeyExpired(String key) {
    final expiry = getExpiryFromCacheKey(key);
    return expiry != null && DateTime.now().isAfter(expiry);
  }
}
