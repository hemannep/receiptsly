// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

/// User entity representing a user in the business domain
/// This is the core business model for users, containing all business rules and logic
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final BusinessProfile businessProfile;
  final Subscription subscription;
  final UserPreferences preferences;
  final Map<String, ChatIntegration> chatIntegrations;
  final UserStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final UserStatus status;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.businessProfile,
    required this.subscription,
    required this.preferences,
    required this.chatIntegrations,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.status = UserStatus.active,
  });

  /// Check if user is fully verified (email and phone if provided)
  bool get isFullyVerified {
    if (phoneNumber != null) {
      return isEmailVerified && isPhoneVerified;
    }
    return isEmailVerified;
  }

  /// Check if user is within their subscription limits
  bool get isWithinSubscriptionLimits {
    return stats.monthlyReceiptCount <= subscription.monthlyReceiptLimit;
  }

  /// Check if subscription is active
  bool get hasActiveSubscription {
    if (subscription.plan == SubscriptionPlan.free) return true;
    return subscription.expiresAt?.isAfter(DateTime.now()) ?? false;
  }

  /// Get remaining receipts this month
  int get remainingReceipts {
    return (subscription.monthlyReceiptLimit - stats.monthlyReceiptCount).clamp(
      0,
      subscription.monthlyReceiptLimit,
    );
  }

  /// Check if user can upload more receipts
  bool get canUploadReceipts {
    return hasActiveSubscription && isWithinSubscriptionLimits;
  }

  /// Get display name (business name if available, otherwise user name)
  String get displayName {
    return businessProfile.businessName.isNotEmpty
        ? businessProfile.businessName
        : name;
  }

  /// Check if user has connected any chat integrations
  bool get hasConnectedChatIntegrations {
    return chatIntegrations.values.any(
      (integration) => integration.isConnected,
    );
  }

  /// Get connected chat platforms
  List<String> get connectedChatPlatforms {
    return chatIntegrations.entries
        .where((entry) => entry.value.isConnected)
        .map((entry) => entry.key)
        .toList();
  }

  /// Business rule: Can user create invoices?
  bool get canCreateInvoices {
    return hasActiveSubscription &&
        businessProfile.isComplete &&
        isEmailVerified;
  }

  /// Business rule: Can user access premium features?
  bool get canAccessPremiumFeatures {
    return subscription.plan != SubscriptionPlan.free && hasActiveSubscription;
  }

  /// Business rule: Can user export data?
  bool get canExportData {
    return hasActiveSubscription;
  }

  /// Copy with method for immutable updates
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    BusinessProfile? businessProfile,
    Subscription? subscription,
    UserPreferences? preferences,
    Map<String, ChatIntegration>? chatIntegrations,
    UserStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    UserStatus? status,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessProfile: businessProfile ?? this.businessProfile,
      subscription: subscription ?? this.subscription,
      preferences: preferences ?? this.preferences,
      chatIntegrations: chatIntegrations ?? this.chatIntegrations,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    phoneNumber,
    profileImageUrl,
    businessProfile,
    subscription,
    preferences,
    chatIntegrations,
    stats,
    createdAt,
    updatedAt,
    isEmailVerified,
    isPhoneVerified,
    status,
  ];

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, name: $name, status: $status)';
  }
}

/// Business profile information
class BusinessProfile extends Equatable {
  final String businessName;
  final BusinessType businessType;
  final String? businessAddress;
  final String? taxId;
  final String country;
  final String currency;
  final String? website;
  final String? logo;

  const BusinessProfile({
    required this.businessName,
    required this.businessType,
    this.businessAddress,
    this.taxId,
    required this.country,
    required this.currency,
    this.website,
    this.logo,
  });

  /// Check if business profile is complete enough for invoicing
  bool get isComplete {
    return businessName.isNotEmpty && country.isNotEmpty && currency.isNotEmpty;
  }

  /// Check if business profile has tax information
  bool get hasTaxInfo {
    return taxId != null && taxId!.isNotEmpty;
  }

  BusinessProfile copyWith({
    String? businessName,
    BusinessType? businessType,
    String? businessAddress,
    String? taxId,
    String? country,
    String? currency,
    String? website,
    String? logo,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessAddress: businessAddress ?? this.businessAddress,
      taxId: taxId ?? this.taxId,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      website: website ?? this.website,
      logo: logo ?? this.logo,
    );
  }

  @override
  List<Object?> get props => [
    businessName,
    businessType,
    businessAddress,
    taxId,
    country,
    currency,
    website,
    logo,
  ];
}

