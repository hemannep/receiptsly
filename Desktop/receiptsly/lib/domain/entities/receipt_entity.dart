// lib/domain/entities/receipt_entity.dart
import 'package:equatable/equatable.dart';

/// Receipt entity representing a receipt in the business domain
/// Contains all business rules and logic for receipt management
class ReceiptEntity extends Equatable {
  final String id;
  final String userId;
  final String vendor;
  final double amount;
  final DateTime date;
  final String category;
  final String? subcategory;
  final String currency;
  final String? description;
  final String? notes;
  final List<String> tags;
  final ReceiptImage image;
  final OCRData ocrData;
  final ReceiptStatus status;
  final ReceiptSource source;
  final SyncStatus syncStatus;
  final double? taxAmount;
  final double? tipAmount;
  final PaymentMethod? paymentMethod;
  final String? projectId;
  final String? clientId;
  final bool isBillable;
  final bool isReimbursable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? externalId; // For chat integrations
  final Map<String, dynamic> metadata;

  const ReceiptEntity({
    required this.id,
    required this.userId,
    required this.vendor,
    required this.amount,
    required this.date,
    required this.category,
    this.subcategory,
    this.currency = 'USD',
    this.description,
    this.notes,
    this.tags = const [],
    required this.image,
    required this.ocrData,
    this.status = ReceiptStatus.pending,
    this.source = ReceiptSource.mobile,
    this.syncStatus = SyncStatus.pending,
    this.taxAmount,
    this.tipAmount,
    this.paymentMethod,
    this.projectId,
    this.clientId,
    this.isBillable = false,
    this.isReimbursable = false,
    required this.createdAt,
    required this.updatedAt,
    this.externalId,
    this.metadata = const {},
  });

  /// Check if receipt is fully processed and validated
  bool get isProcessed {
    return status == ReceiptStatus.processed && ocrData.confidence >= 0.7;
  }

  /// Check if receipt needs manual review
  bool get needsReview {
    return status == ReceiptStatus.needsReview ||
        ocrData.confidence < 0.7 ||
        amount <= 0 ||
        vendor.trim().isEmpty;
  }

  /// Check if receipt is ready for expense reporting
  bool get isReadyForReporting {
    return isProcessed &&
        amount > 0 &&
        vendor.isNotEmpty &&
        category.isNotEmpty;
  }

  /// Get total amount including tax and tip
  double get totalAmount {
    return amount + (taxAmount ?? 0) + (tipAmount ?? 0);
  }

  /// Get subtotal (amount without tax and tip)
  double get subtotal {
    return amount - (taxAmount ?? 0) - (tipAmount ?? 0);
  }

  /// Check if receipt is from a chat integration
  bool get isFromChatbot {
    return source == ReceiptSource.whatsapp || source == ReceiptSource.telegram;
  }

  /// Check if receipt is synced to cloud
  bool get isSynced {
    return syncStatus == SyncStatus.synced;
  }

  /// Check if receipt has failed sync
  bool get hasFailedSync {
    return syncStatus == SyncStatus.failed;
  }

  /// Business rule: Can receipt be edited?
  bool get canBeEdited {
    return status != ReceiptStatus.archived && status != ReceiptStatus.deleted;
  }

  /// Business rule: Can receipt be deleted?
  bool get canBeDeleted {
    return status != ReceiptStatus.archived && status != ReceiptStatus.deleted;
  }

  /// Business rule: Can receipt be marked as billable?
  bool get canMarkAsBillable {
    return clientId != null && projectId != null;
  }

  /// Get age of receipt in days
  int get ageInDays {
    return DateTime.now().difference(date).inDays;
  }

  /// Check if receipt is recent (within last 30 days)
  bool get isRecent {
    return ageInDays <= 30;
  }

