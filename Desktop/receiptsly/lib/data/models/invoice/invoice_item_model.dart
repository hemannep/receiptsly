// lib/data/models/invoice/invoice_item_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:receiptsly_mobile/data/models/user/user_model.dart';

part 'invoice_item_model.freezed.dart';
part 'invoice_item_model.g.dart';

@freezed
class InvoiceItemModel with _$InvoiceItemModel {
  const factory InvoiceItemModel({
    required String id,
    required String description,
    required int quantity,
    required double unitPrice,
    required double totalAmount,
    String? notes,
    String? category,
    String? sku,
    String? unit, // hours, pieces, kg, etc.
    @Default(false) bool isTaxable,
    double? taxRate,
    double? taxAmount,
    double? discountRate,
    double? discountAmount,
    @TimestampConverter() DateTime? startDate,
    @TimestampConverter() DateTime? endDate,
    String? projectId,
    String? taskId,
    String? receiptId, // Link to expense receipt
    Map<String, dynamic>? customFields,
    @Default(1) int sortOrder,
  }) = _InvoiceItemModel;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemModelFromJson(json);
}

// Extension methods for InvoiceItemModel
extension InvoiceItemModelExtension on InvoiceItemModel {
  /// Calculate total amount including tax and discount
  double get calculatedTotal {
    double base = quantity * unitPrice;

    // Apply discount
    if (discountAmount != null) {
      base -= discountAmount!;
    } else if (discountRate != null) {
      base -= base * (discountRate! / 100);
    }

    // Apply tax
    if (isTaxable && taxRate != null) {
      base += base * (taxRate! / 100);
    } else if (taxAmount != null) {
      base += taxAmount!;
    }

    return base;
  }

  /// Get the net amount before tax
  double get netAmount {
    double base = quantity * unitPrice;

    // Apply discount
    if (discountAmount != null) {
      base -= discountAmount!;
    } else if (discountRate != null) {
      base -= base * (discountRate! / 100);
    }

    return base;
  }

  /// Get calculated tax amount
  double get calculatedTaxAmount {
    if (!isTaxable) return 0.0;

    if (taxAmount != null) return taxAmount!;

    if (taxRate != null) {
      return netAmount * (taxRate! / 100);
    }

    return 0.0;
  }

  /// Get calculated discount amount
  double get calculatedDiscountAmount {
    if (discountAmount != null) return discountAmount!;

    if (discountRate != null) {
      return (quantity * unitPrice) * (discountRate! / 100);
    }

    return 0.0;
  }

  /// Check if item is time-based (has date range)
  bool get isTimeBased => startDate != null && endDate != null;

  /// Get duration in hours if time-based
  double get durationInHours {
    if (!isTimeBased) return 0.0;
    return endDate!.difference(startDate!).inMinutes / 60.0;
  }

  /// Get formatted description with dates if time-based
  String get formattedDescription {
    if (!isTimeBased) return description;

    final start = startDate!;
    final end = endDate!;

    return '$description (${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year})';
  }

  /// Create a copy with updated total amount
  InvoiceItemModel updateTotalAmount() {
    return copyWith(totalAmount: calculatedTotal);
  }

  /// Validate the invoice item
  List<String> validate() {
    final errors = <String>[];

    if (description.trim().isEmpty) {
      errors.add('Description is required');
    }

    if (quantity <= 0) {
      errors.add('Quantity must be greater than 0');
    }

    if (unitPrice < 0) {
      errors.add('Unit price cannot be negative');
    }

    if (taxRate != null && (taxRate! < 0 || taxRate! > 100)) {
      errors.add('Tax rate must be between 0 and 100');
    }

    if (discountRate != null && (discountRate! < 0 || discountRate! > 100)) {
      errors.add('Discount rate must be between 0 and 100');
    }

    if (isTimeBased) {
      if (startDate == null) {
        errors.add('Start date is required for time-based items');
      }
      if (endDate == null) {
        errors.add('End date is required for time-based items');
      }
      if (startDate != null &&
          endDate != null &&
          endDate!.isBefore(startDate!)) {
        errors.add('End date must be after start date');
      }
    }

    return errors;
  }

  /// Check if the item is valid
  bool get isValid => validate().isEmpty;
}

// Helper class for creating invoice items
class InvoiceItemBuilder {
  String? _id;
  String? _description;
  int? _quantity;
  double? _unitPrice;
  String? _unit;
  bool? _isTaxable;
  double? _taxRate;

  InvoiceItemBuilder setId(String id) {
    _id = id;
    return this;
  }

  InvoiceItemBuilder setDescription(String description) {
    _description = description;
    return this;
  }

  InvoiceItemBuilder setQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  InvoiceItemBuilder setUnitPrice(double unitPrice) {
    _unitPrice = unitPrice;
    return this;
  }

  InvoiceItemBuilder setUnit(String unit) {
    _unit = unit;
    return this;
  }

  InvoiceItemBuilder setTaxable(bool isTaxable) {
    _isTaxable = isTaxable;
    return this;
  }

  InvoiceItemBuilder setTaxRate(double taxRate) {
    _taxRate = taxRate;
    return this;
  }

  InvoiceItemModel build() {
    final quantity = _quantity ?? 1;
    final unitPrice = _unitPrice ?? 0.0;
    final totalAmount = quantity * unitPrice;

    return InvoiceItemModel(
      id: _id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: _description ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      unit: _unit,
      isTaxable: _isTaxable ?? false,
      taxRate: _taxRate,
    );
  }
}

// Common invoice item templates
class InvoiceItemTemplates {
  static InvoiceItemModel hourlyService({
    required String description,
    required double hours,
    required double hourlyRate,
    double? taxRate,
  }) {
    return InvoiceItemBuilder()
        .setDescription(description)
        .setQuantity(hours.round())
        .setUnitPrice(hourlyRate)
        .setUnit('hours')
        .setTaxable(taxRate != null)
        .setTaxRate(taxRate)
        .build();
  }

  static InvoiceItemModel fixedPriceService({
    required String description,
    required double price,
    double? taxRate,
  }) {
    return InvoiceItemBuilder()
        .setDescription(description)
        .setQuantity(1)
        .setUnitPrice(price)
        .setUnit('service')
        .setTaxable(taxRate != null)
        .setTaxRate(taxRate)
        .build();
  }

  static InvoiceItemModel product({
    required String description,
    required int quantity,
    required double unitPrice,
    String? sku,
    double? taxRate,
  }) {
    final item = InvoiceItemBuilder()
        .setDescription(description)
        .setQuantity(quantity)
        .setUnitPrice(unitPrice)
        .setUnit('pieces')
        .setTaxable(taxRate != null)
        .setTaxRate(taxRate)
        .build();

    return item.copyWith(sku: sku);
  }

  static InvoiceItemModel expense({
    required String description,
    required double amount,
    String? receiptId,
    double? taxRate,
  }) {
    final item = InvoiceItemBuilder()
        .setDescription('Expense: $description')
        .setQuantity(1)
        .setUnitPrice(amount)
        .setUnit('expense')
        .setTaxable(taxRate != null)
        .setTaxRate(taxRate)
        .build();

    return item.copyWith(receiptId: receiptId);
  }
}
