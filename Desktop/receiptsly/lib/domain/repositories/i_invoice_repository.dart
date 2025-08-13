// lib/domain/repositories/i_invoice_repository.dart
import 'dart:async';
import '../entities/invoice_entity.dart';
import '../entities/client_entity.dart';

/// Invoice repository interface defining all invoice-related operations
/// This interface is implemented by the data layer and used by use cases
abstract class IInvoiceRepository {
  /// Stream of invoices for a specific user
  /// Returns real-time updates when invoices are added, updated, or deleted
  /// [userId] - User ID to filter invoices
  /// [filters] - Optional filters to apply
  Stream<List<InvoiceEntity>> watchUserInvoices({
    required String userId,
    InvoiceFilters? filters,
  });

  /// Get invoices for a user with pagination
  /// [userId] - User ID to filter invoices
  /// [filters] - Optional filters to apply
  /// [pagination] - Pagination parameters
  /// Returns paginated list of invoices
  Future<PaginatedResult<InvoiceEntity>> getUserInvoices({
    required String userId,
    InvoiceFilters? filters,
    PaginationParams? pagination,
  });

  /// Get a specific invoice by ID
  /// [invoiceId] - Invoice ID to fetch
  /// Returns invoice entity or null if not found
  Future<InvoiceEntity?> getInvoiceById(String invoiceId);

  /// Get invoice by invoice number
  /// [userId] - User ID to filter by
  /// [invoiceNumber] - Invoice number to search for
  /// Returns invoice entity or null if not found
  Future<InvoiceEntity?> getInvoiceByNumber({
    required String userId,
    required String invoiceNumber,
  });

  /// Create a new invoice
  /// [invoice] - Invoice entity to create
  /// Returns created invoice with generated ID and invoice number
  Future<InvoiceEntity> createInvoice(InvoiceEntity invoice);

  /// Create invoice from template
  /// [templateId] - Template ID to use
  /// [clientId] - Client ID for the invoice
  /// [customData] - Optional custom data to override template
  /// Returns created invoice
  Future<InvoiceEntity> createInvoiceFromTemplate({
    required String templateId,
    required String clientId,
    Map<String, dynamic>? customData,
  });

  /// Update an existing invoice
  /// [invoice] - Updated invoice entity
  /// Returns updated invoice entity
  Future<InvoiceEntity> updateInvoice(InvoiceEntity invoice);

  /// Delete an invoice
  /// [invoiceId] - ID of invoice to delete
  /// [reason] - Optional reason for deletion
  Future<void> deleteInvoice(String invoiceId, {String? reason});

  /// Send invoice to client
  /// [invoiceId] - Invoice ID to send
  /// [emailOptions] - Email sending options
  /// Returns sending result
  Future<InvoiceSendResult> sendInvoice({
    required String invoiceId,
    required InvoiceEmailOptions emailOptions,
  });

  /// Generate PDF for invoice
  /// [invoiceId] - Invoice ID to generate PDF for
  /// [template] - Optional template to use
  /// Returns PDF generation result
  Future<InvoicePDFResult> generateInvoicePDF({
    required String invoiceId,
    InvoiceTemplate? template,
  });

  /// Mark invoice as sent
  /// [invoiceId] - Invoice ID to mark as sent
  /// [sentAt] - Optional timestamp when sent
  /// Returns updated invoice
  Future<InvoiceEntity> markInvoiceAsSent({
    required String invoiceId,
    DateTime? sentAt,
  });

  /// Record payment for invoice
  /// [invoiceId] - Invoice ID to record payment for
  /// [payment] - Payment record details
  /// Returns updated invoice with payment recorded
  Future<InvoiceEntity> recordPayment({
    required String invoiceId,
    required PaymentRecord payment,
  });

  /// Mark invoice as paid
  /// [invoiceId] - Invoice ID to mark as paid
  /// [payment] - Payment record details
  /// Returns updated invoice
  Future<InvoiceEntity> markInvoiceAsPaid({
    required String invoiceId,
    required PaymentRecord payment,
  });

  /// Cancel invoice
  /// [invoiceId] - Invoice ID to cancel
  /// [reason] - Reason for cancellation
  /// Returns updated invoice
  Future<InvoiceEntity> cancelInvoice({
    required String invoiceId,
    required String reason,
  });

