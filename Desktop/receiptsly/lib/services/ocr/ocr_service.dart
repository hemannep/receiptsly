// lib/services/ocr/ocr_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import 'ml_kit_service.dart';
import 'cloud_vision_service.dart';

/// Main OCR service that orchestrates different OCR providers
class OCRService {
  final MLKitService _mlKitService;
  final CloudVisionService _cloudVisionService;
  final Logger _logger;

  OCRService({
    required MLKitService mlKitService,
    required CloudVisionService cloudVisionService,
    required Logger logger,
  }) : _mlKitService = mlKitService,
       _cloudVisionService = cloudVisionService,
       _logger = logger;

  /// Process receipt image with fallback strategy
  Future<OCRResult> processReceiptImage(
    File imageFile, {
    OCRProvider provider = OCRProvider.mlKit,
    bool enableFallback = true,
  }) async {
    try {
      _logger.info('Starting OCR processing for image: ${imageFile.path}');

      // Validate input file
      await _validateImageFile(imageFile);

      // Optimize image for better OCR results
      final optimizedImage = await _optimizeImageForOCR(imageFile);

      OCRResult? result;

      // Try primary provider
      try {
        switch (provider) {
          case OCRProvider.mlKit:
            result = await _mlKitService.processImage(optimizedImage);
            break;
          case OCRProvider.cloudVision:
            result = await _cloudVisionService.processImage(optimizedImage);
            break;
        }
      } catch (e) {
        _logger.warning('Primary OCR provider failed: $e');
        if (!enableFallback) rethrow;
      }

      // Fallback to alternative provider if enabled and primary failed
      if (result == null || !result.success && enableFallback) {
        _logger.info('Attempting fallback OCR provider');
        try {
          switch (provider) {
            case OCRProvider.mlKit:
              result = await _cloudVisionService.processImage(optimizedImage);
              break;
            case OCRProvider.cloudVision:
              result = await _mlKitService.processImage(optimizedImage);
              break;
          }
        } catch (e) {
          _logger.error('Fallback OCR provider also failed: $e');
        }
      }

      // Clean up optimized image
      if (optimizedImage.path != imageFile.path) {
        await optimizedImage.delete();
      }

      if (result == null || !result.success) {
        throw OCRException('All OCR providers failed to process image');
      }

      // Enhance result with additional processing
      result = await _enhanceOCRResult(result, imageFile);

      _logger.info('OCR processing completed successfully');
      return result;
    } catch (e) {
      _logger.error('OCR processing failed: $e');
      throw OCRException('Failed to process image: ${e.toString()}');
    }
  }

  /// Validate image file before processing
  Future<void> _validateImageFile(File imageFile) async {
    if (!await imageFile.exists()) {
      throw OCRException('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize > 50 * 1024 * 1024) {
      // 50MB limit
      throw OCRException('Image file too large (max 50MB)');
    }

    if (fileSize < 1024) {
      // 1KB minimum
      throw OCRException('Image file too small');
    }

    // Validate file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw OCRException('Unsupported image format: $extension');
    }
  }

  /// Optimize image for better OCR results
  Future<File> _optimizeImageForOCR(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw OCRException('Failed to decode image');
      }

      // Apply image optimizations
      image = _applyImageOptimizations(image);

      // Save optimized image
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final optimizedFile = File(
        '${tempDir.path}/ocr_optimized_$timestamp.jpg',
      );

      final optimizedBytes = img.encodeJpg(image, quality: 90);
      await optimizedFile.writeAsBytes(optimizedBytes);

      _logger.debug(
        'Image optimized: ${imageFile.path} -> ${optimizedFile.path}',
      );
      return optimizedFile;
    } catch (e) {
      _logger.warning('Image optimization failed, using original: $e');
      return imageFile;
    }
  }

  /// Apply various image optimizations for better OCR
  img.Image _applyImageOptimizations(img.Image image) {
    // Resize if too large (max 2048px on longest side)
    if (image.width > 2048 || image.height > 2048) {
      final aspectRatio = image.width / image.height;
      int newWidth, newHeight;

      if (image.width > image.height) {
        newWidth = 2048;
        newHeight = (2048 / aspectRatio).round();
      } else {
        newHeight = 2048;
        newWidth = (2048 * aspectRatio).round();
      }

      image = img.copyResize(image, width: newWidth, height: newHeight);
    }

    // Convert to grayscale for better text recognition
    image = img.grayscale(image);

    // Enhance contrast
    image = img.adjustColor(image, contrast: 1.2);

    // Apply slight sharpening
    image = img.convolution(image, [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    // Normalize brightness
    image = img.normalize(image, 0, 255);

    return image;
  }

  /// Enhance OCR result with additional processing
  Future<OCRResult> _enhanceOCRResult(
    OCRResult result,
    File originalImage,
  ) async {
    try {
      if (result.data == null) return result;

      final enhancedData = result.data!.copyWith(
        // Add image metadata
        imageSize: await originalImage.length(),
        imageDimensions: await _getImageDimensions(originalImage),
        // Improve confidence scoring
        confidence: _calculateEnhancedConfidence(result),
        // Add processing timestamp
        processedAt: DateTime.now(),
      );

      return result.copyWith(data: enhancedData);
    } catch (e) {
      _logger.warning('Failed to enhance OCR result: $e');
      return result;
    }
  }

  /// Get image dimensions
  Future<Map<String, int>> _getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        return {'width': image.width, 'height': image.height};
      }
    } catch (e) {
      _logger.warning('Failed to get image dimensions: $e');
    }

    return {'width': 0, 'height': 0};
  }

  /// Calculate enhanced confidence score
  double _calculateEnhancedConfidence(OCRResult result) {
    if (result.data == null) return 0.0;

    double confidence = result.confidence ?? 0.0;

    // Boost confidence based on data quality
    final data = result.data!;

    // Check if essential fields are present
    if (data.vendor.isNotEmpty && data.vendor != 'Unknown') {
      confidence += 0.1;
    }

    if (data.amount > 0) {
      confidence += 0.15;
    }

    if (data.date.difference(DateTime.now()).abs().inDays < 90) {
      confidence += 0.1;
    }

    // Penalize if text is too short or garbled
    if (result.rawText != null && result.rawText!.length < 50) {
      confidence -= 0.2;
    }

    return (confidence).clamp(0.0, 1.0);
  }

  /// Process multiple images in batch
  Future<List<OCRResult>> processBatchImages(
    List<File> imageFiles, {
    OCRProvider provider = OCRProvider.mlKit,
    bool enableFallback = true,
    int maxConcurrency = 3,
  }) async {
    final results = <OCRResult>[];

    // Process in batches to avoid overwhelming the system
    for (int i = 0; i < imageFiles.length; i += maxConcurrency) {
      final batch = imageFiles.skip(i).take(maxConcurrency).toList();

      final batchResults = await Future.wait(
        batch.map(
          (file) => processReceiptImage(
            file,
            provider: provider,
            enableFallback: enableFallback,
          ),
        ),
      );

      results.addAll(batchResults);
    }

    return results;
  }

  /// Dispose of resources
  void dispose() {
    _mlKitService.dispose();
    _cloudVisionService.dispose();
  }
}

