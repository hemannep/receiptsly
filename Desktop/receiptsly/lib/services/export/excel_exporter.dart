
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

enum ExcelExportType {
  receipts,
  invoices,
  clients,
  expenseReport,
  incomeReport,
  taxReport,
  dashboard,
  multiSheet,
}

enum ExcelCellStyle {
  header,
  data,
  currency,
  date,
  percentage,
  total,
  subtitle,
}

class ExcelExportConfig {
  final ExcelExportType exportType;
  final String? sheetName;
  final bool includeHeaders;
  final bool autoFitColumns;
  final bool includeSummary;
  final bool includeCharts;
  final Map<String, String>? columnMapping;
  final List<String>? selectedColumns;
  final Map<String, dynamic>? styling;
  final bool freezeHeaders;
  final bool addFilters;
  final Map<String, dynamic>? metadata;

  ExcelExportConfig({
    required this.exportType,
    this.sheetName,
    this.includeHeaders = true,
    this.autoFitColumns = true,
    this.includeSummary = false,
    this.includeCharts = false,
    this.columnMapping,
    this.selectedColumns,
    this.styling,
    this.freezeHeaders = true,
    this.addFilters = true,
    this.metadata,
  });
}

class ExcelExportResult {
  final bool success;
  final String? filePath;
  final Uint8List? excelBytes;
  final int rowCount;
  final int columnCount;
  final int sheetCount;
  final String? error;
  final Map<String, dynamic>? metadata;

  ExcelExportResult({
    required this.success,
    this.filePath,
    this.excelBytes,
    required this.rowCount,
    required this.columnCount,
    required this.sheetCount,
    this.error,
    this.metadata,
  });
}

class ExcelExporterService {
  static const String _defaultDateFormat = 'dd/mm/yyyy';
  static const String _defaultCurrencyFormat = '#,##0.00';

  // Export data to Excel
  Future<ExcelExportResult> exportToExcel({
    required List<Map<String, dynamic>> data,
    required ExcelExportConfig config,
    String? fileName,
    bool saveToFile = true,
  }) async {
    try {
      if (data.isEmpty) {
        return ExcelExportResult(
          success: false,
          error: 'No data to export',
          rowCount: 0,
          columnCount: 0,
          sheetCount: 0,
        );
      }

      final excel = Excel.createExcel();
      final sheetName = config.sheetName ?? _getDefaultSheetName(config.exportType);
      
      // Remove default sheet and add our custom sheet
      excel.delete('Sheet1');
      excel[sheetName];

      // Get columns to export
      final columns = _getColumnsToExport(data, config);
      
      // Add data to sheet
      await _addDataToSheet(excel, sheetName, data, columns, config);
      
      // Apply styling
      await _applySheetStyling(excel, sheetName, config);
      
      // Add summary if requested
      if (config.includeSummary) {
        await _addSummarySection(excel, sheetName, data, config);
      }

      // Save file or return bytes
      Uint8List? excelBytes;
      String? filePath;

      if (saveToFile) {
        fileName ??= _generateFileName(config.exportType);
        filePath = await _saveToFile(excel, fileName);
      } else {
        excelBytes = excel.encode()!;
      }

      debugPrint('ExcelExporterService: Export completed - ${data.length} rows, ${columns.length} columns');

      return ExcelExportResult(
        success: true,
        filePath: filePath,
        excelBytes: excelBytes,
        rowCount: data.length,
        columnCount: columns.length,
        sheetCount: 1,
        metadata: {
          'exportType': config.exportType.name,
          'sheetName': sheetName,
          'includeHeaders': config.includeHeaders,
          'includeSummary': config.includeSummary,
        },
      );
    } catch (e) {
      debugPrint('ExcelExporterService: Export failed - $e');
      return ExcelExportResult(
        success: false,
        error: e.toString(),
        rowCount: 0,
        columnCount: 0,
        sheetCount: 0,
      );
    }
  }

  // Export multiple sheets
  Future<ExcelExportResult> exportMultiSheet({
    required Map<String, List<Map<String, dynamic>>> sheetsData,
    Map<String, ExcelExportConfig>? sheetConfigs,
    String? fileName,
    bool includeDashboard = true,
  }) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // Remove default sheet

      int totalRows = 0;
      int totalColumns = 0;
      int sheetCount = 0;

      // Add dashboard sheet if requested
      if (includeDashboard) {
        await _addDashboardSheet(excel, sheetsData);
        sheetCount++;
      }