  /// Duplicate invoice
  /// [invoiceId] - Invoice ID to duplicate
  /// [newInvoiceNumber] - Optional new invoice number
  /// [newIssueDate] - Optional new issue date
  /// Returns duplicated invoice
  Future<InvoiceEntity> duplicateInvoice({
    required String invoiceId,
    String? newInvoiceNumber,
    DateTime? newIssueDate,
  });

  /// Get overdue invoices
  /// [userId] - User ID to filter invoices
  /// [pagination] - Pagination parameters
  /// Returns overdue invoices
  Future<PaginatedResult<InvoiceEntity>> getOverdueInvoices({
    required String userId,
    PaginationParams? pagination,
  });

  /// Get invoices due soon
  /// [userId] - User ID to filter invoices
  /// [daysAhead] - Number of days ahead to check
  /// [pagination] - Pagination parameters
  /// Returns invoices due within specified days
  Future<PaginatedResult<InvoiceEntity>> getInvoicesDueSoon({
    required String userId,
    int daysAhead = 7,
    PaginationParams? pagination,
  });

  /// Get unpaid invoices
  /// [userId] - User ID to filter invoices
  /// [pagination] - Pagination parameters
  /// Returns unpaid invoices
  Future<PaginatedResult<InvoiceEntity>> getUnpaidInvoices({
    required String userId,
    PaginationParams? pagination,
  });

  /// Get paid invoices
  /// [userId] - User ID to filter invoices
  /// [dateRange] - Optional date range filter
  /// [pagination] - Pagination parameters
  /// Returns paid invoices
  Future<PaginatedResult<InvoiceEntity>> getPaidInvoices({
    required String userId,
    DateRange? dateRange,
    PaginationParams? pagination,
  });

  /// Get invoices by client
  /// [userId] - User ID to filter invoices
  /// [clientId] - Client ID to filter by
  /// [pagination] - Pagination parameters
  /// Returns invoices for specified client
  Future<PaginatedResult<InvoiceEntity>> getInvoicesByClient({
    required String userId,
    required String clientId,
    PaginationParams? pagination,
  });

  /// Get invoices by project
  /// [userId] - User ID to filter invoices
  /// [projectId] - Project ID to filter by
  /// [pagination] - Pagination parameters
  /// Returns invoices for specified project
  Future<PaginatedResult<InvoiceEntity>> getInvoicesByProject({
    required String userId,
    required String projectId,
    PaginationParams? pagination,
  });

