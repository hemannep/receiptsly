// lib/services/ocr/ml_kit_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../core/constants/app_constants.dart';
import 'ocr_service.dart';

/// ML Kit OCR service for on-device text recognition
class MLKitService {
  final TextRecognizer _textRecognizer;
  final DocumentScanner? _documentScanner;
  final Logger _logger;
  
  static final Map<String, MLKitService> _instances = {};
  
  MLKitService._({
    required TextRecognizer textRecognizer,
    required DocumentScanner? documentScanner,
    required Logger logger,
  }) : _textRecognizer = textRecognizer,
       _documentScanner = documentScanner,
       _logger = logger;

  /// Factory constructor with caching
  factory MLKitService({
    TextRecognitionScript script = TextRecognitionScript.latin,
    required Logger logger,
  }) {
    final key = script.name;
    
    if (!_instances.containsKey(key)) {
      final textRecognizer = TextRecognizer(script: script);
      
      // Initialize document scanner if available
      DocumentScanner? documentScanner;
      try {
        documentScanner = DocumentScanner(
          options: DocumentScannerOptions(
            documentFormat: DocumentFormat.jpeg,
            mode: ScannerMode.full,
            pageLimit: 1,
            isGalleryImport: false,
          ),
        );
      } catch (e) {
        logger.warning('Document scanner not available: $e');
      }
      
      _instances[key] = MLKitService._(
        textRecognizer: textRecognizer,
        documentScanner: documentScanner,
        logger: logger,
      );
    }
    
    return _instances[key]!;
  }

  /// Process image using ML Kit text recognition
  Future<OCRResult> processImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _logger.info('Starting ML Kit text recognition');
      
      // Create input image
      final inputImage = InputImage.fromFile(imageFile);
      