  /// Check if receipt is old (older than 1 year)
  bool get isOld {
    return ageInDays > 365;
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get formatted total amount with currency
  String get formattedTotalAmount {
    return '$currency ${totalAmount.toStringAsFixed(2)}';
  }

  /// Validate receipt data
  List<String> validate() {
    final errors = <String>[];

    if (amount <= 0) {
      errors.add('Amount must be greater than zero');
    }

    if (vendor.trim().isEmpty) {
      errors.add('Vendor name is required');
    }

    if (category.trim().isEmpty) {
      errors.add('Category is required');
    }

    if (date.isAfter(DateTime.now())) {
      errors.add('Receipt date cannot be in the future');
    }

    if (taxAmount != null && taxAmount! < 0) {
      errors.add('Tax amount cannot be negative');
    }

    if (tipAmount != null && tipAmount! < 0) {
      errors.add('Tip amount cannot be negative');
    }

    return errors;
  }

  /// Create a copy with updated OCR confidence
  ReceiptEntity withUpdatedOCRConfidence(double confidence) {
    return copyWith(
      ocrData: ocrData.copyWith(confidence: confidence),
      status: confidence >= 0.7
          ? ReceiptStatus.processed
          : ReceiptStatus.needsReview,
    );
  }

  /// Mark as reviewed and processed
  ReceiptEntity markAsProcessed() {
    return copyWith(status: ReceiptStatus.processed, updatedAt: DateTime.now());
  }

  /// Mark as needing review
  ReceiptEntity markAsNeedsReview(String reason) {
    return copyWith(
      status: ReceiptStatus.needsReview,
      metadata: {...metadata, 'reviewReason': reason},
      updatedAt: DateTime.now(),
    );
  }

  /// Update sync status
  ReceiptEntity updateSyncStatus(SyncStatus newStatus) {
    return copyWith(syncStatus: newStatus, updatedAt: DateTime.now());
  }

  /// Add tag to receipt
  ReceiptEntity addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag], updatedAt: DateTime.now());
  }

  /// Remove tag from receipt
  ReceiptEntity removeTag(String tag) {
    return copyWith(
      tags: tags.where((t) => t != tag).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Archive receipt
  ReceiptEntity archive() {
    return copyWith(status: ReceiptStatus.archived, updatedAt: DateTime.now());
  }

  ReceiptEntity copyWith({
    String? id,
    String? userId,
    String? vendor,
    double? amount,
    DateTime? date,
    String? category,
    String? subcategory,
    String? currency,
    String? description,
    String? notes,
    List<String>? tags,
    ReceiptImage? image,
    OCRData? ocrData,
    ReceiptStatus? status,
    ReceiptSource? source,
    SyncStatus? syncStatus,
    double? taxAmount,
    double? tipAmount,
    PaymentMethod? paymentMethod,
    String? projectId,
    String? clientId,
    bool? isBillable,
    bool? isReimbursable,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? externalId,
    Map<String, dynamic>? metadata,
  }) {
    return ReceiptEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      image: image ?? this.image,
      ocrData: ocrData ?? this.ocrData,
      status: status ?? this.status,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      isBillable: isBillable ?? this.isBillable,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      externalId: externalId ?? this.externalId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    vendor,
    amount,
    date,
    category,
    subcategory,
    currency,
    description,
    notes,
    tags,
    image,
    ocrData,
    status,
    source,
    syncStatus,
    taxAmount,
    tipAmount,
    paymentMethod,
    projectId,
    clientId,
    isBillable,
    isReimbursable,
    createdAt,
    updatedAt,
    externalId,
    metadata,
  ];

  @override
  String toString() {
    return 'ReceiptEntity(id: $id, vendor: $vendor, amount: $amount, status: $status)';
  }
}

/// Receipt image information
class ReceiptImage extends Equatable {
  final String originalUrl;
  final String? thumbnailUrl;
  final String? processedUrl;
  final int? fileSize;
  final String? mimeType;
  final int? width;
  final int? height;
  final ImageQuality quality;
  final bool isCompressed;

  const ReceiptImage({
    required this.originalUrl,
    this.thumbnailUrl,
    this.processedUrl,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.quality = ImageQuality.medium,
    this.isCompressed = false,
  });

  /// Check if image has good quality for OCR
  bool get hasGoodQuality {
    return quality == ImageQuality.high || quality == ImageQuality.medium;
  }

  /// Get best available image URL
  String get bestImageUrl {
    return processedUrl ?? originalUrl;
  }

  ReceiptImage copyWith({
    String? originalUrl,
    String? thumbnailUrl,
    String? processedUrl,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    ImageQuality? quality,
    bool? isCompressed,
  }) {
    return ReceiptImage(
      originalUrl: originalUrl ?? this.originalUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      processedUrl: processedUrl ?? this.processedUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      quality: quality ?? this.quality,
      isCompressed: isCompressed ?? this.isCompressed,
    );
  }

  @override
  List<Object?> get props => [
    originalUrl,
    thumbnailUrl,
    processedUrl,
    fileSize,
    mimeType,
    width,
    height,
    quality,
    isCompressed,
  ];
}

/// OCR extracted data from receipt
class OCRData extends Equatable {
  final String rawText;
  final double confidence;
  final String? extractedVendor;
  final double? extractedAmount;
  final DateTime? extractedDate;
  final String? extractedCategory;
  final List<ReceiptItem> items;
  final String? extractedTax;
  final String? extractedTotal;
  final Map<String, dynamic> boundingBoxes;
  final OCRProvider provider;
  final DateTime processedAt;

  const OCRData({
    required this.rawText,
    required this.confidence,
    this.extractedVendor,
    this.extractedAmount,
    this.extractedDate,
    this.extractedCategory,
    this.items = const [],
    this.extractedTax,
    this.extractedTotal,
    this.boundingBoxes = const {},
    this.provider = OCRProvider.mlKit,
    required this.processedAt,
  });

  /// Check if OCR data has high confidence
  bool get hasHighConfidence {
    return confidence >= 0.8;
  }

  /// Check if OCR data has acceptable confidence
  bool get hasAcceptableConfidence {
    return confidence >= 0.6;
  }

  /// Check if OCR data has low confidence and needs review
  bool get hasLowConfidence {
    return confidence < 0.6;
  }

  /// Get formatted confidence percentage
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(0)}%';
  }

  OCRData copyWith({
    String? rawText,
    double? confidence,
    String? extractedVendor,
    double? extractedAmount,
    DateTime? extractedDate,
    String? extractedCategory,
    List<ReceiptItem>? items,
    String? extractedTax,
    String? extractedTotal,
    Map<String, dynamic>? boundingBoxes,
    OCRProvider? provider,
    DateTime? processedAt,
  }) {
    return OCRData(
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      extractedVendor: extractedVendor ?? this.extractedVendor,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedCategory: extractedCategory ?? this.extractedCategory,
      items: items ?? this.items,
      extractedTax: extractedTax ?? this.extractedTax,
      extractedTotal: extractedTotal ?? this.extractedTotal,
      boundingBoxes: boundingBoxes ?? this.boundingBoxes,
      provider: provider ?? this.provider,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  List<Object?> get props => [
    rawText,
    confidence,
    extractedVendor,
    extractedAmount,
    extractedDate,
    extractedCategory,
    items,
    extractedTax,
    extractedTotal,
    boundingBoxes,
    provider,
    processedAt,
  ];
}

/// Individual item from receipt
class ReceiptItem extends Equatable {
  final String description;
  final double? quantity;
  final double? unitPrice;
  final double? amount;
  final String? category;

  const ReceiptItem({
    required this.description,
    this.quantity,
    this.unitPrice,
    this.amount,
    this.category,
  });

  /// Calculate total amount for this item
  double get totalAmount {
    if (amount != null) return amount!;
    if (quantity != null && unitPrice != null) {
      return quantity! * unitPrice!;
    }
    return 0.0;
  }

  ReceiptItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    double? amount,
    String? category,
  }) {
    return ReceiptItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
    description,
    quantity,
    unitPrice,
    amount,
    category,
  ];
}

/// Enums for receipt-related data
enum ReceiptStatus {
  pending,
  processing,
  processed,
  needsReview,
  approved,
  rejected,
  archived,
  deleted,
}

enum ReceiptSource { mobile, web, whatsapp, telegram, email, api }

enum SyncStatus { pending, syncing, synced, failed, conflict }

enum ImageQuality { low, medium, high, original }

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  digitalWallet,
  check,
  other,
}

enum OCRProvider { mlKit, googleVision, awsTextract, azureVision, tesseract }