  /// Get invoices by date range
  /// [userId] - User ID to filter invoices
  /// [startDate] - Start date (inclusive)
  /// [endDate] - End date (inclusive)
  /// [pagination] - Pagination parameters
  /// Returns invoices in date range
  Future<PaginatedResult<InvoiceEntity>> getInvoicesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    PaginationParams? pagination,
  });

  /// Search invoices by text
  /// [userId] - User ID to filter invoices
  /// [query] - Search query
  /// [filters] - Optional additional filters
  /// [pagination] - Pagination parameters
  /// Returns search results
  Future<PaginatedResult<InvoiceEntity>> searchInvoices({
    required String userId,
    required String query,
    InvoiceFilters? filters,
    PaginationParams? pagination,
  });

  /// Send invoice reminder
  /// [invoiceId] - Invoice ID to send reminder for
  /// [reminderType] - Type of reminder to send
  /// [customMessage] - Optional custom message
  /// Returns reminder sending result
  Future<InvoiceReminderResult> sendInvoiceReminder({
    required String invoiceId,
    required InvoiceReminderType reminderType,
    String? customMessage,
  });

  /// Get invoice reminders that need to be sent
  /// [userId] - User ID to check reminders for
  /// Returns list of invoices needing reminders
  Future<List<InvoiceEntity>> getInvoicesNeedingReminders(String userId);

  /// Bulk send reminders
  /// [invoiceIds] - List of invoice IDs to send reminders for
  /// [reminderType] - Type of reminder to send
  /// Returns bulk reminder result
  Future<BulkReminderResult> bulkSendReminders({
    required List<String> invoiceIds,
    required InvoiceReminderType reminderType,
  });

  /// Get next invoice number
  /// [userId] - User ID to get next number for
  /// [prefix] - Optional prefix for invoice number
  /// Returns next available invoice number
  Future<String> getNextInvoiceNumber({required String userId, String? prefix});

  /// Check if invoice number exists
  /// [userId] - User ID to check within
  /// [invoiceNumber] - Invoice number to check
  /// Returns true if number already exists
  Future<bool> invoiceNumberExists({
    required String userId,
    required String invoiceNumber,
  });

  /// Get invoice statistics
  /// [userId] - User ID to get statistics for
  /// [dateRange] - Optional date range to filter
  /// Returns comprehensive invoice statistics
  Future<InvoiceStatistics> getInvoiceStatistics({
    required String userId,
    DateRange? dateRange,
  });

  /// Get revenue by month
  /// [userId] - User ID to get revenue for
  /// [months] - Number of months to include
  /// Returns monthly revenue data
  Future<List<MonthlyRevenue>> getMonthlyRevenue({
    required String userId,
    int months = 12,
  });

  /// Get revenue by client
  /// [userId] - User ID to get revenue for
  /// [dateRange] - Optional date range to filter
  /// [limit] - Maximum number of clients to return
  /// Returns top clients by revenue
  Future<Map<String, double>> getRevenueByClient({
    required String userId,
    DateRange? dateRange,
    int limit = 10,
  });

  /// Get payment collection metrics
  /// [userId] - User ID to get metrics for
  /// [dateRange] - Optional date range to filter
  /// Returns payment collection analytics
  Future<PaymentCollectionMetrics> getPaymentCollectionMetrics({
    required String userId,
    DateRange? dateRange,
  });

  /// Export invoices to various formats
  /// [userId] - User ID to filter invoices
  /// [format] - Export format (PDF, CSV, Excel)
  /// [filters] - Optional filters to apply
  /// [dateRange] - Optional date range
  /// Returns export result with file path or URL
  Future<ExportResult> exportInvoices({
    required String userId,
    required ExportFormat format,
    InvoiceFilters? filters,
    DateRange? dateRange,
  });

  /// Import invoices from file
  /// [userId] - User ID to import for
  /// [filePath] - Path to import file
  /// [format] - Import file format
  /// [options] - Import options
  /// Returns import result
  Future<ImportResult> importInvoices({
    required String userId,
    required String filePath,
    required ImportFormat format,
    ImportOptions? options,
  });

  /// Get invoice templates
  /// [userId] - User ID to get templates for
  /// Returns list of available templates
  Future<List<InvoiceTemplateEntity>> getInvoiceTemplates(String userId);

  /// Create invoice template
  /// [template] - Template to create
  /// Returns created template
  Future<InvoiceTemplateEntity> createInvoiceTemplate(
    InvoiceTemplateEntity template,
  );

  /// Update invoice template
  /// [template] - Updated template
  /// Returns updated template
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(
    InvoiceTemplateEntity template,
  );

  /// Delete invoice template
  /// [templateId] - Template ID to delete
  Future<void> deleteInvoiceTemplate(String templateId);

  /// Get recurring invoice schedules
  /// [userId] - User ID to get schedules for
  /// Returns list of recurring schedules
  Future<List<RecurringInvoiceSchedule>> getRecurringSchedules(String userId);

  /// Create recurring invoice schedule
  /// [schedule] - Schedule to create
  /// Returns created schedule
  Future<RecurringInvoiceSchedule> createRecurringSchedule(
    RecurringInvoiceSchedule schedule,
  );

  /// Update recurring invoice schedule
  /// [schedule] - Updated schedule
  /// Returns updated schedule
  Future<RecurringInvoiceSchedule> updateRecurringSchedule(
    RecurringInvoiceSchedule schedule,
  );

  /// Delete recurring invoice schedule
  /// [scheduleId] - Schedule ID to delete
  Future<void> deleteRecurringSchedule(String scheduleId);

  /// Process recurring invoices
  /// [userId] - User ID to process for
  /// [date] - Date to process for (default: today)
  /// Returns list of created recurring invoices
  Future<List<InvoiceEntity>> processRecurringInvoices({
    required String userId,
    DateTime? date,
  });

  /// Archive old invoices
  /// [userId] - User ID to archive for
  /// [olderThan] - Archive invoices older than this date
  /// Returns number of archived invoices
  Future<int> archiveOldInvoices({
    required String userId,
    required DateTime olderThan,
  });

  /// Sync invoices with external systems
  /// [userId] - User ID to sync for
  /// [systems] - List of systems to sync with
  /// Returns sync result
  Future<SyncResult> syncInvoices({
    required String userId,
    required List<String> systems,
  });

  /// Validate invoice data
  /// [invoice] - Invoice to validate
  /// Returns list of validation errors
  Future<List<ValidationError>> validateInvoice(InvoiceEntity invoice);

  /// Calculate invoice totals
  /// [lineItems] - Line items to calculate
  /// [taxRate] - Tax rate to apply
  /// [discountAmount] - Discount amount to apply
  /// Returns calculated totals
  Future<InvoiceCalculation> calculateInvoiceTotals({
    required List<InvoiceLineItem> lineItems,
    double taxRate = 0.0,
    double discountAmount = 0.0,
  });

  /// Get invoice PDF download URL
  /// [invoiceId] - Invoice ID to get URL for
  /// [expiryHours] - Hours until URL expires
  /// Returns temporary download URL
  Future<String> getInvoicePDFUrl({
    required String invoiceId,
    int expiryHours = 24,
  });

  /// Preview invoice before sending
  /// [invoice] - Invoice to preview
  /// [template] - Template to use for preview
  /// Returns preview data
  Future<InvoicePreview> previewInvoice({
    required InvoiceEntity invoice,
    InvoiceTemplate? template,
  });
}

