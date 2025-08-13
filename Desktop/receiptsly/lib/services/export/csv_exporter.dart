// lib/services/export/csv_exporter.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

enum CSVDelimiter { comma, semicolon, tab, pipe }

enum CSVExportType {
  receipts,
  invoices,
  clients,
  expenseReport,
  incomeReport,
  taxReport,
  custom,
}

class CSVExportConfig {
  final CSVExportType exportType;
  final CSVDelimiter delimiter;
  final bool includeHeaders;
  final String? dateFormat;
  final String? currencyFormat;
  final List<String>? selectedColumns;
  final Map<String, String>? columnMapping;
  final bool escapeQuotes;
  final String? encoding;
  final Map<String, dynamic>? filters;

  CSVExportConfig({
    required this.exportType,
    this.delimiter = CSVDelimiter.comma,
    this.includeHeaders = true,
    this.dateFormat,
    this.currencyFormat,
    this.selectedColumns,
    this.columnMapping,
    this.escapeQuotes = true,
    this.encoding = 'utf-8',
    this.filters,
  });
}

class CSVExportResult {
  final bool success;
  final String? filePath;
  final String? csvContent;
  final int rowCount;
  final int columnCount;
  final String? error;
  final Map<String, dynamic>? metadata;

  CSVExportResult({
    required this.success,
    this.filePath,
    this.csvContent,
    required this.rowCount,
    required this.columnCount,
    this.error,
    this.metadata,
  });
}

class CSVExporterService {
  static const String _defaultDateFormat = 'yyyy-MM-dd';
  static const String _defaultCurrencyFormat = '#,##0.00';

  // Export data to CSV
  Future<CSVExportResult> exportToCSV({
    required List<Map<String, dynamic>> data,
    required CSVExportConfig config,
    String? fileName,
    bool saveToFile = true,
  }) async {
    try {
      if (data.isEmpty) {
        return CSVExportResult(
          success: false,
          error: 'No data to export',
          rowCount: 0,
          columnCount: 0,
        );
      }

      // Apply filters if specified
      final filteredData = _applyFilters(data, config.filters);

      if (filteredData.isEmpty) {
        return CSVExportResult(
          success: false,
          error: 'No data after applying filters',
          rowCount: 0,
          columnCount: 0,
        );
      }

      // Get columns to export
      final columns = _getColumnsToExport(filteredData, config);

      // Transform data for CSV
      final csvData = _transformDataForCSV(filteredData, columns, config);

      // Generate CSV content
      final csvContent = _generateCSVContent(csvData, config);

      String? filePath;
      if (saveToFile) {
        fileName ??= _generateFileName(config.exportType);
        filePath = await _saveToFile(csvContent, fileName);
      }

      debugPrint(
        'CSVExporterService: Export completed - ${filteredData.length} rows, ${columns.length} columns',
      );

      return CSVExportResult(
        success: true,
        filePath: filePath,
        csvContent: saveToFile ? null : csvContent,
        rowCount: filteredData.length,
        columnCount: columns.length,
        metadata: {
          'exportType': config.exportType.name,
          'delimiter': config.delimiter.name,
          'includeHeaders': config.includeHeaders,
          'originalRowCount': data.length,
          'filteredRowCount': filteredData.length,
        },
      );
    } catch (e) {
      debugPrint('CSVExporterService: Export failed - $e');
      return CSVExportResult(
        success: false,
        error: e.toString(),
        rowCount: 0,
        columnCount: 0,
      );
    }
  }

  // Export receipts to CSV
  Future<CSVExportResult> exportReceipts({
    required List<Map<String, dynamic>> receipts,
    CSVExportConfig? config,
    String? fileName,
  }) async {
    final exportConfig =
        config ??
        CSVExportConfig(
          exportType: CSVExportType.receipts,
          selectedColumns: [
            'date',
            'vendor',
            'amount',
            'category',
            'description',
            'tax_amount',
            'payment_method',
            'status',
          ],
          columnMapping: {
            'date': 'Date',
            'vendor': 'Vendor',
            'amount': 'Amount',
            'category': 'Category',
            'description': 'Description',
            'tax_amount': 'Tax',
            'payment_method': 'Payment Method',
            'status': 'Status',
          },
        );

    return await exportToCSV(
      data: receipts,
      config: exportConfig,
      fileName: fileName ?? 'receipts_export_${_getTimestamp()}.csv',
    );
  }

