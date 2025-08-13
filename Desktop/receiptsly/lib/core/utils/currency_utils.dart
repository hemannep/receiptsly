// lib/core/utils/currency_utils.dart
import 'dart:convert';
import 'dart:math';

/// Comprehensive currency utilities for Receiptsly app
/// Handles currency conversion, formatting, validation, and regional settings
class CurrencyUtils {
  // Currency data with symbols, names, and decimal places
  static const Map<String, Map<String, dynamic>> _currencyData = {
    'USD': {
      'symbol': '\$',
      'name': 'US Dollar',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'United States',
      'code': 'USD',
    },
    'EUR': {
      'symbol': '€',
      'name': 'Euro',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': '.',
      'decimalSeparator': ',',
      'country': 'Eurozone',
      'code': 'EUR',
    },
    'GBP': {
      'symbol': '£',
      'name': 'British Pound',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'United Kingdom',
      'code': 'GBP',
    },
    'JPY': {
      'symbol': '¥',
      'name': 'Japanese Yen',
      'symbolPosition': 'before',
      'decimalPlaces': 0,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Japan',
      'code': 'JPY',
    },
    'CAD': {
      'symbol': 'C\$',
      'name': 'Canadian Dollar',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Canada',
      'code': 'CAD',
    },
    'AUD': {
      'symbol': 'A\$',
      'name': 'Australian Dollar',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Australia',
      'code': 'AUD',
    },
    'CHF': {
      'symbol': 'CHF',
      'name': 'Swiss Franc',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': '\'',
      'decimalSeparator': '.',
      'country': 'Switzerland',
      'code': 'CHF',
    },
    'CNY': {
      'symbol': '¥',
      'name': 'Chinese Yuan',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'China',
      'code': 'CNY',
    },
    'SEK': {
      'symbol': 'kr',
      'name': 'Swedish Krona',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': ' ',
      'decimalSeparator': ',',
      'country': 'Sweden',
      'code': 'SEK',
    },
    'NOK': {
      'symbol': 'kr',
      'name': 'Norwegian Krone',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': ' ',
      'decimalSeparator': ',',
      'country': 'Norway',
      'code': 'NOK',
    },
    'DKK': {
      'symbol': 'kr',
      'name': 'Danish Krone',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': '.',
      'decimalSeparator': ',',
      'country': 'Denmark',
      'code': 'DKK',
    },
    'NZD': {
      'symbol': 'NZ\$',
      'name': 'New Zealand Dollar',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'New Zealand',
      'code': 'NZD',
    },
    'MXN': {
      'symbol': '\$',
      'name': 'Mexican Peso',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Mexico',
      'code': 'MXN',
    },
    'SGD': {
      'symbol': 'S\$',
      'name': 'Singapore Dollar',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Singapore',
      'code': 'SGD',
    },
    'HKD': {
      'symbol': 'HK\$',
      'name': 'Hong Kong Dollar',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Hong Kong',
      'code': 'HKD',
    },
    'INR': {
      'symbol': '₹',
      'name': 'Indian Rupee',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'India',
      'code': 'INR',
    },
    'KRW': {
      'symbol': '₩',
      'name': 'South Korean Won',
      'symbolPosition': 'before',
      'decimalPlaces': 0,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'South Korea',
      'code': 'KRW',
    },
    'TRY': {
      'symbol': '₺',
      'name': 'Turkish Lira',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': '.',
      'decimalSeparator': ',',
      'country': 'Turkey',
      'code': 'TRY',
    },
    'RUB': {
      'symbol': '₽',
      'name': 'Russian Ruble',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': ' ',
      'decimalSeparator': ',',
      'country': 'Russia',
      'code': 'RUB',
    },
    'BRL': {
      'symbol': 'R\$',
      'name': 'Brazilian Real',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': '.',
      'decimalSeparator': ',',
      'country': 'Brazil',
      'code': 'BRL',
    },
    'ZAR': {
      'symbol': 'R',
      'name': 'South African Rand',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ' ',
      'decimalSeparator': '.',
      'country': 'South Africa',
      'code': 'ZAR',
    },
    'PLN': {
      'symbol': 'zł',
      'name': 'Polish Zloty',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': ' ',
      'decimalSeparator': ',',
      'country': 'Poland',
      'code': 'PLN',
    },
    'CZK': {
      'symbol': 'Kč',
      'name': 'Czech Koruna',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
      'thousandSeparator': ' ',
      'decimalSeparator': ',',
      'country': 'Czech Republic',
      'code': 'CZK',
    },
    'HUF': {
      'symbol': 'Ft',
      'name': 'Hungarian Forint',
      'symbolPosition': 'after',
      'decimalPlaces': 0,
      'thousandSeparator': ' ',
      'decimalSeparator': ',',
      'country': 'Hungary',
      'code': 'HUF',
    },
    'ILS': {
      'symbol': '₪',
      'name': 'Israeli Shekel',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Israel',
      'code': 'ILS',
    },
    'AED': {
      'symbol': 'د.إ',
      'name': 'UAE Dirham',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'United Arab Emirates',
      'code': 'AED',
    },
    'SAR': {
      'symbol': 'ر.س',
      'name': 'Saudi Riyal',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Saudi Arabia',
      'code': 'SAR',
    },
    'THB': {
      'symbol': '฿',
      'name': 'Thai Baht',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Thailand',
      'code': 'THB',
    },
    'MYR': {
      'symbol': 'RM',
      'name': 'Malaysian Ringgit',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Malaysia',
      'code': 'MYR',
    },
    'IDR': {
      'symbol': 'Rp',
      'name': 'Indonesian Rupiah',
      'symbolPosition': 'before',
      'decimalPlaces': 0,
      'thousandSeparator': '.',
      'decimalSeparator': ',',
      'country': 'Indonesia',
      'code': 'IDR',
    },
    'PHP': {
      'symbol': '₱',
      'name': 'Philippine Peso',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
      'thousandSeparator': ',',
      'decimalSeparator': '.',
      'country': 'Philippines',
      'code': 'PHP',
    },
    'VND': {
      'symbol': '₫',
      'name': 'Vietnamese Dong',
      'symbolPosition': 'after',
      'decimalPlaces': 0,
      'thousandSeparator': '.',
      'decimalSeparator': ',',
      'country': 'Vietnam',
      'code': 'VND',
    },
  };