/// OCR Provider enum
enum OCRProvider { mlKit, cloudVision }

/// OCR Result model
class OCRResult {
  final bool success;
  final ReceiptData? data;
  final double? confidence;
  final String? rawText;
  final String? error;
  final Duration? processingTime;
  final OCRProvider? provider;

  const OCRResult({
    required this.success,
    this.data,
    this.confidence,
    this.rawText,
    this.error,
    this.processingTime,
    this.provider,
  });

  OCRResult copyWith({
    bool? success,
    ReceiptData? data,
    double? confidence,
    String? rawText,
    String? error,
    Duration? processingTime,
    OCRProvider? provider,
  }) {
    return OCRResult(
      success: success ?? this.success,
      data: data ?? this.data,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      error: error ?? this.error,
      processingTime: processingTime ?? this.processingTime,
      provider: provider ?? this.provider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
      'confidence': confidence,
      'rawText': rawText,
      'error': error,
      'processingTime': processingTime?.inMilliseconds,
      'provider': provider?.name,
    };
  }

  @override
  String toString() {
    return 'OCRResult(success: $success, confidence: $confidence, provider: $provider)';
  }
}

/// Receipt data model
class ReceiptData {
  final String vendor;
  final double amount;
  final DateTime date;
  final List<ReceiptItem> items;
  final String category;
  final String? currency;
  final double? taxAmount;
  final String? paymentMethod;
  final String? receiptNumber;
  final Map<String, dynamic>? metadata;
  final int? imageSize;
  final Map<String, int>? imageDimensions;
  final DateTime? processedAt;

  const ReceiptData({
    required this.vendor,
    required this.amount,
    required this.date,
    required this.items,
    required this.category,
    this.currency,
    this.taxAmount,
    this.paymentMethod,
    this.receiptNumber,
    this.metadata,
    this.imageSize,
    this.imageDimensions,
    this.processedAt,
  });

  ReceiptData copyWith({
    String? vendor,
    double? amount,
    DateTime? date,
    List<ReceiptItem>? items,
    String? category,
    String? currency,
    double? taxAmount,
    String? paymentMethod,
    String? receiptNumber,
    Map<String, dynamic>? metadata,
    int? imageSize,
    Map<String, int>? imageDimensions,
    DateTime? processedAt,
  }) {
    return ReceiptData(
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      items: items ?? this.items,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      metadata: metadata ?? this.metadata,
      imageSize: imageSize ?? this.imageSize,
      imageDimensions: imageDimensions ?? this.imageDimensions,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendor,
      'amount': amount,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'category': category,
      'currency': currency,
      'taxAmount': taxAmount,
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      'metadata': metadata,
      'imageSize': imageSize,
      'imageDimensions': imageDimensions,
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      vendor: json['vendor'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      items: (json['items'] as List? ?? [])
          .map((item) => ReceiptItem.fromJson(item))
          .toList(),
      category: json['category'] ?? 'General',
      currency: json['currency'],
      taxAmount: json['taxAmount']?.toDouble(),
      paymentMethod: json['paymentMethod'],
      receiptNumber: json['receiptNumber'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      imageSize: json['imageSize']?.toInt(),
      imageDimensions: json['imageDimensions']?.cast<String, int>(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
    );
  }
}

/// Receipt item model
class ReceiptItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const ReceiptItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }
}

/// OCR Service Provider
final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService(
    mlKitService: ref.read(mlKitServiceProvider),
    cloudVisionService: ref.read(cloudVisionServiceProvider),
    logger: ref.read(loggerProvider),
  );
});

/// OCR Exception
class OCRException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const OCRException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'OCRException: $message';
}
