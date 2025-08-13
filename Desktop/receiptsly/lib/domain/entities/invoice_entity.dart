// lib/domain/entities/invoice_entity.dart
import 'package:equatable/equatable.dart';

/// Invoice entity representing an invoice in the business domain
/// Contains all business rules and logic for invoice management
class InvoiceEntity extends Equatable {
  final String id;
  final String userId;
  final String invoiceNumber;
  final String clientId;
  final String? projectId;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String currency;
  final InvoiceStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final String? terms;
  final String? footer;
  final InvoiceTemplate template;
  final List<String> attachments;
  final PaymentInformation? paymentInfo;
  final List<PaymentRecord> payments;
  final ReminderSettings reminderSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? paidAt;
  final String? pdfUrl;
  final SyncStatus syncStatus;
  final Map<String, dynamic> metadata;

  const InvoiceEntity({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.clientId,
    this.projectId,
    required this.issueDate,
    required this.dueDate,
    required this.lineItems,
    required this.subtotal,
    this.taxRate = 0.0,
    required this.taxAmount,
    this.discountAmount = 0.0,
    required this.total,
    this.currency = 'USD',
    this.status = InvoiceStatus.draft,
    this.paymentStatus = PaymentStatus.unpaid,
    this.notes,
    this.terms,
    this.footer,
    this.template = InvoiceTemplate.standard,
    this.attachments = const [],
    this.paymentInfo,
    this.payments = const [],
    this.reminderSettings = const ReminderSettings(),
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.paidAt,
    this.pdfUrl,
    this.syncStatus = SyncStatus.pending,
    this.metadata = const {},
  });

  /// Check if invoice is overdue
  bool get isOverdue {
    return status == InvoiceStatus.sent &&
        paymentStatus != PaymentStatus.paid &&
        DateTime.now().isAfter(dueDate);
  }

  /// Get days until due (negative if overdue)
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  /// Get days overdue (0 if not overdue)
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  /// Check if invoice is due soon (within 3 days)
  bool get isDueSoon {
    return daysUntilDue <= 3 && daysUntilDue > 0 && !isOverdue;
  }

  /// Get remaining balance (total - paid amount)
  double get remainingBalance {
    final paidAmount = payments
        .where((p) => p.status == PaymentRecordStatus.confirmed)
        .fold(0.0, (sum, payment) => sum + payment.amount);
    return total - paidAmount;
  }

