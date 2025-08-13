// lib/core/constants/asset_paths.dart

/// Asset path constants for Receiptsly
/// Contains all static asset file paths used throughout the application
class AssetPaths {
  // Private constructor to prevent instantiation
  AssetPaths._();

  /// ==================== BASE DIRECTORIES ====================

  /// Root asset directories
  static const String _assetsRoot = 'assets';
  static const String _imagesRoot = '$_assetsRoot/images';
  static const String _iconsRoot = '$_assetsRoot/icons';
  static const String _animationsRoot = '$_assetsRoot/animations';
  static const String _fontsRoot = '$_assetsRoot/fonts';
  static const String _audioRoot = '$_assetsRoot/audio';
  static const String _dataRoot = '$_assetsRoot/data';

  /// ==================== LOGO & BRANDING ====================

  /// App Logos
  static const String logoMain = '$_imagesRoot/logo/receiptsly_logo.png';
  static const String logoMainSvg = '$_imagesRoot/logo/receiptsly_logo.svg';
  static const String logoIcon = '$_imagesRoot/logo/receiptsly_icon.png';
  static const String logoIconSvg = '$_imagesRoot/logo/receiptsly_icon.svg';
  static const String logoHorizontal =
      '$_imagesRoot/logo/receiptsly_horizontal.png';
  static const String logoVertical =
      '$_imagesRoot/logo/receiptsly_vertical.png';
  static const String logoWhite = '$_imagesRoot/logo/receiptsly_logo_white.png';
  static const String logoBlack = '$_imagesRoot/logo/receiptsly_logo_black.png';
  static const String logoTransparent =
      '$_imagesRoot/logo/receiptsly_logo_transparent.png';

  /// Splash Screen Assets
  static const String splashLogo = '$_imagesRoot/splash/splash_logo.png';
  static const String splashBackground =
      '$_imagesRoot/splash/splash_background.png';
  static const String splashIcon = '$_imagesRoot/splash/splash_icon.png';

  /// ==================== ONBOARDING ASSETS ====================

  /// Onboarding Illustrations
  static const String onboardingWelcome =
      '$_imagesRoot/onboarding/welcome_illustration.png';
  static const String onboardingCapture =
      '$_imagesRoot/onboarding/capture_illustration.png';
  static const String onboardingOrganize =
      '$_imagesRoot/onboarding/organize_illustration.png';
  static const String onboardingInvoice =
      '$_imagesRoot/onboarding/invoice_illustration.png';
  static const String onboardingSync =
      '$_imagesRoot/onboarding/sync_illustration.png';
  static const String onboardingComplete =
      '$_imagesRoot/onboarding/complete_illustration.png';

  /// Onboarding Icons
  static const String onboardingStep1 = '$_iconsRoot/onboarding/step_1.svg';
  static const String onboardingStep2 = '$_iconsRoot/onboarding/step_2.svg';
  static const String onboardingStep3 = '$_iconsRoot/onboarding/step_3.svg';
  static const String onboardingStep4 = '$_iconsRoot/onboarding/step_4.svg';

  /// ==================== AUTHENTICATION ASSETS ====================

  /// Auth Illustrations
  static const String authLogin = '$_imagesRoot/auth/login_illustration.png';
  static const String authSignup = '$_imagesRoot/auth/signup_illustration.png';
  static const String authForgotPassword =
      '$_imagesRoot/auth/forgot_password_illustration.png';
  static const String authEmailVerification =
      '$_imagesRoot/auth/email_verification_illustration.png';
  static const String authPhoneVerification =
      '$_imagesRoot/auth/phone_verification_illustration.png';
  static const String authSuccess =
      '$_imagesRoot/auth/success_illustration.png';

  /// Social Login Icons
  static const String googleIcon = '$_iconsRoot/auth/google_icon.svg';
  static const String appleIcon = '$_iconsRoot/auth/apple_icon.svg';
  static const String facebookIcon = '$_iconsRoot/auth/facebook_icon.svg';
  static const String linkedinIcon = '$_iconsRoot/auth/linkedin_icon.svg';

  /// ==================== NAVIGATION ICONS ====================