      // Add data sheets
      for (final entry in sheetsData.entries) {
        final sheetName = entry.key;
        final data = entry.value;
        
        if (data.isEmpty) continue;

        final config = sheetConfigs?[sheetName] ?? ExcelExportConfig(
          exportType: ExcelExportType.multiSheet,
          sheetName: sheetName,
        );

        final columns = _getColumnsToExport(data, config);
        
        // Add sheet
        excel[sheetName];
        await _addDataToSheet(excel, sheetName, data, columns, config);
        await _applySheetStyling(excel, sheetName, config);

        totalRows += data.length;
        totalColumns += columns.length;
        sheetCount++;
      }

      // Save file
      fileName ??= 'receiptsly_export_${_getTimestamp()}.xlsx';
      final filePath = await _saveToFile(excel, fileName);

      return ExcelExportResult(
        success: true,
        filePath: filePath,
        rowCount: totalRows,
        columnCount: totalColumns,
        sheetCount: sheetCount,
        metadata: {
          'exportType': 'multi_sheet',
          'sheets': sheetsData.keys.toList(),
          'includeDashboard': includeDashboard,
        },
      );
    } catch (e) {
      debugPrint('ExcelExporterService: Multi-sheet export failed - $e');
      return ExcelExportResult(
        success: false,
        error: e.toString(),
        rowCount: 0,
        columnCount: 0,
        sheetCount: 0,
      );
    }
  }

  // Export receipts with detailed formatting
  Future<ExcelExportResult> exportReceipts({
    required List<Map<String, dynamic>> receipts,
    ExcelExportConfig? config,
    String? fileName,
  }) async {
    final exportConfig = config ?? ExcelExportConfig(
      exportType: ExcelExportType.receipts,
      sheetName: 'Receipts',
      includeSummary: true,
      selectedColumns: [
        'date',
        'vendor',
        'amount',
        'category',
        'description',
        'tax_amount',
        'payment_method',
        'status',
        'receipt_number',
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
        'receipt_number': 'Receipt #',
      },
    );

    return await exportToExcel(
      data: receipts,
      config: exportConfig,
      fileName: fileName ?? 'receipts_export_${_getTimestamp()}.xlsx',
    );
  }

  // Export invoices with client summary
  Future<ExcelExportResult> exportInvoices({
    required List<Map<String, dynamic>> invoices,
    ExcelExportConfig? config,
    String? fileName,
  }) async {
    final exportConfig = config ?? ExcelExportConfig(
      exportType: ExcelExportType.invoices,
      sheetName: 'Invoices',
      includeSummary: true,
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
        'payment_method',
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
        'payment_method': 'Payment Method',
      },
    );

    return await exportToExcel(
      data: invoices,
      config: exportConfig,
      fileName: fileName ?? 'invoices_export_${_getTimestamp()}.xlsx',
    );
  }

  // Export comprehensive financial report
  Future<ExcelExportResult> exportFinancialReport({
    required Map<String, dynamic> reportData,
    required DateTime startDate,
    required DateTime endDate,
    String? fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      // Create summary sheet
      await _createFinancialSummarySheet(excel, reportData, startDate, endDate);
      
      // Create detailed sheets
      if (reportData['receipts'] != null) {
        await _addDataToSheet(
          excel, 
          'Expenses', 
          List<Map<String, dynamic>>.from(reportData['receipts']),
          ['date', 'vendor', 'category', 'amount', 'tax_amount', 'total'],
          ExcelExportConfig(exportType: ExcelExportType.expenseReport),
        );
      }

      if (reportData['invoices'] != null) {
        await _addDataToSheet(
          excel, 
          'Income', 
          List<Map<String, dynamic>>.from(reportData['invoices']),
          ['invoice_number', 'client_name', 'issue_date', 'total', 'status'],
          ExcelExportConfig(exportType: ExcelExportType.incomeReport),
        );
      }

      // Add charts sheet
      await _createChartsSheet(excel, reportData);

      fileName ??= 'financial_report_${_formatDateForFileName(startDate)}_to_${_formatDateForFileName(endDate)}.xlsx';
      final filePath = await _saveToFile(excel, fileName);

      return ExcelExportResult(
        success: true,
        filePath: filePath,
        rowCount: _getTotalRows(reportData),
        columnCount: 10, // Estimated
        sheetCount: 4,
        metadata: {
          'reportType': 'financial',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
    } catch (e) {
      return ExcelExportResult(
        success: false,
        error: e.toString(),
        rowCount: 0,
        columnCount: 0,
        sheetCount: 0,
      );
    }
  }

  // Private helper methods

  Future<void> _addDataToSheet(
    Excel excel,
    String sheetName,
    List<Map<String, dynamic>> data,
    List<String> columns,
    ExcelExportConfig config,
  ) async {
    final sheet = excel[sheetName];
    int currentRow = 0;

    // Add headers
    if (config.includeHeaders) {
      for (int col = 0; col < columns.length; col++) {
        final columnName = columns[col];
        final headerText = config.columnMapping?[columnName] ?? _formatColumnName(columnName);
        
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
        cell.value = headerText;
        _applyCellStyle(cell, ExcelCellStyle.header);
      }
      currentRow++;

      // Freeze header row if requested
      if (config.freezeHeaders) {
        sheet.setDefaultColumnWidth(15);
      }
    }

    // Add data rows
    for (final item in data) {
      for (int col = 0; col < columns.length; col++) {
        final columnName = columns[col];
        final value = item[columnName];
        
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
        _setCellValue(cell, value, columnName);
        _applyCellStyle(cell, _getCellStyleForColumn(columnName));
      }
      currentRow++;
    }

    // Auto-fit columns if requested
    if (config.autoFitColumns) {
      for (int col = 0; col < columns.length; col++) {
        sheet.setColumnWidth(col, 20);
      }
    }

    // Add filters if requested
    if (config.addFilters && config.includeHeaders) {
      // Excel package doesn't directly support filters, but we can add a note
      debugPrint('ExcelExporterService: Filters would be applied to range A1:${_getColumnLetter(columns.length - 1)}${data.length + 1}');
    }
  }

  Future<void> _addSummarySection(
    Excel excel,
    String sheetName,
    List<Map<String, dynamic>> data,
    ExcelExportConfig config,
  ) async {
    final sheet = excel[sheetName];
    
    // Find the last used row
    int summaryStartRow = data.length + (config.includeHeaders ? 1 : 0) + 2;
    
    // Add summary title
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow));
    titleCell.value = 'SUMMARY';
    _applyCellStyle(titleCell, ExcelCellStyle.subtitle);
    summaryStartRow += 2;

    // Calculate and add summary statistics
    final summary = _calculateSummary(data, config.exportType);
    
    for (final entry in summary.entries) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow));
      final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryStartRow));
      
      labelCell.value = entry.key;
      valueCell.value = entry.value;
      
      _applyCellStyle(labelCell, ExcelCellStyle.data);
      if (entry.key.toLowerCase().contains('total') || entry.key.toLowerCase().contains('amount')) {
        _applyCellStyle(valueCell, ExcelCellStyle.currency);
      } else {
        _applyCellStyle(valueCell, ExcelCellStyle.data);
      }
      
      summaryStartRow++;
    }
  }

  Future<void> _addDashboardSheet(Excel excel, Map<String, List<Map<String, dynamic>>> sheetsData) async {
    excel['Dashboard'];
    final sheet = excel['Dashboard'];
    
    int currentRow = 0;
    
    // Title
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    titleCell.value = 'RECEIPTSLY EXPORT DASHBOARD';
    _applyCellStyle(titleCell, ExcelCellStyle.header);
    currentRow += 3;

    // Export summary
    final summaryTitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    summaryTitleCell.value = 'Export Summary';
    _applyCellStyle(summaryTitleCell, ExcelCellStyle.subtitle);
    currentRow += 2;

    // Add summary for each sheet
    for (final entry in sheetsData.entries) {
      final sheetNameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      final recordCountCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      
      sheetNameCell.value = entry.key;
      recordCountCell.value = '${entry.value.length} records';
      
      currentRow++;
    }

    currentRow += 2;

    // Export metadata
    final metadataCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    metadataCell.value = 'Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}';
    _applyCellStyle(metadataCell, ExcelCellStyle.data);
  }

  Future<void> _createFinancialSummarySheet(
    Excel excel,
    Map<String, dynamic> reportData,
    DateTime startDate,
    DateTime endDate,
  ) async {
    excel['Financial Summary'];
    final sheet = excel['Financial Summary'];
    
    int currentRow = 0;
    
    // Title
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    titleCell.value = 'FINANCIAL SUMMARY REPORT';
    _applyCellStyle(titleCell, ExcelCellStyle.header);
    currentRow += 2;

    // Period
    final periodCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    periodCell.value = 'Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}';
    currentRow += 3;

    // Summary metrics
    final metrics = [
      ['Total Income', reportData['totalIncome'] ?? 0],
      ['Total Expenses', reportData['totalExpenses'] ?? 0],
      ['Net Profit', (reportData['totalIncome'] ?? 0) - (reportData['totalExpenses'] ?? 0)],
      ['Tax Amount', reportData['totalTax'] ?? 0],
      ['Receipt Count', reportData['receiptCount'] ?? 0],
      ['Invoice Count', reportData['invoiceCount'] ?? 0],
    ];

    for (final metric in metrics) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      
      labelCell.value = metric[0];
      valueCell.value = metric[1];
      
      _applyCellStyle(labelCell, ExcelCellStyle.data);
      if (metric[0].toString().contains('Count')) {
        _applyCellStyle(valueCell, ExcelCellStyle.data);
      } else {
        _applyCellStyle(valueCell, ExcelCellStyle.currency);
      }
      
      currentRow++;
    }
  }

  Future<void> _createChartsSheet(Excel excel, Map<String, dynamic> reportData) async {
    excel['Charts'];
    final sheet = excel['Charts'];
    
    // Add placeholder for charts (Excel package has limited chart support)
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = 'CHARTS AND VISUALIZATIONS';
    _applyCellStyle(titleCell, ExcelCellStyle.header);

    final noteCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
    noteCell.value = 'Chart data has been exported to individual sheets. Use Excel\'s chart tools to create visualizations.';
    _applyCellStyle(noteCell, ExcelCellStyle.data);
  }

  Future<void> _applySheetStyling(Excel excel, String sheetName, ExcelExportConfig config) async {
    final sheet = excel[sheetName];
    
    // Apply any custom styling from config
    if (config.styling != null) {
      // Apply custom styles based on configuration
      debugPrint('ExcelExporterService: Custom styling would be applied');
    }
  }

  void _setCellValue(CellData cell, dynamic value, String columnName) {
    if (value == null) {
      cell.value = '';
    } else if (value is DateTime) {
      cell.value = value;
    } else if (value is num) {
      cell.value = value;
    } else if (value is bool) {
      cell.value = value ? 'Yes' : 'No';
    } else {
      cell.value = value.toString();
    }
  }

  void _applyCellStyle(CellData cell, ExcelCellStyle style) {
    switch (style) {
      case ExcelCellStyle.header:
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          fontColorHex: '#FFFFFF',
          backgroundColorHex: '#4472C4',
        );
        break;
      case ExcelCellStyle.subtitle:
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: '#000000',
        );
        break;
      case ExcelCellStyle.currency:
        cell.cellStyle = CellStyle(
          numberFormat: _defaultCurrencyFormat,
        );
        break;
      case ExcelCellStyle.date:
        cell.cellStyle = CellStyle(
          numberFormat: _defaultDateFormat,
        );
        break;
      case ExcelCellStyle.percentage:
        cell.cellStyle = CellStyle(
          numberFormat: '0.00%',
        );
        break;
      case ExcelCellStyle.total:
        cell.cellStyle = CellStyle(
          bold: true,
          numberFormat: _defaultCurrencyFormat,
          backgroundColorHex: '#F2F2F2',
        );
        break;
      case ExcelCellStyle.data:
      default:
        cell.cellStyle = CellStyle(
          fontSize: 10,
        );
        break;
    }
  }

  ExcelCellStyle _getCellStyleForColumn(String columnName) {
    final lowerColumn = columnName.toLowerCase();
    
    if (lowerColumn.contains('amount') || 
        lowerColumn.contains('total') || 
        lowerColumn.contains('price') ||
        lowerColumn.contains('tax')) {
      return ExcelCellStyle.currency;
    } else if (lowerColumn.contains('date')) {
      return ExcelCellStyle.date;
    } else if (lowerColumn.contains('rate') || 
               lowerColumn.contains('percent')) {
      return ExcelCellStyle.percentage;
    }
    
    return ExcelCellStyle.data;
  }

  List<String> _getColumnsToExport(List<Map<String, dynamic>> data, ExcelExportConfig config) {
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

  String _formatColumnName(String columnName) {
    return columnName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? 
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  Map<String, dynamic> _calculateSummary(List<Map<String, dynamic>> data, ExcelExportType exportType) {
    final summary = <String, dynamic>{};
    
    summary['Total Records'] = data.length;
    
    switch (exportType) {
      case ExcelExportType.receipts:
      case ExcelExportType.expenseReport:
        final totalAmount = data.fold<double>(0, (sum, item) => 
            sum + (item['amount'] as num?)?.toDouble() ?? 0);
        final totalTax = data.fold<double>(0, (sum, item) => 
            sum + (item['tax_amount'] as num?)?.toDouble() ?? 0);
        
        summary['Total Amount'] = totalAmount;
        summary['Total Tax'] = totalTax;
        summary['Grand Total'] = totalAmount + totalTax;
        break;
        
      case ExcelExportType.invoices:
      case ExcelExportType.incomeReport:
        final totalInvoiced = data.fold<double>(0, (sum, item) => 
            sum + (item['total'] as num?)?.toDouble() ?? 0);
        final paidInvoices = data.where((item) => 
            item['status']?.toString().toLowerCase() == 'paid').length;
        
        summary['Total Invoiced'] = totalInvoiced;
        summary['Paid Invoices'] = paidInvoices;
        summary['Outstanding Invoices'] = data.length - paidInvoices;
        break;
        
      default:
        // Generic summary
        break;
    }
    
    return summary;
  }

  String _getDefaultSheetName(ExcelExportType exportType) {
    switch (exportType) {
      case ExcelExportType.receipts:
        return 'Receipts';
      case ExcelExportType.invoices:
        return 'Invoices';
      case ExcelExportType.clients:
        return 'Clients';
      case ExcelExportType.expenseReport:
        return 'Expense Report';
      case ExcelExportType.incomeReport:
        return 'Income Report';
      case ExcelExportType.taxReport:
        return 'Tax Report';
      case ExcelExportType.dashboard:
        return 'Dashboard';
      case ExcelExportType.multiSheet:
        return 'Data';
    }
  }

  Future<String> _saveToFile(Excel excel, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        debugPrint('ExcelExporterService: Excel file saved to ${file.path}');
        return file.path;
      } else {
        throw ExcelExporterException('Failed to encode Excel file');
      }
    } catch (e) {
      debugPrint('ExcelExporterService: Error saving Excel file - $e');
      throw ExcelExporterException('Failed to save Excel file: $e');
    }
  }

  String _generateFileName(ExcelExportType exportType) {
    final timestamp = _getTimestamp();
    switch (exportType) {
      case ExcelExportType.receipts:
        return 'receipts_$timestamp.xlsx';
      case ExcelExportType.invoices:
        return 'invoices_$timestamp.xlsx';
      case ExcelExportType.clients:
        return 'clients_$timestamp.xlsx';
      case ExcelExportType.expenseReport:
        return 'expense_report_$timestamp.xlsx';
      case ExcelExportType.incomeReport:
        return 'income_report_$timestamp.xlsx';
      case ExcelExportType.taxReport:
        return 'tax_report_$timestamp.xlsx';
      case ExcelExportType.dashboard:
        return 'dashboard_$timestamp.xlsx';
      case ExcelExportType.multiSheet:
        return 'receiptsly_export_$timestamp.xlsx';
    }
  }

  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  String _formatDateForFileName(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }

  String _getColumnLetter(int columnIndex) {
    String columnLetter = '';
    while (columnIndex >= 0) {
      columnLetter = String.fromCharCode(65 + (columnIndex % 26)) + columnLetter;
      columnIndex = (columnIndex / 26).floor() - 1;
    }
    return columnLetter;
  }

  int _getTotalRows(Map<String, dynamic> reportData) {
    int total = 0;
    for (final value in reportData.values) {
      if (value is List) {
        total += value.length;
      }
    }
    return total;
  }

  // Validate data before export
  bool validateDataForExport(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return false;
    
    // Check data consistency
    final firstRowKeys = data.first.keys.toSet();
    for (final row in data) {
      final rowKeys = row.keys.toSet();
      if (rowKeys.difference(firstRowKeys).isNotEmpty) {
        debugPrint('ExcelExporterService: Inconsistent data structure detected');
        return false;
      }
    }
    
    return true;
  }

  // Get export template for specific type
  ExcelExportConfig getExportTemplate(ExcelExportType exportType) {
    switch (exportType) {
      case ExcelExportType.receipts:
        return ExcelExportConfig(
          exportType: exportType,
          sheetName: 'Receipts',
          includeSummary: true,
          selectedColumns: ['date', 'vendor', 'amount', 'category', 'tax_amount'],
        );
      case ExcelExportType.invoices:
        return ExcelExportConfig(
          exportType: exportType,
          sheetName: 'Invoices',
          includeSummary: true,
          selectedColumns: ['invoice_number', 'client_name', 'total', 'status', 'due_date'],
        );
      default:
        return ExcelExportConfig(exportType: exportType);
    }
  }
}

// Custom exception for Excel exporter errors
class ExcelExporterException implements Exception {
  final String message;
  
  ExcelExporterException(this.message);
  
  @override
  String toString() => 'ExcelExporterException: $message';
}Columns;