  // Export invoices to CSV
  Future<CSVExportResult> exportInvoices({
    required List<Map<String, dynamic>> invoices,
    CSVExportConfig? config,
    String? fileName,
  }) async {
    final exportConfig =
        config ??
        CSVExportConfig(
          exportType: CSVExportType.invoices,
          selectedColumns: [
            'invoice_number',
            'client_name',
            'issue_date',
            'due_date',
            'subtotal',
            'tax_amount',
            'total',
            'status',
            'payment_date',
          ],
          columnMapping: {
            'invoice_number': 'Invoice #',
            'client_name': 'Client',
            'issue_date': 'Issue Date',
            'due_date': 'Due Date',
            'subtotal': 'Subtotal',
            'tax_amount': 'Tax',
            'total': 'Total',
            'status': 'Status',
            'payment_date': 'Payment Date',
          },
        );

    return await exportToCSV(
      data: invoices,
      config: exportConfig,
      fileName: fileName ?? 'invoices_export_${_getTimestamp()}.csv',
    );
  }

  // Export clients to CSV
  Future<CSVExportResult> exportClients({
    required List<Map<String, dynamic>> clients,
    CSVExportConfig? config,
    String? fileName,
  }) async {
    final exportConfig =
        config ??
        CSVExportConfig(
          exportType: CSVExportType.clients,
          selectedColumns: [
            'name',
            'email',
            'phone',
            'address',
            'total_invoiced',
            'total_paid',
            'outstanding_balance',
            'created_date',
          ],
          columnMapping: {
            'name': 'Client Name',
            'email': 'Email',
            'phone': 'Phone',
            'address': 'Address',
            'total_invoiced': 'Total Invoiced',
            'total_paid': 'Total Paid',
            'outstanding_balance': 'Outstanding Balance',
            'created_date': 'Created Date',
          },
        );

    return await exportToCSV(
      data: clients,
      config: exportConfig,
      fileName: fileName ?? 'clients_export_${_getTimestamp()}.csv',
    );
  }

  // Export expense report to CSV
  Future<CSVExportResult> exportExpenseReport({
    required List<Map<String, dynamic>> expenses,
    required DateTime startDate,
    required DateTime endDate,
    CSVExportConfig? config,
    String? fileName,
  }) async {
    // Add report metadata to each row
    final enrichedData = expenses
        .map(
          (expense) => {
            ...expense,
            'report_period_start': startDate.toIso8601String(),
            'report_period_end': endDate.toIso8601String(),
            'report_generated_date': DateTime.now().toIso8601String(),
          },
        )
        .toList();

    final exportConfig =
        config ??
        CSVExportConfig(
          exportType: CSVExportType.expenseReport,
          selectedColumns: [
            'date',
            'vendor',
            'description',
            'category',
            'amount',
            'tax_amount',
            'total_amount',
            'payment_method',
            'receipt_status',
            'notes',
          ],
          columnMapping: {
            'date': 'Expense Date',
            'vendor': 'Vendor/Merchant',
            'description': 'Description',
            'category': 'Category',
            'amount': 'Amount (excl. tax)',
            'tax_amount': 'Tax Amount',
            'total_amount': 'Total Amount',
            'payment_method': 'Payment Method',
            'receipt_status': 'Receipt Status',
            'notes': 'Notes',
          },
          filters: {
            'date_range': {'start': startDate, 'end': endDate},
          },
        );

    return await exportToCSV(
      data: enrichedData,
      config: exportConfig,
      fileName:
          fileName ??
          'expense_report_${_formatDateForFileName(startDate)}_to_${_formatDateForFileName(endDate)}.csv',
    );
  }

