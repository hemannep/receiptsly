// lib/services/export/pdf_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

enum PDFDocumentType {
  invoice,
  receipt,
  expenseReport,
  incomeReport,
  taxReport,
  clientStatement,
  businessSummary,
}

enum PDFTemplate {
  modern,
  classic,
  minimal,
  professional,
  colorful,
  branded,
}

class PDFGeneratorConfig {
  final PDFDocumentType documentType;
  final PDFTemplate template;
  final PdfPageFormat pageFormat;
  final bool includeWatermark;
  final bool includeFooter;
  final bool includeHeader;
  final Map<String, dynamic> branding;
  final Map<String, dynamic> customStyles;
  final String? logoPath;
  final String? backgroundImagePath;

  PDFGeneratorConfig({
    required this.documentType,
    this.template = PDFTemplate.modern,
    this.pageFormat = PdfPageFormat.a4,
    this.includeWatermark = false,
    this.includeFooter = true,
    this.includeHeader = true,
    this.branding = const {},
    this.customStyles = const {},
    this.logoPath,
    this.backgroundImagePath,
  });
}

class InvoiceData {
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final Map<String, dynamic> businessInfo;
  final Map<String, dynamic> clientInfo;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String currency;
  final String? notes;
  final String? terms;
  final String? paymentInstructions;

  InvoiceData({
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.businessInfo,
    required this.clientInfo,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    this.currency = 'USD',
    this.notes,
    this.terms,
    this.paymentInstructions,
  });
}

class ReportData {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>>? charts;
  final Map<String, dynamic>? metadata;

  ReportData({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.summary,
    this.charts,
    this.metadata,
  });
}

class PDFGeneratorService {
  static const String _fontsPath = 'assets/fonts/';
  static const String _imagesPath = 'assets/images/';
  
  final Map<String, pw.Font> _fonts = {};
  final Map<String, pw.ImageProvider> _images = {};
  
  bool _isInitialized = false;

  // Initialize the PDF generator service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadFonts();
      await _loadImages();
      