  // Get all supported currencies
  static List<String> getSupportedCurrencies() {
    return _currencyData.keys.toList()..sort();
  }

  // Get currency information
  static Map<String, dynamic>? getCurrencyInfo(String currencyCode) {
    return _currencyData[currencyCode.toUpperCase()];
  }

  static String getCurrencySymbol(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    return info?['symbol'] ?? currencyCode.toUpperCase();
  }

  static String getCurrencyName(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    return info?['name'] ?? currencyCode.toUpperCase();
  }

  static int getDecimalPlaces(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    return info?['decimalPlaces'] ?? 2;
  }

  static String getThousandSeparator(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    return info?['thousandSeparator'] ?? ',';
  }

  static String getDecimalSeparator(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    return info?['decimalSeparator'] ?? '.';
  }

  static bool isSymbolBefore(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    return info?['symbolPosition'] == 'before';
  }

  // Currency formatting methods
  static String formatCurrency(
    double amount,
    String currencyCode, {
    bool showSymbol = true,
    bool showCode = false,
    int? overrideDecimalPlaces,
  }) {
    final info = getCurrencyInfo(currencyCode);
    if (info == null) {
      return amount.toStringAsFixed(2);
    }

    final symbol = info['symbol'] as String;
    final symbolPosition = info['symbolPosition'] as String;
    final decimalPlaces =
        overrideDecimalPlaces ?? (info['decimalPlaces'] as int);
    final thousandSeparator = info['thousandSeparator'] as String;
    final decimalSeparator = info['decimalSeparator'] as String;

    // Format the number
    final formattedNumber = _formatNumber(
      amount,
      decimalPlaces,
      thousandSeparator,
      decimalSeparator,
    );

    // Build the final string
    String result = formattedNumber;

    if (showSymbol) {
      if (symbolPosition == 'before') {
        result = symbol + result;
      } else {
        result = result + ' ' + symbol;
      }
    }

    if (showCode) {
      result = result + ' ' + currencyCode.toUpperCase();
    }

    return result;
  }