  // Export income report to CSV
  Future<CSVExportResult> exportIncomeReport({
    required List<Map<String, dynamic>> income,
    required DateTime startDate,
    required DateTime endDate,
    CSVExportConfig? config,
    String? fileName,
  }) async {
    final enrichedData = income
        .map(
          (item) => {
            ...item,
            'report_period_start': startDate.toIso8601String(),
            'report_period_end': endDate.toIso8601String(),
            'report_generated_date': DateTime.now().toIso8601String(),
          },
        )
        .toList();

    final exportConfig =
        config ??
        CSVExportConfig(
          exportType: CSVExportType.incomeReport,
          selectedColumns: [
            'invoice_number',
            'client_name',
            'service_description',
            'invoice_date',
            'payment_date',
            'subtotal',
            'tax_amount',
            'total_amount',
            'payment_method',
            'status',
          ],
          columnMapping: {
            'invoice_number': 'Invoice Number',
            'client_name': 'Client Name',
            'service_description': 'Service Description',
            'invoice_date': 'Invoice Date',
            'payment_date': 'Payment Date',
            'subtotal': 'Subtotal',
            'tax_amount': 'Tax Amount',
            'total_amount': 'Total Amount',
            'payment_method': 'Payment Method',
            'status': 'Status',
          },
        );

    return await exportToCSV(
      data: enrichedData,
      config: exportConfig,
      fileName:
          fileName ??
          'income_report_${_formatDateForFileName(startDate)}_to_${_formatDateForFileName(endDate)}.csv',
    );
  }

  // Export tax report to CSV
  Future<CSVExportResult> exportTaxReport({
    required Map<String, dynamic> taxData,
    required DateTime startDate,
    required DateTime endDate,
    CSVExportConfig? config,
    String? fileName,
  }) async {
    // Convert tax summary and details to flat structure
    final List<Map<String, dynamic>> flattenedData = [];

    // Add summary information
    if (taxData['summary'] != null) {
      final summary = taxData['summary'] as Map<String, dynamic>;
      flattenedData.add({
        'type': 'SUMMARY',
        'description': 'Tax Summary',
        'category': 'Summary',
        'amount': summary['total_tax'] ?? 0,
        'deductible_amount': summary['total_deductible'] ?? 0,
        'taxable_income': summary['taxable_income'] ?? 0,
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
      });
    }

    // Add detailed transactions
    if (taxData['deductible_expenses'] != null) {
      final expenses =
          taxData['deductible_expenses'] as List<Map<String, dynamic>>;
      for (final expense in expenses) {
        flattenedData.add({
          'type': 'DEDUCTIBLE_EXPENSE',
          'description': expense['description'] ?? '',
          'category': expense['category'] ?? '',
          'amount': expense['amount'] ?? 0,
          'deductible_amount': expense['deductible_amount'] ?? 0,
          'tax_rate': expense['tax_rate'] ?? 0,
          'date': expense['date']?.toString() ?? '',
          'vendor': expense['vendor'] ?? '',
        });
      }
    }

    if (taxData['taxable_income'] != null) {
      final income = taxData['taxable_income'] as List<Map<String, dynamic>>;
      for (final item in income) {
        flattenedData.add({
          'type': 'TAXABLE_INCOME',
          'description': item['description'] ?? '',
          'category': item['category'] ?? '',
          'amount': item['amount'] ?? 0,
          'tax_amount': item['tax_amount'] ?? 0,
          'date': item['date']?.toString() ?? '',
          'client': item['client'] ?? '',
        });
      }
    }

    final exportConfig =
        config ??
        CSVExportConfig(
          exportType: CSVExportType.taxReport,
          selectedColumns: [
            'type',
            'date',
            'description',
            'category',
            'vendor',
            'client',
            'amount',
            'deductible_amount',
            'tax_amount',
            'tax_rate',
          ],
          columnMapping: {
            'type': 'Type',
            'date': 'Date',
            'description': 'Description',
            'category': 'Category',
            'vendor': 'Vendor',
            'client': 'Client',
            'amount': 'Amount',
            'deductible_amount': 'Deductible Amount',
            'tax_amount': 'Tax Amount',
            'tax_rate': 'Tax Rate (%)',
          },
        );

    return await exportToCSV(
      data: flattenedData,
      config: exportConfig,
      fileName:
          fileName ??
          'tax_report_${_formatDateForFileName(startDate)}_to_${_formatDateForFileName(endDate)}.csv',
    );
  }