/// User subscription information
class Subscription extends Equatable {
  final SubscriptionPlan plan;
  final DateTime? expiresAt;
  final int monthlyReceiptLimit;
  final int monthlyInvoiceLimit;
  final bool hasAdvancedReports;
  final bool hasApiAccess;
  final bool hasPrioritySupport;
  final SubscriptionStatus status;
  final String? stripeSubscriptionId;
  final DateTime? lastPaymentDate;
  final double? monthlyPrice;

  const Subscription({
    required this.plan,
    this.expiresAt,
    required this.monthlyReceiptLimit,
    required this.monthlyInvoiceLimit,
    this.hasAdvancedReports = false,
    this.hasApiAccess = false,
    this.hasPrioritySupport = false,
    this.status = SubscriptionStatus.active,
    this.stripeSubscriptionId,
    this.lastPaymentDate,
    this.monthlyPrice,
  });

  /// Check if subscription is currently active
  bool get isActive {
    return status == SubscriptionStatus.active &&
        (expiresAt?.isAfter(DateTime.now()) ?? true);
  }

  /// Days until subscription expires
  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  /// Check if subscription is expiring soon (within 7 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 7 && days > 0;
  }

  Subscription copyWith({
    SubscriptionPlan? plan,
    DateTime? expiresAt,
    int? monthlyReceiptLimit,
    int? monthlyInvoiceLimit,
    bool? hasAdvancedReports,
    bool? hasApiAccess,
    bool? hasPrioritySupport,
    SubscriptionStatus? status,
    String? stripeSubscriptionId,
    DateTime? lastPaymentDate,
    double? monthlyPrice,
  }) {
    return Subscription(
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      monthlyReceiptLimit: monthlyReceiptLimit ?? this.monthlyReceiptLimit,
      monthlyInvoiceLimit: monthlyInvoiceLimit ?? this.monthlyInvoiceLimit,
      hasAdvancedReports: hasAdvancedReports ?? this.hasAdvancedReports,
      hasApiAccess: hasApiAccess ?? this.hasApiAccess,
      hasPrioritySupport: hasPrioritySupport ?? this.hasPrioritySupport,
      status: status ?? this.status,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
    );
  }

  @override
  List<Object?> get props => [
    plan,
    expiresAt,
    monthlyReceiptLimit,
    monthlyInvoiceLimit,
    hasAdvancedReports,
    hasApiAccess,
    hasPrioritySupport,
    status,
    stripeSubscriptionId,
    lastPaymentDate,
    monthlyPrice,
  ];
}

/// User preferences and settings
class UserPreferences extends Equatable {
  final String defaultCategory;
  final String defaultCurrency;
  final bool autoSync;
  final bool offlineMode;
  final bool darkMode;
  final NotificationSettings notifications;
  final String language;
  final String timezone;
  final bool autoBackup;
  final double defaultTaxRate;

  const UserPreferences({
    this.defaultCategory = 'General',
    this.defaultCurrency = 'USD',
    this.autoSync = true,
    this.offlineMode = true,
    this.darkMode = false,
    this.notifications = const NotificationSettings(),
    this.language = 'en',
    this.timezone = 'UTC',
    this.autoBackup = true,
    this.defaultTaxRate = 0.0,
  });

  UserPreferences copyWith({
    String? defaultCategory,
    String? defaultCurrency,
    bool? autoSync,
    bool? offlineMode,
    bool? darkMode,
    NotificationSettings? notifications,
    String? language,
    String? timezone,
    bool? autoBackup,
    double? defaultTaxRate,
  }) {
    return UserPreferences(
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      autoSync: autoSync ?? this.autoSync,
      offlineMode: offlineMode ?? this.offlineMode,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      autoBackup: autoBackup ?? this.autoBackup,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
    );
  }

  @override
  List<Object?> get props => [
    defaultCategory,
    defaultCurrency,
    autoSync,
    offlineMode,
    darkMode,
    notifications,
    language,
    timezone,
    autoBackup,
    defaultTaxRate,
  ];
}

/// Notification settings
class NotificationSettings extends Equatable {
  final bool receiptProcessed;
  final bool invoiceCreated;
  final bool paymentReceived;
  final bool subscriptionExpiring;
  final bool weeklyReport;
  final bool monthlyReport;
  final bool chatIntegrationUpdates;

  const NotificationSettings({
    this.receiptProcessed = true,
    this.invoiceCreated = true,
    this.paymentReceived = true,
    this.subscriptionExpiring = true,
    this.weeklyReport = false,
    this.monthlyReport = true,
    this.chatIntegrationUpdates = true,
  });

