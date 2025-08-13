// lib/data/models/receipt/receipt_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@freezed
class ReceiptModel with _$ReceiptModel {
  const factory ReceiptModel({
    required String id,
    required String userId,
    required String vendor,
    required double amount,
    @TimestampConverter() required DateTime date,
    required String category,
    required String currency,
    required ReceiptStatus status,
    required String imageUrl,
    String? thumbnailUrl,
    String? notes,
    String? description,
    double? taxAmount,
    String? taxType, // VAT, GST, Sales Tax, etc.
    String? paymentMethod, // Cash, Card, Check, etc.
    String? receiptNumber,
    String? projectId,
    String? clientId,
    required OCRDataModel ocrData,
    required List<ReceiptItemModel> items,
    required LocationDataModel? location,
    required SyncStatusModel syncStatus,
    required String source, // mobile, whatsapp, telegram, web
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @TimestampConverter() DateTime? processedAt,
    @TimestampConverter() DateTime? reviewedAt,
    String? reviewedBy,
    @Default(false) bool isReimbursable,
    @Default(false) bool isPersonal,
    @Default(false) bool isBillable,
    @Default(false) bool isRecurring,
    @Default([]) List<String> tags,
    Map<String, dynamic>? metadata,
    String? originalFileName,
    int? fileSize,
    @Default(1) int version,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);
}

@freezed
class ReceiptItemModel with _$ReceiptItemModel {
  const factory ReceiptItemModel({
    required String id,
    required String description,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
    String? category,
    String? sku,
    String? notes,
    @Default(false) bool isTaxable,
    double? taxAmount,
    Map<String, dynamic>? metadata,
  }) = _ReceiptItemModel;

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemModelFromJson(json);
}

@freezed
class OCRDataModel with _$OCRDataModel {
  const factory OCRDataModel({
    required String rawText,
    required double confidence,
    String? extractedVendor,
    double? extractedAmount,
    String? extractedDate,
    String? extractedCategory,
    String? extractedCurrency,
    double? extractedTax,
    String? extractedPaymentMethod,
    String? extractedReceiptNumber,
    required List<OCRLineItemModel> extractedItems,
    required BoundingBoxModel? vendorBoundingBox,
    required BoundingBoxModel? amountBoundingBox,
    required BoundingBoxModel? dateBoundingBox,
    @TimestampConverter() required DateTime processedAt,
    required String processingEngine, // ml_kit, google_vision, textract
    String? processingVersion,
    Map<String, dynamic>? additionalData,
    @Default(false) bool requiresReview,
    String? reviewReason,
  }) = _OCRDataModel;

  factory OCRDataModel.fromJson(Map<String, dynamic> json) =>
      _$OCRDataModelFromJson(json);
}

@freezed
class OCRLineItemModel with _$OCRLineItemModel {
  const factory OCRLineItemModel({
    required String text,
    required double confidence,
    String? extractedDescription,
    int? extractedQuantity,
    double? extractedPrice,
    required BoundingBoxModel boundingBox,
  }) = _OCRLineItemModel;

  factory OCRLineItemModel.fromJson(Map<String, dynamic> json) =>
      _$OCRLineItemModelFromJson(json);
}

@freezed
class BoundingBoxModel with _$BoundingBoxModel {
  const factory BoundingBoxModel({
    required double x,
    required double y,
    required double width,
    required double height,
  }) = _BoundingBoxModel;

  factory BoundingBoxModel.fromJson(Map<String, dynamic> json) =>
      _$BoundingBoxModelFromJson(json);
}

@freezed
class LocationDataModel with _$LocationDataModel {
  const factory LocationDataModel({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? accuracy,
    @TimestampConverter() required DateTime capturedAt,
  }) = _LocationDataModel;

  factory LocationDataModel.fromJson(Map<String, dynamic> json) =>
      _$LocationDataModelFromJson(json);
}

@freezed
class SyncStatusModel with _$SyncStatusModel {
  const factory SyncStatusModel({
    @Default(false) bool isSynced,
    @Default(false) bool needsSync,
    @Default(false) bool hasSyncError,
    String? syncError,
    @TimestampConverter() DateTime? lastSyncAttempt,
    @TimestampConverter() DateTime? lastSuccessfulSync,
    @Default(0) int syncRetryCount,
    @Default(3) int maxRetries,
    String? syncVersion,
    Map<String, dynamic>? conflictData,
    @Default(false) bool hasConflict,
  }) = _SyncStatusModel;

  factory SyncStatusModel.fromJson(Map<String, dynamic> json) =>
      _$SyncStatusModelFromJson(json);
}

// Helper class for creating new receipts
class ReceiptModelBuilder {
  String? _id;
  String? _userId;
  String? _vendor;
  double? _amount;
  DateTime? _date;
  String? _category;
  String? _currency;
  ReceiptStatus? _status;
  String? _imageUrl;
  String? _source;

  ReceiptModelBuilder setId(String id) {
    _id = id;
    return this;
  }

  ReceiptModelBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  ReceiptModelBuilder setVendor(String vendor) {
    _vendor = vendor;
    return this;
  }

  ReceiptModelBuilder setAmount(double amount) {
    _amount = amount;
    return this;
  }

  ReceiptModelBuilder setDate(DateTime date) {
    _date = date;
    return this;
  }

  ReceiptModelBuilder setCategory(String category) {
    _category = category;
    return this;
  }

  ReceiptModelBuilder setCurrency(String currency) {
    _currency = currency;
    return this;
  }

  ReceiptModelBuilder setStatus(ReceiptStatus status) {
    _status = status;
    return this;
  }

  ReceiptModelBuilder setImageUrl(String imageUrl) {
    _imageUrl = imageUrl;
    return this;
  }

  ReceiptModelBuilder setSource(String source) {
    _source = source;
    return this;
  }

  ReceiptModel build() {
    final now = DateTime.now();

    return ReceiptModel(
      id: _id ?? '',
      userId: _userId ?? '',
      vendor: _vendor ?? 'Unknown Vendor',
      amount: _amount ?? 0.0,
      date: _date ?? now,
      category: _category ?? 'General',
      currency: _currency ?? 'USD',
      status: _status ?? ReceiptStatus.pending,
      imageUrl: _imageUrl ?? '',
      source: _source ?? 'mobile',
      ocrData: const OCRDataModel(
        rawText: '',
        confidence: 0.0,
        extractedItems: [],
        vendorBoundingBox: null,
        amountBoundingBox: null,
        dateBoundingBox: null,
        processedAt: null,
        processingEngine: '',
      ),
      items: [],
      location: null,
      syncStatus: const SyncStatusModel(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