/// Filters for invoice queries
class InvoiceFilters {
  final List<InvoiceStatus>? statuses;
  final List<PaymentStatus>? paymentStatuses;
  final List<String>? clientIds;
  final List<String>? projectIds;
  final DateRange? issueDateRange;
  final DateRange? dueDateRange;
  final DateRange? sentDateRange;
  final DateRange? paidDateRange;
  final AmountRange? amountRange;
  final String? currency;
  final bool? isOverdue;
  final bool? isDueSoon;
  final List<String>? invoiceNumbers;

  const InvoiceFilters({
    this.statuses,
    this.paymentStatuses,
    this.clientIds,
    this.projectIds,
    this.issueDateRange,
    this.dueDateRange,
    this.sentDateRange,
    this.paidDateRange,
    this.amountRange,
    this.currency,
    this.isOverdue,
    this.isDueSoon,
    this.invoiceNumbers,
  });

  /// Check if any filters are applied
  bool get hasFilters {
    return statuses != null ||
        paymentStatuses != null ||
        clientIds != null ||
        projectIds != null ||
        issueDateRange != null ||
        dueDateRange != null ||
        sentDateRange != null ||
        paidDateRange != null ||
        amountRange != null ||
        currency != null ||
        isOverdue != null ||
        isDueSoon != null ||
        invoiceNumbers != null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (statuses != null)
        'statuses': statuses?.map((s) => s.toString()).toList(),
      if (paymentStatuses != null)
        'paymentStatuses': paymentStatuses?.map((s) => s.toString()).toList(),
      if (clientIds != null) 'clientIds': clientIds,
      if (projectIds != null) 'projectIds': projectIds,
      if (issueDateRange != null) 'issueDateRange': issueDateRange!.toMap(),
      if (dueDateRange != null) 'dueDateRange': dueDateRange!.toMap(),
      if (sentDateRange != null) 'sentDateRange': sentDateRange!.toMap(),
      if (paidDateRange != null) 'paidDateRange': paidDateRange!.toMap(),
      if (amountRange != null) 'amountRange': amountRange!.toMap(),
      if (currency != null) 'currency': currency,
      if (isOverdue != null) 'isOverdue': isOverdue,
      if (isDueSoon != null) 'isDueSoon': isDueSoon,
      if (invoiceNumbers != null) 'invoiceNumbers': invoiceNumbers,
    };
  }
}