      _isInitialized = true;
      debugPrint('PDFGeneratorService: Initialized successfully');
    } catch (e) {
      debugPrint('PDFGeneratorService: Initialization failed - $e');
      // Continue with default fonts if custom fonts fail
      _isInitialized = true;
    }
  }

  // Load custom fonts
  Future<void> _loadFonts() async {
    try {
      // Try to load custom fonts, fallback to default if not available
      try {
        final regularFontData = await rootBundle.load('${_fontsPath}Roboto-Regular.ttf');
        _fonts['regular'] = pw.Font.ttf(regularFontData);
      } catch (e) {
        _fonts['regular'] = pw.Font.helvetica();
      }

      try {
        final boldFontData = await rootBundle.load('${_fontsPath}Roboto-Bold.ttf');
        _fonts['bold'] = pw.Font.ttf(boldFontData);
      } catch (e) {
        _fonts['bold'] = pw.Font.helveticaBold();
      }

      try {
        final italicFontData = await rootBundle.load('${_fontsPath}Roboto-Italic.ttf');
        _fonts['italic'] = pw.Font.ttf(italicFontData);
      } catch (e) {
        _fonts['italic'] = pw.Font.helveticaOblique();
      }

      try {
        final monoFontData = await rootBundle.load('${_fontsPath}RobotoMono-Regular.ttf');
        _fonts['mono'] = pw.Font.ttf(monoFontData);
      } catch (e) {
        _fonts['mono'] = pw.Font.courier();
      }
      
      debugPrint('PDFGeneratorService: Fonts loaded');
    } catch (e) {
      debugPrint('PDFGeneratorService: Error loading fonts - $e, using defaults');
      // Set default fonts
      _fonts['regular'] = pw.Font.helvetica();
      _fonts['bold'] = pw.Font.helveticaBold();
      _fonts['italic'] = pw.Font.helveticaOblique();
      _fonts['mono'] = pw.Font.courier();
    }
  }

  // Load images and logos
  Future<void> _loadImages() async {
    try {
      try {
        final logoData = await rootBundle.load('${_imagesPath}logo.png');
        _images['logo'] = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('PDFGeneratorService: Logo not found');
      }

      try {
        final watermarkData = await rootBundle.load('${_imagesPath}watermark.png');
        _images['watermark'] = pw.MemoryImage(watermarkData.buffer.asUint8List());
      } catch (e) {
        debugPrint('PDFGeneratorService: Watermark not found');
      }
      
      debugPrint('PDFGeneratorService: Images loaded');
    } catch (e) {
      debugPrint('PDFGeneratorService: Error loading images - $e');
      // Continue without images
    }
  }

  // Generate invoice PDF
  Future<Uint8List> generateInvoice(
    InvoiceData invoiceData,
    PDFGeneratorConfig config,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final pdf = pw.Document();
      
      // Add invoice pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: config.pageFormat,
          margin: const pw.EdgeInsets.all(40),
          header: config.includeHeader 
              ? (context) => _buildInvoiceHeader(invoiceData, config)
              : null,
          footer: config.includeFooter 
              ? (context) => _buildFooter(config, context)
              : null,
          build: (context) => _buildInvoiceContent(invoiceData, config),
        ),
      );

      final bytes = await pdf.save();
      debugPrint('PDFGeneratorService: Invoice PDF generated - ${bytes.length} bytes');
      
      return bytes;
    } catch (e) {
      debugPrint('PDFGeneratorService: Error generating invoice - $e');
      throw PDFGeneratorException('Failed to generate invoice PDF: $e');
    }
  }

  // Generate expense report PDF
  Future<Uint8List> generateExpenseReport(
    ReportData reportData,
    PDFGeneratorConfig config,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: config.pageFormat,
          margin: const pw.EdgeInsets.all(40),
          header: config.includeHeader 
              ? (context) => _buildReportHeader(reportData, config)
              : null,
          footer: config.includeFooter 
              ? (context) => _buildFooter(config, context)
              : null,
          build: (context) => _buildExpenseReportContent(reportData, config),
        ),
      );

      final bytes = await pdf.save();
      debugPrint('PDFGeneratorService: Expense report PDF generated - ${bytes.length} bytes');
      
      return bytes;
    } catch (e) {
      debugPrint('PDFGeneratorService: Error generating expense report - $e');
      throw PDFGeneratorException('Failed to generate expense report PDF: $e');
    }
  }

  // Generate receipt PDF
  Future<Uint8List> generateReceipt(
    Map<String, dynamic> receiptData,
    PDFGeneratorConfig config,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5, // Smaller format for receipts
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildReceiptContent(receiptData, config),
        ),
      );

      final bytes = await pdf.save();
      debugPrint('PDFGeneratorService: Receipt PDF generated - ${bytes.length} bytes');
      
      return bytes;
    } catch (e) {
      debugPrint('PDFGeneratorService: Error generating receipt - $e');
      throw PDFGeneratorException('Failed to generate receipt PDF: $e');
    }
  }

  // Generate tax report PDF
  Future<Uint8List> generateTaxReport(
    ReportData reportData,
    PDFGeneratorConfig config,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final pdf = pw.Document();
      
      // Add cover page
      pdf.addPage(_buildTaxReportCoverPage(reportData, config));
      
      // Add summary page
      pdf.addPage(_buildTaxReportSummaryPage(reportData, config));
      
      // Add detailed pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: config.pageFormat,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildReportHeader(reportData, config),
          footer: (context) => _buildFooter(config, context),
          build: (context) => _buildTaxReportContent(reportData, config),
        ),
      );

      final bytes = await pdf.save();
      debugPrint('PDFGeneratorService: Tax report PDF generated - ${bytes.length} bytes');
      
      return bytes;
    } catch (e) {
      debugPrint('PDFGeneratorService: Error generating tax report - $e');
      throw PDFGeneratorException('Failed to generate tax report PDF: $e');
    }
  }

  // Build invoice header
  pw.Widget _buildInvoiceHeader(InvoiceData invoiceData, PDFGeneratorConfig config) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Logo and business info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (_images['logo'] != null)
                pw.Image(_images['logo']!, width: 120, height: 60),
              pw.SizedBox(height: 10),
              pw.Text(
                invoiceData.businessInfo['name']?.toString() ?? 'Business Name',
                style: pw.TextStyle(
                  font: _fonts['bold'],
                  fontSize: 16,
                  color: _getThemeColor(config.template),
                ),
              ),
              pw.Text(
                invoiceData.businessInfo['address']?.toString() ?? '',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
              ),
              pw.Text(
                '${invoiceData.businessInfo['email']?.toString() ?? ''} | ${invoiceData.businessInfo['phone']?.toString() ?? ''}',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
              ),
            ],
          ),
          // Invoice details
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  font: _fonts['bold'],
                  fontSize: 28,
                  color: _getThemeColor(config.template),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Invoice #: ${invoiceData.invoiceNumber}',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 12),
              ),
              pw.Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(invoiceData.issueDate)}',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 12),
              ),
              pw.Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(invoiceData.dueDate)}',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build invoice content
  List<pw.Widget> _buildInvoiceContent(InvoiceData invoiceData, PDFGeneratorConfig config) {
    return [
      // Client information
      pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 20),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      font: _fonts['bold'],
                      fontSize: 14,
                      color: _getThemeColor(config.template),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    invoiceData.clientInfo['name']?.toString() ?? 'Client Name',
                    style: pw.TextStyle(font: _fonts['bold'], fontSize: 12),
                  ),
                  pw.Text(
                    invoiceData.clientInfo['address']?.toString() ?? '',
                    style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
                  ),
                  pw.Text(
                    invoiceData.clientInfo['email']?.toString() ?? '',
                    style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Payment Details:',
                    style: pw.TextStyle(
                      font: _fonts['bold'],
                      fontSize: 14,
                      color: _getThemeColor(config.template),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  if (invoiceData.paymentInstructions != null)
                    pw.Text(
                      invoiceData.paymentInstructions!,
                      style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Items table
      _buildInvoiceItemsTable(invoiceData, config),

      // Totals section
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Container()),
            pw.Expanded(
              flex: 2,
              child: _buildTotalsSection(invoiceData, config),
            ),
          ],
        ),
      ),

      // Notes and terms
      if (invoiceData.notes != null || invoiceData.terms != null)
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (invoiceData.notes != null) ...[
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    font: _fonts['bold'],
                    fontSize: 12,
                    color: _getThemeColor(config.template),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  invoiceData.notes!,
                  style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
                ),
                pw.SizedBox(height: 15),
              ],
              if (invoiceData.terms != null) ...[
                pw.Text(
                  'Terms & Conditions:',
                  style: pw.TextStyle(
                    font: _fonts['bold'],
                    fontSize: 12,
                    color: _getThemeColor(config.template),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  invoiceData.terms!,
                  style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  // Build invoice items table
  pw.Widget _buildInvoiceItemsTable(InvoiceData invoiceData, PDFGeneratorConfig config) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _getThemeColor(config.template).shade(0.1),
          ),
          children: [
            _buildTableCell('Description', isHeader: true, config: config),
            _buildTableCell('Qty', isHeader: true, config: config),
            _buildTableCell('Rate', isHeader: true, config: config),
            _buildTableCell('Amount', isHeader: true, config: config),
          ],
        ),
        // Data rows
        ...invoiceData.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item['description']?.toString() ?? '', config: config),
            _buildTableCell((item['quantity'] ?? 0).toString(), config: config),
            _buildTableCell(_formatCurrency(_safeDouble(item['rate']), invoiceData.currency), config: config),
            _buildTableCell(_formatCurrency(_safeDouble(item['amount']), invoiceData.currency), config: config),
          ],
        )).toList(),
      ],
    );
  }

  // Build table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false, required PDFGeneratorConfig config}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isHeader ? _fonts['bold'] : _fonts['regular'],
          fontSize: isHeader ? 11 : 10,
          color: isHeader ? _getThemeColor(config.template) : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  // Build totals section
  pw.Widget _buildTotalsSection(InvoiceData invoiceData, PDFGeneratorConfig config) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal', invoiceData.subtotal, invoiceData.currency, config),
          if (invoiceData.discountAmount > 0)
            _buildTotalRow('Discount', -invoiceData.discountAmount, invoiceData.currency, config),
          if (invoiceData.taxAmount > 0)
            _buildTotalRow('Tax', invoiceData.taxAmount, invoiceData.currency, config),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _getThemeColor(config.template).shade(0.1),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(5),
                bottomRight: pw.Radius.circular(5),
              ),
            ),
            child: _buildTotalRow(
              'Total',
              invoiceData.total,
              invoiceData.currency,
              config,
              isTotal: true,
            ),
          ),
        ],
      ),
    );
  }

  // Build total row
  pw.Widget _buildTotalRow(
    String label,
    double amount,
    String currency,
    PDFGeneratorConfig config, {
    bool isTotal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isTotal ? _fonts['bold'] : _fonts['regular'],
              fontSize: isTotal ? 12 : 10,
              color: isTotal ? _getThemeColor(config.template) : PdfColors.black,
            ),
          ),
          pw.Text(
            _formatCurrency(amount, currency),
            style: pw.TextStyle(
              font: isTotal ? _fonts['bold'] : _fonts['regular'],
              fontSize: isTotal ? 12 : 10,
              color: isTotal ? _getThemeColor(config.template) : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Build expense report content
  List<pw.Widget> _buildExpenseReportContent(ReportData reportData, PDFGeneratorConfig config) {
    return [
      // Summary section
      _buildReportSummary(reportData, config),
      
      pw.SizedBox(height: 20),
      
      // Expenses table
      _buildExpenseTable(reportData, config),
      
      pw.SizedBox(height: 20),
      
      // Charts (if available)
      if (reportData.charts != null && reportData.charts!.isNotEmpty)
        _buildChartsSection(reportData.charts!, config),
    ];
  }

  // Build report summary
  pw.Widget _buildReportSummary(ReportData reportData, PDFGeneratorConfig config) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _getThemeColor(config.template).shade(0.05),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _getThemeColor(config.template)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              font: _fonts['bold'],
              fontSize: 16,
              color: _getThemeColor(config.template),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            children: reportData.summary.entries.map((entry) => 
              pw.Container(
                width: 150,
                margin: const pw.EdgeInsets.only(right: 20, bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry.key.toString().replaceAll('_', ' ').toUpperCase(),
                      style: pw.TextStyle(
                        font: _fonts['regular'],
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _formatValue(entry.value),
                      style: pw.TextStyle(
                        font: _fonts['bold'],
                        fontSize: 14,
                        color: _getThemeColor(config.template),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  // Build expense table
  pw.Widget _buildExpenseTable(ReportData reportData, PDFGeneratorConfig config) {
    if (reportData.data.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.Text(
            'No expenses found for the selected period',
            style: pw.TextStyle(font: _fonts['italic'], fontSize: 12),
          ),
        ),
      );
    }

    // Get column headers from first data item
    final headers = reportData.data.first.keys.toList();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: Map.fromIterable(
        List.generate(headers.length, (index) => index),
        value: (_) => const pw.FlexColumnWidth(1),
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _getThemeColor(config.template).shade(0.1),
          ),
          children: headers.map((header) => 
            _buildTableCell(
              header.toString().replaceAll('_', ' ').toUpperCase(),
              isHeader: true,
              config: config,
            ),
          ).toList(),
        ),
        // Data rows (limit to prevent overflow)
        ...reportData.data.take(50).map((item) => pw.TableRow(
          children: headers.map((header) => 
            _buildTableCell(_formatValue(item[header]), config: config),
          ).toList(),
        )).toList(),
      ],
    );
  }

  // Build charts section (simplified representation)
  pw.Widget _buildChartsSection(List<Map<String, dynamic>> charts, PDFGeneratorConfig config) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Charts & Visualizations',
          style: pw.TextStyle(
            font: _fonts['bold'],
            fontSize: 16,
            color: _getThemeColor(config.template),
          ),
        ),
        pw.SizedBox(height: 10),
        ...charts.take(3).map((chart) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                chart['title']?.toString() ?? 'Chart',
                style: pw.TextStyle(font: _fonts['bold'], fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              // Placeholder for chart
              pw.Container(
                height: 150,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Chart: ${chart['type']?.toString() ?? 'Unknown'}',
                    style: pw.TextStyle(font: _fonts['italic'], fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  // Build receipt content
  pw.Widget _buildReceiptContent(Map<String, dynamic> receiptData, PDFGeneratorConfig config) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Column(
            children: [
              if (_images['logo'] != null)
                pw.Image(_images['logo']!, width: 60, height: 30),
              pw.SizedBox(height: 5),
              pw.Text(
                'RECEIPT',
                style: pw.TextStyle(
                  font: _fonts['bold'],
                  fontSize: 18,
                  color: _getThemeColor(config.template),
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 15),
        
        // Receipt details
        _buildReceiptDetails(receiptData, config),
        
        pw.SizedBox(height: 15),
        
        // Thank you message
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              font: _fonts['italic'],
              fontSize: 12,
              color: _getThemeColor(config.template),
            ),
          ),
        ),
      ],
    );
  }

  // Build receipt details
  pw.Widget _buildReceiptDetails(Map<String, dynamic> receiptData, PDFGeneratorConfig config) {
    return pw.Column(
      children: [
        _buildReceiptRow('Date:', _formatDate(receiptData['date']), config),
        _buildReceiptRow('Vendor:', receiptData['vendor']?.toString() ?? 'Unknown', config),
        _buildReceiptRow('Category:', receiptData['category']?.toString() ?? 'General', config),
        _buildReceiptRow('Amount:', _formatCurrency(_safeDouble(receiptData['amount']), receiptData['currency']?.toString() ?? 'USD'), config),
        if (receiptData['tax'] != null)
          _buildReceiptRow('Tax:', _formatCurrency(_safeDouble(receiptData['tax']), receiptData['currency']?.toString() ?? 'USD'), config),
        if (receiptData['notes'] != null) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            'Notes: ${receiptData['notes']}',
            style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
          ),
        ],
      ],
    );
  }

  // Build receipt row
  pw.Widget _buildReceiptRow(String label, String value, PDFGeneratorConfig config) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: _fonts['regular'], fontSize: 11),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: _fonts['bold'], fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Build tax report pages
  pw.Page _buildTaxReportCoverPage(ReportData reportData, PDFGeneratorConfig config) {
    return pw.Page(
      pageFormat: config.pageFormat,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (_images['logo'] != null)
              pw.Image(_images['logo']!, width: 150, height: 75),
            pw.SizedBox(height: 30),
            pw.Text(
              'TAX REPORT',
              style: pw.TextStyle(
                font: _fonts['bold'],
                fontSize: 32,
                color: _getThemeColor(config.template),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              reportData.title,
              style: pw.TextStyle(font: _fonts['regular'], fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${DateFormat('MMMM dd, yyyy').format(reportData.startDate)} - ${DateFormat('MMMM dd, yyyy').format(reportData.endDate)}',
              style: pw.TextStyle(font: _fonts['regular'], fontSize: 14),
            ),
            pw.SizedBox(height: 50),
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
              style: pw.TextStyle(font: _fonts['italic'], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  pw.Page _buildTaxReportSummaryPage(ReportData reportData, PDFGeneratorConfig config) {
    return pw.Page(
      pageFormat: config.pageFormat,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Executive Summary',
            style: pw.TextStyle(
              font: _fonts['bold'],
              fontSize: 24,
              color: _getThemeColor(config.template),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportSummary(reportData, config),
          pw.SizedBox(height: 30),
          // Add more summary sections as needed
          pw.Text(
            'Report Period',
            style: pw.TextStyle(
              font: _fonts['bold'],
              fontSize: 16,
              color: _getThemeColor(config.template),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'From: ${DateFormat('MMMM dd, yyyy').format(reportData.startDate)}',
            style: pw.TextStyle(font: _fonts['regular'], fontSize: 12),
          ),
          pw.Text(
            'To: ${DateFormat('MMMM dd, yyyy').format(reportData.endDate)}',
            style: pw.TextStyle(font: _fonts['regular'], fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildTaxReportContent(ReportData reportData, PDFGeneratorConfig config) {
    return [
      pw.Text(
        'Detailed Tax Information',
        style: pw.TextStyle(
          font: _fonts['bold'],
          fontSize: 18,
          color: _getThemeColor(config.template),
        ),
      ),
      pw.SizedBox(height: 15),
      _buildExpenseTable(reportData, config),
    ];
  }

  // Build report header
  pw.Widget _buildReportHeader(ReportData reportData, PDFGeneratorConfig config) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                reportData.title,
                style: pw.TextStyle(
                  font: _fonts['bold'],
                  fontSize: 16,
                  color: _getThemeColor(config.template),
                ),
              ),
              pw.Text(
                '${DateFormat('MMM dd, yyyy').format(reportData.startDate)} - ${DateFormat('MMM dd, yyyy').format(reportData.endDate)}',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
              ),
            ],
          ),
          if (_images['logo'] != null)
            pw.Image(_images['logo']!, width: 80, height: 40),
        ],
      ),
    );
  }

  // Build footer
  pw.Widget _buildFooter(PDFGeneratorConfig config, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Receiptsly',
            style: pw.TextStyle(font: _fonts['italic'], fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(font: _fonts['regular'], fontSize: 8),
          ),
        ],
      ),
    );
  }

  // Save PDF to file
  Future<File> savePDFToFile(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      debugPrint('PDFGeneratorService: PDF saved to ${file.path}');
      return file;
    } catch (e) {
      debugPrint('PDFGeneratorService: Error saving PDF - $e');
      throw PDFGeneratorException('Failed to save PDF: $e');
    }
  }

  // Generate custom report with flexible data
  Future<Uint8List> generateCustomReport({
    required String title,
    required List<Map<String, dynamic>> data,
    required Map<String, dynamic> summary,
    PDFGeneratorConfig? config,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final reportData = ReportData(
      title: title,
      startDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      endDate: endDate ?? DateTime.now(),
      data: data,
      summary: summary,
    );

    final pdfConfig = config ?? PDFGeneratorConfig(
      documentType: PDFDocumentType.businessSummary,
      template: PDFTemplate.professional,
    );

    return await generateExpenseReport(reportData, pdfConfig);
  }

  // Generate client statement
  Future<Uint8List> generateClientStatement({
    required Map<String, dynamic> clientInfo,
    required List<Map<String, dynamic>> invoices,
    required Map<String, dynamic> summary,
    PDFGeneratorConfig? config,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final pdf = pw.Document();
      final pdfConfig = config ?? PDFGeneratorConfig(
        documentType: PDFDocumentType.clientStatement,
        template: PDFTemplate.professional,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pdfConfig.pageFormat,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildClientStatementHeader(clientInfo, pdfConfig),
          footer: (context) => _buildFooter(pdfConfig, context),
          build: (context) => _buildClientStatementContent(clientInfo, invoices, summary, pdfConfig),
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw PDFGeneratorException('Failed to generate client statement: $e');
    }
  }

  // Build client statement header
  pw.Widget _buildClientStatementHeader(Map<String, dynamic> clientInfo, PDFGeneratorConfig config) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (_images['logo'] != null)
                pw.Image(_images['logo']!, width: 120, height: 60),
              pw.SizedBox(height: 10),
              pw.Text(
                'CLIENT STATEMENT',
                style: pw.TextStyle(
                  font: _fonts['bold'],
                  fontSize: 24,
                  color: _getThemeColor(config.template),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                clientInfo['name']?.toString() ?? 'Client Name',
                style: pw.TextStyle(font: _fonts['bold'], fontSize: 16),
              ),
              pw.Text(
                clientInfo['email']?.toString() ?? '',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 12),
              ),
              pw.Text(
                'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                style: pw.TextStyle(font: _fonts['regular'], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build client statement content
  List<pw.Widget> _buildClientStatementContent(
    Map<String, dynamic> clientInfo,
    List<Map<String, dynamic>> invoices,
    Map<String, dynamic> summary,
    PDFGeneratorConfig config,
  ) {
    return [
      // Client summary
      _buildClientSummary(summary, config),
      pw.SizedBox(height: 20),
      
      // Invoices table
      if (invoices.isNotEmpty) ...[
        pw.Text(
          'Invoice History',
          style: pw.TextStyle(
            font: _fonts['bold'],
            fontSize: 16,
            color: _getThemeColor(config.template),
          ),
        ),
        pw.SizedBox(height: 10),
        _buildInvoicesTable(invoices, config),
      ] else
        pw.Text(
          'No invoices found for this client.',
          style: pw.TextStyle(font: _fonts['italic'], fontSize: 12),
        ),
    ];
  }

  // Build client summary
  pw.Widget _buildClientSummary(Map<String, dynamic> summary, PDFGeneratorConfig config) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _getThemeColor(config.template).shade(0.05),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _getThemeColor(config.template)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Account Summary',
            style: pw.TextStyle(
              font: _fonts['bold'],
              fontSize: 16,
              color: _getThemeColor(config.template),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Invoiced:', style: pw.TextStyle(font: _fonts['regular'], fontSize: 12)),
                  pw.Text('Total Paid:', style: pw.TextStyle(font: _fonts['regular'], fontSize: 12)),
                  pw.Text('Outstanding Balance:', style: pw.TextStyle(font: _fonts['bold'], fontSize: 12)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(_formatCurrency(_safeDouble(summary['total_invoiced']), 'USD'), 
                    style: pw.TextStyle(font: _fonts['regular'], fontSize: 12)),
                  pw.Text(_formatCurrency(_safeDouble(summary['total_paid']), 'USD'), 
                    style: pw.TextStyle(font: _fonts['regular'], fontSize: 12)),
                  pw.Text(_formatCurrency(_safeDouble(summary['outstanding_balance']), 'USD'), 
                    style: pw.TextStyle(font: _fonts['bold'], fontSize: 12, color: _getThemeColor(config.template))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build invoices table
  pw.Widget _buildInvoicesTable(List<Map<String, dynamic>> invoices, PDFGeneratorConfig config) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _getThemeColor(config.template).shade(0.1),
          ),
          children: [
            _buildTableCell('Invoice #', isHeader: true, config: config),
            _buildTableCell('Date', isHeader: true, config: config),
            _buildTableCell('Amount', isHeader: true, config: config),
            _buildTableCell('Due Date', isHeader: true, config: config),
            _buildTableCell('Status', isHeader: true, config: config),
          ],
        ),
        // Data rows
        ...invoices.take(20).map((invoice) => pw.TableRow(
          children: [
            _buildTableCell(invoice['invoice_number']?.toString() ?? '', config: config),
            _buildTableCell(_formatDate(invoice['issue_date']), config: config),
            _buildTableCell(_formatCurrency(_safeDouble(invoice['total']), 'USD'), config: config),
            _buildTableCell(_formatDate(invoice['due_date']), config: config),
            _buildTableCell(invoice['status']?.toString() ?? '', config: config),
          ],
        )).toList(),
      ],
    );
  }

  // Helper methods
  PdfColor _getThemeColor(PDFTemplate template) {
    switch (template) {
      case PDFTemplate.modern:
        return PdfColors.blue;
      case PDFTemplate.classic:
        return PdfColors.black;
      case PDFTemplate.minimal:
        return PdfColors.grey800;
      case PDFTemplate.professional:
        return PdfColors.indigo;
      case PDFTemplate.colorful:
        return PdfColors.teal;
      case PDFTemplate.branded:
        return PdfColors.deepOrange;
    }
  }

  String _formatCurrency(double amount, String currency) {
    try {
      final formatter = NumberFormat.currency(symbol: _getCurrencySymbol(currency));
      return formatter.format(amount);
    } catch (e) {
      return '${_getCurrencySymbol(currency)}${amount.toStringAsFixed(2)}';
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\;
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'CAD':
        return 'C\;
      case 'AUD':
        return 'A\;
      default:
        return currency;
    }
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (date is String) {
      try {
        final parsed = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy').format(parsed);
      } catch (e) {
        return date;
      }
    }
    return date?.toString() ?? '';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    } else if (value is DateTime) {
      return DateFormat('MMM dd, yyyy').format(value);
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Get available templates
  List<PDFTemplate> getAvailableTemplates() {
    return PDFTemplate.values;
  }

  // Get template preview info
  Map<String, dynamic> getTemplateInfo(PDFTemplate template) {
    switch (template) {
      case PDFTemplate.modern:
        return {
          'name': 'Modern',
          'description': 'Clean and contemporary design with blue accents',
          'color': PdfColors.blue,
          'features': ['Professional layout', 'Modern typography', 'Clean lines'],
        };
      case PDFTemplate.classic:
        return {
          'name': 'Classic',
          'description': 'Traditional business document style',
          'color': PdfColors.black,
          'features': ['Traditional layout', 'Conservative styling', 'Professional appearance'],
        };
      case PDFTemplate.minimal:
        return {
          'name': 'Minimal',
          'description': 'Simple and clean with minimal styling',
          'color': PdfColors.grey800,
          'features': ['Minimalist design', 'Focus on content', 'Clean typography'],
        };
      case PDFTemplate.professional:
        return {
          'name': 'Professional',
          'description': 'Corporate-style with professional appearance',
          'color': PdfColors.indigo,
          'features': ['Corporate styling', 'Professional colors', 'Business-focused'],
        };
      case PDFTemplate.colorful:
        return {
          'name': 'Colorful',
          'description': 'Vibrant design with colorful accents',
          'color': PdfColors.teal,
          'features': ['Vibrant colors', 'Eye-catching design', 'Modern styling'],
        };
      case PDFTemplate.branded:
        return {
          'name': 'Branded',
          'description': 'Customizable template for brand consistency',
          'color': PdfColors.deepOrange,
          'features': ['Brand customization', 'Logo integration', 'Custom colors'],
        };
    }
  }

  // Validate data before PDF generation
  bool validateInvoiceData(InvoiceData data) {
    if (data.invoiceNumber.isEmpty) return false;
    if (data.items.isEmpty) return false;
    if (data.total < 0) return false;
    if (data.businessInfo['name'] == null || data.businessInfo['name'].toString().isEmpty) return false;
    if (data.clientInfo['name'] == null || data.clientInfo['name'].toString().isEmpty) return false;
    return true;
  }

  bool validateReportData(ReportData data) {
    if (data.title.isEmpty) return false;
    if (data.startDate.isAfter(data.endDate)) return false;
    return true;
  }

  // Get PDF generation statistics
  Map<String, dynamic> getGenerationStats() {
    return {
      'isInitialized': _isInitialized,
      'fontsLoaded': _fonts.length,
      'imagesLoaded': _images.length,
      'availableTemplates': PDFTemplate.values.length,
      'supportedFormats': ['A4', 'A5', 'Letter', 'Legal'],
    };
  }

  // Dispose resources
  void dispose() {
    _fonts.clear();
    _images.clear();
    _isInitialized = false;
    debugPrint('PDFGeneratorService: Disposed');
  }
}

// Custom exception for PDF generator errors
class PDFGeneratorException implements Exception {
  final String message;
  
  PDFGeneratorException(this.message);
  
  @override
  String toString() => 'PDFGeneratorException: $message';
}