  // Private helper methods

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> data,
    Map<String, dynamic>? filters,
  ) {
    if (filters == null || filters.isEmpty) {
      return data;
    }

    return data.where((item) {
      for (final filter in filters.entries) {
        if (!_passesFilter(item, filter.key, filter.value)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _passesFilter(
    Map<String, dynamic> item,
    String filterKey,
    dynamic filterValue,
  ) {
    switch (filterKey) {
      case 'date_range':
        return _passesDateRangeFilter(item, filterValue);
      case 'amount_range':
        return _passesAmountRangeFilter(item, filterValue);
      case 'category':
        return _passesCategoryFilter(item, filterValue);
      case 'status':
        return _passesStatusFilter(item, filterValue);
      default:
        return true;
    }
  }

  bool _passesDateRangeFilter(Map<String, dynamic> item, dynamic filterValue) {
    if (filterValue is! Map<String, dynamic>) return true;

    final start = filterValue['start'] as DateTime?;
    final end = filterValue['end'] as DateTime?;

    final itemDate = _parseDate(item['date']) ?? _parseDate(item['created_at']);
    if (itemDate == null) return true;

    if (start != null && itemDate.isBefore(start)) return false;
    if (end != null && itemDate.isAfter(end)) return false;

    return true;
  }

  bool _passesAmountRangeFilter(
    Map<String, dynamic> item,
    dynamic filterValue,
  ) {
    if (filterValue is! Map<String, dynamic>) return true;

    final min = filterValue['min'] as double?;
    final max = filterValue['max'] as double?;

    final amount = _parseDouble(item['amount']) ?? _parseDouble(item['total']);
    if (amount == null) return true;

    if (min != null && amount < min) return false;
    if (max != null && amount > max) return false;

    return true;
  }

  bool _passesCategoryFilter(Map<String, dynamic> item, dynamic filterValue) {
    if (filterValue is String) {
      return item['category']?.toString().toLowerCase() ==
          filterValue.toLowerCase();
    } else if (filterValue is List) {
      final itemCategory = item['category']?.toString().toLowerCase();
      return filterValue.any(
        (cat) => cat.toString().toLowerCase() == itemCategory,
      );
    }
    return true;
  }

  bool _passesStatusFilter(Map<String, dynamic> item, dynamic filterValue) {
    if (filterValue is String) {
      return item['status']?.toString().toLowerCase() ==
          filterValue.toLowerCase();
    } else if (filterValue is List) {
      final itemStatus = item['status']?.toString().toLowerCase();
      return filterValue.any(
        (status) => status.toString().toLowerCase() == itemStatus,
      );
    }
    return true;
  }

  List<String> _getColumnsToExport(
    List<Map<String, dynamic>> data,
    CSVExportConfig config,
  ) {
    if (config.selectedColumns != null && config.selectedColumns!.isNotEmpty) {
      return config.selectedColumns!;
    }

    // Get all unique keys from the data
    final allKeys = <String>{};
    for (final item in data) {
      allKeys.addAll(item.keys);
    }

    return allKeys.toList()..sort();
  }

  List<List<String>> _transformDataForCSV(
    List<Map<String, dynamic>> data,
    List<String> columns,
    CSVExportConfig config,
  ) {
    final csvData = <List<String>>[];

    // Add headers if requested
    if (config.includeHeaders) {
      final headers = columns.map((col) {
        return config.columnMapping?[col] ?? _formatColumnName(col);
      }).toList();
      csvData.add(headers);
    }

    // Add data rows
    for (final item in data) {
      final row = columns.map((col) {
        return _formatCellValue(item[col], col, config);
      }).toList();
      csvData.add(row);
    }

    return csvData;
  }

  String _formatCellValue(
    dynamic value,
    String columnName,
    CSVExportConfig config,
  ) {
    if (value == null) return '';

    // Handle different data types
    if (value is DateTime) {
      final format = config.dateFormat ?? _defaultDateFormat;
      return DateFormat(format).format(value);
    } else if (value is double || value is int) {
      if (columnName.toLowerCase().contains('amount') ||
          columnName.toLowerCase().contains('price') ||
          columnName.toLowerCase().contains('total')) {
        return _formatCurrency(value.toDouble());
      } else if (columnName.toLowerCase().contains('rate') ||
          columnName.toLowerCase().contains('percent')) {
        return '${value.toStringAsFixed(2)}%';
      }
      return value.toString();
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is List) {
      return value.join('; ');
    } else if (value is Map) {
      return jsonEncode(value);
    }

    // Escape quotes if needed
    String stringValue = value.toString();
    if (config.escapeQuotes && stringValue.contains('"')) {
      stringValue = stringValue.replaceAll('"', '""');
    }

    return stringValue;
  }

  String _formatColumnName(String columnName) {
    return columnName
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  String _generateCSVContent(
    List<List<String>> csvData,
    CSVExportConfig config,
  ) {
    final delimiter = _getDelimiterString(config.delimiter);

    return const ListToCsvConverter().convert(
      csvData,
      fieldDelimiter: delimiter,
      textDelimiter: '"',
      eol: '\n',
    );
  }

  String _getDelimiterString(CSVDelimiter delimiter) {
    switch (delimiter) {
      case CSVDelimiter.comma:
        return ',';
      case CSVDelimiter.semicolon:
        return ';';
      case CSVDelimiter.tab:
        return '\t';
      case CSVDelimiter.pipe:
        return '|';
    }
  }

  Future<String> _saveToFile(String csvContent, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvContent, encoding: utf8);

      debugPrint('CSVExporterService: CSV saved to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('CSVExporterService: Error saving CSV - $e');
      throw CSVExporterException('Failed to save CSV file: $e');
    }
  }

  String _generateFileName(CSVExportType exportType) {
    final timestamp = _getTimestamp();
    switch (exportType) {
      case CSVExportType.receipts:
        return 'receipts_$timestamp.csv';
      case CSVExportType.invoices:
        return 'invoices_$timestamp.csv';
      case CSVExportType.clients:
        return 'clients_$timestamp.csv';
      case CSVExportType.expenseReport:
        return 'expense_report_$timestamp.csv';
      case CSVExportType.incomeReport:
        return 'income_report_$timestamp.csv';
      case CSVExportType.taxReport:
        return 'tax_report_$timestamp.csv';
      case CSVExportType.custom:
        return 'export_$timestamp.csv';
    }
  }

  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  String _formatDateForFileName(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Bulk export multiple types
  Future<Map<String, CSVExportResult>> exportBulk({
    required Map<CSVExportType, List<Map<String, dynamic>>> data,
    Map<CSVExportType, CSVExportConfig>? configs,
    String? directoryPath,
  }) async {
    final results = <String, CSVExportResult>{};

    for (final entry in data.entries) {
      final exportType = entry.key;
      final exportData = entry.value;
      final config =
          configs?[exportType] ?? CSVExportConfig(exportType: exportType);

      try {
        final result = await exportToCSV(
          data: exportData,
          config: config,
          fileName: _generateFileName(exportType),
        );

        results[exportType.name] = result;
      } catch (e) {
        results[exportType.name] = CSVExportResult(
          success: false,
          error: e.toString(),
          rowCount: 0,
          columnCount: 0,
        );
      }
    }

    return results;
  }

  // Get export statistics
  Map<String, dynamic> getExportStatistics(List<CSVExportResult> results) {
    final successful = results.where((r) => r.success).length;
    final failed = results.length - successful;
    final totalRows = results.fold<int>(0, (sum, r) => sum + r.rowCount);
    final totalColumns = results.fold<int>(0, (sum, r) => sum + r.columnCount);

    return {
      'total_exports': results.length,
      'successful_exports': successful,
      'failed_exports': failed,
      'total_rows_exported': totalRows,
      'total_columns_exported': totalColumns,
      'success_rate': results.isNotEmpty
          ? (successful / results.length) * 100
          : 0,
    };
  }

  // Validate CSV data before export
  bool validateDataForExport(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return false;

    // Check if all rows have consistent structure
    final firstRowKeys = data.first.keys.toSet();

    for (final row in data) {
      final rowKeys = row.keys.toSet();
      if (rowKeys.difference(firstRowKeys).isNotEmpty ||
          firstRowKeys.difference(rowKeys).isNotEmpty) {
        debugPrint('CSVExporterService: Inconsistent data structure detected');
        return false;
      }
    }

    return true;
  }
}

// Custom exception for CSV exporter errors
class CSVExporterException implements Exception {
  final String message;

  CSVExporterException(this.message);

  @override
  String toString() => 'CSVExporterException: $message';
}
