// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

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
  static const String salesEmail = 'sales@receiptsly.app';
  static const String privacyEmail = 'privacy@receiptsly.app';
  static const String securityEmail = 'security@receiptsly.app';
  static const String websiteUrl = 'https://receiptsly.app';
  static const String privacyPolicyUrl = 'https://receiptsly.app/privacy';
  static const String termsOfServiceUrl = 'https://receiptsly.app/terms';
  static const String cookiePolicyUrl = 'https://receiptsly.app/cookies';
  static const String gdprUrl = 'https://receiptsly.app/gdpr';

  /// Supported Locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (US)
    Locale('en', 'GB'), // English (UK)
    Locale('es', 'ES'), // Spanish (Spain)
    Locale('es', 'MX'), // Spanish (Mexico)
    Locale('fr', 'FR'), // French (France)
    Locale('de', 'DE'), // German (Germany)
    Locale('it', 'IT'), // Italian (Italy)
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('ja', 'JP'), // Japanese (Japan)
    Locale('ko', 'KR'), // Korean (South Korea)
    Locale('zh', 'CN'), // Chinese (Simplified)
    Locale('zh', 'TW'), // Chinese (Traditional)
    Locale('ar', 'SA'), // Arabic (Saudi Arabia)
    Locale('hi', 'IN'), // Hindi (India)
    Locale('ru', 'RU'), // Russian (Russia)
  ];

  /// Default Settings
  static const String defaultLanguageCode = 'en';
  static const String defaultCountryCode = 'US';
  static const String defaultCurrency = 'USD';
  static const String defaultTimezone = 'UTC';

  /// API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration exponentialBackoffBase = Duration(seconds: 1);
  static const int maxConcurrentRequests = 5;

  /// Authentication
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration shortSessionTimeout = Duration(hours: 2);
  static const Duration extendedSessionTimeout = Duration(days: 30);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int otpLength = 6;
  static const Duration otpTimeout = Duration(minutes: 5);
  static const int maxOtpAttempts = 3;
  static const Duration passwordResetTimeout = Duration(hours: 24);

  /// Security
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int pinLength = 4;
  static const int maxPinAttempts = 3;
  static const Duration biometricTimeout = Duration(seconds: 30);
  static const String biometricReason =
      'Authenticate to access your Receiptsly account';
  static const bool enableBiometricAuth = true;
  static const bool enableEncryption = true;
  static const String encryptionAlgorithm = 'AES-256';

  /// OCR Configuration
  static const double minOcrConfidence = 0.7;
  static const double highOcrConfidence = 0.9;
  static const int maxImageSizeMB = 10;
  static const int maxImageResolution = 2048;
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  ];
  static const int imageCompressionQuality = 85;
  static const int highQualityCompressionQuality = 95;
  static const int maxOcrRetries = 3;
  static const Duration ocrTimeout = Duration(seconds: 45);
  static const Duration ocrProcessingTimeout = Duration(minutes: 2);

  /// Receipt Processing
  static const int maxReceiptsPerMonth = 50; // Free tier
  static const int maxReceiptsPerMonthPro = 500; // Pro tier
  static const int maxReceiptsPerMonthBusiness = 2000; // Business tier
  static const int maxReceiptsPerMonthEnterprise = -1; // Unlimited
  static const Duration receiptRetentionPeriod = Duration(
    days: 365 * 7,
  ); // 7 years
  static const int maxReceiptImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxBulkReceiptUpload = 50;

  static const List<String> defaultCategories = [
    'Food & Dining',
    'Transportation',
    'Office Supplies',
    'Software & Technology',
    'Professional Services',
    'Marketing & Advertising',
    'Travel & Accommodation',
    'Utilities',
    'Equipment & Hardware',
    'Insurance',
    'Taxes & Fees',
    'Education & Training',
    'Health & Medical',
    'Entertainment',
    'Miscellaneous',
  ];

  static const List<String> businessCategories = [
    'Advertising',
    'Car and Truck Expenses',
    'Commissions and Fees',
    'Contract Labor',
    'Depletion',
    'Depreciation',
    'Employee Benefit Programs',
    'Insurance',
    'Interest',
    'Legal and Professional Services',
    'Office Expense',
    'Pension and Profit-Sharing Plans',
    'Rent or Lease',
    'Repairs and Maintenance',
    'Supplies',
    'Taxes and Licenses',
    'Travel and Meals',
    'Utilities',
    'Wages',
    'Other Expenses',
  ];

  /// Invoice Configuration
  static const String defaultInvoiceTemplate = 'standard';
  static const int invoiceNumberLength = 8;
  static const String invoicePrefix = 'INV-';
  static const String quotePrefix = 'QUO-';
  static const String receiptPrefix = 'RCP-';
  static const int defaultPaymentTermsDays = 30;
  static const double defaultTaxRate = 0.0;
  static const int maxInvoiceItems = 50;
  static const int maxInvoiceNoteLength = 2000;
  static const Duration invoiceDueDateGracePeriod = Duration(days: 3);

  static const List<int> commonPaymentTerms = [0, 15, 30, 45, 60, 90];
  static const List<String> invoiceStatuses = [
    'draft',
    'sent',
    'viewed',
    'partial',
    'paid',
    'overdue',
    'cancelled',
    'refunded',
  ];

  /// Currency Configuration
  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'JPY',
    'CHF',
    'SEK',
    'NOK',
    'DKK',
    'INR',
    'CNY',
    'KRW',
    'SGD',
    'HKD',
    'NZD',
    'MXN',
    'BRL',
    'ZAR',
    'RUB',
  ];

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'JPY': '¥',
    'CHF': 'CHF',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'INR': '₹',
    'CNY': '¥',
    'KRW': '₩',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NZD': 'NZ\$',
    'MXN': '\$',
    'BRL': 'R\$',
    'ZAR': 'R',
    'RUB': '₽',
  };

  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'JPY': 'Japanese Yen',
    'CHF': 'Swiss Franc',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'INR': 'Indian Rupee',
    'CNY': 'Chinese Yuan',
    'KRW': 'South Korean Won',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NZD': 'New Zealand Dollar',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    'ZAR': 'South African Rand',
    'RUB': 'Russian Ruble',
  };

  /// File Upload and Storage
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxBulkUploadFiles = 20;
  static const int maxAttachmentsPerReceipt = 5;
  static const int maxAttachmentsPerInvoice = 10;

  static const List<String> allowedFileTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'application/pdf',
    'text/csv',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  static const List<String> supportedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'csv',
    'xlsx',
    'xls',
  ];

  static const List<String> supportedExportFormats = [
    'PDF',
    'CSV',
    'Excel',
    'JSON',
    'XML',
  ];

  /// Pagination and Data Loading
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 5;
  static const int infiniteScrollThreshold = 5;
  static const int preloadItemCount = 10;

  /// Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration imageCacheExpiration = Duration(days: 30);
  static const Duration dataCacheExpiration = Duration(hours: 6);
  static const Duration userCacheExpiration = Duration(hours: 12);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxImageCacheSize = 200 * 1024 * 1024; // 200MB
  static const int maxDatabaseCacheSize = 50 * 1024 * 1024; // 50MB

  /// Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const Duration forceSyncInterval = Duration(hours: 6);
  static const Duration backgroundSyncInterval = Duration(hours: 1);
  static const int maxSyncRetries = 5;
  static const Duration syncTimeout = Duration(minutes: 10);
  static const int syncBatchSize = 50;
  static const int maxSyncQueueSize = 1000;
  static const Duration syncConflictResolutionTimeout = Duration(minutes: 5);

  /// Offline Configuration
  static const int maxOfflineQueue = 1000;
  static const Duration offlineRetention = Duration(days: 30);
  static const int maxConflictResolution = 10;
  static const Duration offlineDataExpiration = Duration(days: 7);
  static const int maxOfflineStorageSize = 500 * 1024 * 1024; // 500MB

  /// Chat Bot Configuration
  static const Duration botResponseTimeout = Duration(seconds: 30);
  static const int maxBotMessageLength = 4096;
  static const Duration botSessionTimeout = Duration(hours: 2);
  static const int maxBotConversationHistory = 50;
  static const int maxBotAttachmentsPerMessage = 3;

  static const List<String> supportedBotCommands = [
    '/start',
    '/help',
    '/stats',
    '/recent',
    '/settings',
    '/export',
    '/invoice',
    '/receipt',
    '/clients',
    '/reports',
  ];

  static const List<String> supportedBotPlatforms = [
    'telegram',
    'whatsapp',
    'slack',
    'discord',
  ];

  /// Subscription Tiers
  static const Map<String, Map<String, dynamic>> subscriptionTiers = {
    'free': {
      'name': 'Free',
      'monthlyReceipts': 50,
      'invoicesPerMonth': 10,
      'clients': 5,
      'storageGB': 1,
      'chatIntegration': false,
      'advancedReports': false,
      'prioritySupport': false,
      'apiAccess': false,
      'customBranding': false,
      'multiUser': false,
      'price': 0.0,
      'currency': 'USD',
      'features': [
        'Basic OCR',
        'PDF export',
        'Email support',
        'Mobile app access',
      ],
    },
    'pro': {
      'name': 'Pro',
      'monthlyReceipts': 500,
      'invoicesPerMonth': 100,
      'clients': 50,
      'storageGB': 10,
      'chatIntegration': true,
      'advancedReports': true,
      'prioritySupport': false,
      'apiAccess': false,
      'customBranding': false,
      'multiUser': false,
      'price': 9.99,
      'currency': 'USD',
      'features': [
        'Advanced OCR',
        'Multiple export formats',
        'WhatsApp/Telegram integration',
        'Advanced reporting',
        'Priority email support',
        'Cloud backup',
      ],
    },
    'business': {
      'name': 'Business',
      'monthlyReceipts': 2000,
      'invoicesPerMonth': 500,
      'clients': 200,
      'storageGB': 50,
      'chatIntegration': true,
      'advancedReports': true,
      'prioritySupport': true,
      'apiAccess': true,
      'customBranding': false,
      'multiUser': true,
      'maxUsers': 5,
      'price': 29.99,
      'currency': 'USD',
      'features': [
        'AI-powered categorization',
        'Team collaboration',
        'API access',
        'Custom integrations',
        'Phone support',
        'Advanced analytics',
      ],
    },
    'enterprise': {
      'name': 'Enterprise',
      'monthlyReceipts': -1, // unlimited
      'invoicesPerMonth': -1, // unlimited
      'clients': -1, // unlimited
      'storageGB': 500,
      'chatIntegration': true,
      'advancedReports': true,
      'prioritySupport': true,
      'apiAccess': true,
      'customBranding': true,
      'multiUser': true,
      'maxUsers': -1, // unlimited
      'price': 99.99,
      'currency': 'USD',
      'features': [
        'White-label branding',
        'Dedicated support',
        'Custom deployment',
        'Advanced security',
        'SLA guarantee',
        'Custom training',
      ],
    },
  };

  /// Payment Methods
  static const List<String> supportedPaymentMethods = [
    'card',
    'apple_pay',
    'google_pay',
    'paypal',
    'bank_transfer',
    'stripe',
  ];

  /// Animation and UI
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackbarDuration = Duration(seconds: 4);
  static const Duration tooltipDuration = Duration(seconds: 3);

  /// UI Layout
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double cardElevation = 2.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets compactPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
  );

  /// Platform Specific
  static const double iosStatusBarHeight = 44.0;
  static const double androidStatusBarHeight = 24.0;
  static const double iosBottomSafeArea = 34.0;
  static const double androidNavigationBarHeight = 48.0;
  static const double tabBarHeight = 56.0;
  static const double appBarHeight = 56.0;

  /// Validation Rules
  static const int minBusinessNameLength = 2;
  static const int maxBusinessNameLength = 100;
  static const int maxReceiptDescriptionLength = 500;
  static const int maxInvoiceNotesLength = 1000;
  static const int maxClientNameLength = 100;
  static const int maxClientAddressLength = 200;
  static const double minAmount = 0.01;
  static const double maxAmount = 999999.99;
  static const int maxDecimalPlaces = 2;

  /// Date and Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy • HH:mm';
  static const String invoiceDateFormat = 'MMMM dd, yyyy';
  static const String shortDateFormat = 'MM/dd/yyyy';
  static const String timeFormat = 'HH:mm:ss';
  static const String displayTimeFormat = 'h:mm a';
  static const String isoDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

  /// Regular Expressions
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String amountRegex = r'^\d+(\.\d{1,2})?$';
  static const String alphanumericRegex = r'^[a-zA-Z0-9]+$';
  static const String businessNameRegex = r"^[a-zA-Z0-9\s\-&.,']+$";
  static const String invoiceNumberRegex = r'^[A-Z]{2,3}-\d{4,6}$';
  static const String zipCodeRegex = r'^\d{5}(-\d{4})?$';
  static const String currencyRegex = r'^\d+(\.\d{1,2})?$';

  /// Notification Configuration
  static const String defaultNotificationChannel = 'receiptsly_general';
  static const String syncNotificationChannel = 'receiptsly_sync';
  static const String paymentNotificationChannel = 'receiptsly_payments';
  static const String marketingNotificationChannel = 'receiptsly_marketing';
  static const String urgentNotificationChannel = 'receiptsly_urgent';

  static const Duration notificationRetention = Duration(days: 30);
  static const int maxNotificationsPerDay = 10;
  static const Duration quietHoursStart = Duration(hours: 22); // 10 PM
  static const Duration quietHoursEnd = Duration(hours: 8); // 8 AM

  /// Analytics Events
  static const String eventAppOpen = 'app_open';
  static const String eventAppClosed = 'app_closed';
  static const String eventReceiptScanned = 'receipt_scanned';
  static const String eventReceiptManualEntry = 'receipt_manual_entry';
  static const String eventInvoiceCreated = 'invoice_created';
  static const String eventInvoiceSent = 'invoice_sent';
  static const String eventExportGenerated = 'export_generated';
  static const String eventSubscriptionUpgraded = 'subscription_upgraded';
  static const String eventFeatureUsed = 'feature_used';
  static const String eventUserRegistered = 'user_registered';
  static const String eventUserLogin = 'user_login';
  static const String eventPaymentProcessed = 'payment_processed';
  static const String eventSyncCompleted = 'sync_completed';
  static const String eventErrorOccurred = 'error_occurred';

  /// Error Codes and Messages
  static const String errorNetworkUnavailable = 'NETWORK_UNAVAILABLE';
  static const String errorUnauthorized = 'UNAUTHORIZED';
  static const String errorForbidden = 'FORBIDDEN';
  static const String errorNotFound = 'NOT_FOUND';
  static const String errorServerError = 'SERVER_ERROR';
  static const String errorInvalidData = 'INVALID_DATA';
  static const String errorQuotaExceeded = 'QUOTA_EXCEEDED';
  static const String errorFileTooBig = 'FILE_TOO_BIG';
  static const String errorUnsupportedFormat = 'UNSUPPORTED_FORMAT';
  static const String errorOcrFailed = 'OCR_FAILED';
  static const String errorSyncFailed = 'SYNC_FAILED';
  static const String errorPaymentFailed = 'PAYMENT_FAILED';
  static const String errorSubscriptionExpired = 'SUBSCRIPTION_EXPIRED';

  // Error Messages
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
      'File size exceeds the maximum limit of ${maxFileSize ~/ (1024 * 1024)}MB.';
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
  static const String backupCompletedMessage = 'Backup completed successfully!';
  static const String settingsSavedMessage = 'Settings saved successfully!';

  /// Feature Flags (Default Values)
  static const Map<String, bool> defaultFeatureFlags = {
    'enableChatBot': true,
    'enableOfflineMode': true,
    'enableAdvancedReports': true,
    'enableBulkUpload': true,
    'enableAutoSync': true,
    'enablePushNotifications': true,
    'enableCrashReporting': true,
    'enableAnalytics': true,
    'enableBetaFeatures': false,
    'enableBiometricAuth': true,
    'enableDarkMode': true,
    'enableAutoBackup': true,
    'enableSmartCategorization': true,
    'enableMultiCurrency': true,
    'enableTeamFeatures': false,
    'enableAPIAccess': false,
    'enableCustomBranding': false,
    'enableAdvancedSecurity': false,
  };

  /// URLs and Links
  static const String appStoreUrl = 'https://apps.apple.com/app/receiptsly';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.receiptsly.app';
  static const String webAppUrl = 'https://app.receiptsly.app';
  static const String helpCenterUrl = 'https://help.receiptsly.app';
  static const String contactUsUrl = 'https://receiptsly.app/contact';
  static const String upgradeUrl = 'https://receiptsly.app/upgrade';
  static const String blogUrl = 'https://receiptsly.app/blog';
  static const String statusPageUrl = 'https://status.receiptsly.app';

  /// Social Media
  static const String twitterUrl = 'https://twitter.com/receiptsly';
  static const String linkedinUrl = 'https://linkedin.com/company/receiptsly';
  static const String facebookUrl = 'https://facebook.com/receiptsly';
  static const String youtubeUrl = 'https://youtube.com/@receiptsly';
  static const String githubUrl = 'https://github.com/receiptsly';

  /// Deep Link Schemes
  static const String deepLinkScheme = 'receiptsly';
  static const String receiptDeepLink = '$deepLinkScheme://receipt';
  static const String invoiceDeepLink = '$deepLinkScheme://invoice';
  static const String settingsDeepLink = '$deepLinkScheme://settings';
  static const String dashboardDeepLink = '$deepLinkScheme://dashboard';
  static const String reportsDeepLink = '$deepLinkScheme://reports';
  static const String clientsDeepLink = '$deepLinkScheme://clients';
  static const String subscriptionDeepLink = '$deepLinkScheme://subscription';

  /// Asset Paths
  static const String logoPath = 'assets/images/logo/app_logo.png';
  static const String logoLightPath = 'assets/images/logo/app_logo_light.png';
  static const String logoDarkPath = 'assets/images/logo/app_logo_dark.png';
  static const String splashLogoPath = 'assets/images/logo/splash_logo.png';
  static const String placeholderImagePath = 'assets/images/placeholder.png';
  static const String emptyStatePath = 'assets/images/empty_state.png';
  static const String errorImagePath = 'assets/images/error.png';

  /// Animation Assets
  static const String loadingAnimationPath = 'assets/animations/loading.json';
  static const String successAnimationPath = 'assets/animations/success.json';
  static const String errorAnimationPath = 'assets/animations/error.json';
  static const String emptyAnimationPath = 'assets/animations/empty.json';
  static const String syncAnimationPath = 'assets/animations/sync.json';
  static const String processingAnimationPath =
      'assets/animations/processing.json';

  /// Report Types
  static const List<String> availableReportTypes = [
    'Expense Summary',
    'Income vs Expenses',
    'Category Breakdown',
    'Monthly Trends',
    'Tax Summary',
    'Client Revenue',
    'Profit & Loss',
    'Cash Flow',
    'Year-over-Year Comparison',
    'Custom Report',
  ];

  /// Export Templates
  static const Map<String, String> exportTemplates = {
    'expense_summary': 'Expense Summary Report',
    'tax_report': 'Tax Preparation Report',
    'client_invoice': 'Client Invoice Report',
    'monthly_summary': 'Monthly Summary Report',
    'annual_report': 'Annual Financial Report',
  };

  /// Keyboard Shortcuts (Desktop/Web)
  static const Map<String, String> keyboardShortcuts = {
    'Ctrl+N': 'New Receipt',
    'Ctrl+Shift+N': 'New Invoice',
    'Ctrl+I': 'Import Data',
    'Ctrl+E': 'Export Data',
    'Ctrl+S': 'Save/Sync',
    'Ctrl+F': 'Search',
    'Ctrl+R': 'Refresh',
    'Ctrl+P': 'Print',
    'Ctrl+D': 'Dashboard',
    'Ctrl+1': 'Receipts',
    'Ctrl+2': 'Invoices',
    'Ctrl+3': 'Clients',
    'Ctrl+4': 'Reports',
    'Ctrl+5': 'Settings',
    'Ctrl+/': 'Help',
    'Escape': 'Close Dialog',
    'F5': 'Refresh',
  };

  /// Database Configuration
  static const String databaseName = 'receiptsly.db';
  static const int databaseVersion = 1;
  static const List<String> databaseTables = [
    'users',
    'receipts',
    'invoices',
    'clients',
    'categories',
    'settings',
    'sync_queue',
    'offline_actions',
    'attachments',
    'notifications',
    'audit_logs',
  ];

  /// Cache Keys
  static const String cacheKeyUserSettings = 'user_settings';
  static const String cacheKeyReceipts = 'cached_receipts';
  static const String cacheKeyInvoices = 'cached_invoices';
  static const String cacheKeyClients = 'cached_clients';
  static const String cacheKeyCategories = 'cached_categories';
  static const String cacheKeyReports = 'cached_reports';
  static const String cacheKeyUserProfile = 'user_profile';
  static const String cacheKeySubscription = 'subscription_info';
  static const String cacheKeyFeatureFlags = 'feature_flags';

  /// Onboarding Configuration
  static const List<Map<String, String>> onboardingSteps = [
    {
      'title': 'Welcome to Receiptsly',
      'description':
          'Manage your receipts and invoices with AI-powered automation',
      'image': 'assets/images/onboarding/welcome.png',
    },
    {
      'title': 'Scan Receipts Instantly',
      'description':
          'Use your camera or upload images to extract data automatically',
      'image': 'assets/images/onboarding/scan.png',
    },
    {
      'title': 'Create Professional Invoices',
      'description': 'Generate and send invoices to your clients in minutes',
      'image': 'assets/images/onboarding/invoice.png',
    },
    {
      'title': 'Track Everything',
      'description': 'Monitor your expenses, income, and business growth',
      'image': 'assets/images/onboarding/tracking.png',
    },
    {
      'title': 'Stay Organized',
      'description':
          'Keep all your financial documents organized and accessible',
      'image': 'assets/images/onboarding/organized.png',
    },
    {
      'title': 'Sync Across Devices',
      'description':
          'Access your data anywhere with automatic cloud synchronization',
      'image': 'assets/images/onboarding/sync.png',
    },
  ];

  /// Tutorial Steps
  static const List<Map<String, String>> tutorialSteps = [
    {
      'step': 'scan_receipt',
      'title': 'Scan Your First Receipt',
      'description':
          'Tap the camera button to scan a receipt and see the magic happen',
    },
    {
      'step': 'create_invoice',
      'title': 'Create an Invoice',
      'description': 'Add a client and create your first professional invoice',
    },
    {
      'step': 'view_reports',
      'title': 'View Reports',
      'description':
          'Check your expense reports and track your business growth',
    },
    {
      'step': 'setup_sync',
      'title': 'Enable Sync',
      'description': 'Keep your data safe with automatic cloud backup',
    },
  ];

  /// Utility Methods

  /// Get currency symbol by code
  static String getCurrencySymbol(String currencyCode) {
    return currencySymbols[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Get currency name by code
  static String getCurrencyName(String currencyCode) {
    return currencyNames[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Get subscription plan details
  static Map<String, dynamic>? getSubscriptionPlan(String planId) {
    return subscriptionTiers[planId];
  }

  /// Check if feature is enabled by default
  static bool isFeatureEnabledByDefault(String feature) {
    return defaultFeatureFlags[feature] ?? false;
  }

  /// Get supported locale codes
  static List<String> getSupportedLocaleCodes() {
    return supportedLocales
        .map((locale) => locale.languageCode)
        .toSet()
        .toList();
  }

  /// Get supported country codes
  static List<String> getSupportedCountryCodes() {
    return supportedLocales
        .map((locale) => locale.countryCode ?? '')
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Validation Methods

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(emailRegex, caseSensitive: false).hasMatch(email);
  }

  /// Validate phone format
  static bool isValidPhone(String phone) {
    return RegExp(
      phoneRegex,
    ).hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  /// Validate currency amount format
  static bool isValidCurrency(String amount) {
    return RegExp(currencyRegex).hasMatch(amount);
  }

  /// Validate invoice number format
  static bool isValidInvoiceNumber(String invoiceNumber) {
    return RegExp(invoiceNumberRegex).hasMatch(invoiceNumber);
  }

  /// Validate business name
  static bool isValidBusinessName(String name) {
    return name.length >= minBusinessNameLength &&
        name.length <= maxBusinessNameLength &&
        RegExp(businessNameRegex).hasMatch(name);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    if (password.length < minPasswordLength ||
        password.length > maxPasswordLength) {
      return false;
    }

    // Check for at least one uppercase, lowercase, digit, and special character
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  /// Validate amount range
  static bool isValidAmount(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }

  /// Utility Functions

  /// Get file extension from filename
  static String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  /// Check if file type is supported for images
  static bool isSupportedImageType(String extension) {
    return supportedImageFormats.contains(extension.toLowerCase());
  }

  /// Check if file type is supported for documents
  static bool isSupportedDocumentType(String extension) {
    return supportedDocumentTypes.contains(extension.toLowerCase());
  }

  /// Check if MIME type is allowed
  static bool isAllowedMimeType(String mimeType) {
    return allowedFileTypes.contains(mimeType.toLowerCase());
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format currency amount
  static String formatCurrency(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(maxDecimalPlaces)}';
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }

  /// Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (999 * (DateTime.now().microsecond / 1000000)))
            .round()
            .toString();
  }

  /// Generate invoice number
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final sequence = (now.day * 100 + now.hour).toString().padLeft(4, '0');
    return '$invoicePrefix$year$month$sequence';
  }

  /// Generate receipt reference
  static String generateReceiptReference() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final sequence = now.millisecondsSinceEpoch.toString().substring(8);
    return '$receiptPrefix$year$month$sequence';
  }

  /// Generate quote number
  static String generateQuoteNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final sequence = (now.day * 100 + now.minute).toString().padLeft(4, '0');
    return '$quotePrefix$year$month$sequence';
  }

  /// Calculate due date from payment terms
  static DateTime calculateDueDate(DateTime invoiceDate, int paymentTermsDays) {
    return invoiceDate.add(Duration(days: paymentTermsDays));
  }

  /// Check if invoice is overdue
  static bool isInvoiceOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate.add(invoiceDueDateGracePeriod));
  }

  /// Get days until due
  static int getDaysUntilDue(DateTime dueDate) {
    return dueDate.difference(DateTime.now()).inDays;
  }

  /// Get subscription tier for user
  static String getSubscriptionTierForLimits(
    int monthlyReceipts,
    int monthlyInvoices,
  ) {
    for (final entry in subscriptionTiers.entries) {
      final tier = entry.value;
      final receiptLimit = tier['monthlyReceipts'] as int;
      final invoiceLimit = tier['invoicesPerMonth'] as int;

      if ((receiptLimit == -1 || monthlyReceipts <= receiptLimit) &&
          (invoiceLimit == -1 || monthlyInvoices <= invoiceLimit)) {
        return entry.key;
      }
    }
    return 'enterprise'; // Default to highest tier
  }

  /// Check if user has reached subscription limits
  static bool hasReachedLimit(String tier, String limitType, int currentUsage) {
    final tierData = subscriptionTiers[tier];
    if (tierData == null) return false;

    final limit = tierData[limitType] as int?;
    if (limit == null || limit == -1) return false; // Unlimited

    return currentUsage >= limit;
  }

  /// Get remaining quota for subscription tier
  static int getRemainingQuota(
    String tier,
    String limitType,
    int currentUsage,
  ) {
    final tierData = subscriptionTiers[tier];
    if (tierData == null) return 0;

    final limit = tierData[limitType] as int?;
    if (limit == null || limit == -1) return -1; // Unlimited

    return (limit - currentUsage).clamp(0, limit);
  }

  /// Get upgrade recommendation
  static String? getUpgradeRecommendation(
    String currentTier,
    String limitType,
    int currentUsage,
  ) {
    if (hasReachedLimit(currentTier, limitType, currentUsage)) {
      final tierOrder = ['free', 'pro', 'business', 'enterprise'];
      final currentIndex = tierOrder.indexOf(currentTier);

      if (currentIndex < tierOrder.length - 1) {
        return tierOrder[currentIndex + 1];
      }
    }
    return null;
  }

  /// Format date for display
  static String formatDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Format relative time
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()}mo ago';
    } else {
      return '${(difference.inDays / 365).round()}y ago';
    }
  }

  /// Check if current time is within quiet hours
  static bool isQuietHours() {
    final now = DateTime.now();
    final currentTime = Duration(hours: now.hour, minutes: now.minute);

    // Handle quiet hours that span midnight
    if (quietHoursStart > quietHoursEnd) {
      return currentTime >= quietHoursStart || currentTime <= quietHoursEnd;
    } else {
      return currentTime >= quietHoursStart && currentTime <= quietHoursEnd;
    }
  }

  /// Get default export filename
  static String getDefaultExportFilename(String reportType, String format) {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final sanitizedType = reportType.toLowerCase().replaceAll(' ', '_');
    return 'receiptsly_${sanitizedType}_$timestamp.${format.toLowerCase()}';
  }

  /// Constants for testing and development
  static const bool enableTestMode = false;
  static const bool enableMockData = false;
  static const bool enablePerformanceLogging = false;
  static const bool enableMemoryLogging = false;
  static const bool enableNetworkLogging = false;

  /// Development URLs (only used in debug mode)
  static const String devApiBaseUrl = 'http://localhost:3000/api';
  static const String stagingApiBaseUrl = 'https://staging-api.receiptsly.app';
  static const String prodApiBaseUrl = 'https://api.receiptsly.app';
}
