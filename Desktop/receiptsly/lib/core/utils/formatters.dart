// lib/core/utils/formatters.dart
import 'dart:math';
import 'package:intl/intl.dart';

/// Comprehensive formatting utilities for Receiptsly app
/// Handles currency, numbers, text, file sizes, etc.
class Formatters {
  // Currency Formatters
  static String formatCurrency(
    double amount, {
    String currencyCode = 'USD',
    String? locale,
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale ?? 'en_US',
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: 2,
      );
      return formatter.format(amount);
    } catch (e) {
      // Fallback formatting
      return '${_getCurrencySymbol(currencyCode)}${amount.toStringAsFixed(2)}';
    }
  }

  static String formatCurrencyCompact(
    double amount, {
    String currencyCode = 'USD',
  }) {
    final symbol = _getCurrencySymbol(currencyCode);

    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  static String formatCurrencyWithoutSymbol(
    double amount, {
    int decimalPlaces = 2,
  }) {
    return amount.toStringAsFixed(decimalPlaces);
  }

  static String formatCurrencyRange(
    double minAmount,
    double maxAmount, {
    String currencyCode = 'USD',
  }) {
    final symbol = _getCurrencySymbol(currencyCode);
    return '$symbol${minAmount.toStringAsFixed(2)} - $symbol${maxAmount.toStringAsFixed(2)}';
  }

  static String _getCurrencySymbol(String currencyCode) {
    const currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'CHF ',
      'CNY': '¥',
      'SEK': 'kr',
      'NZD': 'NZ\$',
      'MXN': '\$',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'NOK': 'kr',
      'INR': '₹',
      'KRW': '₩',
      'TRY': '₺',
      'RUB': '₽',
      'BRL': 'R\$',
      'ZAR': 'R',
    };

    return currencySymbols[currencyCode.toUpperCase()] ??
        currencyCode.toUpperCase() + ' ';
  }

  // Number Formatters
  static String formatNumber(num number, {int decimalPlaces = 0}) {
    final formatter = NumberFormat(
      '#,##0' + (decimalPlaces > 0 ? '.${'0' * decimalPlaces}' : ''),
    );
    return formatter.format(number);
  }

  static String formatPercentage(double value, {int decimalPlaces = 1}) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }

  static String formatCompactNumber(num number) {
    if (number.abs() >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number.abs() >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number.abs() >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  static String formatOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }

    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  // Text Formatters
  static String formatName(String name) {
    if (name.isEmpty) return '';

    return name
        .trim()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  static String formatBusinessName(String businessName) {
    if (businessName.isEmpty) return '';

    return businessName
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';

          // Handle special cases for business names
          final lowerWord = word.toLowerCase();
          if (['llc', 'inc', 'ltd', 'corp'].contains(lowerWord)) {
            return word.toUpperCase();
          }

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static String formatInitials(String name) {
    if (name.isEmpty) return '';

    return name
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join('');
  }

  static String truncateText(
    String text,
    int maxLength, {
    String suffix = '...',
  }) {
    if (text.length <= maxLength) return text;

    final truncated = text.substring(0, maxLength - suffix.length);
    return truncated + suffix;
  }

  static String formatSentenceCase(String text) {
    if (text.isEmpty) return '';

    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String formatTitleCase(String text) {
    if (text.isEmpty) return '';

    final words = text.toLowerCase().split(' ');
    final titleCaseWords = words.map((word) {
      if (word.isEmpty) return '';

      // Don't capitalize articles, prepositions, and conjunctions unless they're the first word
      final skipWords = [
        'a',
        'an',
        'the',
        'and',
        'but',
        'or',
        'for',
        'nor',
        'on',
        'at',
        'to',
        'from',
        'up',
        'by',
        'of',
        'in',
        'with',
      ];
      if (words.indexOf(word) > 0 && skipWords.contains(word)) {
        return word;
      }

      return word[0].toUpperCase() + word.substring(1);
    });

    return titleCaseWords.join(' ');
  }

  // Phone Number Formatters
  static String formatPhoneNumber(
    String phoneNumber, {
    String countryCode = 'US',
  }) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) return phoneNumber;

    switch (countryCode.toUpperCase()) {
      case 'US':
      case 'CA':
        return _formatUSPhoneNumber(digitsOnly);
      case 'UK':
        return _formatUKPhoneNumber(digitsOnly);
      case 'DE':
        return _formatGermanPhoneNumber(digitsOnly);
      default:
        return _formatInternationalPhoneNumber(digitsOnly);
    }
  }

  static String _formatUSPhoneNumber(String digits) {
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return digits;
  }

  static String _formatUKPhoneNumber(String digits) {
    if (digits.length == 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    } else if (digits.length == 11) {
      return '${digits.substring(0, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
    }
    return digits;
  }

  static String _formatGermanPhoneNumber(String digits) {
    if (digits.length >= 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return digits;
  }

  static String _formatInternationalPhoneNumber(String digits) {
    if (digits.length > 4) {
      return '+${digits.substring(0, min(3, digits.length))} ${digits.substring(min(3, digits.length))}';
    }
    return digits;
  }

  // File Size Formatters
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  // Invoice Number Formatters
  static String formatInvoiceNumber(
    String baseNumber, {
    String prefix = 'INV',
  }) {
    final paddedNumber = baseNumber.padLeft(4, '0');
    return '$prefix-$paddedNumber';
  }

  static String generateInvoiceNumber(DateTime date, int sequenceNumber) {
    final year = date.year.toString().substring(2);
    final month = date.month.toString().padLeft(2, '0');
    final sequence = sequenceNumber.toString().padLeft(3, '0');
    return 'INV-$year$month-$sequence';
  }

  // Receipt Number Formatters
  static String formatReceiptNumber(int receiptId) {
    return 'RCP-${receiptId.toString().padLeft(6, '0')}';
  }

  // Address Formatters
  static String formatAddress(Map<String, String?> address) {
    final parts = <String>[];

    if (address['street']?.isNotEmpty == true) {
      parts.add(address['street']!);
    }

    final cityStateZip = <String>[];
    if (address['city']?.isNotEmpty == true) {
      cityStateZip.add(address['city']!);
    }
    if (address['state']?.isNotEmpty == true) {
      cityStateZip.add(address['state']!);
    }
    if (address['zipCode']?.isNotEmpty == true) {
      cityStateZip.add(address['zipCode']!);
    }

    if (cityStateZip.isNotEmpty) {
      parts.add(cityStateZip.join(', '));
    }

    if (address['country']?.isNotEmpty == true) {
      parts.add(address['country']!);
    }

    return parts.join('\n');
  }

  // Tax Rate Formatters
  static String formatTaxRate(double rate) {
    if (rate == 0) return '0%';
    return '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2)}%';
  }

  // Duration Formatters
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${duration.inSeconds} second${duration.inSeconds == 1 ? '' : 's'}';
    }
  }

  static String formatDetailedDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];

    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0 && days == 0) parts.add('${seconds}s');

    return parts.isEmpty ? '0s' : parts.join(' ');
  }

  // Status Formatters
  static String formatStatus(String status) {
    if (status.isEmpty) return '';

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  static String formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'overdue':
        return 'Overdue';
      case 'draft':
        return 'Draft';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return formatStatus(status);
    }
  }

  // Credit Card Formatters
  static String formatCreditCardNumber(String cardNumber) {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length <= 4) return digitsOnly;

    final formatted = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(digitsOnly[i]);
    }

    return formatted.toString();
  }

  static String maskCreditCardNumber(String cardNumber) {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 4) return cardNumber;

    final lastFour = digitsOnly.substring(digitsOnly.length - 4);
    final masked = '*' * (digitsOnly.length - 4);

    return formatCreditCardNumber(masked + lastFour);
  }

  // List Formatters
  static String formatList(
    List<String> items, {
    String separator = ', ',
    String? lastSeparator,
  }) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;

    final lastSep = lastSeparator ?? ' and ';

    if (items.length == 2) {
      return '${items.first}$lastSep${items.last}';
    }

    final allButLast = items.sublist(0, items.length - 1).join(separator);
    return '$allButLast$lastSep${items.last}';
  }

  // Category Formatters
  static String formatCategoryName(String category) {
    if (category.isEmpty) return '';

    // Handle special category formatting
    final specialCategories = {
      'food_and_dining': 'Food & Dining',
      'software_and_technology': 'Software & Technology',
      'travel_and_accommodation': 'Travel & Accommodation',
      'marketing_and_advertising': 'Marketing & Advertising',
      'office_supplies': 'Office Supplies',
      'professional_services': 'Professional Services',
      'equipment_and_tools': 'Equipment & Tools',
      'training_and_education': 'Training & Education',
      'health_and_medical': 'Health & Medical',
    };

    final lowerCategory = category.toLowerCase().replaceAll(' ', '_');

    if (specialCategories.containsKey(lowerCategory)) {
      return specialCategories[lowerCategory]!;
    }

    return formatTitleCase(category.replaceAll('_', ' '));
  }

  // URL Formatters
  static String formatUrl(String url) {
    if (url.isEmpty) return '';

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }

    return url;
  }

  static String formatDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(formatUrl(url));
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }

  // Color Formatters
  static String formatHexColor(String color) {
    if (color.isEmpty) return '';

    // Remove # if present
    color = color.replaceAll('#', '');

    // Ensure 6 characters
    if (color.length == 3) {
      color = color.split('').map((char) => char + char).join('');
    }

    if (color.length == 6) {
      return '#${color.toUpperCase()}';
    }

    return color;
  }

  // Version Formatters
  static String formatVersion(String version) {
    if (version.isEmpty) return '0.0.0';

    final parts = version.split('.');
    while (parts.length < 3) {
      parts.add('0');
    }

    return parts.take(3).join('.');
  }

  // Input Formatters for Text Fields
  static String formatCurrencyInput(String input) {
    // Remove non-digit characters except decimal point
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');

    // Ensure only one decimal point
    final parts = cleaned.split('.');
    if (parts.length > 2) {
      return '${parts[0]}.${parts.sublist(1).join('')}';
    }

    // Limit decimal places to 2
    if (parts.length == 2 && parts[1].length > 2) {
      return '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    return cleaned;
  }

  static String formatPhoneInput(String input) {
    // Remove all non-digit characters
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to reasonable phone number length
    if (digitsOnly.length > 15) {
      return digitsOnly.substring(0, 15);
    }

    return digitsOnly;
  }

  // Error Message Formatters
  static String formatErrorMessage(String error) {
    if (error.isEmpty) return 'An unknown error occurred';

    // Remove technical prefixes
    error = error.replaceAll(
      RegExp(r'^(Exception:|Error:|FirebaseException:)\s*'),
      '',
    );

    // Ensure first letter is capitalized
    if (error.isNotEmpty) {
      error = error[0].toUpperCase() + error.substring(1);
    }

    // Ensure it ends with a period
    if (!error.endsWith('.') && !error.endsWith('!') && !error.endsWith('?')) {
      error += '.';
    }

    return error;
  }

  // Search Query Formatters
  static String formatSearchQuery(String query) {
    return query.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    ); // Replace multiple spaces with single space
  }

  // Slug Formatters
  static String formatSlug(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-+|-+$'), ''); // Remove leading/trailing hyphens
  }

  // API Response Formatters
  static Map<String, dynamic> formatApiResponse(Map<String, dynamic> response) {
    final formatted = <String, dynamic>{};

    response.forEach((key, value) {
      // Convert snake_case to camelCase
      final camelKey = key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => match.group(1)!.toUpperCase(),
      );

      formatted[camelKey] = value;
    });

    return formatted;
  }

  // Template Variable Formatters
  static String formatTemplate(
    String template,
    Map<String, dynamic> variables,
  ) {
    String result = template;

    variables.forEach((key, value) {
      final placeholder = '{{$key}}';
      final formattedValue = _formatTemplateValue(value);
      result = result.replaceAll(placeholder, formattedValue);
    });

    return result;
  }

  static String _formatTemplateValue(dynamic value) {
    if (value == null) return '';

    if (value is DateTime) {
      return DateFormat('MMM d, y').format(value);
    }

    if (value is double) {
      return formatCurrency(value);
    }

    return value.toString();
  }
}