  /// Bottom Navigation Icons
  static const String navDashboard = '$_iconsRoot/navigation/dashboard.svg';
  static const String navDashboardFilled =
      '$_iconsRoot/navigation/dashboard_filled.svg';
  static const String navReceipts = '$_iconsRoot/navigation/receipts.svg';
  static const String navReceiptsFilled =
      '$_iconsRoot/navigation/receipts_filled.svg';
  static const String navInvoices = '$_iconsRoot/navigation/invoices.svg';
  static const String navInvoicesFilled =
      '$_iconsRoot/navigation/invoices_filled.svg';
  static const String navReports = '$_iconsRoot/navigation/reports.svg';
  static const String navReportsFilled =
      '$_iconsRoot/navigation/reports_filled.svg';
  static const String navSettings = '$_iconsRoot/navigation/settings.svg';
  static const String navSettingsFilled =
      '$_iconsRoot/navigation/settings_filled.svg';

  /// Floating Action Button Icons
  static const String fabAdd = '$_iconsRoot/navigation/add.svg';
  static const String fabCamera = '$_iconsRoot/navigation/camera.svg';
  static const String fabScan = '$_iconsRoot/navigation/scan.svg';
  static const String fabUpload = '$_iconsRoot/navigation/upload.svg';

  /// ==================== FEATURE ICONS ====================

  /// Receipt Icons
  static const String receiptIcon = '$_iconsRoot/features/receipt.svg';
  static const String receiptScan = '$_iconsRoot/features/receipt_scan.svg';
  static const String receiptUpload = '$_iconsRoot/features/receipt_upload.svg';
  static const String receiptProcessing =
      '$_iconsRoot/features/receipt_processing.svg';
  static const String receiptApproved =
      '$_iconsRoot/features/receipt_approved.svg';
  static const String receiptRejected =
      '$_iconsRoot/features/receipt_rejected.svg';

  /// Invoice Icons
  static const String invoiceIcon = '$_iconsRoot/features/invoice.svg';
  static const String invoiceCreate = '$_iconsRoot/features/invoice_create.svg';
  static const String invoiceSend = '$_iconsRoot/features/invoice_send.svg';
  static const String invoicePaid = '$_iconsRoot/features/invoice_paid.svg';
  static const String invoiceOverdue =
      '$_iconsRoot/features/invoice_overdue.svg';
  static const String invoiceDraft = '$_iconsRoot/features/invoice_draft.svg';

  /// Client Icons
  static const String clientIcon = '$_iconsRoot/features/client.svg';
  static const String clientAdd = '$_iconsRoot/features/client_add.svg';
  static const String clientManage = '$_iconsRoot/features/client_manage.svg';

  /// Report Icons
  static const String reportIcon = '$_iconsRoot/features/report.svg';
  static const String reportChart = '$_iconsRoot/features/report_chart.svg';
  static const String reportExport = '$_iconsRoot/features/report_export.svg';
  static const String reportAnalytics =
      '$_iconsRoot/features/report_analytics.svg';

  /// ==================== CATEGORY ICONS ====================

  /// Expense Category Icons
  static const String categoryFood = '$_iconsRoot/categories/food_dining.svg';
  static const String categoryTransport =
      '$_iconsRoot/categories/transportation.svg';
  static const String categoryOffice =
      '$_iconsRoot/categories/office_supplies.svg';
  static const String categoryTechnology =
      '$_iconsRoot/categories/technology.svg';
  static const String categoryProfessional =
      '$_iconsRoot/categories/professional_services.svg';
  static const String categoryMarketing =
      '$_iconsRoot/categories/marketing.svg';
  static const String categoryTravel = '$_iconsRoot/categories/travel.svg';
  static const String categoryUtilities =
      '$_iconsRoot/categories/utilities.svg';
  static const String categoryEquipment =
      '$_iconsRoot/categories/equipment.svg';
  static const String categoryGeneral = '$_iconsRoot/categories/general.svg';
  static const String categoryEducation =
      '$_iconsRoot/categories/education.svg';
  static const String categoryHealth = '$_iconsRoot/categories/health.svg';
  static const String categoryEntertainment =
      '$_iconsRoot/categories/entertainment.svg';

  /// ==================== STATUS ICONS ====================

  /// General Status Icons
  static const String statusSuccess = '$_iconsRoot/status/success.svg';
  static const String statusError = '$_iconsRoot/status/error.svg';
  static const String statusWarning = '$_iconsRoot/status/warning.svg';
  static const String statusInfo = '$_iconsRoot/status/info.svg';
  static const String statusPending = '$_iconsRoot/status/pending.svg';
  static const String statusProcessing = '$_iconsRoot/status/processing.svg';

