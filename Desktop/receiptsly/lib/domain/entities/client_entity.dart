// lib/domain/entities/client_entity.dart
import 'package:equatable/equatable.dart';

/// Client entity representing a client in the business domain
/// Contains all business rules and logic for client management
class ClientEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? companyName;
  final ClientType type;
  final ContactInformation contactInfo;
  final BillingInformation billingInfo;
  final List<String> projectIds;
  final ClientStatus status;
  final double totalBilled;
  final double totalPaid;
  final double outstandingAmount;
  final int totalInvoices;
  final PaymentTerms defaultPaymentTerms;
  final String? notes;
  final List<String> tags;
  final ClientPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastInvoiceDate;
  final DateTime? lastPaymentDate;
  final SyncStatus syncStatus;
  final Map<String, dynamic> metadata;

  const ClientEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.companyName,
    this.type = ClientType.individual,
    required this.contactInfo,
    required this.billingInfo,
    this.projectIds = const [],
    this.status = ClientStatus.active,
    this.totalBilled = 0.0,
    this.totalPaid = 0.0,
    this.outstandingAmount = 0.0,
    this.totalInvoices = 0,
    this.defaultPaymentTerms = const PaymentTerms(),
    this.notes,
    this.tags = const [],
    this.preferences = const ClientPreferences(),
    required this.createdAt,
    required this.updatedAt,
    this.lastInvoiceDate,
    this.lastPaymentDate,
    this.syncStatus = SyncStatus.pending,
    this.metadata = const {},
  });

  /// Get display name (company name if available, otherwise person name)
  String get displayName {
    if (type == ClientType.company && companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    return name;
  }

  /// Get full display name with both company and person name if applicable
  String get fullDisplayName {
    if (type == ClientType.company && companyName != null && companyName!.isNotEmpty) {
      return '$companyName ($name)';
    }
    return name;
  }

  /// Calculate outstanding balance
  double get calculatedOutstanding {
    return totalBilled - totalPaid;
  }

  /// Check if client has outstanding payments
  bool get hasOutstandingPayments {
    return calculatedOutstanding > 0.01; // Allow for small rounding differences
  }

  /// Check if client is a good payer (pays on time)
  bool get isGoodPayer {
    if (totalInvoices == 0) return true;
    return calculatedOutstanding / totalBilled < 0.1; // Less than 10% outstanding
  }

  /// Check if client is overdue
  bool get isOverdue {
    return hasOutstandingPayments && 
           lastInvoiceDate != null && 
           DateTime.now().difference(lastInvoiceDate!).inDays > defaultPaymentTerms.daysUntilDue;
  }

  /// Get payment history score (0-100)
  int get paymentScore {
    if (totalInvoices == 0) return 100;
    
    final paymentRatio = totalPaid / totalBilled;
    int score = (paymentRatio * 100).round();
    
    // Deduct points for being overdue
    if (isOverdue) {
      score = (score * 0.8).round();
    }
    
    // Deduct points for having too many outstanding invoices
    if (hasOutstandingPayments && calculatedOutstanding / totalBilled > 0.2) {
      score = (score * 0.9).round();
    }
    
    return score.clamp(0, 100);
  }

  /// Get client risk level based on payment history
  ClientRiskLevel get riskLevel {
    final score = paymentScore;
    if (score >= 80) return ClientRiskLevel.low;
    if (score >= 60) return ClientRiskLevel.medium;
    if (score >= 40) return ClientRiskLevel.high;
    return ClientRiskLevel.veryHigh;
  }

  /// Check if client information is complete
  bool get isComplete {
    return name.isNotEmpty &&
           contactInfo.email.isNotEmpty &&
           billingInfo.isComplete;
  }

  /// Check if client can receive invoices
  bool get canReceiveInvoices {
    return status == ClientStatus.active &&
           contactInfo.email.isNotEmpty &&
           isComplete;
  }

  /// Business rule: Can client be archived?
  bool get canBeArchived {
    return status == ClientStatus.active &&
           !hasOutstandingPayments &&
           projectIds.isEmpty;
  }

  /// Business rule: Can client be deleted?
  bool get canBeDeleted {
    return status == ClientStatus.inactive &&
           totalInvoices == 0 &&
           projectIds.isEmpty;
  }

  /// Get days since last invoice
  int? get daysSinceLastInvoice {
    if (lastInvoiceDate == null) return null;
    return DateTime.now().difference(lastInvoiceDate!).inDays;
  }

  /// Get days since last payment
  int? get daysSinceLastPayment {
    if (lastPaymentDate == null) return null;
    return DateTime.now().difference(lastPaymentDate!).inDays;
  }

  /// Check if client is inactive (no activity in 90 days)
  bool get isInactive {
    final lastActivity = [lastInvoiceDate, lastPaymentDate, updatedAt]
        .where((date) => date != null)
        .map((date) => date!)
        .fold<DateTime?>(null, (latest, date) {
          if (latest == null) return date;
          return date.isAfter(latest) ? date : latest;
        });
    
    if (lastActivity == null) return true;
    return DateTime.now().difference(lastActivity).inDays > 90;
  }

  /// Validate client data
  List<String> validate() {
    final errors = <String>[];
    
    if (name.trim().isEmpty) {
      errors.add('Client name is required');
    }
    
    if (type == ClientType.company && (companyName == null || companyName!.trim().isEmpty)) {
      errors.add('Company name is required for company clients');
    }
    
    // Validate contact information
    final contactErrors = contactInfo.validate();
    errors.addAll(contactErrors);
    
    // Validate billing information
    final billingErrors = billingInfo.validate();
    errors.addAll(billingErrors);
    
    if (totalBilled < 0) {
      errors.add('Total billed cannot be negative');
    }
    
    if (totalPaid < 0) {
      errors.add('Total paid cannot be negative');
    }
    
    if (totalPaid > totalBilled) {
      errors.add('Total paid cannot exceed total billed');
    }
    
    return errors;
  }

  /// Add project to client
  ClientEntity addProject(String projectId) {
    if (projectIds.contains(projectId)) return this;
    return copyWith(
      projectIds: [...projectIds, projectId],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove project from client
  ClientEntity removeProject(String projectId) {
    return copyWith(
      projectIds: projectIds.where((id) => id != projectId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Add tag to client
  ClientEntity addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(
      tags: [...tags, tag],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove tag from client
  ClientEntity removeTag(String tag) {
    return copyWith(
      tags: tags.where((t) => t != tag).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update financial totals
  ClientEntity updateFinancials({
    required double totalBilled,
    required double totalPaid,
    required int totalInvoices,
    DateTime? lastInvoiceDate,
    DateTime? lastPaymentDate,
  }) {
    return copyWith(
      totalBilled: totalBilled,
      totalPaid: totalPaid,
      outstandingAmount: totalBilled - totalPaid,
      totalInvoices: totalInvoices,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as inactive
  ClientEntity markAsInactive() {
    return copyWith(
      status: ClientStatus.inactive,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as active
  ClientEntity markAsActive() {
    return copyWith(
      status: ClientStatus.active,
      updatedAt: DateTime.now(),
    );
  }

  /// Archive client
  ClientEntity archive() {
    return copyWith(
      status: ClientStatus.archived,
      updatedAt: DateTime.now(),
    );
  }

  ClientEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? companyName,
    ClientType? type,
    ContactInformation? contactInfo,
    BillingInformation? billingInfo,
    List<String>? projectIds,
    ClientStatus? status,
    double? totalBilled,
    double? totalPaid,
    double? outstandingAmount,
    int? totalInvoices,
    PaymentTerms? defaultPaymentTerms,
    String? notes,
    List<String>? tags,
    ClientPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastInvoiceDate,
    DateTime? lastPaymentDate,
    SyncStatus? syncStatus,
    Map<String, dynamic>? metadata,
  }) {
    return ClientEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      type: type ?? this.type,
      contactInfo: contactInfo ?? this.contactInfo,
      billingInfo: billingInfo ?? this.billingInfo,
      projectIds: projectIds ?? this.projectIds,
      status: status ?? this.status,
      totalBilled: totalBilled ?? this.totalBilled,
      totalPaid: totalPaid ?? this.totalPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      defaultPaymentTerms: defaultPaymentTerms ?? this.defaultPaymentTerms,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      syncStatus: syncStatus ?? this.syncStatus,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        companyName,
        type,
        contactInfo,
        billingInfo,
        projectIds,
        status,
        totalBilled,
        totalPaid,
        outstandingAmount,
        totalInvoices,
        defaultPaymentTerms,
        notes,
        tags,
        preferences,
        createdAt,
        updatedAt,
        lastInvoiceDate,
        lastPaymentDate,
        syncStatus,
        metadata,
      ];

  @override
  String toString() {
    return 'ClientEntity(id: $id, name: $displayName, status: $status, outstanding: $outstandingAmount)';
  }
}

/// Contact information for client
class ContactInformation extends Equatable {
  final String email;
  final String? phone;
  final String? website;
  final Address? address;
  final String? preferredContactMethod;
  final String? timezone;

  const ContactInformation({
    required this.email,
    this.phone,
    this.website,
    this.address,
    this.preferredContactMethod,
    this.timezone,
  });

  /// Check if contact information is complete
  bool get isComplete {
    return email.isNotEmpty;
  }

  /// Validate contact information
  List<String> validate() {
    final errors = <String>[];
    
    if (email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(email)) {
      errors.add('Invalid email format');
    }
    
    if (phone != null && phone!.isNotEmpty && !_isValidPhone(phone!)) {
      errors.add('Invalid phone number format');
    }
    
    if (website != null && website!.isNotEmpty && !_isValidWebsite(website!)) {
      errors.add('Invalid website URL format');
    }
    
    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+).hasMatch(phone);
  }

  bool _isValidWebsite(String website) {
    return RegExp(r'^https?://').hasMatch(website) || 
           RegExp(r'^www\.').hasMatch(website) ||
           RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}).hasMatch(website);
  }

  ContactInformation copyWith({
    String? email,
    String? phone,
    String? website,
    Address? address,
    String? preferredContactMethod,
    String? timezone,
  }) {
    return ContactInformation(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  List<Object?> get props => [
        email,
        phone,
        website,
        address,
        preferredContactMethod,
        timezone,
      ];
}

/// Billing information for client
class BillingInformation extends Equatable {
  final Address? billingAddress;
  final String? taxId;
  final String? vatNumber;
  final String? billingEmail;
  final String? purchaseOrderRequired;
  final String? billingContactName;
  final String? billingContactPhone;

  const BillingInformation({
    this.billingAddress,
    this.taxId,
    this.vatNumber,
    this.billingEmail,
    this.purchaseOrderRequired,
    this.billingContactName,
    this.billingContactPhone,
  });

  /// Check if billing information is complete enough for invoicing
  bool get isComplete {
    return billingAddress != null;
  }

  /// Check if billing information has tax details
  bool get hasTaxInfo {
    return (taxId != null && taxId!.isNotEmpty) || 
           (vatNumber != null && vatNumber!.isNotEmpty);
  }

  /// Validate billing information
  List<String> validate() {
    final errors = <String>[];
    
    if (billingEmail != null && billingEmail!.isNotEmpty) {
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(billingEmail!)) {
        errors.add('Invalid billing email format');
      }
    }
    
    return errors;
  }

  BillingInformation copyWith({
    Address? billingAddress,
    String? taxId,
    String? vatNumber,
    String? billingEmail,
    String? purchaseOrderRequired,
    String? billingContactName,
    String? billingContactPhone,
  }) {
    return BillingInformation(
      billingAddress: billingAddress ?? this.billingAddress,
      taxId: taxId ?? this.taxId,
      vatNumber: vatNumber ?? this.vatNumber,
      billingEmail: billingEmail ?? this.billingEmail,
      purchaseOrderRequired: purchaseOrderRequired ?? this.purchaseOrderRequired,
      billingContactName: billingContactName ?? this.billingContactName,
      billingContactPhone: billingContactPhone ?? this.billingContactPhone,
    );
  }

  @override
  List<Object?> get props => [
        billingAddress,
        taxId,
        vatNumber,
        billingEmail,
        purchaseOrderRequired,
        billingContactName,
        billingContactPhone,
      ];
}

/// Address information
class Address extends Equatable {
  final String street;
  final String? street2;
  final String city;
  final String? state;
  final String postalCode;
  final String country;

  const Address({
    required this.street,
    this.street2,
    required this.city,
    this.state,
    required this.postalCode,
    required this.country,
  });

  /// Get formatted address as a single string
  String get formatted {
    final parts = <String>[
      street,
      if (street2 != null && street2!.isNotEmpty) street2!,
      city,
      if (state != null && state!.isNotEmpty) state!,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  /// Get formatted address as multiple lines
  List<String> get formattedLines {
    final lines = <String>[
      street,
      if (street2 != null && street2!.isNotEmpty) street2!,
      '$city, ${state ?? ''} $postalCode'.trim(),
      country,
    ];
    return lines.where((line) => line.isNotEmpty).toList();
  }

  Address copyWith({
    String? street,
    String? street2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return Address(
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [
        street,
        street2,
        city,
        state,
        postalCode,
        country,
      ];
}

/// Payment terms for client
class PaymentTerms extends Equatable {
  final int daysUntilDue;
  final double? earlyPaymentDiscount;
  final int? earlyPaymentDays;
  final double? latePaymentFee;
  final String? paymentInstructions;

  const PaymentTerms({
    this.daysUntilDue = 30,
    this.earlyPaymentDiscount,
    this.earlyPaymentDays,
    this.latePaymentFee,
    this.paymentInstructions,
  });

  /// Get payment terms description
  String get description {
    String desc = 'Net $daysUntilDue';
    
    if (earlyPaymentDiscount != null && earlyPaymentDays != null) {
      desc += ', ${(earlyPaymentDiscount! * 100).toStringAsFixed(1)}% early payment discount if paid within $earlyPaymentDays days';
    }
    
    if (latePaymentFee != null) {
      desc += ', ${(latePaymentFee! * 100).toStringAsFixed(1)}% late payment fee';
    }
    
    return desc;
  }

  PaymentTerms copyWith({
    int? daysUntilDue,
    double? earlyPaymentDiscount,
    int? earlyPaymentDays,
    double? latePaymentFee,
    String? paymentInstructions,
  }) {
    return PaymentTerms(
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      earlyPaymentDiscount: earlyPaymentDiscount ?? this.earlyPaymentDiscount,
      earlyPaymentDays: earlyPaymentDays ?? this.earlyPaymentDays,
      latePaymentFee: latePaymentFee ?? this.latePaymentFee,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
    );
  }

  @override
  List<Object?> get props => [
        daysUntilDue,
        earlyPaymentDiscount,
        earlyPaymentDays,
        latePaymentFee,
        paymentInstructions,
      ];
}

/// Client preferences
class ClientPreferences extends Equatable {
  final String preferredCurrency;
  final String preferredLanguage;
  final bool receiveEmailNotifications;
  final bool receiveInvoiceReminders;
  final String invoiceDeliveryMethod;
  final String? customInvoiceTemplate;

  const ClientPreferences({
    this.preferredCurrency = 'USD',
    this.preferredLanguage = 'en',
    this.receiveEmailNotifications = true,
    this.receiveInvoiceReminders = true,
    this.invoiceDeliveryMethod = 'email',
    this.customInvoiceTemplate,
  });

  ClientPreferences copyWith({
    String? preferredCurrency,
    String? preferredLanguage,
    bool? receiveEmailNotifications,
    bool? receiveInvoiceReminders,
    String? invoiceDeliveryMethod,
    String? customInvoiceTemplate,
  }) {
    return ClientPreferences(
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      receiveEmailNotifications: receiveEmailNotifications ?? this.receiveEmailNotifications,
      receiveInvoiceReminders: receiveInvoiceReminders ?? this.receiveInvoiceReminders,
      invoiceDeliveryMethod: invoiceDeliveryMethod ?? this.invoiceDeliveryMethod,
      customInvoiceTemplate: customInvoiceTemplate ?? this.customInvoiceTemplate,
    );
  }

  @override
  List<Object?> get props => [
        preferredCurrency,
        preferredLanguage,
        receiveEmailNotifications,
        receiveInvoiceReminders,
        invoiceDeliveryMethod,
        customInvoiceTemplate,
      ];
}

/// Enums for client-related data
enum ClientType {
  individual,
  company,
  nonprofit,
  government,
}

enum ClientStatus {
  active,
  inactive,
  archived,
  blocked,
}

enum ClientRiskLevel {
  low,
  medium,
  high,
  veryHigh,
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}