  /// Get total paid amount
  double get totalPaid {
    return payments
        .where((p) => p.status == PaymentRecordStatus.confirmed)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  /// Check if invoice is fully paid
  bool get isFullyPaid {
    return remainingBalance <= 0.01; // Allow for small rounding differences
  }

  /// Check if invoice is partially paid
  bool get isPartiallyPaid {
    final paid = totalPaid;
    return paid > 0 && paid < total;
  }

  /// Business rule: Can invoice be edited?
  bool get canBeEdited {
    return status == InvoiceStatus.draft;
  }

  /// Business rule: Can invoice be sent?
  bool get canBeSent {
    return status == InvoiceStatus.draft &&
        lineItems.isNotEmpty &&
        total > 0 &&
        invoiceNumber.isNotEmpty &&
        clientId.isNotEmpty;
  }

  /// Business rule: Can invoice be deleted?
  bool get canBeDeleted {
    return status == InvoiceStatus.draft ||
        (status == InvoiceStatus.sent && paymentStatus == PaymentStatus.unpaid);
  }

  /// Business rule: Can payment be recorded?
  bool get canRecordPayment {
    return status == InvoiceStatus.sent &&
        paymentStatus != PaymentStatus.paid &&
        remainingBalance > 0;
  }

  /// Business rule: Can invoice be cancelled?
  bool get canBeCancelled {
    return status == InvoiceStatus.sent &&
        paymentStatus == PaymentStatus.unpaid;
  }

  /// Business rule: Can reminder be sent?
  bool get canSendReminder {
    return status == InvoiceStatus.sent &&
        paymentStatus != PaymentStatus.paid &&
        sentAt != null;
  }

  /// Calculate age of invoice in days
  int get ageInDays {
    return DateTime.now().difference(issueDate).inDays;
  }

  /// Get formatted total with currency
  String get formattedTotal {
    return '$currency ${total.toStringAsFixed(2)}';
  }

  /// Get formatted remaining balance with currency
  String get formattedRemainingBalance {
    return '$currency ${remainingBalance.toStringAsFixed(2)}';
  }

  /// Validate invoice data
  List<String> validate() {
    final errors = <String>[];

    if (invoiceNumber.trim().isEmpty) {
      errors.add('Invoice number is required');
    }

    if (clientId.trim().isEmpty) {
      errors.add('Client is required');
    }

    if (lineItems.isEmpty) {
      errors.add('At least one line item is required');
    }

    if (total <= 0) {
      errors.add('Invoice total must be greater than zero');
    }

    if (dueDate.isBefore(issueDate)) {
      errors.add('Due date cannot be before issue date');
    }

    if (taxRate < 0 || taxRate > 1) {
      errors.add('Tax rate must be between 0 and 100%');
    }

    // Validate line items
    for (int i = 0; i < lineItems.length; i++) {
      final item = lineItems[i];
      final itemErrors = item.validate();
      for (final error in itemErrors) {
        errors.add('Line item ${i + 1}: $error');
      }
    }

    return errors;
  }

  /// Calculate totals from line items
  InvoiceCalculation calculateTotals() {
    final subtotalCalc = lineItems.fold(0.0, (sum, item) => sum + item.total);
    final taxAmountCalc = subtotalCalc * taxRate;
    final totalCalc = subtotalCalc + taxAmountCalc - discountAmount;

    return InvoiceCalculation(
      subtotal: subtotalCalc,
      taxAmount: taxAmountCalc,
      total: totalCalc.clamp(0.0, double.infinity),
    );
  }

  /// Update status to sent
  InvoiceEntity markAsSent() {
    return copyWith(
      status: InvoiceStatus.sent,
      paymentStatus: PaymentStatus.unpaid,
      sentAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update status to paid
  InvoiceEntity markAsPaid(PaymentRecord payment) {
    return copyWith(
      status: InvoiceStatus.sent,
      paymentStatus: PaymentStatus.paid,
      payments: [...payments, payment],
      paidAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Add partial payment
  InvoiceEntity addPayment(PaymentRecord payment) {
    final newPayments = [...payments, payment];
    final newTotalPaid = newPayments
        .where((p) => p.status == PaymentRecordStatus.confirmed)
        .fold(0.0, (sum, p) => sum + p.amount);

    final newPaymentStatus = newTotalPaid >= total
        ? PaymentStatus.paid
        : newTotalPaid > 0
        ? PaymentStatus.partiallyPaid
        : PaymentStatus.unpaid;

    return copyWith(
      payments: newPayments,
      paymentStatus: newPaymentStatus,
      paidAt: newPaymentStatus == PaymentStatus.paid ? DateTime.now() : paidAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Cancel invoice
  InvoiceEntity cancel(String reason) {
    return copyWith(
      status: InvoiceStatus.cancelled,
      paymentStatus: PaymentStatus.cancelled,
      metadata: {...metadata, 'cancellationReason': reason},
      updatedAt: DateTime.now(),
    );
  }

  /// Add line item
  InvoiceEntity addLineItem(InvoiceLineItem item) {
    final newLineItems = [...lineItems, item];
    final calculation = copyWith(lineItems: newLineItems).calculateTotals();

    return copyWith(
      lineItems: newLineItems,
      subtotal: calculation.subtotal,
      taxAmount: calculation.taxAmount,
      total: calculation.total,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove line item
  InvoiceEntity removeLineItem(int index) {
    if (index < 0 || index >= lineItems.length) return this;

    final newLineItems = List<InvoiceLineItem>.from(lineItems)..removeAt(index);
    final calculation = copyWith(lineItems: newLineItems).calculateTotals();

    return copyWith(
      lineItems: newLineItems,
      subtotal: calculation.subtotal,
      taxAmount: calculation.taxAmount,
      total: calculation.total,
      updatedAt: DateTime.now(),
    );
  }

  /// Update line item
  InvoiceEntity updateLineItem(int index, InvoiceLineItem item) {
    if (index < 0 || index >= lineItems.length) return this;

    final newLineItems = List<InvoiceLineItem>.from(lineItems);
    newLineItems[index] = item;
    final calculation = copyWith(lineItems: newLineItems).calculateTotals();

    return copyWith(
      lineItems: newLineItems,
      subtotal: calculation.subtotal,
      taxAmount: calculation.taxAmount,
      total: calculation.total,
      updatedAt: DateTime.now(),
    );
  }

  InvoiceEntity copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    String? clientId,
    String? projectId,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceLineItem>? lineItems,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? total,
    String? currency,
    InvoiceStatus? status,
    PaymentStatus? paymentStatus,
    String? notes,
    String? terms,
    String? footer,
    InvoiceTemplate? template,
    List<String>? attachments,
    PaymentInformation? paymentInfo,
    List<PaymentRecord>? payments,
    ReminderSettings? reminderSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? paidAt,
    String? pdfUrl,
    SyncStatus? syncStatus,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      footer: footer ?? this.footer,
      template: template ?? this.template,
      attachments: attachments ?? this.attachments,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      payments: payments ?? this.payments,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      paidAt: paidAt ?? this.paidAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    invoiceNumber,
    clientId,
    projectId,
    issueDate,
    dueDate,
    lineItems,
    subtotal,
    taxRate,
    taxAmount,
    discountAmount,
    total,
    currency,
    status,
    paymentStatus,
    notes,
    terms,
    footer,
    template,
    attachments,
    paymentInfo,
    payments,
    reminderSettings,
    createdAt,
    updatedAt,
    sentAt,
    paidAt,
    pdfUrl,
    syncStatus,
    metadata,
  ];

  @override
  String toString() {
    return 'InvoiceEntity(id: $id, invoiceNumber: $invoiceNumber, total: $total, status: $status)';
  }
}

/// Invoice line item
class InvoiceLineItem extends Equatable {
  final String description;
  final double quantity;
  final double rate;
  final double total;
  final String? unit;
  final String? category;

  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.rate,
    required this.total,
    this.unit,
    this.category,
  });

  /// Calculate total (quantity × rate)
  double get calculatedTotal {
    return quantity * rate;
  }

  /// Validate line item
  List<String> validate() {
    final errors = <String>[];

    if (description.trim().isEmpty) {
      errors.add('Description is required');
    }

    if (quantity <= 0) {
      errors.add('Quantity must be greater than zero');
    }

    if (rate < 0) {
      errors.add('Rate cannot be negative');
    }

    if (total < 0) {
      errors.add('Total cannot be negative');
    }

    return errors;
  }

  InvoiceLineItem copyWith({
    String? description,
    double? quantity,
    double? rate,
    double? total,
    String? unit,
    String? category,
  }) {
    return InvoiceLineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      total: total ?? this.total,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
    description,
    quantity,
    rate,
    total,
    unit,
    category,
  ];
}

/// Payment information for invoice
class PaymentInformation extends Equatable {
  final String? bankName;
  final String? accountNumber;
  final String? routingNumber;
  final String? swiftCode;
  final String? paypalEmail;
  final String? stripeAccountId;
  final List<PaymentMethod> acceptedMethods;
  final String? paymentInstructions;

  const PaymentInformation({
    this.bankName,
    this.accountNumber,
    this.routingNumber,
    this.swiftCode,
    this.paypalEmail,
    this.stripeAccountId,
    this.acceptedMethods = const [],
    this.paymentInstructions,
  });

  PaymentInformation copyWith({
    String? bankName,
    String? accountNumber,
    String? routingNumber,
    String? swiftCode,
    String? paypalEmail,
    String? stripeAccountId,
    List<PaymentMethod>? acceptedMethods,
    String? paymentInstructions,
  }) {
    return PaymentInformation(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      swiftCode: swiftCode ?? this.swiftCode,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      acceptedMethods: acceptedMethods ?? this.acceptedMethods,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
    );
  }

  @override
  List<Object?> get props => [
    bankName,
    accountNumber,
    routingNumber,
    swiftCode,
    paypalEmail,
    stripeAccountId,
    acceptedMethods,
    paymentInstructions,
  ];
}

/// Payment record for tracking payments
class PaymentRecord extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? reference;
  final String? notes;
  final PaymentRecordStatus status;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
    this.notes,
    this.status = PaymentRecordStatus.pending,
    required this.createdAt,
  });

  PaymentRecord copyWith({
    String? id,
    double? amount,
    DateTime? date,
    PaymentMethod? method,
    String? reference,
    String? notes,
    PaymentRecordStatus? status,
    DateTime? createdAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    date,
    method,
    reference,
    notes,
    status,
    createdAt,
  ];
}

/// Reminder settings for invoice
class ReminderSettings extends Equatable {
  final bool enableReminders;
  final List<int> reminderDays; // Days before due date
  final int maxReminders;
  final int sentReminders;
  final DateTime? lastReminderSent;

  const ReminderSettings({
    this.enableReminders = true,
    this.reminderDays = const [7, 3, 1], // 7, 3, 1 days before due
    this.maxReminders = 3,
    this.sentReminders = 0,
    this.lastReminderSent,
  });

  /// Check if reminder should be sent
  bool shouldSendReminder(DateTime dueDate) {
    if (!enableReminders || sentReminders >= maxReminders) return false;

    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    // Check if any reminder day matches current days until due
    for (final reminderDay in reminderDays) {
      if (daysUntilDue <= reminderDay) {
        // Check if we haven't sent a reminder recently
        if (lastReminderSent == null ||
            DateTime.now().difference(lastReminderSent!).inDays >= 1) {
          return true;
        }
      }
    }

    return false;
  }

  ReminderSettings copyWith({
    bool? enableReminders,
    List<int>? reminderDays,
    int? maxReminders,
    int? sentReminders,
    DateTime? lastReminderSent,
  }) {
    return ReminderSettings(
      enableReminders: enableReminders ?? this.enableReminders,
      reminderDays: reminderDays ?? this.reminderDays,
      maxReminders: maxReminders ?? this.maxReminders,
      sentReminders: sentReminders ?? this.sentReminders,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
    );
  }

  @override
  List<Object?> get props => [
    enableReminders,
    reminderDays,
    maxReminders,
    sentReminders,
    lastReminderSent,
  ];
}

/// Invoice calculation helper
class InvoiceCalculation extends Equatable {
  final double subtotal;
  final double taxAmount;
  final double total;

  const InvoiceCalculation({
    required this.subtotal,
    required this.taxAmount,
    required this.total,
  });

  @override
  List<Object?> get props => [subtotal, taxAmount, total];
}

/// Enums for invoice-related data
enum InvoiceStatus { draft, sent, viewed, cancelled, archived }

enum PaymentStatus { unpaid, partiallyPaid, paid, overdue, cancelled }

enum PaymentRecordStatus { pending, confirmed, failed, cancelled }

enum InvoiceTemplate { standard, modern, minimal, detailed, custom }

enum PaymentMethod {
  bankTransfer,
  creditCard,
  paypal,
  stripe,
  cash,
  check,
  other,
}

enum SyncStatus { pending, syncing, synced, failed, conflict }