  /// Connection Status Icons
  static const String statusOnline = '$_iconsRoot/status/online.svg';
  static const String statusOffline = '$_iconsRoot/status/offline.svg';
  static const String statusSyncing = '$_iconsRoot/status/syncing.svg';
  static const String statusSynced = '$_iconsRoot/status/synced.svg';

  /// ==================== ACTION ICONS ====================

  /// Common Actions
  static const String actionEdit = '$_iconsRoot/actions/edit.svg';
  static const String actionDelete = '$_iconsRoot/actions/delete.svg';
  static const String actionShare = '$_iconsRoot/actions/share.svg';
  static const String actionDownload = '$_iconsRoot/actions/download.svg';
  static const String actionUpload = '$_iconsRoot/actions/upload.svg';
  static const String actionCopy = '$_iconsRoot/actions/copy.svg';
  static const String actionPrint = '$_iconsRoot/actions/print.svg';
  static const String actionSearch = '$_iconsRoot/actions/search.svg';
  static const String actionFilter = '$_iconsRoot/actions/filter.svg';
  static const String actionSort = '$_iconsRoot/actions/sort.svg';
  static const String actionRefresh = '$_iconsRoot/actions/refresh.svg';
  static const String actionSync = '$_iconsRoot/actions/sync.svg';
  static const String actionSettings = '$_iconsRoot/actions/settings.svg';
  static const String actionHelp = '$_iconsRoot/actions/help.svg';
  static const String actionClose = '$_iconsRoot/actions/close.svg';
  static const String actionBack = '$_iconsRoot/actions/back.svg';
  static const String actionForward = '$_iconsRoot/actions/forward.svg';
  static const String actionExpand = '$_iconsRoot/actions/expand.svg';
  static const String actionCollapse = '$_iconsRoot/actions/collapse.svg';

  /// File Actions
  static const String actionExportPdf = '$_iconsRoot/actions/export_pdf.svg';
  static const String actionExportCsv = '$_iconsRoot/actions/export_csv.svg';
  static const String actionExportExcel =
      '$_iconsRoot/actions/export_excel.svg';

  /// ==================== COMMUNICATION ICONS ====================

  /// Chat & Messaging
  static const String whatsappIcon = '$_iconsRoot/communication/whatsapp.svg';
  static const String telegramIcon = '$_iconsRoot/communication/telegram.svg';
  static const String emailIcon = '$_iconsRoot/communication/email.svg';
  static const String smsIcon = '$_iconsRoot/communication/sms.svg';
  static const String chatIcon = '$_iconsRoot/communication/chat.svg';
  static const String notificationIcon =
      '$_iconsRoot/communication/notification.svg';

  /// ==================== PAYMENT ICONS ====================

  /// Payment Methods
  static const String creditCardIcon = '$_iconsRoot/payment/credit_card.svg';
  static const String debitCardIcon = '$_iconsRoot/payment/debit_card.svg';
  static const String paypalIcon = '$_iconsRoot/payment/paypal.svg';
  static const String stripeIcon = '$_iconsRoot/payment/stripe.svg';
  static const String bankTransferIcon =
      '$_iconsRoot/payment/bank_transfer.svg';
  static const String cashIcon = '$_iconsRoot/payment/cash.svg';

  /// Currency Icons
  static const String currencyUsd = '$_iconsRoot/currency/usd.svg';
  static const String currencyEur = '$_iconsRoot/currency/eur.svg';
  static const String currencyGbp = '$_iconsRoot/currency/gbp.svg';
  static const String currencyJpy = '$_iconsRoot/currency/jpy.svg';
  static const String currencyInr = '$_iconsRoot/currency/inr.svg';
  static const String currencyCad = '$_iconsRoot/currency/cad.svg';
  static const String currencyAud = '$_iconsRoot/currency/aud.svg';

  /// ==================== INTEGRATION ICONS ====================

  /// Third-party Integrations
  static const String googleDriveIcon =
      '$_iconsRoot/integrations/google_drive.svg';
  static const String dropboxIcon = '$_iconsRoot/integrations/dropbox.svg';
  static const String oneDriveIcon = '$_iconsRoot/integrations/onedrive.svg';
  static const String quickbooksIcon =
      '$_iconsRoot/integrations/quickbooks.svg';
  static const String xeroIcon = '$_iconsRoot/integrations/xero.svg';
  static const String freshbooksIcon =
      '$_iconsRoot/integrations/freshbooks.svg';
  static const String slackIcon = '$_iconsRoot/integrations/slack.svg';
  static const String zapierIcon = '$_iconsRoot/integrations/zapier.svg';

