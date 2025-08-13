// lib/data/models/client/client_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:receiptsly_mobile/data/models/user/user_model.dart';

part 'client_model.freezed.dart';
part 'client_model.g.dart';

@freezed
class ClientModel with _$ClientModel {
  const factory ClientModel({
    required String id,
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? company,
    String? website,
    String? vatNumber,
    String? taxId,
    String? registrationNumber,
    required ClientAddressModel address,
    required ClientBillingModel billing,
    required ClientContactModel contact,
    required List<String> tags,
    String? notes,
    String? profileImage,
    @Default('active') String status, // active, inactive, archived
    @Default('USD') String currency,
    @Default('en') String language,
    @Default(30) int defaultPaymentTerms, // days
    @Default(0.0) double defaultHourlyRate,
    @Default(0.0) double totalBilled,
    @Default(0.0) double totalPaid,
    @Default(0.0) double outstandingBalance,
    @Default(0) int totalInvoices,
    @Default(0) int paidInvoices,
    @Default(0) int overdueInvoices,
    @TimestampConverter() DateTime? lastInvoiceDate,
    @TimestampConverter() DateTime? lastPaymentDate,
    @TimestampConverter() DateTime? lastContactDate,
    required Map<String, dynamic> customFields,
    required ClientPreferencesModel preferences,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @Default(1) int version,
  }) = _ClientModel;

  factory ClientModel.fromJson(Map<String, dynamic> json) =>
      _$ClientModelFromJson(json);
}

@freezed
class ClientAddressModel with _$ClientAddressModel {
  const factory ClientAddressModel({
    @Default('') String street,
    @Default('') String street2,
    @Default('') String city,
    @Default('') String state,
    @Default('') String postalCode,
    @Default('') String country,
    @Default(false) bool isPrimary,
    @Default('billing') String type, // billing, shipping, office
  }) = _ClientAddressModel;

  factory ClientAddressModel.fromJson(Map<String, dynamic> json) =>
      _$ClientAddressModelFromJson(json);
}

@freezed
class ClientBillingModel with _$ClientBillingModel {
  const factory ClientBillingModel({
    @Default('email') String preferredMethod, // email, postal, whatsapp
    @Default(true) bool sendReminders,
    @Default([7, 14, 30]) List<int> reminderDays,
    @Default('net30') String paymentTerms,
    @Default([]) List<String> acceptedPaymentMethods,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
    String? iban,
    String? swiftCode,
    Map<String, dynamic>? paymentGatewaySettings,
  }) = _ClientBillingModel;

  factory ClientBillingModel.fromJson(Map<String, dynamic> json) =>
      _$ClientBillingModelFromJson(json);
}

@freezed
class ClientContactModel with _$ClientContactModel {
  const factory ClientContactModel({
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? primaryContactTitle,
    @Default([]) List<ClientContactPersonModel> additionalContacts,
    String? preferredContactMethod, // email, phone, whatsapp
    String? timezone,
    String? workingHoursStart,
    String? workingHoursEnd,
    @Default([]) List<String> workingDays, // mon, tue, wed, etc.
  }) = _ClientContactModel;

  factory ClientContactModel.fromJson(Map<String, dynamic> json) =>
      _$ClientContactModelFromJson(json);
}

@freezed
class ClientContactPersonModel with _$ClientContactPersonModel {
  const factory ClientContactPersonModel({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? title,
    String? department,
    @Default(false) bool isPrimary,
    @Default('active') String status,
    Map<String, dynamic>? notes,
  }) = _ClientContactPersonModel;

  factory ClientContactPersonModel.fromJson(Map<String, dynamic> json) =>
      _$ClientContactPersonModelFromJson(json);
}

