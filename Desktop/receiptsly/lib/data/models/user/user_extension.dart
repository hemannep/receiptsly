// lib/data/models/user/user_extension.dart
import 'package:receiptsly/core/router/route_guards.dart';

extension UserModelExtension on UserModel {
  /// Checks if the user has an active subscription
  bool get hasActiveSubscription {
    final now = DateTime.now();
    return subscription.validUntil != null &&
        subscription.validUntil!.isAfter(now) &&
        subscription.status == 'active';
  }

  /// Checks if the user is on a free plan
  bool get isOnFreePlan => subscription.plan == 'free';

  /// Checks if the user is on a premium plan
  bool get isOnPremiumPlan =>
      subscription.plan == 'premium' || subscription.plan == 'pro';

  /// Gets the number of days until subscription expires
  int get daysUntilExpiry {
    if (subscription.validUntil == null) return 0;
    final now = DateTime.now();
    final difference = subscription.validUntil!.difference(now);
    return difference.inDays;
  }

  /// Checks if subscription is expiring soon (within 7 days)
  bool get isSubscriptionExpiringSoon {
    return hasActiveSubscription && daysUntilExpiry <= 7;
  }

  /// Gets the user's display name (prioritizes business name)
  String get displayName {
    if (businessName.isNotEmpty) return businessName;
    return name;
  }

  /// Gets the user's initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  /// Checks if user profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        businessName.isNotEmpty &&
        country.isNotEmpty &&
        currency.isNotEmpty;
  }

  /// Gets completion percentage of user profile
  double get profileCompletionPercentage {
    int completedFields = 0;
    const int totalFields = 8;

    if (name.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (businessName.isNotEmpty) completedFields++;
    if (businessType.isNotEmpty) completedFields++;
    if (country.isNotEmpty) completedFields++;
    if (currency.isNotEmpty) completedFields++;
    if (phoneNumber?.isNotEmpty == true) completedFields++;
    if (businessAddress?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }

  /// Checks if user can upload more receipts
  bool get canUploadReceipts {
    if (hasActiveSubscription) return true;
    return subscription.receiptCount < subscription.monthlyLimit;
  }

  /// Gets remaining receipt uploads for current period
  int get remainingReceiptUploads {
    if (hasActiveSubscription) return 999; // Unlimited for premium
    return subscription.monthlyLimit - subscription.receiptCount;
  }

  /// Checks if user can create more invoices
  bool get canCreateInvoices {
    if (hasActiveSubscription) return true;
    return subscription.invoiceCount < subscription.invoiceLimit;
  }

  /// Gets remaining invoice creations for current period
  int get remainingInvoiceCreations {
    if (hasActiveSubscription) return 999; // Unlimited for premium
    return subscription.invoiceLimit - subscription.invoiceCount;
  }

  /// Checks if user can add more clients
  bool get canAddClients {
    if (hasActiveSubscription) return true;
    return subscription.clientCount < subscription.clientLimit;
  }

  /// Gets remaining client additions
  int get remainingClientAdditions {
    if (hasActiveSubscription) return 999; // Unlimited for premium
    return subscription.clientLimit - subscription.clientCount;
  }

  /// Gets storage usage percentage
  double get storageUsagePercentage {
    if (subscription.storageLimit == 0) return 0;
    return subscription.storageUsed / subscription.storageLimit;
  }

  /// Checks if storage is nearly full (>80%)
  bool get isStorageNearlyFull => storageUsagePercentage > 0.8;

  /// Checks if storage is full (>95%)
  bool get isStorageFull => storageUsagePercentage > 0.95;

  /// Gets formatted storage usage string
  String get formattedStorageUsage {
    final used = subscription.storageUsed;
    final limit = subscription.storageLimit;

    if (used < 1024) {
      return '${used.toStringAsFixed(1)} MB / ${limit.toStringAsFixed(0)} MB';
    } else {
      final usedGB = used / 1024;
      final limitGB = limit / 1024;
      return '${usedGB.toStringAsFixed(1)} GB / ${limitGB.toStringAsFixed(1)} GB';
    }
  }

  /// Checks if user has any chat integrations connected
  bool get hasChatIntegrations {
    return chatIntegrations.whatsapp.connected ||
        chatIntegrations.telegram.connected;
  }

  /// Gets list of connected chat platforms
  List<String> get connectedChatPlatforms {
    final platforms = <String>[];
    if (chatIntegrations.whatsapp.connected) platforms.add('WhatsApp');
    if (chatIntegrations.telegram.connected) platforms.add('Telegram');
    return platforms;
  }

  /// Checks if user has verified contact information
  bool get hasVerifiedContact {
    return isEmailVerified || isPhoneVerified;
  }

  /// Gets user's timezone based on country (simplified)
  String get timezone {
    switch (country.toUpperCase()) {
      case 'US':
      case 'USA':
        return 'America/New_York';
      case 'UK':
      case 'GB':
        return 'Europe/London';
      case 'DE':
      case 'GERMANY':
        return 'Europe/Berlin';
      case 'IN':
      case 'INDIA':
        return 'Asia/Kolkata';
      case 'JP':
      case 'JAPAN':
        return 'Asia/Tokyo';
      case 'AU':
      case 'AUSTRALIA':
        return 'Australia/Sydney';
      case 'CA':
      case 'CANADA':
        return 'America/Toronto';
      case 'NP':
      case 'NEPAL':
        return 'Asia/Kathmandu';
      default:
        return 'UTC';
    }
  }

  /// Creates a new instance with updated subscription
  UserModel updateSubscription(SubscriptionModel newSubscription) {
    return copyWith(subscription: newSubscription, updatedAt: DateTime.now());
  }

  /// Creates a new instance with updated preferences
  UserModel updatePreferences(PreferencesModel newPreferences) {
    return copyWith(preferences: newPreferences, updatedAt: DateTime.now());
  }

  /// Creates a new instance with updated chat integrations
  UserModel updateChatIntegrations(ChatIntegrationsModel newIntegrations) {
    return copyWith(
      chatIntegrations: newIntegrations,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a new instance marking email as verified
  UserModel markEmailVerified() {
    return copyWith(
      isEmailVerified: true,
      emailVerifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a new instance marking phone as verified
  UserModel markPhoneVerified() {
    return copyWith(
      isPhoneVerified: true,
      phoneVerifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a new instance with updated last login
  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now(), updatedAt: DateTime.now());
  }

  /// Converts to map for Firestore
  Map<String, dynamic> toFirestore() {
    final json = toJson();

    // Convert DateTime objects to Timestamps for Firestore
    json['createdAt'] = TimestampConverter().toJson(createdAt);
    json['updatedAt'] = TimestampConverter().toJson(updatedAt);

    if (lastLoginAt != null) {
      json['lastLoginAt'] = TimestampConverter().toJson(lastLoginAt!);
    }
    if (emailVerifiedAt != null) {
      json['emailVerifiedAt'] = TimestampConverter().toJson(emailVerifiedAt!);
    }
    if (phoneVerifiedAt != null) {
      json['phoneVerifiedAt'] = TimestampConverter().toJson(phoneVerifiedAt!);
    }

    return json;
  }

  /// Creates UserModel from Firestore document
  static UserModel fromFirestore(Map<String, dynamic> data) {
    return UserModel.fromJson(data);
  }
}
