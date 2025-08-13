// lib/data/models/invoice/invoice_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:receiptsly_mobile/data/models/user/user_model.dart';
import 'package:receiptsly_mobile/data/models/invoice/invoice_status.dart';
import 'package:receiptsly_mobile/data/models/invoice/invoice_item_model.dart';

part 'invoice_model.freezed.dart';
part 'invoice_model.g.dart';

@freezed
class InvoiceModel with _$InvoiceModel {
  const factory InvoiceModel({
    required String id,
    required String userId,
    required String clientId,
    required String invoiceNumber,
    required InvoiceStatus status,
    @TimestampConverter() required DateTime issueDate,
    @TimestampConverter() required DateTime dueDate,
    @TimestampConverter() DateTime? paidDate,
    required String currency,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    required double amountPaid,
    required double amountDue,
    required List<InvoiceItemModel> items,
    required InvoiceTaxModel tax,
    required InvoiceDiscountModel discount,
    String? notes,
    String? terms,
    String? paymentInstructions,
    String? projectId,
    String? poNumber, // Purchase Order Number
    required InvoiceClientModel client,
    required InvoiceBusinessModel business,
    String? templateId,
    String? pdfUrl,
    String? publicUrl,
    required List<InvoicePaymentModel> payments,
    required List<InvoiceReminderModel> reminders,
    @TimestampConverter() DateTime? lastReminderSent,
    @TimestampConverter() DateTime? nextReminderDue,
    @Default([]) List<String> tags,
    @Default(false) bool isRecurring,
    String? recurringProfileId,
    @Default(false) bool isTemplate,
    @Default(false) bool isDraft,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @TimestampConverter() DateTime? sentAt,
    @TimestampConverter() DateTime? viewedAt,
    String? sentMethod, // email, whatsapp, telegram
    Map<String, dynamic>? metadata,
    @Default(1) int version,
    String? externalId,
  }) = _InvoiceModel;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceModelFromJson(json);
}

@freezed
class InvoiceTaxModel with _$InvoiceTaxModel {
  const factory InvoiceTaxModel({
    @Default(0.0) double rate,
    @Default('') String type, // VAT, GST, Sales Tax, etc.
    @Default(0.0) double amount,
    @Default(true) bool inclusive,
    String? taxId,
    String? description,
  }) = _InvoiceTaxModel;

  factory InvoiceTaxModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceTaxModelFromJson(json);
}

@freezed
class InvoiceDiscountModel with _$InvoiceDiscountModel {
  const factory InvoiceDiscountModel({
    @Default(0.0) double amount,
    @Default('fixed') String type, // fixed, percentage
    String? description,
    String? couponCode,
  }) = _InvoiceDiscountModel;

  factory InvoiceDiscountModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceDiscountModelFromJson(json);
}

@freezed
class InvoiceClientModel with _$InvoiceClientModel {
  const factory InvoiceClientModel({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? company,
    required InvoiceAddressModel address,
    String? taxId,
    String? website,
    Map<String, dynamic>? customFields,
  }) = _InvoiceClientModel;

  factory InvoiceClientModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceClientModelFromJson(json);
}

@freezed
class InvoiceBusinessModel with _$InvoiceBusinessModel {
  const factory InvoiceBusinessModel({
    required String name,
    required String email,
    String? phone,
    String? website,
    String? logo,
    required InvoiceAddressModel address,
    String? taxId,
    String? registrationNumber,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? customFields,
  }) = _InvoiceBusinessModel;

  factory InvoiceBusinessModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceBusinessModelFromJson(json);
}

@freezed
class InvoiceAddressModel with _$InvoiceAddressModel {
  const factory InvoiceAddressModel({
    @Default('') String street,
    @Default('') String city,
    @Default('') String state,
    @Default('') String postalCode,
    @Default('') String country,
  }) = _InvoiceAddressModel;

  factory InvoiceAddressModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceAddressModelFromJson(json);
}

