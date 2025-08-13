// lib/data/models/user/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    required String name,
    required String businessName,
    required String businessType,
    required String country,
    required String currency,
    String? phoneNumber,
    String? profileImageUrl,
    String? businessLogo,
    String? businessAddress,
    String? taxId,
    String? website,
    required SubscriptionModel subscription,
    required PreferencesModel preferences,
    required ChatIntegrationsModel chatIntegrations,
    required List<String> categories,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @TimestampConverter() DateTime? lastLoginAt,
    @TimestampConverter() DateTime? emailVerifiedAt,
    @TimestampConverter() DateTime? phoneVerifiedAt,
    @Default(true) bool isActive,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isPhoneVerified,
    @Default(false) bool isTwoFactorEnabled,
    Map<String, dynamic>? metadata,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    @Default('free') String plan,
    @TimestampConverter() DateTime? validUntil,
    @Default(0) int receiptCount,
    @Default(50) int monthlyLimit,
    @Default(0) int invoiceCount,
    @Default(10) int invoiceLimit,
    @Default(0) int clientCount,
    @Default(5) int clientLimit,
    @Default(0) double storageUsed, // in MB
    @Default(100.0) double storageLimit, // in MB
    @Default([]) List<String> features,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    @TimestampConverter() DateTime? lastPaymentAt,
    @TimestampConverter() DateTime? nextBillingAt,
    @Default('active') String status, // active, inactive, cancelled, past_due
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

@freezed
class PreferencesModel with _$PreferencesModel {
  const factory PreferencesModel({
    @Default('General') String defaultCategory,
    @Default(true) bool autoSync,
    @Default(true) bool offlineMode,
    @Default(true) bool notifications,
    @Default('light') String theme, // light, dark, system
    @Default('en') String language,
    @Default('MM/dd/yyyy') String dateFormat,
    @Default('12') String timeFormat, // 12, 24
    @Default(true) bool enableOCR,
    @Default(0.75) double ocrConfidenceThreshold,
    @Default(true) bool autoCategorizeBusiness,
    @Default(30) int invoicePaymentTerms, // days
    @Default(true) bool sendPaymentReminders,
    @Default([7, 14, 30]) List<int> reminderDays,
    @Default(true) bool enableLocationTracking,
    @Default('USD') String defaultCurrency,
    @Default('en_US') String numberFormat,
    @Default(true) bool backupToCloud,
    @Default(7) int backupRetentionDays,
  }) = _PreferencesModel;

  factory PreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$PreferencesModelFromJson(json);
}

@freezed
class ChatIntegrationsModel with _$ChatIntegrationsModel {
  const factory ChatIntegrationsModel({
    required WhatsAppIntegration whatsapp,
    required TelegramIntegration telegram,
    @Default(false) bool slackEnabled,
    String? slackWebhookUrl,
    @Default(false) bool discordEnabled,
    String? discordWebhookUrl,
  }) = _ChatIntegrationsModel;

  factory ChatIntegrationsModel.fromJson(Map<String, dynamic> json) =>
      _$ChatIntegrationsModelFromJson(json);
}

@freezed
class WhatsAppIntegration with _$WhatsAppIntegration {
  const factory WhatsAppIntegration({
    @Default(false) bool connected,
    String? phoneNumber,
    String? qrCode,
    @TimestampConverter() DateTime? connectedAt,
    @TimestampConverter() DateTime? lastUsedAt,
    @Default(true) bool autoProcessReceipts,
    @Default(true) bool sendConfirmations,
    @Default('en') String language,
  }) = _WhatsAppIntegration;

  factory WhatsAppIntegration.fromJson(Map<String, dynamic> json) =>
      _$WhatsAppIntegrationFromJson(json);
}

@freezed
class TelegramIntegration with _$TelegramIntegration {
  const factory TelegramIntegration({
    @Default(false) bool connected,
    String? userId,
    String? chatId,
    String? username,
    @TimestampConverter() DateTime? connectedAt,
    @TimestampConverter() DateTime? lastUsedAt,
    @Default(true) bool autoProcessReceipts,
    @Default(true) bool sendConfirmations,
    @Default('en') String language,
  }) = _TelegramIntegration;

  factory TelegramIntegration.fromJson(Map<String, dynamic> json) =>
      _$TelegramIntegrationFromJson(json);
}

// Custom converter for Firestore Timestamps
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  Object toJson(DateTime dateTime) => Timestamp.fromDate(dateTime);
}