@freezed
class ClientPreferencesModel with _$ClientPreferencesModel {
  const factory ClientPreferencesModel({
    @Default(true) bool enableNotifications,
    @Default(true) bool enableEmailReminders,
    @Default(false) bool enableSmsReminders,
    @Default(false) bool enableWhatsappReminders,
    @Default('pdf') String invoiceFormat, // pdf, html
    @Default('detailed') String invoiceTemplate, // minimal, detailed, custom
    @Default(false) bool autoSendInvoices,
    @Default(false) bool requirePurchaseOrder,
    @Default(false) bool enableLateFees,
    @Default(0.0) double lateFeePercentage,
    @Default(0.0) double lateFeeFixed,
    Map<String, dynamic>? customSettings,
  }) = _ClientPreferencesModel;

  factory ClientPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$ClientPreferencesModelFromJson(json);
}

// Extension methods for ClientModel
extension ClientModelExtension on ClientModel {
  /// Get the client's display name (company or personal name)
  String get displayName {
    if (company?.isNotEmpty == true) {
      return company!;
    }
    return name;
  }

  /// Get client's initials for avatar
  String get initials {
    final displayName = this.displayName;
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'C';
  }

  /// Check if client profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        address.street.isNotEmpty &&
        address.city.isNotEmpty &&
        address.country.isNotEmpty;
  }

  /// Get completion percentage of client profile
  double get profileCompletionPercentage {
    int completedFields = 0;
    const int totalFields = 10;

    if (name.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (phone?.isNotEmpty == true) completedFields++;
    if (company?.isNotEmpty == true) completedFields++;
    if (address.street.isNotEmpty) completedFields++;
    if (address.city.isNotEmpty) completedFields++;
    if (address.country.isNotEmpty) completedFields++;
    if (contact.primaryContactName?.isNotEmpty == true) completedFields++;
    if (billing.preferredMethod.isNotEmpty) completedFields++;
    if (tags.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  /// Check if client is active
  bool get isActive => status == 'active';

  /// Check if client is archived
  bool get isArchived => status == 'archived';

  /// Get payment terms in days
  int get paymentTermsInDays {
    final terms = billing.paymentTerms;
    if (terms.startsWith('net')) {
      return int.tryParse(terms.substring(3)) ?? defaultPaymentTerms;
    }
    return defaultPaymentTerms;
  }

  /// Calculate average days to payment
  double get averageDaysToPayment {
    if (paidInvoices == 0) return 0.0;
    // This would typically be calculated from actual payment history
    // For now, return a placeholder
    return paymentTermsInDays * 0.8; // Assume 80% of payment terms on average
  }

  /// Get payment reliability score (0-100)
  int get paymentReliabilityScore {
    if (totalInvoices == 0) return 100; // New client, assume good

    final paidPercentage = (paidInvoices / totalInvoices) * 100;
    final overduePercentage = (overdueInvoices / totalInvoices) * 100;

    // Simple scoring algorithm
    int score = paidPercentage.round();
    score -= (overduePercentage * 2).round(); // Penalize overdue more

    return score.clamp(0, 100);
  }

  /// Get payment reliability label
  String get paymentReliabilityLabel {
    final score = paymentReliabilityScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Very Poor';
  }

  /// Check if client has overdue invoices
  bool get hasOverdueInvoices => overdueInvoices > 0;

  /// Check if client has outstanding balance
  bool get hasOutstandingBalance => outstandingBalance > 0;

  /// Get formatted full address
  String get formattedAddress {
    final parts = <String>[];

    if (address.street.isNotEmpty) parts.add(address.street);
    if (address.street2.isNotEmpty) parts.add(address.street2);

    final cityState = <String>[];
    if (address.city.isNotEmpty) cityState.add(address.city);
    if (address.state.isNotEmpty) cityState.add(address.state);
    if (cityState.isNotEmpty) parts.add(cityState.join(', '));

    if (address.postalCode.isNotEmpty) parts.add(address.postalCode);
    if (address.country.isNotEmpty) parts.add(address.country);

    return parts.join('\n');
  }

  /// Get primary contact information
  String get primaryContactInfo {
    final contact = this.contact;
    if (contact.primaryContactName?.isNotEmpty == true) {
      return contact.primaryContactName!;
    }
    return name;
  }

  /// Get best contact method for this client
  String get bestContactMethod {
    final contact = this.contact;
    if (contact.preferredContactMethod?.isNotEmpty == true) {
      return contact.preferredContactMethod!;
    }

    // Default priority: email > phone > whatsapp
    if (email.isNotEmpty) return 'email';
    if (phone?.isNotEmpty == true) return 'phone';
    return 'email';
  }

  /// Check if client can be contacted via WhatsApp
  bool get canContactViaWhatsApp {
    return phone?.isNotEmpty == true && billing.preferredMethod == 'whatsapp';
  }

  /// Get next reminder date based on preferences
  DateTime? getNextReminderDate(DateTime invoiceDueDate) {
    if (!billing.sendReminders || billing.reminderDays.isEmpty) {
      return null;
    }

    final firstReminderDays = billing.reminderDays.first;
    return invoiceDueDate.subtract(Duration(days: firstReminderDays));
  }

  /// Create a copy with updated financial data
  ClientModel updateFinancials({
    double? totalBilled,
    double? totalPaid,
    double? outstandingBalance,
    int? totalInvoices,
    int? paidInvoices,
    int? overdueInvoices,
    DateTime? lastInvoiceDate,
    DateTime? lastPaymentDate,
  }) {
    return copyWith(
      totalBilled: totalBilled ?? this.totalBilled,
      totalPaid: totalPaid ?? this.totalPaid,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      paidInvoices: paidInvoices ?? this.paidInvoices,
      overdueInvoices: overdueInvoices ?? this.overdueInvoices,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated contact date
  ClientModel updateLastContact() {
    return copyWith(lastContactDate: DateTime.now(), updatedAt: DateTime.now());
  }

  /// Validate the client model
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Client name is required');
    }

    if (email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors.add('Invalid email format');
    }

    if (phone?.isNotEmpty == true &&
        !RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone!)) {
      errors.add('Invalid phone number format');
    }

    if (defaultPaymentTerms < 0 || defaultPaymentTerms > 365) {
      errors.add('Payment terms must be between 0 and 365 days');
    }

    if (defaultHourlyRate < 0) {
      errors.add('Hourly rate cannot be negative');
    }

    return errors;
  }

  /// Check if the client is valid
  bool get isValid => validate().isEmpty;

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    final json = toJson();

    // Convert DateTime objects to Timestamps for Firestore
    json['createdAt'] = TimestampConverter().toJson(createdAt);
    json['updatedAt'] = TimestampConverter().toJson(updatedAt);

    if (lastInvoiceDate != null) {
      json['lastInvoiceDate'] = TimestampConverter().toJson(lastInvoiceDate!);
    }
    if (lastPaymentDate != null) {
      json['lastPaymentDate'] = TimestampConverter().toJson(lastPaymentDate!);
    }
    if (lastContactDate != null) {
      json['lastContactDate'] = TimestampConverter().toJson(lastContactDate!);
    }

    return json;
  }

  /// Create ClientModel from Firestore document
  static ClientModel fromFirestore(Map<String, dynamic> data) {
    return ClientModel.fromJson(data);
  }
}

// Helper class for creating new clients
class ClientModelBuilder {
  String? _id;
  String? _userId;
  String? _name;
  String? _email;
  String? _phone;
  String? _company;

  ClientModelBuilder setId(String id) {
    _id = id;
    return this;
  }

  ClientModelBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  ClientModelBuilder setName(String name) {
    _name = name;
    return this;
  }

  ClientModelBuilder setEmail(String email) {
    _email = email;
    return this;
  }

  ClientModelBuilder setPhone(String phone) {
    _phone = phone;
    return this;
  }

  ClientModelBuilder setCompany(String company) {
    _company = company;
    return this;
  }

  ClientModel build() {
    final now = DateTime.now();

    return ClientModel(
      id: _id ?? '',
      userId: _userId ?? '',
      name: _name ?? '',
      email: _email ?? '',
      phone: _phone,
      company: _company,
      address: const ClientAddressModel(),
      billing: const ClientBillingModel(),
      contact: const ClientContactModel(),
      tags: [],
      customFields: {},
      preferences: const ClientPreferencesModel(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