  static String formatCurrencyCompact(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);

    if (amount.abs() >= 1000000000) {
      return '${symbol}${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount.abs() >= 1000000) {
      return '${symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${symbol}${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(amount, currencyCode);
    }
  }

  static String formatCurrencyRange(
    double minAmount,
    double maxAmount,
    String currencyCode,
  ) {
    final minFormatted = formatCurrency(minAmount, currencyCode);
    final maxFormatted = formatCurrency(maxAmount, currencyCode);
    return '$minFormatted - $maxFormatted';
  }

  static String _formatNumber(
    double amount,
    int decimalPlaces,
    String thousandSeparator,
    String decimalSeparator,
  ) {
    // Handle negative numbers
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();

    // Split into integer and decimal parts
    final integerPart = absoluteAmount.floor();
    final decimalPart = absoluteAmount - integerPart;

    // Format integer part with thousand separators
    String integerString = integerPart.toString();
    if (integerPart >= 1000) {
      integerString = _addThousandSeparators(integerString, thousandSeparator);
    }

    // Format decimal part
    String result = integerString;
    if (decimalPlaces > 0) {
      final decimalString = (decimalPart * pow(10, decimalPlaces))
          .round()
          .toString()
          .padLeft(decimalPlaces, '0');
      result += decimalSeparator + decimalString;
    }

    // Add negative sign if needed
    if (isNegative) {
      result = '-' + result;
    }

    return result;
  }

  static String _addThousandSeparators(String number, String separator) {
    final reversed = number.split('').reversed.toList();
    final withSeparators = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withSeparators.add(separator);
      }
      withSeparators.add(reversed[i]);
    }

    return withSeparators.reversed.join('');
  }

  // Currency parsing methods
  static double? parseCurrency(String currencyString, String currencyCode) {
    if (currencyString.isEmpty) return null;

    final info = getCurrencyInfo(currencyCode);
    if (info == null) return null;

    final symbol = info['symbol'] as String;
    final thousandSeparator = info['thousandSeparator'] as String;
    final decimalSeparator = info['decimalSeparator'] as String;

    // Remove currency symbol and code
    String cleaned = currencyString
        .replaceAll(symbol, '')
        .replaceAll(currencyCode.toUpperCase(), '')
        .trim();

    // Handle negative numbers
    bool isNegative = cleaned.startsWith('-') || cleaned.startsWith('(');
    cleaned = cleaned.replaceAll(RegExp(r'^[-\(]|[\)]$'), '');

    // Replace thousand separators
    cleaned = cleaned.replaceAll(thousandSeparator, '');

    // Replace decimal separator with standard dot
    if (decimalSeparator != '.') {
      cleaned = cleaned.replaceAll(decimalSeparator, '.');
    }

    // Parse the number
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;

    return isNegative ? -parsed : parsed;
  }

  static double? parseAmount(String amountString) {
    if (amountString.isEmpty) return null;

    // Remove common currency symbols and formatting
    String cleaned = amountString
        .replaceAll(RegExp(r'[\$€£¥₹₩₺₽₪₫฿]'), '')
        .replaceAll(RegExp(r'[A-Z]{3}'), '') // Remove currency codes
        .replaceAll(RegExp(r'[,\s]'), '') // Remove commas and spaces
        .trim();

    // Handle negative numbers
    bool isNegative = cleaned.startsWith('-') || cleaned.startsWith('(');
    cleaned = cleaned.replaceAll(RegExp(r'[-()]'), '');

    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;

    return isNegative ? -parsed : parsed;
  }

  // Currency validation methods
  static bool isValidCurrency(String currencyCode) {
    return _currencyData.containsKey(currencyCode.toUpperCase());
  }

  static bool isValidAmount(double amount, String currencyCode) {
    if (amount.isNaN || amount.isInfinite) return false;

    final decimalPlaces = getDecimalPlaces(currencyCode);

    // Check if the amount has more decimal places than allowed
    final multiplier = pow(10, decimalPlaces);
    final rounded = (amount * multiplier).round() / multiplier;

    return (amount - rounded).abs() <
        0.0001; // Allow for floating point precision
  }

  static String? validateCurrencyAmount(
    String amountString,
    String currencyCode,
  ) {
    if (amountString.isEmpty) {
      return 'Amount is required';
    }

    final amount = parseAmount(amountString);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    if (amount > 999999999.99) {
      return 'Amount is too large';
    }

    if (!isValidAmount(amount, currencyCode)) {
      final decimalPlaces = getDecimalPlaces(currencyCode);
      return 'Amount can have at most $decimalPlaces decimal places';
    }

    return null;
  }

  // Currency conversion methods (requires exchange rates)
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
    Map<String, double> exchangeRates,
  ) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = exchangeRates[fromCurrency.toUpperCase()];
    final toRate = exchangeRates[toCurrency.toUpperCase()];

    if (fromRate == null || toRate == null) {
      throw ArgumentError(
        'Exchange rate not available for currency conversion',
      );
    }

    // Convert to base currency (usually USD) then to target currency
    final baseAmount = amount / fromRate;
    return baseAmount * toRate;
  }

  static String formatConvertedAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
    Map<String, double> exchangeRates,
  ) {
    final convertedAmount = convertCurrency(
      amount,
      fromCurrency,
      toCurrency,
      exchangeRates,
    );
    return formatCurrency(convertedAmount, toCurrency);
  }

  // Regional currency methods
  static String getCurrencyByCountry(String countryCode) {
    const countryCurrencies = {
      'US': 'USD',
      'CA': 'CAD',
      'GB': 'GBP',
      'AU': 'AUD',
      'NZ': 'NZD',
      'JP': 'JPY',
      'KR': 'KRW',
      'CN': 'CNY',
      'IN': 'INR',
      'SG': 'SGD',
      'HK': 'HKD',
      'MX': 'MXN',
      'BR': 'BRL',
      'ZA': 'ZAR',
      'CH': 'CHF',
      'SE': 'SEK',
      'NO': 'NOK',
      'DK': 'DKK',
      'PL': 'PLN',
      'CZ': 'CZK',
      'HU': 'HUF',
      'TR': 'TRY',
      'RU': 'RUB',
      'IL': 'ILS',
      'AE': 'AED',
      'SA': 'SAR',
      'TH': 'THB',
      'MY': 'MYR',
      'ID': 'IDR',
      'PH': 'PHP',
      'VN': 'VND',
    };

    return countryCurrencies[countryCode.toUpperCase()] ?? 'USD';
  }

  static List<String> getCurrenciesByRegion(String region) {
    const regionCurrencies = {
      'north_america': ['USD', 'CAD', 'MXN'],
      'europe': ['EUR', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF'],
      'asia_pacific': [
        'JPY',
        'KRW',
        'CNY',
        'INR',
        'SGD',
        'HKD',
        'AUD',
        'NZD',
        'THB',
        'MYR',
        'IDR',
        'PHP',
        'VND',
      ],
      'middle_east': ['AED', 'SAR', 'ILS'],
      'africa': ['ZAR'],
      'south_america': ['BRL'],
    };

    return regionCurrencies[region.toLowerCase()] ?? [];
  }

  // Currency display methods
  static List<Map<String, String>> getCurrencyList({
    bool includeSymbol = true,
  }) {
    return _currencyData.entries.map((entry) {
      final code = entry.key;
      final info = entry.value;

      return {
        'code': code,
        'name': info['name'] as String,
        'symbol': info['symbol'] as String,
        'country': info['country'] as String,
        'display': includeSymbol
            ? '${info['symbol']} $code - ${info['name']}'
            : '$code - ${info['name']}',
      };
    }).toList()..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  static List<Map<String, String>> getPopularCurrencies() {
    const popularCodes = [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
      'CHF',
      'CNY',
    ];

    return popularCodes.map((code) {
      final info = _currencyData[code]!;
      return {
        'code': code,
        'name': info['name'] as String,
        'symbol': info['symbol'] as String,
        'country': info['country'] as String,
      };
    }).toList();
  }

  // Tax and business methods
  static double calculateTax(
    double amount,
    double taxRate,
    String currencyCode,
  ) {
    final taxAmount = amount * (taxRate / 100);
    final decimalPlaces = getDecimalPlaces(currencyCode);
    final multiplier = pow(10, decimalPlaces);

    return (taxAmount * multiplier).round() / multiplier;
  }

  static double calculateTotal(
    double subtotal,
    double taxAmount,
    double discount,
  ) {
    return subtotal + taxAmount - discount;
  }

  static Map<String, double> calculateInvoiceTotals(
    List<Map<String, dynamic>> lineItems,
    double taxRate,
    double discount,
    String currencyCode,
  ) {
    double subtotal = 0;

    for (final item in lineItems) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      final rate = (item['rate'] as num?)?.toDouble() ?? 0;
      subtotal += quantity * rate;
    }

    final taxAmount = calculateTax(subtotal, taxRate, currencyCode);
    final total = calculateTotal(subtotal, taxAmount, discount);

    return {
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discount': discount,
      'total': total,
    };
  }

  // Receipt processing methods
  static String detectCurrencyFromText(String text) {
    // Look for currency symbols in text
    for (final entry in _currencyData.entries) {
      final symbol = entry.value['symbol'] as String;
      if (text.contains(symbol)) {
        return entry.key;
      }
    }

    // Look for currency codes
    for (final code in _currencyData.keys) {
      if (text.toUpperCase().contains(code)) {
        return code;
      }
    }

    return 'USD'; // Default fallback
  }

  static double? extractAmountFromText(String text) {
    // Common patterns for amounts in receipts
    final patterns = [
      RegExp(
        r'TOTAL[\s:]*[\$€£¥₹₩₺₽₪₫฿]?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'AMOUNT[\s:]*[\$€£¥₹₩₺₽₪₫฿]?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'[\$€£¥₹₩₺₽₪₫฿]\s*([\d,]+\.?\d*)'),
      RegExp(r'([\d,]+\.?\d*)\s*[\$€£¥₹₩₺₽₪₫฿]'),
      RegExp(r'([\d,]+\.\d{2})'), // Decimal amounts
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    return null;
  }

  // Utility methods
  static String roundCurrency(double amount, String currencyCode) {
    final decimalPlaces = getDecimalPlaces(currencyCode);
    final multiplier = pow(10, decimalPlaces);
    final rounded = (amount * multiplier).round() / multiplier;

    return formatCurrency(rounded, currencyCode);
  }

  static double roundAmount(double amount, String currencyCode) {
    final decimalPlaces = getDecimalPlaces(currencyCode);
    final multiplier = pow(10, decimalPlaces);

    return (amount * multiplier).round() / multiplier;
  }

  static bool isMajorCurrency(String currencyCode) {
    const majorCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD'];
    return majorCurrencies.contains(currencyCode.toUpperCase());
  }

  static String getCurrencyFlag(String currencyCode) {
    const currencyFlags = {
      'USD': '🇺🇸',
      'EUR': '🇪🇺',
      'GBP': '🇬🇧',
      'JPY': '🇯🇵',
      'CAD': '🇨🇦',
      'AUD': '🇦🇺',
      'CHF': '🇨🇭',
      'CNY': '🇨🇳',
      'SEK': '🇸🇪',
      'NOK': '🇳🇴',
      'DKK': '🇩🇰',
      'NZD': '🇳🇿',
      'MXN': '🇲🇽',
      'SGD': '🇸🇬',
      'HKD': '🇭🇰',
      'INR': '🇮🇳',
      'KRW': '🇰🇷',
      'TRY': '🇹🇷',
      'RUB': '🇷🇺',
      'BRL': '🇧🇷',
      'ZAR': '🇿🇦',
      'PLN': '🇵🇱',
      'CZK': '🇨🇿',
      'HUF': '🇭🇺',
      'ILS': '🇮🇱',
      'AED': '🇦🇪',
      'SAR': '🇸🇦',
      'THB': '🇹🇭',
      'MYR': '🇲🇾',
      'IDR': '🇮🇩',
      'PHP': '🇵🇭',
      'VND': '🇻🇳',
    };

    return currencyFlags[currencyCode.toUpperCase()] ?? '💱';
  }

  // Export/Import methods
  static Map<String, dynamic> exportCurrencySettings(String currencyCode) {
    final info = getCurrencyInfo(currencyCode);
    if (info == null) return {};

    return {
      'currencyCode': currencyCode,
      'symbol': info['symbol'],
      'name': info['name'],
      'decimalPlaces': info['decimalPlaces'],
      'thousandSeparator': info['thousandSeparator'],
      'decimalSeparator': info['decimalSeparator'],
      'symbolPosition': info['symbolPosition'],
    };
  }

  static String formatForExport(
    double amount,
    String currencyCode,
    String format,
  ) {
    switch (format.toLowerCase()) {
      case 'csv':
        return amount.toStringAsFixed(getDecimalPlaces(currencyCode));
      case 'json':
        return jsonEncode({
          'amount': amount,
          'currency': currencyCode,
          'formatted': formatCurrency(amount, currencyCode),
        });
      case 'xml':
        return '<amount currency="$currencyCode">${amount.toStringAsFixed(getDecimalPlaces(currencyCode))}</amount>';
      default:
        return formatCurrency(amount, currencyCode);
    }
  }

  // Analytics methods
  static Map<String, double> aggregateAmountsByCurrency(
    List<Map<String, dynamic>> transactions,
  ) {
    final totals = <String, double>{};

    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
      final currency = transaction['currency'] as String? ?? 'USD';

      totals[currency] = (totals[currency] ?? 0) + amount;
    }

    return totals;
  }

  static String formatMultiCurrencyTotal(Map<String, double> amounts) {
    if (amounts.isEmpty) return '';

    if (amounts.length == 1) {
      final entry = amounts.entries.first;
      return formatCurrency(entry.value, entry.key);
    }

    final formatted = amounts.entries
        .map((entry) => formatCurrency(entry.value, entry.key))
        .toList();

    return formatted.join(' + ');
  }

  // Input formatting for text fields
  static String formatCurrencyInput(String input, String currencyCode) {
    if (input.isEmpty) return input;

    final decimalPlaces = getDecimalPlaces(currencyCode);
    final decimalSeparator = getDecimalSeparator(currencyCode);

    // Remove invalid characters
    String cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');

    // Handle decimal separator
    if (decimalSeparator != '.') {
      cleaned = cleaned.replaceAll('.', decimalSeparator);
    }

    // Ensure only one decimal separator
    final parts = cleaned.split(decimalSeparator);
    if (parts.length > 2) {
      cleaned = '${parts[0]}$decimalSeparator${parts.sublist(1).join('')}';
    }

    // Limit decimal places
    if (parts.length == 2 && parts[1].length > decimalPlaces) {
      parts[1] = parts[1].substring(0, decimalPlaces);
      cleaned = parts.join(decimalSeparator);
    }

    return cleaned;
  }
}