/// Invoice email options
class InvoiceEmailOptions {
  final String to;
  final List<String>? cc;
  final List<String>? bcc;
  final String? subject;
  final String? message;
  final bool includePDF;
  final bool requestDeliveryReceipt;
  final bool requestReadReceipt;

  const InvoiceEmailOptions({
    required this.to,
    this.cc,
    this.bcc,
    this.subject,
    this.message,
    this.includePDF = true,
    this.requestDeliveryReceipt = false,
    this.requestReadReceipt = false,
  });
}

/// Invoice send result
class InvoiceSendResult {
  final bool success;
  final String? messageId;
  final DateTime sentAt;
  final String? error;
  final Map<String, dynamic>? deliveryInfo;

  const InvoiceSendResult({
    required this.success,
    this.messageId,
    required this.sentAt,
    this.error,
    this.deliveryInfo,
  });
}

/// Invoice PDF generation result
class InvoicePDFResult {
  final bool success;
  final String? pdfUrl;
  final String? filePath;
  final int? fileSize;
  final String? error;

  const InvoicePDFResult({
    required this.success,
    this.pdfUrl,
    this.filePath,
    this.fileSize,
    this.error,
  });
}

/// Invoice reminder result
class InvoiceReminderResult {
  final bool success;
  final DateTime sentAt;
  final InvoiceReminderType type;
  final String? error;

  const InvoiceReminderResult({
    required this.success,
    required this.sentAt,
    required this.type,
    this.error,
  });
}

/// Bulk reminder result
class BulkReminderResult {
  final int totalInvoices;
  final int successfulReminders;
  final int failedReminders;
  final List<String> errors;
  final DateTime completedAt;

  const BulkReminderResult({
    required this.totalInvoices,
    required this.successfulReminders,
    required this.failedReminders,
    required this.errors,
    required this.completedAt,
  });

  double get successRate {
    if (totalInvoices == 0) return 0.0;
    return successfulReminders / totalInvoices;
  }
}

/// Invoice statistics
class InvoiceStatistics {
  final int totalInvoices;
  final double totalAmount;
  final double totalPaid;
  final double totalOutstanding;
  final double averageInvoiceAmount;
  final double averagePaymentTime;
  final int overdueInvoices;
  final double overdueAmount;
  final Map<String, int> invoicesByStatus;
  final Map<String, double> revenueByClient;
  final Map<String, int> invoicesByMonth;

  const InvoiceStatistics({
    required this.totalInvoices,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.averageInvoiceAmount,
    required this.averagePaymentTime,
    required this.overdueInvoices,
    required this.overdueAmount,
    required this.invoicesByStatus,
    required this.revenueByClient,
    required this.invoicesByMonth,
  });

  /// Calculate collection rate
  double get collectionRate {
    if (totalAmount == 0) return 0.0;
    return totalPaid / totalAmount;
  }

  /// Calculate overdue rate
  double get overdueRate {
    if (totalInvoices == 0) return 0.0;
    return overdueInvoices / totalInvoices;
  }
}

/// Monthly revenue data
class MonthlyRevenue {
  final int year;
  final int month;
  final double amount;
  final int invoiceCount;
  final double averageInvoiceAmount;

  const MonthlyRevenue({
    required this.year,
    required this.month,
    required this.amount,
    required this.invoiceCount,
    required this.averageInvoiceAmount,
  });

  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

/// Payment collection metrics
class PaymentCollectionMetrics {
  final double averagePaymentTime;
  final double onTimePaymentRate;
  final double latePaymentRate;
  final double collectionEfficiency;
  final Map<String, double> paymentTimeByClient;
  final List<PaymentTrend> paymentTrends;

  const PaymentCollectionMetrics({
    required this.averagePaymentTime,
    required this.onTimePaymentRate,
    required this.latePaymentRate,
    required this.collectionEfficiency,
    required this.paymentTimeByClient,
    required this.paymentTrends,
  });
}

/// Payment trend data
class PaymentTrend {
  final String period;
  final double averagePaymentTime;
  final double collectionRate;

  const PaymentTrend({
    required this.period,
    required this.averagePaymentTime,
    required this.collectionRate,
  });
}

/// Import result
class ImportResult {
  final bool success;
  final int totalRecords;
  final int successfulImports;
  final int failedImports;
  final List<String> errors;
  final List<InvoiceEntity> importedInvoices;

