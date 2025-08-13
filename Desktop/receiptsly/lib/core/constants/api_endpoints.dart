// lib/core/constants/api_endpoints.dart

/// API endpoint constants for Receiptsly
/// Contains all REST API endpoints and Firebase collection paths
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  /// Base URLs for different environments
  static const String _baseUrlDev = 'https://receiptsly-dev.web.app/api/v1';
  static const String _baseUrlStaging =
      'https://receiptsly-staging.web.app/api/v1';
  static const String _baseUrlProd = 'https://api.receiptsly.app/v1';

  /// Current base URL (should be configured based on environment)
  static const String baseUrl = _baseUrlProd;

  /// Firebase Functions Base URLs
  static const String _functionsBaseUrlDev =
      'https://us-central1-receiptsly-dev.cloudfunctions.net';
  static const String _functionsBaseUrlStaging =
      'https://us-central1-receiptsly-staging.cloudfunctions.net';
  static const String _functionsBaseUrlProd =
      'https://us-central1-receiptsly-prod.cloudfunctions.net';

  static const String functionsBaseUrl = _functionsBaseUrlProd;

  /// External Service URLs
  static const String stripeBaseUrl = 'https://api.stripe.com/v1';
  static const String googleVisionBaseUrl = 'https://vision.googleapis.com/v1';
  static const String whatsappApiBaseUrl = 'https://graph.facebook.com/v18.0';
  static const String telegramApiBaseUrl = 'https://api.telegram.org';

  /// ==================== AUTHENTICATION ENDPOINTS ====================

  /// User Authentication
  static const String signUp = '$baseUrl/auth/signup';
  static const String signIn = '$baseUrl/auth/signin';
  static const String signOut = '$baseUrl/auth/signout';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String verifyEmail = '$baseUrl/auth/verify-email';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String changePassword = '$baseUrl/auth/change-password';
  static const String deleteAccount = '$baseUrl/auth/delete-account';

  /// Social Authentication
  static const String googleAuth = '$baseUrl/auth/google';
  static const String appleAuth = '$baseUrl/auth/apple';
  static const String facebookAuth = '$baseUrl/auth/facebook';

  /// Phone Authentication
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String verifyPhone = '$baseUrl/auth/verify-phone';

  /// ==================== USER MANAGEMENT ENDPOINTS ====================

  /// User Profile
  static const String userProfile = '$baseUrl/user/profile';
  static const String updateProfile = '$baseUrl/user/profile';
  static const String uploadAvatar = '$baseUrl/user/avatar';
  static const String deleteAvatar = '$baseUrl/user/avatar';

  /// User Preferences
  static const String userPreferences = '$baseUrl/user/preferences';
  static const String updatePreferences = '$baseUrl/user/preferences';
  static const String notificationSettings = '$baseUrl/user/notifications';

  /// User Statistics
  static const String userStats = '$baseUrl/user/stats';
  static const String monthlyStats = '$baseUrl/user/stats/monthly';
  static const String yearlyStats = '$baseUrl/user/stats/yearly';

  /// ==================== RECEIPT ENDPOINTS ====================

  /// Receipt CRUD Operations
  static const String receipts = '$baseUrl/receipts';
  static String getReceipt(String id) => '$baseUrl/receipts/$id';
  static String updateReceipt(String id) => '$baseUrl/receipts/$id';
  static String deleteReceipt(String id) => '$baseUrl/receipts/$id';

  /// Receipt Processing
  static const String uploadReceipt = '$baseUrl/receipts/upload';
  static const String processOcr = '$baseUrl/receipts/process-ocr';
  static const String bulkUpload = '$baseUrl/receipts/bulk-upload';
  static String reprocessReceipt(String id) =>
      '$baseUrl/receipts/$id/reprocess';

  /// Receipt Search & Filter
  static const String searchReceipts = '$baseUrl/receipts/search';
  static const String filterReceipts = '$baseUrl/receipts/filter';
  static const String receiptsByCategory = '$baseUrl/receipts/by-category';
  static const String receiptsByDateRange = '$baseUrl/receipts/by-date-range';
  static const String receiptsByVendor = '$baseUrl/receipts/by-vendor';

  /// Receipt Export
  static const String exportReceipts = '$baseUrl/receipts/export';
  static const String exportReceiptsPdf = '$baseUrl/receipts/export/pdf';
  static const String exportReceiptsCsv = '$baseUrl/receipts/export/csv';
  static const String exportReceiptsExcel = '$baseUrl/receipts/export/excel';

  /// ==================== INVOICE ENDPOINTS ====================

  /// Invoice CRUD Operations
  static const String invoices = '$baseUrl/invoices';
  static String getInvoice(String id) => '$baseUrl/invoices/$id';
  static String updateInvoice(String id) => '$baseUrl/invoices/$id';
  static String deleteInvoice(String id) => '$baseUrl/invoices/$id';
  static String duplicateInvoice(String id) =>
      '$baseUrl/invoices/$id/duplicate';

  /// Invoice Operations
  static const String createInvoice = '$baseUrl/invoices/create';
  static String sendInvoice(String id) => '$baseUrl/invoices/$id/send';
  static String markAsPaid(String id) => '$baseUrl/invoices/$id/mark-paid';
  static String markAsOverdue(String id) =>
      '$baseUrl/invoices/$id/mark-overdue';
  static String addPayment(String id) => '$baseUrl/invoices/$id/payments';

  /// Invoice Templates
  static const String invoiceTemplates = '$baseUrl/invoices/templates';
  static String getInvoiceTemplate(String id) =>
      '$baseUrl/invoices/templates/$id';
  static const String createInvoiceTemplate =
      '$baseUrl/invoices/templates/create';
  static String updateInvoiceTemplate(String id) =>
      '$baseUrl/invoices/templates/$id';
  static String deleteInvoiceTemplate(String id) =>
      '$baseUrl/invoices/templates/$id';

  /// Invoice PDF Generation
  static String generateInvoicePdf(String id) => '$baseUrl/invoices/$id/pdf';
  static String previewInvoice(String id) => '$baseUrl/invoices/$id/preview';

  /// Invoice Search & Filter
  static const String searchInvoices = '$baseUrl/invoices/search';
  static const String filterInvoices = '$baseUrl/invoices/filter';
  static const String overdueInvoices = '$baseUrl/invoices/overdue';
  static const String paidInvoices = '$baseUrl/invoices/paid';
  static const String draftInvoices = '$baseUrl/invoices/drafts';

  /// ==================== CLIENT ENDPOINTS ====================

  /// Client CRUD Operations
  static const String clients = '$baseUrl/clients';
  static String getClient(String id) => '$baseUrl/clients/$id';
  static String updateClient(String id) => '$baseUrl/clients/$id';
  static String deleteClient(String id) => '$baseUrl/clients/$id';

  /// Client Operations
  static const String createClient = '$baseUrl/clients/create';
  static String clientInvoices(String id) => '$baseUrl/clients/$id/invoices';
  static String clientReceipts(String id) => '$baseUrl/clients/$id/receipts';
  static String clientStats(String id) => '$baseUrl/clients/$id/stats';

  /// Client Search
  static const String searchClients = '$baseUrl/clients/search';
  static const String clientSuggestions = '$baseUrl/clients/suggestions';

  /// ==================== CATEGORY ENDPOINTS ====================

  /// Category Management
  static const String categories = '$baseUrl/categories';
  static String getCategory(String id) => '$baseUrl/categories/$id';
  static const String createCategory = '$baseUrl/categories/create';
  static String updateCategory(String id) => '$baseUrl/categories/$id';
  static String deleteCategory(String id) => '$baseUrl/categories/$id';

  /// Category Analytics
  static const String categoryStats = '$baseUrl/categories/stats';
  static String categoryExpenses(String id) =>
      '$baseUrl/categories/$id/expenses';

  /// ==================== REPORTS ENDPOINTS ====================

  /// Report Generation
  static const String reports = '$baseUrl/reports';
  static const String expenseReport = '$baseUrl/reports/expenses';
  static const String incomeReport = '$baseUrl/reports/income';
  static const String profitLossReport = '$baseUrl/reports/profit-loss';
  static const String taxReport = '$baseUrl/reports/tax';
  static const String categoryReport = '$baseUrl/reports/category-breakdown';
  static const String monthlyTrends = '$baseUrl/reports/monthly-trends';
  static const String yearlyComparison = '$baseUrl/reports/yearly-comparison';

  /// Custom Reports
  static const String customReports = '$baseUrl/reports/custom';
  static String getCustomReport(String id) => '$baseUrl/reports/custom/$id';
  static const String createCustomReport = '$baseUrl/reports/custom/create';
  static String updateCustomReport(String id) => '$baseUrl/reports/custom/$id';
  static String deleteCustomReport(String id) => '$baseUrl/reports/custom/$id';

  /// Report Export
  static const String exportReport = '$baseUrl/reports/export';
  static String exportReportPdf(String reportId) =>
      '$baseUrl/reports/$reportId/pdf';
  static String exportReportCsv(String reportId) =>
      '$baseUrl/reports/$reportId/csv';
  static String exportReportExcel(String reportId) =>
      '$baseUrl/reports/$reportId/excel';

  /// ==================== SUBSCRIPTION ENDPOINTS ====================

  /// Subscription Management
  static const String subscription = '$baseUrl/subscription';
  static const String subscriptionPlans = '$baseUrl/subscription/plans';
  static const String currentSubscription = '$baseUrl/subscription/current';
  static const String subscriptionHistory = '$baseUrl/subscription/history';
  static const String upgradeSubscription = '$baseUrl/subscription/upgrade';
  static const String cancelSubscription = '$baseUrl/subscription/cancel';
  static const String renewSubscription = '$baseUrl/subscription/renew';

  /// Billing
  static const String billingHistory = '$baseUrl/billing/history';
  static const String invoiceBilling = '$baseUrl/billing/invoices';
  static const String paymentMethods = '$baseUrl/billing/payment-methods';
  static const String addPaymentMethod = '$baseUrl/billing/payment-methods/add';
  static String deletePaymentMethod(String id) =>
      '$baseUrl/billing/payment-methods/$id';

  /// ==================== SYNC ENDPOINTS ====================

  /// Data Synchronization
  static const String sync = '$baseUrl/sync';
  static const String syncStatus = '$baseUrl/sync/status';
  static const String forcSync = '$baseUrl/sync/force';
  static const String syncQueue = '$baseUrl/sync/queue';
  static const String syncConflicts = '$baseUrl/sync/conflicts';
  static String resolveSyncConflict(String id) =>
      '$baseUrl/sync/conflicts/$id/resolve';

  /// Backup & Restore
  static const String createBackup = '$baseUrl/backup/create';
  static const String restoreBackup = '$baseUrl/backup/restore';
  static const String backupHistory = '$baseUrl/backup/history';
  static String downloadBackup(String id) => '$baseUrl/backup/$id/download';

  /// ==================== CHAT BOT ENDPOINTS ====================

  /// WhatsApp Bot
  static const String whatsappWebhook = '$functionsBaseUrl/whatsappWebhook';
  static const String whatsappBotSendMessage =
      '$functionsBaseUrl/whatsappSendMessage';
  static const String whatsappConnectUser =
      '$baseUrl/integrations/whatsapp/connect';
  static const String whatsappDisconnectUser =
      '$baseUrl/integrations/whatsapp/disconnect';

  /// Telegram Bot
  static const String telegramWebhook = '$functionsBaseUrl/telegramWebhook';
  static const String telegramSendMessageFunction =
      '$functionsBaseUrl/telegramSendMessage';
  static const String telegramConnectUser =
      '$baseUrl/integrations/telegram/connect';
  static const String telegramDisconnectUser =
      '$baseUrl/integrations/telegram/disconnect';

  /// Bot Management
  static const String botSettings = '$baseUrl/integrations/bot/settings';
  static const String botCommands = '$baseUrl/integrations/bot/commands';
  static const String botHistory = '$baseUrl/integrations/bot/history';

  /// ==================== NOTIFICATIONS ENDPOINTS ====================

  /// Push Notifications
  static const String registerDevice = '$baseUrl/notifications/register-device';
  static const String unregisterDevice =
      '$baseUrl/notifications/unregister-device';
  static const String sendNotification = '$baseUrl/notifications/send';
  static const String notificationHistory = '$baseUrl/notifications/history';
  static String markNotificationAsRead(String id) =>
      '$baseUrl/notifications/$id/read';

  /// Email Notifications
  static const String emailSettings = '$baseUrl/notifications/email/settings';
  static const String sendEmail = '$baseUrl/notifications/email/send';
  static const String emailTemplates = '$baseUrl/notifications/email/templates';

  /// ==================== INTEGRATION ENDPOINTS ====================

  /// Third-party Integrations
  static const String integrations = '$baseUrl/integrations';
  static const String availableIntegrations = '$baseUrl/integrations/available';
  static const String connectedIntegrations = '$baseUrl/integrations/connected';
  static String connectIntegration(String provider) =>
      '$baseUrl/integrations/$provider/connect';
  static String disconnectIntegration(String provider) =>
      '$baseUrl/integrations/$provider/disconnect';

  /// Cloud Storage Integrations
  static const String googleDriveIntegration =
      '$baseUrl/integrations/google-drive';
  static const String dropboxIntegration = '$baseUrl/integrations/dropbox';
  static const String oneDriveIntegration = '$baseUrl/integrations/onedrive';

  /// Accounting Software Integrations
  static const String quickbooksIntegration =
      '$baseUrl/integrations/quickbooks';
  static const String xeroIntegration = '$baseUrl/integrations/xero';
  static const String freshbooksIntegration =
      '$baseUrl/integrations/freshbooks';

  /// ==================== ANALYTICS ENDPOINTS ====================

  /// App Analytics
  static const String analytics = '$baseUrl/analytics';
  static const String userEvents = '$baseUrl/analytics/events';
  static const String performanceMetrics = '$baseUrl/analytics/performance';
  static const String crashReports = '$baseUrl/analytics/crashes';
  static const String featureUsage = '$baseUrl/analytics/features';

  /// ==================== ADMIN ENDPOINTS ====================

  /// Admin Panel (for internal use)
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminStats = '$baseUrl/admin/stats';
  static const String adminReports = '$baseUrl/admin/reports';
  static const String adminNotifications = '$baseUrl/admin/notifications';
  static String adminUserDetails(String userId) =>
      '$baseUrl/admin/users/$userId';
  static String suspendUser(String userId) =>
      '$baseUrl/admin/users/$userId/suspend';
  static String activateUser(String userId) =>
      '$baseUrl/admin/users/$userId/activate';

  /// ==================== FIREBASE CLOUD FUNCTIONS ====================

  /// Firebase Functions
  static const String processReceiptFunction =
      '$functionsBaseUrl/processReceipt';
  static const String generateInvoiceFunction =
      '$functionsBaseUrl/generateInvoice';
  static const String sendInvoiceFunction = '$functionsBaseUrl/sendInvoice';
  static const String syncDataFunction = '$functionsBaseUrl/syncData';
  static const String cleanupDataFunction = '$functionsBaseUrl/cleanupData';
  static const String generateReportFunction =
      '$functionsBaseUrl/generateReport';
  static const String processPaymentFunction =
      '$functionsBaseUrl/processPayment';
  static const String scheduleNotificationFunction =
      '$functionsBaseUrl/scheduleNotification';

  /// ==================== FIREBASE COLLECTIONS ====================

  /// Firestore Collection Paths
  static const String usersCollection = 'users';
  static const String receiptsCollection = 'receipts';
  static const String invoicesCollection = 'invoices';
  static const String clientsCollection = 'clients';
  static const String categoriesCollection = 'categories';
  static const String subscriptionsCollection = 'subscriptions';
  static const String syncQueueCollection = 'syncQueue';
  static const String conflictsCollection = 'conflicts';
  static const String notificationsCollection = 'notifications';
  static const String analyticsCollection = 'analytics';
  static const String feedbackCollection = 'feedback';
  static const String supportTicketsCollection = 'supportTickets';
  static const String auditLogsCollection = 'auditLogs';

  /// Firestore Subcollections
  static String userReceipts(String userId) =>
      '$usersCollection/$userId/receipts';
  static String userInvoices(String userId) =>
      '$usersCollection/$userId/invoices';
  static String userClients(String userId) =>
      '$usersCollection/$userId/clients';
  static String userCategories(String userId) =>
      '$usersCollection/$userId/categories';
  static String userPreferencesSubcollection(String userId) =>
      '$usersCollection/$userId/preferences';
  static String userNotifications(String userId) =>
      '$usersCollection/$userId/notifications';
  static String invoicePayments(String invoiceId) =>
      '$invoicesCollection/$invoiceId/payments';
  static String receiptItems(String receiptId) =>
      '$receiptsCollection/$receiptId/items';

  /// ==================== EXTERNAL API ENDPOINTS ====================

  /// Stripe Payment Processing
  static const String stripeCreateCustomer = '$stripeBaseUrl/customers';
  static const String stripeCreateSubscription = '$stripeBaseUrl/subscriptions';
  static const String stripeCreatePaymentIntent =
      '$stripeBaseUrl/payment_intents';
  static const String stripeCreateInvoice = '$stripeBaseUrl/invoices';
  static const String stripeWebhooks = '$stripeBaseUrl/webhook_endpoints';
  static String stripeGetCustomer(String customerId) =>
      '$stripeBaseUrl/customers/$customerId';
  static String stripeUpdateSubscription(String subscriptionId) =>
      '$stripeBaseUrl/subscriptions/$subscriptionId';
  static String stripeCancelSubscription(String subscriptionId) =>
      '$stripeBaseUrl/subscriptions/$subscriptionId';

  /// Google Cloud Vision API
  static const String googleVisionTextDetection =
      '$googleVisionBaseUrl/images:annotate';
  static const String googleVisionDocumentTextDetection =
      '$googleVisionBaseUrl/images:annotateDocument';

  /// WhatsApp Business API
  static String whatsappBusinessSendMessage(String phoneNumberId) =>
      '$whatsappApiBaseUrl/$phoneNumberId/messages';
  static String whatsappUploadMedia(String phoneNumberId) =>
      '$whatsappApiBaseUrl/$phoneNumberId/media';
  static String whatsappGetMedia(String mediaId) =>
      '$whatsappApiBaseUrl/$mediaId';

  /// Telegram Bot API
  static String telegramSendMessageApi(String botToken) =>
      '$telegramApiBaseUrl/bot$botToken/sendMessage';
  static String telegramSendPhoto(String botToken) =>
      '$telegramApiBaseUrl/bot$botToken/sendPhoto';
  static String telegramSendDocument(String botToken) =>
      '$telegramApiBaseUrl/bot$botToken/sendDocument';
  static String telegramGetFile(String botToken) =>
      '$telegramApiBaseUrl/bot$botToken/getFile';
  static String telegramSetWebhook(String botToken) =>
      '$telegramApiBaseUrl/bot$botToken/setWebhook';

  /// ==================== HELPER METHODS ====================

  /// Get user-specific endpoint
  static String getUserEndpoint(String userId, String resource) {
    return '$baseUrl/users/$userId/$resource';
  }

  /// Get paginated endpoint
  static String getPaginatedEndpoint(
    String endpoint, {
    int page = 1,
    int limit = 20,
  }) {
    return '$endpoint?page=$page&limit=$limit';
  }

  /// Get filtered endpoint
  static String getFilteredEndpoint(
    String endpoint,
    Map<String, dynamic> filters,
  ) {
    final queryParams = filters.entries
        .where((entry) => entry.value != null)
        .map(
          (entry) =>
              '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
        )
        .join('&');
    return queryParams.isNotEmpty ? '$endpoint?$queryParams' : endpoint;
  }

  /// Get date range endpoint
  static String getDateRangeEndpoint(
    String endpoint,
    DateTime startDate,
    DateTime endDate,
  ) {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    return '$endpoint?startDate=$start&endDate=$end';
  }

  /// Get search endpoint
  static String getSearchEndpoint(
    String endpoint,
    String query, {
    List<String>? fields,
  }) {
    var searchUrl = '$endpoint?q=${Uri.encodeComponent(query)}';
    if (fields != null && fields.isNotEmpty) {
      searchUrl += '&fields=${fields.join(',')}';
    }
    return searchUrl;
  }

  /// Get file upload endpoint with multipart support
  static String getFileUploadEndpoint(String endpoint, {String? folder}) {
    return folder != null
        ? '$endpoint?folder=${Uri.encodeComponent(folder)}'
        : endpoint;
  }

  /// ==================== API VERSIONING ====================

  /// Version 1 Endpoints (Current)
  static const String apiV1 = '/v1';

  /// Version 2 Endpoints (Future)
  static const String apiV2 = '/v2';

  /// Get versioned endpoint
  static String getVersionedEndpoint(String endpoint, {String version = 'v1'}) {
    return endpoint.replaceFirst('/v1', '/$version');
  }

  /// ==================== ERROR ENDPOINTS ====================

  /// Error Reporting
  static const String reportError = '$baseUrl/errors/report';
  static const String errorLogs = '$baseUrl/errors/logs';
  static const String crashReport = '$baseUrl/errors/crash';

  /// ==================== HEALTH CHECK ENDPOINTS ====================

  /// System Health
  static const String healthCheck = '$baseUrl/health';
  static const String apiStatus = '$baseUrl/status';
  static const String systemInfo = '$baseUrl/system/info';
  static const String databaseHealth = '$baseUrl/health/database';
  static const String storageHealth = '$baseUrl/health/storage';
  static const String functionsHealth = '$baseUrl/health/functions';

  /// ==================== DEVELOPMENT ENDPOINTS ====================

  /// Debug & Testing (Development only)
  static const String debugInfo = '$baseUrl/debug/info';
  static const String testEndpoint = '$baseUrl/test';
  static const String mockData = '$baseUrl/mock';
  static const String resetTestData = '$baseUrl/test/reset';

  /// Performance Testing
  static const String loadTest = '$baseUrl/test/load';
  static const String stressTest = '$baseUrl/test/stress';

  /// ==================== RATE LIMITING INFO ====================

  /// Rate limit headers to check in responses
  static const String rateLimitHeaderTotal = 'X-RateLimit-Limit';
  static const String rateLimitHeaderRemaining = 'X-RateLimit-Remaining';
  static const String rateLimitHeaderReset = 'X-RateLimit-Reset';

  /// ==================== WEBHOOK ENDPOINTS ====================

  /// Webhook Management
  static const String webhooks = '$baseUrl/webhooks';
  static const String createWebhook = '$baseUrl/webhooks/create';
  static String updateWebhook(String id) => '$baseUrl/webhooks/$id';
  static String deleteWebhook(String id) => '$baseUrl/webhooks/$id';
  static String testWebhook(String id) => '$baseUrl/webhooks/$id/test';

  /// Webhook Events
  static const String webhookEvents = '$baseUrl/webhooks/events';
  static const String webhookLogs = '$baseUrl/webhooks/logs';
  static String webhookEventDetails(String eventId) =>
      '$baseUrl/webhooks/events/$eventId';

  /// ==================== FEATURE FLAGS ENDPOINTS ====================

  /// Feature Management
  static const String featureFlags = '$baseUrl/features';
  static const String userFeatures = '$baseUrl/features/user';
  static String enableFeature(String feature) =>
      '$baseUrl/features/$feature/enable';
  static String disableFeature(String feature) =>
      '$baseUrl/features/$feature/disable';
}
