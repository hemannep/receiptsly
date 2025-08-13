// lib/services/ocr/cloud_vision_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/environment.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';
import 'ocr_service.dart';

/// Google Cloud Vision OCR service for advanced text recognition
class CloudVisionService {
  final String _apiKey;
  final http.Client _httpClient;
  final Logger _logger;
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';
  
  CloudVisionService({
    required String apiKey,
    required http.Client httpClient,
    required Logger logger,
  }) : _apiKey = apiKey,
       _httpClient = httpClient,
       _logger = logger;

  /// Process image using Google Cloud Vision API
  Future<OCRResult> processImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _logger.info('Starting Google Cloud Vision text detection');
      
      // Convert image to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Prepare request payload
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION', 'maxResults': 1},
              {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1},
            ],
            'imageContext': {
              'textDetectionParams': {
                'enableTextDetectionConfidenceScore': true,
              }
            }
          }
        ]
      };
      
      // Make API request
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw CloudVisionException(
          'API request failed with status ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Check for API errors
      if (responseData.containsKey('error')) {
        final error = responseData['error'] as Map<String, dynamic>;
        throw CloudVisionException(
          'Cloud Vision API error: ${error['message']}',
          code: error['code']?.toString(),
        );
      }
      
      // Extract text annotations
      final responses = responseData['responses'] as List;
      if (responses.isEmpty) {
        return OCRResult(
          success: false,
          error: 'No response from Cloud Vision API',
          provider: OCRProvider.cloudVision,
          processingTime: stopwatch.elapsed,
        );
      }
      
      final response = responses.first as Map<String, dynamic>;
      
      // Check for detection errors
      if (response.containsKey('error')) {
        final error = response['error'] as Map<String, dynamic>;
        throw CloudVisionException(
          'Text detection error: ${error['message']}',
          code: error['code']?.toString(),
        );
      }
      
      // Get text annotations
      final textAnnotations = response['textAnnotations'] as List?;
      final fullTextAnnotation = response['fullTextAnnotation'] as Map<String, dynamic>?;
      
      if (textAnnotations == null || textAnnotations.isEmpty) {
        return OCRResult(
          success: false,
          error: 'No text detected in image',
          provider: OCRProvider.cloudVision,
          processingTime: stopwatch.elapsed,
        );
      }
      
      // Extract full text
      final fullText = textAnnotations.first['description'] as String;
      
      // Extract structured data
      final receiptData = await _extractReceiptData(
        fullText, 
        textAnnotations,
        fullTextAnnotation,
      );
      
      // Calculate confidence
      final confidence = _calculateConfidence(textAnnotations, receiptData);
      
      stopwatch.stop();
      
      _logger.info('Cloud Vision processing completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return OCRResult(
        success: true,
        data: receiptData,
        confidence: confidence,
        rawText: fullText,
        provider: OCRProvider.cloudVision,
        processingTime: stopwatch.elapsed,
      );
      
    } catch (e) {
      stopwatch.stop();
      _logger.error('Cloud Vision text detection failed: $e');
      
      return OCRResult(
        success: false,
        error: 'Cloud Vision processing failed: ${e.toString()}',
        provider: OCRProvider.cloudVision,
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// Extract structured receipt data from Cloud Vision response
  Future<ReceiptData> _extractReceiptData(
    String fullText,
    List textAnnotations,
    Map<String, dynamic>? fullTextAnnotation,
  ) async {
    
    // Use structured text if available
    final structuredText = _extractStructuredText(fullTextAnnotation);
    final textToAnalyze = structuredText.isNotEmpty ? structuredText : fullText;
    
    // Extract components using advanced patterns
    final vendor = _extractVendorAdvanced(textAnnotations);
    final amount = _extractAmountAdvanced(textToAnalyze, textAnnotations);
    final date = _extractDateAdvanced(textToAnalyze);
    final items = _extractItemsAdvanced(textToAnalyze, fullTextAnnotation);
    final category = _predictCategoryAdvanced(vendor, items, textToAnalyze);
    final currency = _extractCurrencyAdvanced(textToAnalyze);
    final taxAmount = _extractTaxAdvanced(textToAnalyze, amount);
    final paymentMethod = _extractPaymentMethodAdvanced(textToAnalyze);
    final receiptNumber = _extractReceiptNumberAdvanced(textToAnalyze);
    
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
        'annotationsCount': textAnnotations.length,
        'extractionMethod': 'cloud-vision',
        'hasStructuredText': fullTextAnnotation != null,
        'confidence': _calculateRawConfidence(textAnnotations),
      },
    );
  }

  /// Extract structured text from full text annotation
  String _extractStructuredText(Map<String, dynamic>? fullTextAnnotation) {
    if (fullTextAnnotation == null) return '';
    
    final pages = fullTextAnnotation['pages'] as List?;
    if (pages == null || pages.isEmpty) return '';
    
    final lines = <String>[];
    
    for (final page in pages) {
      final blocks = page['blocks'] as List? ?? [];
      
      for (final block in blocks) {
        final paragraphs = block['paragraphs'] as List? ?? [];
        
        for (final paragraph in paragraphs) {
          final words = paragraph['words'] as List? ?? [];
          final lineWords = <String>[];
          
          for (final word in words) {
            final symbols = word['symbols'] as List? ?? [];
            final wordText = symbols
                .map((symbol) => symbol['text'] as String? ?? '')
                .join('');
            
            if (wordText.isNotEmpty) {
              lineWords.add(wordText);
            }
          }
          
          if (lineWords.isNotEmpty) {
            lines.add(lineWords.join(' '));
          }
        }
      }
    }
    
    return lines.join('\n');
  }

  /// Extract vendor name using advanced positioning
  String _extractVendorAdvanced(List textAnnotations) {
    if (textAnnotations.length < 2) return 'Unknown Vendor';
    
    // Skip the first annotation (full text) and look at individual annotations
    final annotations = textAnnotations.skip(1).toList();
    
    // Sort by Y coordinate (top to bottom)
    annotations.sort((a, b) {
      final aVertices = a['boundingPoly']['vertices'] as List;
      final bVertices = b['boundingPoly']['vertices'] as List;
      
      final aTop = aVertices.map((v) => v['y'] as int? ?? 0).reduce((a, b) => a < b ? a : b);
      final bTop = bVertices.map((v) => v['y'] as int? ?? 0).reduce((a, b) => a < b ? a : b);
      
      return aTop.compareTo(bTop);
    });
    
    // Look for vendor in top annotations
    for (int i = 0; i < annotations.length && i < 10; i++) {
      final text = annotations[i]['description'] as String;
      
      if (_isLikelyVendorName(text)) {
        return _cleanVendorName(text);
      }
    }
    
    return 'Unknown Vendor';
  }

  /// Extract amount using advanced confidence scoring
  double _extractAmountAdvanced(String fullText, List textAnnotations) {
    final amounts = <AmountCandidate>[];
    
    // Look for total patterns with high confidence
    final totalPatterns = [
      RegExp(r'(?:total|amount due|grand total|balance due|final total)[\s:]*\$?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(?:^|\s)total[\s:]*\$?([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'(?:pay|payment)[\s:]*\$?([\d,]+\.\d{2})', caseSensitive: false),
    ];
    
    for (final pattern in totalPatterns) {
      final matches = pattern.allMatches(fullText);
      for (final match in matches) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          amounts.add(AmountCandidate(
            amount: amount,
            confidence: 0.9,
            source: 'total_pattern',
          ));
        }
      }
    }
    
    // Look for currency amounts in annotations
    for (int i = 1; i < textAnnotations.length; i++) {
      final annotation = textAnnotations[i];
      final text = annotation['description'] as String;
      
      final currencyPattern = RegExp(r'\$(\d{1,6}(?:,\d{3})*\.\d{2})');
      final match = currencyPattern.firstMatch(text);
      
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          // Calculate confidence based on position (bottom = higher confidence)
          final position = _getAnnotationPosition(annotation);
          final confidence = 0.3 + (position * 0.4); // 0.3 to 0.7 based on position
          
          amounts.add(AmountCandidate(
            amount: amount,
            confidence: confidence,
            source: 'currency_pattern',
          ));
        }
      }
    }
    
    // Sort by confidence and return best candidate
    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b.confidence.compareTo(a.confidence));
      return amounts.first.amount;
    }
    
    return 0.0;
  }

  /// Get relative position of annotation (0.0 = top, 1.0 = bottom)
  double _getAnnotationPosition(Map<String, dynamic> annotation) {
    try {
      final vertices = annotation['boundingPoly']['vertices'] as List;
      final y = vertices.map((v) => v['y'] as int? ?? 0).reduce((a, b) => a + b) / vertices.length;
      
      // This is a simplified calculation - in practice, you'd need image height
      return (y / 1000).clamp(0.0, 1.0);
    } catch (e) {
      return 0.5; // Default middle position
    }
  }

  /// Extract date using advanced parsing
  DateTime _extractDateAdvanced(String text) {
    final datePatterns = [
      // Standard formats
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      RegExp(r'(\d{2,4})[/-](\d{1,2})[/-](\d{1,2})'),
      
      // Month name formats
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{2,4})', caseSensitive: false),
      
      // ISO format
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      
      // Timestamp formats
      RegExp(r'(\d{1,2}):(\d{2}):(\d{2})\s+(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
    ];
    
    final candidates = <DateTime>[];
    
    for (final pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        try {
          final parsedDate = _parseAdvancedDate(match.group(0)!);
          if (parsedDate != null && _isReasonableReceiptDate(parsedDate)) {
            candidates.add(parsedDate);
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    // Return most reasonable date or current date
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.compareTo(a)); // Most recent first
      return candidates.first;
    }
    
    return DateTime.now();
  }

  /// Parse date with advanced logic
  DateTime? _parseAdvancedDate(String dateStr) {
    try {
      // Handle month names
      final monthNames = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
        'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      };
      
      // Month name pattern
      final monthPattern = RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})', caseSensitive: false);
      final monthMatch = monthPattern.firstMatch(dateStr);
      
      if (monthMatch != null) {
        final monthStr = monthMatch.group(1)!.toLowerCase();
        final monthKey = monthNames.keys.firstWhere(
          (key) => monthStr.startsWith(key.substring(0, 3)),
          orElse: () => '',
        );
        
        if (monthKey.isNotEmpty) {
          final day = int.parse(monthMatch.group(2)!);
          var year = int.parse(monthMatch.group(3)!);
          if (year < 100) year += 2000;
          
          return DateTime(year, monthNames[monthKey]!, day);
        }
      }
      
      // ISO format
      final isoPattern = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
      final isoMatch = isoPattern.firstMatch(dateStr);
      if (isoMatch != null) {
        final year = int.parse(isoMatch.group(1)!);
        final month = int.parse(isoMatch.group(2)!);
        final day = int.parse(isoMatch.group(3)!);
        return DateTime(year, month, day);
      }
      
      // Numeric patterns with smart year detection
      final numPattern = RegExp(r'(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})');
      final numMatch = numPattern.firstMatch(dateStr);
      
      if (numMatch != null) {
        var part1 = int.parse(numMatch.group(1)!);
        final part2 = int.parse(numMatch.group(2)!);
        var part3 = int.parse(numMatch.group(3)!);
        
        int year, month, day;
        
        // Smart detection based on number ranges
        if (part1 > 31) {
          // YYYY/MM/DD format
          year = part1;
          month = part2;
          day = part3;
        } else if (part3 > 31) {
          // MM/DD/YYYY or DD/MM/YYYY format
          if (part1 > 12) {
            // DD/MM/YYYY
            day = part1;
            month = part2;
            year = part3;
          } else {
            // MM/DD/YYYY
            month = part1;
            day = part2;
            year = part3;
          }
        } else {
          // Ambiguous case - use context or default to MM/DD/YY
          month = part1;
          day = part2;
          year = part3;
          if (year < 100) {
            year += year > 50 ? 1900 : 2000; // Smart century detection
          }
        }
        
        // Validate date components
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900) {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      // Invalid date format
    }
    
    return null;
  }

  /// Check if date is reasonable for a receipt
  bool _isReasonableReceiptDate(DateTime date) {
    final now = DateTime.now();
    final twoYearsAgo = now.subtract(const Duration(days: 730));
    final oneWeekFromNow = now.add(const Duration(days: 7));
    
    return date.isAfter(twoYearsAgo) && date.isBefore(oneWeekFromNow);
  }

  /// Extract items using advanced text structure analysis
  List<ReceiptItem> _extractItemsAdvanced(String text, Map<String, dynamic>? fullTextAnnotation) {
    final items = <ReceiptItem>[];
    
    // Try structured extraction first
    if (fullTextAnnotation != null) {
      items.addAll(_extractItemsFromStructuredText(fullTextAnnotation));
    }
    
    // Fallback to pattern-based extraction
    if (items.isEmpty) {
      items.addAll(_extractItemsFromPatterns(text));
    }
    
    return items;
  }

  /// Extract items from structured text annotation
  List<ReceiptItem> _extractItemsFromStructuredText(Map<String, dynamic> fullTextAnnotation) {
    final items = <ReceiptItem>[];
    
    try {
      final pages = fullTextAnnotation['pages'] as List? ?? [];
      
      for (final page in pages) {
        final blocks = page['blocks'] as List? ?? [];
        
        for (final block in blocks) {
          final paragraphs = block['paragraphs'] as List? ?? [];
          
          for (final paragraph in paragraphs) {
            final words = paragraph['words'] as List? ?? [];
            final lineText = _extractLineText(words);
            
            if (lineText.isNotEmpty) {
              final item = _parseLineAsItem(lineText);
              if (item != null) {
                items.add(item);
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to extract items from structured text: $e');
    }
    
    return items;
  }

  /// Extract line text from words
  String _extractLineText(List words) {
    final wordTexts = <String>[];
    
    for (final word in words) {
      final symbols = word['symbols'] as List? ?? [];
      final wordText = symbols
          .map((symbol) => symbol['text'] as String? ?? '')
          .join('');
      
      if (wordText.isNotEmpty) {
        wordTexts.add(wordText);
      }
    }
    
    return wordTexts.join(' ');
  }

  /// Extract items using pattern matching
  List<ReceiptItem> _extractItemsFromPatterns(String text) {
    final items = <ReceiptItem>[];
    final lines = text.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      final item = _parseLineAsItem(trimmedLine);
      if (item != null) {
        items.add(item);
      }
    }
    
    return items;
  }

  /// Parse a line as potential receipt item
  ReceiptItem? _parseLineAsItem(String line) {
    // Skip obvious non-item lines
    if (_isNonItemLine(line)) return null;
    
    // Pattern: "Item description 2.50" or "2x Item $5.00"
    final itemPatterns = [
      RegExp(r'^(.+?)\s+\$?([\d,]+\.?\d*)),
      RegExp(r'^(\d+)x?\s+(.+?)\s+\$?([\d,]+\.?\d*)),
      RegExp(r'^(.+?)\s+(\d+)\s+@\s+\$?([\d,]+\.?\d*)\s+=\s+\$?([\d,]+\.?\d*)),
      RegExp(r'^(.+?)\s+(\d+)\s+\$?([\d,]+\.?\d*)),
    ];
    
    for (final pattern in itemPatterns) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      
      try {
        if (pattern.pattern.contains('@')) {
          // Pattern: "Item 2 @ $5.00 = $10.00"
          final description = match.group(1)!.trim();
          final quantity = int.parse(match.group(2)!);
          final unitPrice = double.parse(match.group(3)!.replaceAll(',', ''));
          final totalPrice = double.parse(match.group(4)!.replaceAll(',', ''));
          
          if (_isValidItem(description, quantity, unitPrice, totalPrice)) {
            return ReceiptItem(
              description: description,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            );
          }
        } else if (pattern.pattern.startsWith(r'^(\d+)x?')) {
          // Pattern: "2x Item $10.00"
          final quantity = int.parse(match.group(1)!);
          final description = match.group(2)!.trim();
          final totalPrice = double.parse(match.group(3)!.replaceAll(',', ''));
          final unitPrice = totalPrice / quantity;
          
          if (_isValidItem(description, quantity, unitPrice, totalPrice)) {
            return ReceiptItem(
              description: description,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            );
          }
        } else if (match.groupCount == 3) {
          // Pattern: "Item 2 $10.00"
          final description = match.group(1)!.trim();
          final quantity = int.tryParse(match.group(2)!) ?? 1;
          final totalPrice = double.parse(match.group(3)!.replaceAll(',', ''));
          final unitPrice = totalPrice / quantity;
          
          if (_isValidItem(description, quantity, unitPrice, totalPrice)) {
            return ReceiptItem(
              description: description,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            );
          }
        } else {
          // Pattern: "Item $10.00"
          final description = match.group(1)!.trim();
          final totalPrice = double.parse(match.group(2)!.replaceAll(',', ''));
          
          if (_isValidItem(description, 1, totalPrice, totalPrice)) {
            return ReceiptItem(
              description: description,
              quantity: 1,
              unitPrice: totalPrice,
              totalPrice: totalPrice,
            );
          }
        }
      } catch (e) {
        continue; // Invalid format, try next pattern
      }
    }
    
    return null;
  }

  /// Check if line is obviously not an item
  bool _isNonItemLine(String line) {
    final excludePatterns = [
      RegExp(r'^(total|subtotal|tax|discount|change|cash|card|credit|payment|balance|due), caseSensitive: false),
      RegExp(r'^\d+), // Only numbers
      RegExp(r'^[*#-]+), // Only symbols
      RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}), // Dates
      RegExp(r'^(thank you|receipt|store|copy|customer|server|table), caseSensitive: false),
      RegExp(r'^\d+\s*(st|nd|rd|th|street|ave|avenue|blvd|road|rd)', caseSensitive: false),
      RegExp(r'^(open|close|manager|cashier)', caseSensitive: false),
    ];
    
    for (final pattern in excludePatterns) {
      if (pattern.hasMatch(line)) return true;
    }
    
    return line.length < 3 || line.length > 100;
  }

  /// Validate if extracted data represents a valid item
  bool _isValidItem(String description, int quantity, double unitPrice, double totalPrice) {
    return description.isNotEmpty &&
           description.length >= 2 &&
           description.length <= 100 &&
           quantity > 0 &&
           quantity <= 1000 &&
           unitPrice > 0 &&
           unitPrice <= 10000 &&
           totalPrice > 0 &&
           totalPrice <= 50000 &&
           (totalPrice - (unitPrice * quantity)).abs() < 0.01; // Price consistency check
  }

  /// Advanced category prediction with ML-like scoring
  String _predictCategoryAdvanced(String vendor, List<ReceiptItem> items, String fullText) {
    final scores = <String, double>{};
    final categories = [
      'Food & Dining',
      'Transportation',
      'Office Supplies',
      'Software & Technology',
      'Healthcare',
      'Retail',
      'Entertainment',
      'Utilities',
      'General',
    ];
    
    // Initialize scores
    for (final category in categories) {
      scores[category] = 0.0;
    }
    
    // Vendor-based scoring
    _scoreByVendor(vendor.toLowerCase(), scores);
    
    // Items-based scoring
    _scoreByItems(items, scores);
    
    // Full text analysis
    _scoreByFullText(fullText.toLowerCase(), scores);
    
    // Find category with highest score
    String bestCategory = 'General';
    double bestScore = scores['General']!;
    
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestCategory = entry.key;
        bestScore = entry.value;
      }
    }
    
    return bestCategory;
  }

  /// Score categories based on vendor name
  void _scoreByVendor(String vendor, Map<String, double> scores) {
    final vendorPatterns = {
      'Food & Dining': [
        'restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'food', 'diner',
        'kitchen', 'bar', 'grill', 'bistro', 'tavern', 'bakery', 'deli',
        'mcdonald', 'subway', 'starbucks', 'kfc', 'domino', 'taco bell'
      ],
      'Transportation': [
        'gas', 'fuel', 'shell', 'chevron', 'bp', 'exxon', 'mobil', 'station',
        'uber', 'lyft', 'taxi', 'parking', 'metro', 'transit'
      ],
      'Office Supplies': [
        'office', 'staples', 'depot', 'supplies', 'paper', 'fedex', 'ups',
        'kinko', 'print', 'copy'
      ],
      'Software & Technology': [
        'apple', 'microsoft', 'google', 'adobe', 'tech', 'computer', 'software',
        'amazon', 'best buy', 'electronics'
      ],
      'Healthcare': [
        'pharmacy', 'medical', 'clinic', 'hospital', 'health', 'care',
        'walgreens', 'cvs', 'rite aid', 'doctor', 'dental'
      ],
      'Retail': [
        'walmart', 'target', 'costco', 'store', 'shop', 'market', 'mall',
        'retail', 'clothing', 'fashion'
      ],
      'Entertainment': [
        'movie', 'theater', 'cinema', 'game', 'sport', 'gym', 'fitness'
      ],
      'Utilities': [
        'electric', 'water', 'gas', 'utility', 'phone', 'internet', 'cable'
      ],
    };
    
    for (final entry in vendorPatterns.entries) {
      for (final keyword in entry.value) {
        if (vendor.contains(keyword)) {
          scores[entry.key] = scores[entry.key]! + 2.0;
        }
      }
    }
  }

  /// Score categories based on items
  void _scoreByItems(List<ReceiptItem> items, Map<String, double> scores) {
    final itemKeywords = {
      'Food & Dining': [
        'food', 'meal', 'drink', 'coffee', 'sandwich', 'pizza', 'burger',
        'salad', 'soup', 'appetizer', 'dessert', 'beverage'
      ],
      'Transportation': [
        'gas', 'fuel', 'diesel', 'premium', 'regular', 'parking'
      ],
      'Office Supplies': [
        'paper', 'pen', 'pencil', 'stapler', 'notebook', 'folder', 'ink',
        'toner', 'envelope'
      ],
      'Software & Technology': [
        'software', 'app', 'subscription', 'license', 'cloud', 'service'
      ],
      'Healthcare': [
        'medicine', 'prescription', 'vitamin', 'bandage', 'first aid'
      ],
    };
    
    for (final item in items) {
      final description = item.description.toLowerCase();
      
      for (final entry in itemKeywords.entries) {
        for (final keyword in entry.value) {
          if (description.contains(keyword)) {
            scores[entry.key] = scores[entry.key]! + 1.0;
          }
        }
      }
    }
  }

  /// Score categories based on full text analysis
  void _scoreByFullText(String text, Map<String, double> scores) {
    final contextKeywords = {
      'Food & Dining': [
        'server', 'table', 'order', 'menu', 'tip', 'gratuity', 'dine'
      ],
      'Transportation': [
        'gallon', 'mile', 'pump', 'grade', 'octane'
      ],
      'Office Supplies': [
        'office', 'business', 'corporate', 'supply'
      ],
      'Healthcare': [
        'patient', 'prescription', 'rx', 'generic', 'brand'
      ],
    };
    
    for (final entry in contextKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          scores[entry.key] = scores[entry.key]! + 0.5;
        }
      }
    }
  }

  /// Extract currency with regional support
  String? _extractCurrencyAdvanced(String text) {
    final currencyPatterns = [
      RegExp(r'\$(\d+\.?\d*)'), // USD
      RegExp(r'€(\d+\.?\d*)'), // EUR
      RegExp(r'£(\d+\.?\d*)'), // GBP
      RegExp(r'¥(\d+\.?\d*)'), // JPY/CNY
      RegExp(r'₹(\d+\.?\d*)'), // INR
      RegExp(r'(\d+\.?\d*)\s*(USD|EUR|GBP|JPY|CNY|INR|CAD|AUD|CHF|SEK|NOK|DKK)', caseSensitive: false),
    ];
    
    for (final pattern in currencyPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final fullMatch = match.group(0)!;
        if (fullMatch.contains('\)) return 'USD';
        if (fullMatch.contains('€')) return 'EUR';
        if (fullMatch.contains('£')) return 'GBP';
        if (fullMatch.contains('¥')) return 'JPY';
        if (fullMatch.contains('₹')) return 'INR';
        
        // Check text-based currency codes
        final upperMatch = fullMatch.toUpperCase();
        final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'CAD', 'AUD', 'CHF', 'SEK', 'NOK', 'DKK'];
        for (final currency in currencies) {
          if (upperMatch.contains(currency)) return currency;
        }
      }
    }
    
    return 'USD'; // Default
  }

  /// Extract tax with multiple formats
  double? _extractTaxAdvanced(String text, double totalAmount) {
    final taxPatterns = [
      RegExp(r'(?:tax|vat|gst|hst|pst|qst)[\s:]*\$?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)%?\s*(?:tax|vat|gst)', caseSensitive: false),
      RegExp(r'(?:sales tax|state tax|local tax)[\s:]*\$?([\d,]+\.?\d*)', caseSensitive: false),
    ];
    
    for (final pattern in taxPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final taxStr = match.group(1)!.replaceAll(',', '');
        final tax = double.tryParse(taxStr);
        if (tax != null && tax > 0) {
          // Handle percentage vs amount
          if (tax < 1.0) {
            // Likely a percentage in decimal form
            return totalAmount * tax;
          } else if (tax < 50.0 && tax / totalAmount > 0.5) {
            // Likely a percentage
            return totalAmount * (tax / 100);
          } else if (tax < totalAmount * 0.3) {
            // Reasonable tax amount
            return tax;
          }
        }
      }
    }
    
    return null;
  }

  /// Extract payment method with advanced patterns
  String? _extractPaymentMethodAdvanced(String text) {
    final paymentPatterns = [
      RegExp(r'\b(cash|credit|debit|card|visa|mastercard|amex|discover|paypal|apple pay|google pay|contactless)\b', caseSensitive: false),
      RegExp(r'(xxxx|****)\s*(\d{4})', caseSensitive: false), // Masked card numbers
      RegExp(r'(chip|tap|swipe|insert)', caseSensitive: false),
    ];
    
    for (final pattern in paymentPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final payment = match.group(1)!.toLowerCase();
        
        // Normalize payment method names
        if (payment.contains('apple')) return 'apple_pay';
        if (payment.contains('google')) return 'google_pay';
        if (payment.contains('paypal')) return 'paypal';
        if (['visa', 'mastercard', 'amex', 'discover'].contains(payment)) return 'credit_card';
        if (['chip', 'tap', 'contactless'].contains(payment)) return 'card';
        
        return payment;
      }
    }
    
    return null;
  }

  /// Extract receipt number with advanced patterns
  String? _extractReceiptNumberAdvanced(String text) {
    final receiptPatterns = [
      RegExp(r'(?:receipt|ref|reference|confirmation|order|transaction)[\s#:]*([A-Z0-9]{4,})', caseSensitive: false),
      RegExp(r'#([A-Z0-9]{4,})', caseSensitive: false),
      RegExp(r'(?:txn|trans)[\s#:]*([A-Z0-9]{6,})', caseSensitive: false),
      RegExp(r'([A-Z]{2,}\d{4,})', caseSensitive: false),
    ];
    
    for (final pattern in receiptPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final receiptNum = match.group(1)!;
        
        // Validate receipt number format
        if (receiptNum.length >= 4 && receiptNum.length <= 20) {
          return receiptNum;
        }
      }
    }
    
    return null;
  }

  /// Calculate confidence based on Cloud Vision annotations
  double _calculateConfidence(List textAnnotations, ReceiptData data) {
    double confidence = _calculateRawConfidence(textAnnotations);
    
    // Boost confidence based on extracted data quality
    if (data.vendor != 'Unknown Vendor') confidence += 0.15;
    if (data.amount > 0) confidence += 0.15;
    if (data.items.isNotEmpty) confidence += 0.1;
    if (data.currency != null) confidence += 0.05;
    if (data.receiptNumber != null) confidence += 0.05;
    if (data.taxAmount != null) confidence += 0.05;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate raw confidence from Cloud Vision annotations
  double _calculateRawConfidence(List textAnnotations) {
    if (textAnnotations.isEmpty) return 0.0;
    
    // Look for confidence scores in annotations
    double totalConfidence = 0.0;
    int confidenceCount = 0;
    
    for (final annotation in textAnnotations.skip(1)) { // Skip full text annotation
      final confidence = annotation['confidence'] as double?;
      if (confidence != null) {
        totalConfidence += confidence;
        confidenceCount++;
      }
    }
    
    if (confidenceCount > 0) {
      return totalConfidence / confidenceCount;
    }
    
    // Fallback: estimate confidence based on text length and structure
    final fullText = textAnnotations.first['description'] as String? ?? '';
    double estimatedConfidence = 0.3; // Base confidence
    
    if (fullText.length > 50) estimatedConfidence += 0.2;
    if (fullText.length > 100) estimatedConfidence += 0.2;
    if (fullText.contains(RegExp(r'\$\d+\.\d{2}'))) estimatedConfidence += 0.2;
    if (fullText.contains(RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'))) estimatedConfidence += 0.1;
    
    return estimatedConfidence;
  }

  /// Helper methods
  bool _isLikelyVendorName(String text) {
    if (text.length < 3 || text.length > 50) return false;
    
    // Must contain at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) return false;
    
    // Skip obvious non-vendor patterns
    final excludePatterns = [
      RegExp(r'^\d+),
      RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}),
      RegExp(r'^(receipt|thank you|store|copy|customer|total|subtotal), caseSensitive: false),
    ];
    
    for (final pattern in excludePatterns) {
      if (pattern.hasMatch(text)) return false;
    }
    
    return true;
  }

  String _cleanVendorName(String text) {
    text = text.replaceAll(RegExp(r'\b(inc|llc|corp|ltd|co)\b\.?', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'[*#]+'), '');
    text = text.trim();
    return text.isEmpty ? 'Unknown Vendor' : text;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Amount candidate for confidence scoring
class AmountCandidate {
  final double amount;
  final double confidence;
  final String source;

  AmountCandidate({
    required this.amount,
    required this.confidence,
    required this.source,
  });
}

/// Cloud Vision Exception
class CloudVisionException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const CloudVisionException(
    this.message, {
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'CloudVisionException: $message';
}

/// Provider for Cloud Vision service
final cloudVisionServiceProvider = Provider<CloudVisionService>((ref) {
  return CloudVisionService(
    apiKey: ref.read(environmentConfigProvider).googleCloudApiKey,
    httpClient: ref.read(httpClientProvider),
    logger: ref.read(loggerProvider),
  );
});