  const ImportResult({
    required this.success,
    required this.totalRecords,
    required this.successfulImports,
    required this.failedImports,
    required this.errors,
    required this.importedInvoices,
  });
}

/// Import options
class ImportOptions {
  final bool skipDuplicates;
  final bool validateData;
  final String? defaultCurrency;
  final Map<String, String>? fieldMapping;

  const ImportOptions({
    this.skipDuplicates = true,
    this.validateData = true,
    this.defaultCurrency,
    this.fieldMapping,
  });
}

/// Invoice template entity
class InvoiceTemplateEntity {
  final String id;
  final String userId;
  final String name;
  final String description;
  final InvoiceTemplate template;
  final Map<String, dynamic> settings;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceTemplateEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.template,
    required this.settings,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Recurring invoice schedule
class RecurringInvoiceSchedule {
  final String id;
  final String userId;
  final String clientId;
  final String? projectId;
  final String templateId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int currentOccurrences;
  final DateTime? nextInvoiceDate;
  final bool isActive;
  final Map<String, dynamic> invoiceData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringInvoiceSchedule({
    required this.id,
    required this.userId,
    required this.clientId,
    this.projectId,
    required this.templateId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.currentOccurrences = 0,
    this.nextInvoiceDate,
    this.isActive = true,
    required this.invoiceData,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if schedule should create next invoice
  bool shouldCreateInvoice(DateTime currentDate) {
    if (!isActive || nextInvoiceDate == null) return false;
    if (endDate != null && currentDate.isAfter(endDate!)) return false;
    if (maxOccurrences != null && currentOccurrences >= maxOccurrences!)
      return false;
    return !currentDate.isBefore(nextInvoiceDate!);
  }

  /// Calculate next invoice date
  DateTime calculateNextInvoiceDate() {
    final current = nextInvoiceDate ?? startDate;
    switch (frequency) {
      case RecurringFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return current.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case RecurringFrequency.quarterly:
        return DateTime(current.year, current.month + 3, current.day);
      case RecurringFrequency.semiannually:
        return DateTime(current.year, current.month + 6, current.day);
      case RecurringFrequency.annually:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }
}

/// Invoice preview data
class InvoicePreview {
  final String htmlContent;
  final String? pdfUrl;
  final Map<String, dynamic> templateData;
  final List<String> errors;
  final List<String> warnings;

  const InvoicePreview({
    required this.htmlContent,
    this.pdfUrl,
    required this.templateData,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isValid => !hasErrors;
}

/// Validation error
class ValidationError {
  final String field;
  final String message;
  final ValidationErrorType type;

  const ValidationError({
    required this.field,
    required this.message,
    required this.type,
  });

  @override
  String toString() {
    return 'ValidationError: $field - $message';
  }
}

/// Enums for invoice operations
enum InvoiceReminderType { gentle, standard, urgent, final_, custom }

enum RecurringFrequency {
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannually,
  annually,
}

enum ImportFormat { csv, excel, json, xml }

enum ValidationErrorType {
  required,
  invalid,
  outOfRange,
  duplicate,
  businessRule,
}

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  bool get isValid => !start.isAfter(end);
  Duration get duration => end.difference(start);

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  Map<String, dynamic> toMap() {
    return {'start': start.toIso8601String(), 'end': end.toIso8601String()};
  }

  factory DateRange.fromMap(Map<String, dynamic> map) {
    return DateRange(
      start: DateTime.parse(map['start']),
      end: DateTime.parse(map['end']),
    );
  }

  factory DateRange.currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  factory DateRange.lastMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  factory DateRange.currentYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  factory DateRange.lastYear() {
    final now = DateTime.now();
    final start = DateTime(now.year - 1, 1, 1);
    final end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
    return DateRange(start: start, end: end);
  }
}

/// Amount range helper class
class AmountRange {
  final double? min;
  final double? max;

  const AmountRange({this.min, this.max});

  bool get isValid {
    if (min != null && max != null) {
      return min! <= max!;
    }
    return true;
  }

  bool contains(double amount) {
    if (min != null && amount < min!) return false;
    if (max != null && amount > max!) return false;
    return true;
  }

  Map<String, dynamic> toMap() {
    return {if (min != null) 'min': min, if (max != null) 'max': max};
  }
}

/// Pagination parameters
class PaginationParams {
  final int page;
  final int limit;
  final String? sortBy;
  final SortOrder sortOrder;
  final String? cursor;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder = SortOrder.desc,
    this.cursor,
  });

  int get offset => (page - 1) * limit;

  Map<String, dynamic> toMap() {
    return {
      'page': page,
      'limit': limit,
      if (sortBy != null) 'sortBy': sortBy,
      'sortOrder': sortOrder.toString().split('.').last,
      if (cursor != null) 'cursor': cursor,
    };
  }
}

/// Paginated result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int limit;
  final bool hasNext;
  final bool hasPrevious;
  final String? nextCursor;
  final String? previousCursor;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.hasPrevious,
    this.nextCursor,
    this.previousCursor,
  });

