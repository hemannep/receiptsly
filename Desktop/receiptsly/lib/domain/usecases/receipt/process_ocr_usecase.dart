import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../entities/receipt_entity.dart';
import '../../repositories/i_receipt_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/ocr/ocr_service.dart';

class ProcessOCRUseCase {
  final IReceiptRepository _receiptRepository;
  final OCRService _ocrService;

  ProcessOCRUseCase(this._receiptRepository, this._ocrService);

  Future<Either<Failure, ReceiptEntity>> call(ProcessOCRParams params) async {
    try {
      // Get receipt entity
      final receiptResult = await _receiptRepository.getById(params.receiptId);

      return receiptResult.fold((failure) => Left(failure), (receipt) async {
        // Check if already processed
        if (receipt.ocrData != null && receipt.ocrData!.confidence > 0.7) {
          return Right(receipt);
        }

        // Process OCR
        final ocrResult = await _processReceiptOCR(receipt, params);

        return ocrResult.fold(
          (failure) => Left(failure),
          (updatedReceipt) => Right(updatedReceipt),
        );
      });
    } catch (e) {
      return Left(
        OCRProcessingFailure('OCR processing failed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, ReceiptEntity>> _processReceiptOCR(
    ReceiptEntity receipt,
    ProcessOCRParams params,
  ) async {
    try {
      // Get image file
      File? imageFile;

      if (receipt.imageLocalPath != null) {
        imageFile = File(receipt.imageLocalPath!);
      } else if (receipt.imageUrl != null) {
        // Download image if only URL is available
        final downloadResult = await _receiptRepository.downloadImage(
          receipt.imageUrl!,
        );
        imageFile = downloadResult.fold((failure) => null, (file) => file);
      }

      if (imageFile == null || !await imageFile.exists()) {
        return Left(OCRProcessingFailure('Image file not found'));
      }

      // Process with OCR service
      final ocrResult = await _ocrService.processReceiptImage(imageFile);

      if (!ocrResult.success) {
        return Left(
          OCRProcessingFailure(ocrResult.error ?? 'OCR processing failed'),
        );
      }

      // Extract and validate OCR data
      final extractedData = _extractAndValidateData(
        ocrResult.data!,
        ocrResult.rawText!,
      );

      // Create OCR data entity
      final ocrData = OCRDataEntity(
        rawText: ocrResult.rawText!,
        vendor: extractedData.vendor,
        amount: extractedData.amount,
        date: extractedData.date,
        items: extractedData.items,
        category: extractedData.category,
        currency: extractedData.currency,
        taxAmount: extractedData.taxAmount,
        confidence: ocrResult.confidence ?? 0.0,
        extractedAt: DateTime.now(),
        needsReview: _needsManualReview(
          extractedData,
          ocrResult.confidence ?? 0.0,
        ),
      );

      // Update receipt with OCR data
      final updatedReceipt = receipt.copyWith(
        ocrData: ocrData,
        vendor: extractedData.vendor,
        amount: extractedData.amount,
        date: extractedData.date,
        category: extractedData.category,
        status: ocrData.needsReview
            ? ReceiptStatus.needsReview
            : ReceiptStatus.processed,
        updatedAt: DateTime.now(),
      );

      // Save updated receipt
      final saveResult = await _receiptRepository.update(updatedReceipt);

      return saveResult.fold((failure) => Left(failure), (savedReceipt) async {
        // Queue for categorization if confidence is high enough
        if (ocrData.confidence > 0.8) {
          await _receiptRepository.queueForCategorization(savedReceipt.id);
        }

        return Right(savedReceipt);
      });
    } catch (e) {
      return Left(
        OCRProcessingFailure('OCR processing error: ${e.toString()}'),
      );
    }
  }

  ExtractedReceiptData _extractAndValidateData(
    ReceiptData rawData,
    String rawText,
  ) {
    // Validate and clean extracted data
    final vendor = _validateVendor(rawData.vendor);
    final amount = _validateAmount(rawData.amount);
    final date = _validateDate(rawData.date);
    final category = _validateCategory(rawData.category);
    final currency = _validateCurrency(rawData.currency);
    final taxAmount = _validateTaxAmount(rawData.taxAmount, amount);

    // Extract line items with validation
    final items = _validateItems(rawData.items);

    return ExtractedReceiptData(
      vendor: vendor,
      amount: amount,
      date: date,
      items: items,
      category: category,
      currency: currency,
      taxAmount: taxAmount,
    );
  }

  String _validateVendor(String? vendor) {
    if (vendor == null || vendor.trim().isEmpty || vendor.length < 2) {
      return 'Unknown Vendor';
    }

    // Clean vendor name
    vendor = vendor.trim();

    // Remove common prefixes/suffixes
    vendor = vendor.replaceAll(
      RegExp(r'^(the|a|an)\s+', caseSensitive: false),
      '',
    );
    vendor = vendor.replaceAll(
      RegExp(r'\s+(inc|llc|ltd|corp)\.?$', caseSensitive: false),
      '',
    );

    // Capitalize properly
    return _toTitleCase(vendor);
  }

  double _validateAmount(double? amount) {
    if (amount == null || amount <= 0 || amount > 999999) {
      return 0.0;
    }
    return double.parse(amount.toStringAsFixed(2));
  }

  DateTime _validateDate(DateTime? date) {
    if (date == null) {
      return DateTime.now();
    }

    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final oneWeekFromNow = now.add(const Duration(days: 7));

    // Date should be within reasonable range
    if (date.isBefore(oneYearAgo) || date.isAfter(oneWeekFromNow)) {
      return DateTime.now();
    }

    return date;
  }

  String _validateCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return 'General';
    }

    // Map to standard categories
    final standardCategories = {
      'food': 'Food & Dining',
      'dining': 'Food & Dining',
      'restaurant': 'Food & Dining',
      'transportation': 'Transportation',
      'fuel': 'Transportation',
      'gas': 'Transportation',
      'office': 'Office Supplies',
      'supplies': 'Office Supplies',
      'technology': 'Software & Technology',
      'software': 'Software & Technology',
      'travel': 'Travel',
      'hotel': 'Travel',
      'medical': 'Medical & Health',
      'health': 'Medical & Health',
    };

    final lowerCategory = category.toLowerCase();
    for (final key in standardCategories.keys) {
      if (lowerCategory.contains(key)) {
        return standardCategories[key]!;
      }
    }

    return _toTitleCase(category);
  }

  String _validateCurrency(String? currency) {
    if (currency == null || currency.trim().isEmpty) {
      return 'USD'; // Default currency
    }

    // Common currency mappings
    final currencyMap = {
      '\$': 'USD',
      '€': 'EUR',
      '£': 'GBP',
      '¥': 'JPY',
      '₹': 'INR',
    };

    return currencyMap[currency] ?? currency.toUpperCase();
  }

  double? _validateTaxAmount(double? taxAmount, double amount) {
    if (taxAmount == null || taxAmount <= 0) {
      return null;
    }

    // Tax amount shouldn't be more than 50% of total amount
    if (taxAmount > amount * 0.5) {
      return null;
    }

    return double.parse(taxAmount.toStringAsFixed(2));
  }

  List<ReceiptItemEntity> _validateItems(List<ReceiptItem>? items) {
    if (items == null || items.isEmpty) {
      return [];
    }

    return items
        .where((item) => item.description.isNotEmpty)
        .map(
          (item) => ReceiptItemEntity(
            description: _toTitleCase(item.description),
            quantity: item.quantity > 0 ? item.quantity : 1,
            unitPrice: item.unitPrice > 0 ? item.unitPrice : 0.0,
            totalPrice: item.totalPrice > 0 ? item.totalPrice : item.unitPrice,
          ),
        )
        .toList();
  }

  bool _needsManualReview(ExtractedReceiptData data, double confidence) {
    // Low confidence
    if (confidence < 0.7) return true;

    // Missing critical data
    if (data.vendor == 'Unknown Vendor' || data.amount == 0.0) return true;

    // Suspicious amounts
    if (data.amount > 10000) return true;

    // Date too far in past/future
    final now = DateTime.now();
    if (data.date.isBefore(now.subtract(const Duration(days: 90))) ||
        data.date.isAfter(now.add(const Duration(days: 1)))) {
      return true;
    }

    return false;
  }

  String _toTitleCase(String text) {
    return text
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : word,
        )
        .join(' ');
  }
}

class ProcessOCRParams {
  final String receiptId;
  final bool forceReprocess;
  final OCRProcessingOptions? options;

  ProcessOCRParams({
    required this.receiptId,
    this.forceReprocess = false,
    this.options,
  });
}

class OCRProcessingOptions {
  final bool enhanceImage;
  final bool extractLineItems;
  final String? expectedCurrency;
  final String? expectedLanguage;

  OCRProcessingOptions({
    this.enhanceImage = true,
    this.extractLineItems = true,
    this.expectedCurrency,
    this.expectedLanguage,
  });
}

class ExtractedReceiptData {
  final String vendor;
  final double amount;
  final DateTime date;
  final List<ReceiptItemEntity> items;
  final String category;
  final String currency;
  final double? taxAmount;

  ExtractedReceiptData({
    required this.vendor,
    required this.amount,
    required this.date,
    required this.items,
    required this.category,
    required this.currency,
    this.taxAmount,
  });
}