  /// ==================== EMPTY STATE ILLUSTRATIONS ====================

  /// Empty States
  static const String emptyReceipts =
      '$_imagesRoot/empty_states/empty_receipts.png';
  static const String emptyInvoices =
      '$_imagesRoot/empty_states/empty_invoices.png';
  static const String emptyClients =
      '$_imagesRoot/empty_states/empty_clients.png';
  static const String emptyReports =
      '$_imagesRoot/empty_states/empty_reports.png';
  static const String emptySearch =
      '$_imagesRoot/empty_states/empty_search.png';
  static const String noInternet = '$_imagesRoot/empty_states/no_internet.png';
  static const String serverError =
      '$_imagesRoot/empty_states/server_error.png';
  static const String maintenanceMode =
      '$_imagesRoot/empty_states/maintenance.png';

  /// ==================== BACKGROUND IMAGES ====================

  /// Backgrounds
  static const String backgroundPattern =
      '$_imagesRoot/backgrounds/pattern.png';
  static const String backgroundGradient =
      '$_imagesRoot/backgrounds/gradient.png';
  static const String backgroundAuth =
      '$_imagesRoot/backgrounds/auth_background.png';
  static const String backgroundOnboarding =
      '$_imagesRoot/backgrounds/onboarding_background.png';
  static const String backgroundDashboard =
      '$_imagesRoot/backgrounds/dashboard_background.png';

  /// ==================== ANIMATIONS ====================

  /// Lottie Animations
  static const String animationLoading = '$_animationsRoot/loading.json';
  static const String animationSuccess = '$_animationsRoot/success.json';
  static const String animationError = '$_animationsRoot/error.json';
  static const String animationUploading = '$_animationsRoot/uploading.json';
  static const String animationProcessing = '$_animationsRoot/processing.json';
  static const String animationSyncing = '$_animationsRoot/syncing.json';
  static const String animationEmptyState = '$_animationsRoot/empty_state.json';
  static const String animationCelebration =
      '$_animationsRoot/celebration.json';
  static const String animationScanReceipt =
      '$_animationsRoot/scan_receipt.json';
  static const String animationInvoiceSent =
      '$_animationsRoot/invoice_sent.json';
  static const String animationDataSync = '$_animationsRoot/data_sync.json';
  static const String animationWelcome = '$_animationsRoot/welcome.json';
  static const String animationSearching = '$_animationsRoot/searching.json';

  /// Rive Animations
  static const String riveLogoAnimation = '$_animationsRoot/logo_animation.riv';
  static const String riveOnboardingFlow =
      '$_animationsRoot/onboarding_flow.riv';
  static const String riveReceiptScan = '$_animationsRoot/receipt_scan.riv';

  /// ==================== AUDIO FILES ====================

  /// Sound Effects
  static const String soundCameraShutter = '$_audioRoot/camera_shutter.mp3';
  static const String soundNotification = '$_audioRoot/notification.mp3';
  static const String soundSuccess = '$_audioRoot/success.mp3';
  static const String soundError = '$_audioRoot/error.mp3';
  static const String soundUploadComplete = '$_audioRoot/upload_complete.mp3';
  static const String soundInvoiceSent = '$_audioRoot/invoice_sent.mp3';

  /// ==================== DATA FILES ====================

  /// JSON Data Files
  static const String countriesData = '$_dataRoot/countries.json';
  static const String currenciesData = '$_dataRoot/currencies.json';
  static const String timezonesData = '$_dataRoot/timezones.json';
  static const String categoriesData = '$_dataRoot/default_categories.json';
  static const String invoiceTemplatesData =
      '$_dataRoot/invoice_templates.json';
  static const String businessTypesData = '$_dataRoot/business_types.json';
  static const String taxRatesData = '$_dataRoot/tax_rates.json';

  /// ==================== FONTS ====================

  /// Custom Fonts
  static const String fontPrimary = 'Inter';
  static const String fontSecondary = 'Roboto';
  static const String fontDisplay = 'Poppins';
  static const String fontMono = 'RobotoMono';

  /// Font Files
  static const String fontInterRegular = '$_fontsRoot/Inter-Regular.ttf';
  static const String fontInterMedium = '$_fontsRoot/Inter-Medium.ttf';
  static const String fontInterSemiBold = '$_fontsRoot/Inter-SemiBold.ttf';
  static const String fontInterBold = '$_fontsRoot/Inter-Bold.ttf';