@freezed
class InvoicePaymentModel with _$InvoicePaymentModel {
  const factory InvoicePaymentModel({
    required String id,
    required double amount,
    @TimestampConverter() required DateTime date,
    required String method, // cash, card, bank_transfer, etc.
    String? reference,
    String? notes,
    @Default('completed') String status,
    @TimestampConverter() required DateTime createdAt,
  }) = _InvoicePaymentModel;

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) =>
      _$InvoicePaymentModelFromJson(json);
}

@freezed
class InvoiceReminderModel with _$InvoiceReminderModel {
  const factory InvoiceReminderModel({
    required String id,
    required int daysBefore, // Days before due date
    required String type, // email, sms, whatsapp
    @Default('pending') String status, // pending, sent, failed
    @TimestampConverter() DateTime? sentAt,
    String? message,
    String? subject,
    Map<String, dynamic>? deliveryInfo,
  }) = _InvoiceReminderModel;

  factory InvoiceReminderModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceReminderModelFromJson(json);
}

// Helper class for creating new invoices
class InvoiceModelBuilder {
  String? _id;
  String? _userId;
  String? _clientId;
  String? _invoiceNumber;
  InvoiceStatus? _status;
  DateTime? _issueDate;
  DateTime? _dueDate;
  String? _currency;
  List<InvoiceItemModel>? _items;
  InvoiceClientModel? _client;
  InvoiceBusinessModel? _business;

  InvoiceModelBuilder setId(String id) {
    _id = id;
    return this;
  }

  InvoiceModelBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  InvoiceModelBuilder setClientId(String clientId) {
    _clientId = clientId;
    return this;
  }

  InvoiceModelBuilder setInvoiceNumber(String invoiceNumber) {
    _invoiceNumber = invoiceNumber;
    return this;
  }

  InvoiceModelBuilder setStatus(InvoiceStatus status) {
    _status = status;
    return this;
  }

  InvoiceModelBuilder setIssueDate(DateTime issueDate) {
    _issueDate = issueDate;
    return this;
  }

  InvoiceModelBuilder setDueDate(DateTime dueDate) {
    _dueDate = dueDate;
    return this;
  }

  InvoiceModelBuilder setCurrency(String currency) {
    _currency = currency;
    return this;
  }

  InvoiceModelBuilder setItems(List<InvoiceItemModel> items) {
    _items = items;
    return this;
  }

  InvoiceModelBuilder setClient(InvoiceClientModel client) {
    _client = client;
    return this;
  }

  InvoiceModelBuilder setBusiness(InvoiceBusinessModel business) {
    _business = business;
    return this;
  }

  InvoiceModel build() {
    final now = DateTime.now();
    final items = _items ?? [];

    // Calculate totals
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );

    final tax = const InvoiceTaxModel();
    final discount = const InvoiceDiscountModel();

    final taxAmount = (subtotal - discount.amount) * (tax.rate / 100);
    final totalAmount = subtotal + taxAmount - discount.amount;

    return InvoiceModel(
      id: _id ?? '',
      userId: _userId ?? '',
      clientId: _clientId ?? '',
      invoiceNumber: _invoiceNumber ?? '',
      status: _status ?? InvoiceStatus.draft,
      issueDate: _issueDate ?? now,
      dueDate: _dueDate ?? now.add(const Duration(days: 30)),
      currency: _currency ?? 'USD',
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discount.amount,
      totalAmount: totalAmount,
      amountPaid: 0.0,
      amountDue: totalAmount,
      items: items,
      tax: tax,
      discount: discount,
      client:
          _client ??
          const InvoiceClientModel(
            id: '',
            name: '',
            email: '',
            address: InvoiceAddressModel(),
          ),
      business:
          _business ??
          const InvoiceBusinessModel(
            name: '',
            email: '',
            address: InvoiceAddressModel(),
          ),
      payments: [],
      reminders: [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
