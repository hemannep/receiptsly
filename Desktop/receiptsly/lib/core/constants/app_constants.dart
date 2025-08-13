// lib/core/constants/app_constants.dart

/// Application-wide constants for Receiptsly
/// Contains all static values used throughout the application
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// App Information
  static const String appName = 'Receiptsly';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String packageName = 'com.receiptsly.app';
  static const String appDescription = 'AI-Powered Receipt & Expense Tracking';
  static const String companyName = 'Receiptsly Inc.';
  static const String supportEmail = 'support@receiptsly.app';
  static const String websiteUrl = 'https://receiptsly.app';
  static const String privacyPolicyUrl = 'https://receiptsly.app/privacy';
  static const String termsOfServiceUrl = 'https://receiptsly.app/terms';

  /// API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Authentication
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int otpLength = 6;
  static const Duration otpTimeout = Duration(minutes: 5);

  /// OCR Configuration
  static const double minOcrConfidence = 0.7;
  static const int maxImageSizeMB = 10;
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const int imageCompressionQuality = 85;
  static const int maxOcrRetries = 3;
  static const Duration ocrTimeout = Duration(seconds: 45);

  /// Receipt Processing
  static const int maxReceiptsPerMonth = 50; // Free tier
  static const int maxReceiptsPerMonthPro = 500; // Pro tier
  static const int maxReceiptsPerMonthBusiness = 2000; // Business tier
  static const Duration receiptRetentionPeriod = Duration(
    days: 365 * 7,
  ); // 7 years
  static const List<String> defaultCategories = [
    'Food & Dining',
    'Transportation',
    'Office Supplies',
    'Software & Technology',
    'Professional Services',
    'Marketing & Advertising',
    'Travel & Accommodation',
    'Utilities',
    'Equipment',
    'General',
  ];

  /// Invoice Configuration
  static const String defaultInvoiceTemplate = 'standard';
  static const int invoiceNumberLength = 8;
  static const String invoicePrefix = 'INV-';
  static const int defaultPaymentTermsDays = 30;
  static const double defaultTaxRate = 0.0;
  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'JPY',
    'INR',
    'CNY',
  ];
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'JPY': '¥',
    'INR': '₹',
    'CNY': '¥',
  };

  /// File Upload Limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxBulkUploadFiles = 20;
  static const List<String> allowedFileTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 5;

  /// Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration imageCacheExpiration = Duration(days: 30);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxImageCacheSize = 200 * 1024 * 1024; // 200MB

  /// Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const Duration forceSyncInterval = Duration(hours: 6);
  static const int maxSyncRetries = 5;
  static const Duration syncTimeout = Duration(minutes: 10);
  static const int syncBatchSize = 50;

  /// Offline Configuration
  static const int maxOfflineQueue = 1000;
  static const Duration offlineRetention = Duration(days: 30);
  static const int maxConflictResolution = 10;

  /// Chat Bot Configuration
  static const Duration botResponseTimeout = Duration(seconds: 30);
  static const int maxBotMessageLength = 4096;
  static const Duration botSessionTimeout = Duration(hours: 2);
  static const List<String> supportedBotCommands = [
    '/start',
    '/help',
    '/stats',
    '/recent',
    '/settings',
  ];

  /// Subscription Tiers
  static const Map<String, Map<String, dynamic>> subscriptionTiers = {
    'free': {
      'name': 'Free',
      'monthlyReceipts': 50,
      'invoicesPerMonth': 10,
      'clients': 5,
      'chatIntegration': false,
      'advancedReports': false,
      'priority_support': false,
      'price': 0.0,
    },
    'pro': {
      'name': 'Pro',
      'monthlyReceipts': 500,
      'invoicesPerMonth': 100,
      'clients': 50,
      'chatIntegration': true,
      'advancedReports': true,
      'priority_support': false,
      'price': 9.99,
    },
    'business': {
      'name': 'Business',
      'monthlyReceipts': 2000,
      'invoicesPerMonth': 500,
      'clients': 200,
      'chatIntegration': true,
      'advancedReports': true,
      'priority_support': true,
      'price': 29.99,
    },
  };

  /// Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 250);

  /// Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minBusinessNameLength = 2;
  static const int maxBusinessNameLength = 100;
  static const int maxReceiptDescriptionLength = 500;
  static const int maxInvoiceNotesLength = 1000;
  static const double minAmount = 0.01;
  static const double maxAmount = 999999.99;

  /// Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy • HH:mm';
  static const String invoiceDateFormat = 'MMMM dd, yyyy';

  /// Regular Expressions
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String amountRegex = r'^\d+(\.\d{1,2})?$';
  static const String alphanumericRegex = r'^[a-zA-Z0-9]+$';
  static const String businessNameRegex = r"^[a-zA-Z0-9\s\-&.,']+$";

  /// Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  static const String accountLockedMessage =
      'Account temporarily locked due to too many failed attempts.';
  static const String sessionExpiredMessage =
      'Your session has expired. Please log in again.';
  static const String insufficientPermissionsMessage =
      'You don\'t have permission to perform this action.';
  static const String fileTooLargeMessage =
      'File size exceeds the maximum limit.';
  static const String unsupportedFileTypeMessage =
      'File type is not supported.';
  static const String ocrFailedMessage =
      'Failed to process receipt. Please try again or enter details manually.';
  static const String syncFailedMessage =
      'Failed to sync data. Will retry automatically.';
  static const String subscriptionExpiredMessage =
      'Your subscription has expired. Please upgrade to continue.';
  static const String monthlyLimitExceededMessage =
      'Monthly receipt limit exceeded. Please upgrade your plan.';

  /// Success Messages
  static const String receiptProcessedMessage =
      'Receipt processed successfully!';
  static const String invoiceSentMessage = 'Invoice sent successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String passwordChangedMessage = 'Password changed successfully!';
  static const String subscriptionUpgradedMessage =
      'Subscription upgraded successfully!';
  static const String dataExportedMessage = 'Data exported successfully!';
  static const String syncCompletedMessage = 'Data synced successfully!';

  /// Feature Flags
  static const bool enableChatBot = true;
  static const bool enableOfflineMode = true;
  static const bool enableAdvancedReports = true;
  static const bool enableBulkUpload = true;
  static const bool enableAutoSync = true;
  static const bool enablePushNotifications = true;
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = true;
  static const bool enableBetaFeatures = false;

  /// Debug Configuration
  static const bool enableDebugMode = false;
  static const bool enableVerboseLogging = false;
  static const bool enableNetworkLogging = false;
  static const bool enablePerformanceMonitoring = true;

  /// URLs and Deep Links
  static const String appStoreUrl = 'https://apps.apple.com/app/receiptsly';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.receiptsly.app';
  static const String helpCenterUrl = 'https://help.receiptsly.app';
  static const String contactUsUrl = 'https://receiptsly.app/contact';
  static const String upgradeUrl = 'https://receiptsly.app/upgrade';

  /// Deep Link Schemes
  static const String deepLinkScheme = 'receiptsly';
  static const String receiptDeepLink = '$deepLinkScheme://receipt';
  static const String invoiceDeepLink = '$deepLinkScheme://invoice';
  static const String settingsDeepLink = '$deepLinkScheme://settings';

  /// Platform Specific
  static const double iosStatusBarHeight = 44.0;
  static const double androidStatusBarHeight = 24.0;
  static const double iosBottomSafeArea = 34.0;
  static const double androidNavigationBarHeight = 48.0;

  /// Biometric Authentication
  static const String biometricReason =
      'Authenticate to access your Receiptsly account';
  static const bool enableBiometricAuth = true;
  static const Duration biometricTimeout = Duration(seconds: 30);

  /// Export Formats
  static const List<String> supportedExportFormats = ['PDF', 'CSV', 'Excel'];
  static const String defaultExportFormat = 'PDF';

  /// Report Types
  static const List<String> availableReportTypes = [
    'Expense Summary',
    'Income vs Expenses',
    'Category Breakdown',
    'Monthly Trends',
    'Tax Summary',
    'Client Revenue',
  ];

  /// Keyboard Shortcuts (Web)
  static const Map<String, String> keyboardShortcuts = {
    'Ctrl+N': 'New Receipt',
    'Ctrl+I': 'New Invoice',
    'Ctrl+S': 'Save',
    'Ctrl+E': 'Export',
    'Ctrl+F': 'Search',
    'Ctrl+R': 'Refresh',
    'Escape': 'Close Dialog',
  };
}