  int get totalPages => (totalCount / limit).ceil();
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Export result
class ExportResult {
  final bool success;
  final String? filePath;
  final String? downloadUrl;
  final String? fileName;
  final ExportFormat format;
  final int recordCount;
  final String? error;

  const ExportResult({
    required this.success,
    this.filePath,
    this.downloadUrl,
    this.fileName,
    required this.format,
    this.recordCount = 0,
    this.error,
  });
}

/// Sync result
class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final int conflicts;
  final List<String> errors;
  final DateTime completedAt;

  const SyncResult({
    required this.success,
    required this.synced,
    required this.failed,
    required this.conflicts,
    required this.errors,
    required this.completedAt,
  });

  String get summary {
    return 'Synced: $synced, Failed: $failed, Conflicts: $conflicts';
  }
}

/// Sort order enum
enum SortOrder { asc, desc }

/// Export format enum
enum ExportFormat { pdf, csv, excel, json }

/// Invoice repository exceptions
class InvoiceException implements Exception {
  final String message;
  final InvoiceErrorCode code;
  final dynamic originalException;

  const InvoiceException({
    required this.message,
    required this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'InvoiceException: $message (code: $code)';
  }

  factory InvoiceException.custom({
    required String message,
    required InvoiceErrorCode code,
  }) {
    return InvoiceException(message: message, code: code);
  }

  factory InvoiceException.notFound(String invoiceId) {
    return InvoiceException(
      message: 'Invoice not found: $invoiceId',
      code: InvoiceErrorCode.notFound,
    );
  }

  factory InvoiceException.duplicateNumber(String invoiceNumber) {
    return InvoiceException(
      message: 'Invoice number already exists: $invoiceNumber',
      code: InvoiceErrorCode.duplicateNumber,
    );
  }

  factory InvoiceException.cannotModify(String reason) {
    return InvoiceException(
      message: 'Cannot modify invoice: $reason',
      code: InvoiceErrorCode.cannotModify,
    );
  }

  factory InvoiceException.sendFailed(String reason) {
    return InvoiceException(
      message: 'Failed to send invoice: $reason',
      code: InvoiceErrorCode.sendFailed,
    );
  }

  factory InvoiceException.pdfGenerationFailed(String reason) {
    return InvoiceException(
      message: 'PDF generation failed: $reason',
      code: InvoiceErrorCode.pdfGenerationFailed,
    );
  }

  factory InvoiceException.permissionDenied() {
    return InvoiceException(
      message: 'Permission denied: user cannot access this invoice',
      code: InvoiceErrorCode.permissionDenied,
    );
  }

  factory InvoiceException.quotaExceeded() {
    return InvoiceException(
      message: 'Invoice quota exceeded for current subscription',
      code: InvoiceErrorCode.quotaExceeded,
    );
  }
}

/// Invoice error codes
enum InvoiceErrorCode {
  notFound,
  permissionDenied,
  invalidData,
  duplicateNumber,
  cannotModify,
  sendFailed,
  pdfGenerationFailed,
  reminderFailed,
  exportFailed,
  importFailed,
  validationFailed,
  quotaExceeded,
  networkError,
  storageError,
  templateNotFound,
  clientNotFound,
  projectNotFound,
  recurringScheduleError,
  paymentRecordingError,
  unknown,
}