  static const String fontPoppinsRegular = '$_fontsRoot/Poppins-Regular.ttf';
  static const String fontPoppinsMedium = '$_fontsRoot/Poppins-Medium.ttf';
  static const String fontPoppinsSemiBold = '$_fontsRoot/Poppins-SemiBold.ttf';
  static const String fontPoppinsBold = '$_fontsRoot/Poppins-Bold.ttf';

  /// ==================== HELPER METHODS ====================

  /// Get category icon by name
  static String getCategoryIcon(String categoryName) {
    switch (categoryName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('&', 'and')) {
      case 'food_and_dining':
        return categoryFood;
      case 'transportation':
        return categoryTransport;
      case 'office_supplies':
        return categoryOffice;
      case 'software_and_technology':
        return categoryTechnology;
      case 'professional_services':
        return categoryProfessional;
      case 'marketing_and_advertising':
        return categoryMarketing;
      case 'travel_and_accommodation':
        return categoryTravel;
      case 'utilities':
        return categoryUtilities;
      case 'equipment':
        return categoryEquipment;
      case 'education':
        return categoryEducation;
      case 'health':
        return categoryHealth;
      case 'entertainment':
        return categoryEntertainment;
      default:
        return categoryGeneral;
    }
  }

  /// Get currency icon by code
  static String getCurrencyIcon(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return currencyUsd;
      case 'EUR':
        return currencyEur;
      case 'GBP':
        return currencyGbp;
      case 'JPY':
        return currencyJpy;
      case 'INR':
        return currencyInr;
      case 'CAD':
        return currencyCad;
      case 'AUD':
        return currencyAud;
      default:
        return currencyUsd;
    }
  }

  /// Get status icon by status
  static String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'approved':
      case 'paid':
        return statusSuccess;
      case 'error':
      case 'failed':
      case 'rejected':
        return statusError;
      case 'warning':
      case 'overdue':
        return statusWarning;
      case 'info':
      case 'draft':
        return statusInfo;
      case 'pending':
      case 'reviewing':
        return statusPending;
      case 'processing':
      case 'uploading':
        return statusProcessing;
      default:
        return statusInfo;
    }
  }

  /// Get invoice status icon
  static String getInvoiceStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return invoicePaid;
      case 'overdue':
        return invoiceOverdue;
      case 'draft':
        return invoiceDraft;
      case 'sent':
        return invoiceSend;
      default:
        return invoiceIcon;
    }
  }

  /// Get file export icon by format
  static String getExportIcon(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return actionExportPdf;
      case 'csv':
        return actionExportCsv;
      case 'excel':
      case 'xlsx':
        return actionExportExcel;
      default:
        return actionDownload;
    }
  }

  /// Get integration icon by provider
  static String getIntegrationIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'whatsapp':
        return whatsappIcon;
      case 'telegram':
        return telegramIcon;
      case 'google_drive':
        return googleDriveIcon;
      case 'dropbox':
        return dropboxIcon;
      case 'onedrive':
        return oneDriveIcon;
      case 'quickbooks':
        return quickbooksIcon;
      case 'xero':
        return xeroIcon;
      case 'freshbooks':
        return freshbooksIcon;
      case 'slack':
        return slackIcon;
      case 'zapier':
        return zapierIcon;
      default:
        return actionSettings;
    }
  }

  /// Get payment method icon
  static String getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'credit_card':
        return creditCardIcon;
      case 'debit_card':
        return debitCardIcon;
      case 'paypal':
        return paypalIcon;
      case 'stripe':
        return stripeIcon;
      case 'bank_transfer':
        return bankTransferIcon;
      case 'cash':
        return cashIcon;
      default:
        return creditCardIcon;
    }
  }

  /// Check if asset exists (for development purposes)
  static bool assetExists(String assetPath) {
    // This would be implemented with proper asset checking in production
    return assetPath.isNotEmpty;
  }

  /// Get asset based on theme (light/dark)
  static String getThemedAsset(
    String lightAsset,
    String darkAsset,
    bool isDarkTheme,
  ) {
    return isDarkTheme ? darkAsset : lightAsset;
  }

  /// Get responsive asset based on screen size
  static String getResponsiveAsset(String baseAsset, String size) {
    final extension = baseAsset.split('.').last;
    final baseName = baseAsset.replaceAll('.$extension', '');
    return '${baseName}_$size.$extension';
  }
}