  NotificationSettings copyWith({
    bool? receiptProcessed,
    bool? invoiceCreated,
    bool? paymentReceived,
    bool? subscriptionExpiring,
    bool? weeklyReport,
    bool? monthlyReport,
    bool? chatIntegrationUpdates,
  }) {
    return NotificationSettings(
      receiptProcessed: receiptProcessed ?? this.receiptProcessed,
      invoiceCreated: invoiceCreated ?? this.invoiceCreated,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      subscriptionExpiring: subscriptionExpiring ?? this.subscriptionExpiring,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      monthlyReport: monthlyReport ?? this.monthlyReport,
      chatIntegrationUpdates:
          chatIntegrationUpdates ?? this.chatIntegrationUpdates,
    );
  }

  @override
  List<Object?> get props => [
    receiptProcessed,
    invoiceCreated,
    paymentReceived,
    subscriptionExpiring,
    weeklyReport,
    monthlyReport,
    chatIntegrationUpdates,
  ];
}

/// Chat integration settings
class ChatIntegration extends Equatable {
  final bool isConnected;
  final String? botId;
  final String? chatId;
  final DateTime? connectedAt;
  final DateTime? lastUsedAt;
  final Map<String, dynamic> settings;

  const ChatIntegration({
    this.isConnected = false,
    this.botId,
    this.chatId,
    this.connectedAt,
    this.lastUsedAt,
    this.settings = const {},
  });

  ChatIntegration copyWith({
    bool? isConnected,
    String? botId,
    String? chatId,
    DateTime? connectedAt,
    DateTime? lastUsedAt,
    Map<String, dynamic>? settings,
  }) {
    return ChatIntegration(
      isConnected: isConnected ?? this.isConnected,
      botId: botId ?? this.botId,
      chatId: chatId ?? this.chatId,
      connectedAt: connectedAt ?? this.connectedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
    isConnected,
    botId,
    chatId,
    connectedAt,
    lastUsedAt,
    settings,
  ];
}

/// User statistics
class UserStats extends Equatable {
  final int totalReceipts;
  final int monthlyReceiptCount;
  final int totalInvoices;
  final int monthlyInvoiceCount;
  final double totalExpenses;
  final double monthlyExpenses;
  final double totalIncome;
  final double monthlyIncome;
  final DateTime lastLoginAt;
  final DateTime lastReceiptAt;
  final DateTime lastInvoiceAt;

  const UserStats({
    this.totalReceipts = 0,
    this.monthlyReceiptCount = 0,
    this.totalInvoices = 0,
    this.monthlyInvoiceCount = 0,
    this.totalExpenses = 0.0,
    this.monthlyExpenses = 0.0,
    this.totalIncome = 0.0,
    this.monthlyIncome = 0.0,
    required this.lastLoginAt,
    required this.lastReceiptAt,
    required this.lastInvoiceAt,
  });

  /// Calculate monthly profit
  double get monthlyProfit {
    return monthlyIncome - monthlyExpenses;
  }

  /// Calculate total profit
  double get totalProfit {
    return totalIncome - totalExpenses;
  }

  UserStats copyWith({
    int? totalReceipts,
    int? monthlyReceiptCount,
    int? totalInvoices,
    int? monthlyInvoiceCount,
    double? totalExpenses,
    double? monthlyExpenses,
    double? totalIncome,
    double? monthlyIncome,
    DateTime? lastLoginAt,
    DateTime? lastReceiptAt,
    DateTime? lastInvoiceAt,
  }) {
    return UserStats(
      totalReceipts: totalReceipts ?? this.totalReceipts,
      monthlyReceiptCount: monthlyReceiptCount ?? this.monthlyReceiptCount,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      monthlyInvoiceCount: monthlyInvoiceCount ?? this.monthlyInvoiceCount,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      totalIncome: totalIncome ?? this.totalIncome,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastReceiptAt: lastReceiptAt ?? this.lastReceiptAt,
      lastInvoiceAt: lastInvoiceAt ?? this.lastInvoiceAt,
    );
  }

  @override
  List<Object?> get props => [
    totalReceipts,
    monthlyReceiptCount,
    totalInvoices,
    monthlyInvoiceCount,
    totalExpenses,
    monthlyExpenses,
    totalIncome,
    monthlyIncome,
    lastLoginAt,
    lastReceiptAt,
    lastInvoiceAt,
  ];
}

/// Enums for user-related data
enum UserStatus { active, inactive, suspended, deleted }

enum BusinessType {
  freelancer,
  consultant,
  contractor,
  smallBusiness,
  retailer,
  restaurant,
  service,
  other,
}

enum SubscriptionPlan { free, basic, premium, enterprise }

enum SubscriptionStatus { active, expired, cancelled, suspended }