      // Process with text recognizer
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return OCRResult(
          success: false,
          error: 'No text detected in image',
          provider: OCRProvider.mlKit,
          processingTime: stopwatch.elapsed,
        );
      }
      
      // Extract receipt data
      final receiptData = await _extractReceiptData(recognizedText);
      
      // Calculate confidence
      final confidence = _calculateConfidence(recognizedText, receiptData);
      
      stopwatch.stop();
      
      _logger.info('ML Kit processing completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return OCRResult(
        success: true,
        data: receiptData,
        confidence: confidence,
        rawText: recognizedText.text,
        provider: OCRProvider.mlKit,
        processingTime: stopwatch.elapsed,
      );
      
    } catch (e) {
      stopwatch.stop();
      _logger.error('ML Kit text recognition failed: $e');
      
      return OCRResult(
        success: false,
        error: 'ML Kit processing failed: ${e.toString()}',
        provider: OCRProvider.mlKit,
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// Extract structured receipt data from recognized text
  Future<ReceiptData> _extractReceiptData(RecognizedText recognizedText) async {
    final text = recognizedText.text;
    final blocks = recognizedText.blocks;
    
    // Extract components
    final vendor = _extractVendor(blocks);
    final amount = _extractAmount(text, blocks);
    final date = _extractDate(text);
    final items = _extractItems(blocks);
    final category = _predictCategory(vendor, items);
    final currency = _extractCurrency(text);
    final taxAmount = _extractTax(text, amount);
    final paymentMethod = _extractPaymentMethod(text);
    final receiptNumber = _extractReceiptNumber(text);
    
    return ReceiptData(
      vendor: vendor,
      amount: amount,
      date: date,
      items: items,
      category: category,
      currency: currency,
      taxAmount: taxAmount,
      paymentMethod: paymentMethod,
      receiptNumber: receiptNumber,
      metadata: {
        'textBlocks': blocks.length,
        'totalCharacters': text.length,
        'extractionMethod': 'mlkit',
      },
    );
  }

  /// Extract vendor name from text blocks
  String _extractVendor(List<TextBlock> blocks) {
    if (blocks.isEmpty) return 'Unknown Vendor';
    
    // Look for vendor name in first few blocks
    for (int i = 0; i < math.min(blocks.length, 5); i++) {
      final block = blocks[i];
      
      for (final line in block.lines) {
        final text = line.text.trim();
        
        // Skip if looks like date, number, or address
        if (_isLikelyVendorName(text)) {
          return _cleanVendorName(text);
        }
      }
    }
    
    // Fallback to first non-numeric block
    for (final block in blocks) {
      final text = block.text.trim();
      if (text.length > 3 && !_isNumeric(text) && !_isDate(text)) {
        return _cleanVendorName(text);
      }
    }
    
    return 'Unknown Vendor';
  }

  /// Check if text is likely a vendor name
  bool _isLikelyVendorName(String text) {
    if (text.length < 3 || text.length > 50) return false;
    
    // Skip common non-vendor patterns
    final excludePatterns = [
      RegExp(r'^\d+$'), // Only numbers
      RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$'), // Dates
      RegExp(r'^(receipt|thank you|store|copy|customer)$', caseSensitive: false),
      RegExp(r'^\d+\s*(st|nd|rd|th|street|ave|avenue|blvd|road|rd)$', caseSensitive: false),
    ];
    
    for (final pattern in excludePatterns) {
      if (pattern.hasMatch(text)) return false;
    }
    
    // Should contain at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) return false;
    
    return true;
  }

  /// Clean vendor name
  String _cleanVendorName(String text) {
    // Remove common suffixes/prefixes
    text = text.replaceAll(RegExp(r'\b(inc|llc|corp|ltd|co)\b\.?', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'[*#]+'), '');
    text = text.trim();
    
    return text.isEmpty ? 'Unknown Vendor' : text;
  }

  /// Extract amount from text
  double _extractAmount(String fullText, List<TextBlock> blocks) {
    // Look for total patterns first
    final totalPatterns = [
      RegExp(r'(?:total|amount due|grand total|balance due)[\s:]*\$?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(?:^|\s)total[\s:]*\$?([\d,]+\.\d{2})', caseSensitive: false),
    ];
    
    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) return amount;
      }
    }
    
    // Look for currency amounts in blocks (bottom-up approach)
    final amounts = <double>[];
    
    for (int i = blocks.length - 1; i >= 0; i--) {
      final block = blocks[i];
      
      for (final line in block.lines) {
        final text = line.text;
        
        // Find currency patterns
        final currencyPatterns = [
          RegExp(r'\$(\d{1,6}(?:,\d{3})*\.\d{2})'), // $123.45, $1,234.56
          RegExp(r'(\d{1,6}(?:,\d{3})*\.\d{2})\s*(?:\$|USD|EUR|GBP)', caseSensitive: false),
        ];
        
        for (final pattern in currencyPatterns) {
          final matches = pattern.allMatches(text);
          for (final match in matches) {
            final amountStr = match.group(1)!.replaceAll(',', '');
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0) {
              amounts.add(amount);
            }
          }
        }
      }
    }
    
    // Return the largest reasonable amount (likely the total)
    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b.compareTo(a));
      return amounts.first;
    }
    
    return 0.0;
  }

  /// Extract date from text
  DateTime _extractDate(String text) {
    final datePatterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{2,4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{2,4})', caseSensitive: false),
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final parsedDate = _parseDate(match.group(0)!);
          if (parsedDate != null && _isReasonableDate(parsedDate)) {
            return parsedDate;
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    return DateTime.now();
  }

  /// Parse date string
  DateTime? _parseDate(String dateStr) {
    try {
      // Handle different date formats
      final monthNames = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      
      // Month name formats
      final monthNamePattern = RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})', caseSensitive: false);
      final monthMatch = monthNamePattern.firstMatch(dateStr);
      
      if (monthMatch != null) {
        final monthStr = monthMatch.group(1)!.toLowerCase().substring(0, 3);
        final day = int.parse(monthMatch.group(2)!);
        var year = int.parse(monthMatch.group(3)!);
        
        if (year < 100) year += 2000;
        
        final month = monthNames[monthStr]!;
        return DateTime(year, month, day);
      }
      
      // Numeric formats
      final numericPattern = RegExp(r'(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})');
      final numMatch = numericPattern.firstMatch(dateStr);
      
      if (numMatch != null) {
        var part1 = int.parse(numMatch.group(1)!);
        final part2 = int.parse(numMatch.group(2)!);
        var part3 = int.parse(numMatch.group(3)!);
        
        // Determine if it's YYYY/MM/DD or MM/DD/YYYY
        int year, month, day;
        
        if (part1 > 31) {
          // YYYY/MM/DD
          year = part1;
          month = part2;
          day = part3;
        } else if (part3 > 31) {
          // MM/DD/YYYY
          month = part1;
          day = part2;
          year = part3;
        } else {
          // Ambiguous, assume MM/DD/YY or MM/DD/YYYY
          month = part1;
          day = part2;
          year = part3;
          if (year < 100) year += 2000;
        }
        
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    
    return null;
  }

  /// Check if date is reasonable (within last 2 years or next month)
  bool _isReasonableDate(DateTime date) {
    final now = DateTime.now();
    final twoYearsAgo = now.subtract(const Duration(days: 730));
    final oneMonthFromNow = now.add(const Duration(days: 31));
    
    return date.isAfter(twoYearsAgo) && date.isBefore(oneMonthFromNow);
  }

  /// Extract receipt items
  List<ReceiptItem> _extractItems(List<TextBlock> blocks) {
    final items = <ReceiptItem>[];
    
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        
        // Look for item patterns: "Item Name 2.50" or "2x Item Name $5.00"
        final itemPatterns = [
          RegExp(r'^(.+?)\s+\$?(\d+\.?\d*)),
          RegExp(r'^(\d+)x?\s+(.+?)\s+\$?(\d+\.?\d*)),
          RegExp(r'^(.+?)\s+(\d+)\s+\$?(\d+\.?\d*)),
        ];
        
        for (final pattern in itemPatterns) {
          final match = pattern.firstMatch(text);
          if (match != null) {
            try {
              String description;
              int quantity = 1;
              double price;
              
              if (pattern.pattern.startsWith(r'^(\d+)x?')) {
                // Pattern: "2x Item Name $5.00"
                quantity = int.parse(match.group(1)!);
                description = match.group(2)!.trim();
                price = double.parse(match.group(3)!);
              } else if (match.groupCount == 3) {
                // Pattern: "Item Name 2 $5.00"
                description = match.group(1)!.trim();
                quantity = int.tryParse(match.group(2)!) ?? 1;
                price = double.parse(match.group(3)!);
              } else {
                // Pattern: "Item Name 5.00"
                description = match.group(1)!.trim();
                price = double.parse(match.group(2)!);
              }
              
              if (description.isNotEmpty && price > 0 && _isValidItemDescription(description)) {
                items.add(ReceiptItem(
                  description: description,
                  quantity: quantity,
                  unitPrice: price / quantity,
                  totalPrice: price,
                ));
              }
            } catch (e) {
              // Invalid item format, skip
            }
            break;
          }
        }
      }
    }
    
    return items;
  }

  /// Check if description is valid item
  bool _isValidItemDescription(String description) {
    if (description.length < 2 || description.length > 100) return false;
    
    // Exclude common non-item patterns
    final excludePatterns = [
      RegExp(r'^(total|subtotal|tax|discount|change|cash|card|credit), caseSensitive: false),
      RegExp(r'^\d+), // Only numbers
      RegExp(r'^[*#-]+), // Only symbols
      RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}), // Dates
    ];
    
    for (final pattern in excludePatterns) {
      if (pattern.hasMatch(description)) return false;
    }
    
    return true;
  }

  /// Predict category based on vendor and items
  String _predictCategory(String vendor, List<ReceiptItem> items) {
    final vendorLower = vendor.toLowerCase();
    final itemsText = items.map((item) => item.description.toLowerCase()).join(' ');
    
    // Food & Dining
    final foodKeywords = ['restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'food', 'diner', 'kitchen', 'bar', 'grill'];
    if (foodKeywords.any((keyword) => vendorLower.contains(keyword)) ||
        ['food', 'meal', 'drink', 'coffee', 'sandwich', 'pizza'].any((keyword) => itemsText.contains(keyword))) {
      return 'Food & Dining';
    }
    
    // Transportation
    final transportKeywords = ['gas', 'fuel', 'shell', 'chevron', 'bp', 'exxon', 'mobil', 'station'];
    if (transportKeywords.any((keyword) => vendorLower.contains(keyword)) ||
        ['gas', 'fuel', 'diesel'].any((keyword) => itemsText.contains(keyword))) {
      return 'Transportation';
    }
    
    // Office Supplies
    final officeKeywords = ['office', 'staples', 'depot', 'supplies', 'store', 'paper'];
    if (officeKeywords.any((keyword) => vendorLower.contains(keyword)) ||
        ['paper', 'pen', 'stapler', 'notebook'].any((keyword) => itemsText.contains(keyword))) {
      return 'Office Supplies';
    }
    
    // Technology
    final techKeywords = ['apple', 'microsoft', 'google', 'adobe', 'tech', 'computer', 'software'];
    if (techKeywords.any((keyword) => vendorLower.contains(keyword)) ||
        ['software', 'app', 'subscription', 'license'].any((keyword) => itemsText.contains(keyword))) {
      return 'Software & Technology';
    }
    
    // Healthcare
    final healthKeywords = ['pharmacy', 'medical', 'clinic', 'hospital', 'health', 'care'];
    if (healthKeywords.any((keyword) => vendorLower.contains(keyword))) {
      return 'Healthcare';
    }
    
    // Retail
    final retailKeywords = ['store', 'shop', 'market', 'mall', 'retail'];
    if (retailKeywords.any((keyword) => vendorLower.contains(keyword))) {
      return 'Retail';
    }
    
    return 'General';
  }

  /// Extract currency symbol
  String? _extractCurrency(String text) {
    final currencyPatterns = [
      RegExp(r'\$(\d+\.?\d*)'), // USD
      RegExp(r'€(\d+\.?\d*)'), // EUR
      RegExp(r'£(\d+\.?\d*)'), // GBP
      RegExp(r'¥(\d+\.?\d*)'), // JPY
      RegExp(r'(\d+\.?\d*)\s*(USD|EUR|GBP|JPY|CAD|AUD)', caseSensitive: false),
    ];
    
    for (final pattern in currencyPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final fullMatch = match.group(0)!;
        if (fullMatch.contains('\)) return 'USD';
        if (fullMatch.contains('€')) return 'EUR';
        if (fullMatch.contains('£')) return 'GBP';
        if (fullMatch.contains('¥')) return 'JPY';
        if (fullMatch.contains('USD')) return 'USD';
        if (fullMatch.contains('EUR')) return 'EUR';
        if (fullMatch.contains('GBP')) return 'GBP';
        if (fullMatch.contains('JPY')) return 'JPY';
        if (fullMatch.contains('CAD')) return 'CAD';
        if (fullMatch.contains('AUD')) return 'AUD';
      }
    }
    
    return 'USD'; // Default
  }

  /// Extract tax amount
  double? _extractTax(String text, double totalAmount) {
    final taxPatterns = [
      RegExp(r'(?:tax|vat|gst)[\s:]*\$?(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)%?\s*(?:tax|vat|gst)', caseSensitive: false),
    ];
    
    for (final pattern in taxPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final taxStr = match.group(1)!;
        final tax = double.tryParse(taxStr);
        if (tax != null) {
          // If tax seems to be a percentage, convert to amount
          if (tax < 1.0 && tax > 0) {
            return totalAmount * tax;
          } else if (tax > 0 && tax < totalAmount) {
            return tax;
          }
        }
      }
    }
    
    return null;
  }

  /// Extract payment method
  String? _extractPaymentMethod(String text) {
    final paymentPatterns = [
      RegExp(r'\b(cash|credit|debit|card|visa|mastercard|amex|discover)\b', caseSensitive: false),
    ];
    
    for (final pattern in paymentPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.toLowerCase();
      }
    }
    
    return null;
  }

  /// Extract receipt number
  String? _extractReceiptNumber(String text) {
    final receiptPatterns = [
      RegExp(r'(?:receipt|ref|reference|confirmation)[\s#:]*([A-Z0-9]{4,})', caseSensitive: false),
      RegExp(r'#([A-Z0-9]{4,})', caseSensitive: false),
    ];
    
    for (final pattern in receiptPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!;
      }
    }
    
    return null;
  }

  /// Calculate confidence score based on extracted data
  double _calculateConfidence(RecognizedText recognizedText, ReceiptData data) {
    double confidence = 0.0;
    
    // Base confidence from text quality
    final textLength = recognizedText.text.length;
    if (textLength > 50) confidence += 0.2;
    if (textLength > 100) confidence += 0.1;
    
    // Vendor confidence
    if (data.vendor != 'Unknown Vendor' && data.vendor.isNotEmpty) {
      confidence += 0.25;
    }
    
    // Amount confidence
    if (data.amount > 0) {
      confidence += 0.25;
      if (data.amount > 1 && data.amount < 10000) {
        confidence += 0.1; // Reasonable amount range
      }
    }
    
    // Date confidence
    if (_isReasonableDate(data.date)) {
      confidence += 0.15;
    }
    
    // Items confidence
    if (data.items.isNotEmpty) {
      confidence += 0.1;
      if (data.items.length > 1) {
        confidence += 0.05;
      }
    }
    
    // Additional fields confidence
    if (data.currency != null) confidence += 0.05;
    if (data.taxAmount != null) confidence += 0.05;
    if (data.receiptNumber != null) confidence += 0.05;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Helper methods
  bool _isNumeric(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), '')) != null;
  }

  bool _isDate(String text) {
    final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    return datePattern.hasMatch(text);
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _documentScanner?.close();
  }
}

/// Provider for ML Kit service
final mlKitServiceProvider = Provider<MLKitService>((ref) {
  return MLKitService(
    script: TextRecognitionScript.latin,
    logger: ref.read(loggerProvider),
  );
});

/// Provider for different scripts
final mlKitChineseServiceProvider = Provider<MLKitService>((ref) {
  return MLKitService(
    script: TextRecognitionScript.chinese,
    logger: ref.read(loggerProvider),
  );
});

final mlKitDevanagariServiceProvider = Provider<MLKitService>((ref) {
  return MLKitService(
    script: TextRecognitionScript.devanagari,
    logger: ref.read(loggerProvider),
  );
});

final mlKitJapaneseServiceProvider = Provider<MLKitService>((ref) {
  return MLKitService(
    script: TextRecognitionScript.japanese,
    logger: ref.read(loggerProvider),
  );
});

final mlKitKoreanServiceProvider = Provider<MLKitService>((ref) {
  return MLKitService(
    script: TextRecognitionScript.korean,
    logger: ref.read(loggerProvider),
  );
});