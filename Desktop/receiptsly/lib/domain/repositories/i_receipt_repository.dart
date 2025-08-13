// lib/domain/repositories/i_receipt_repository.dart
import 'dart:async';
import 'dart:io';
import '../entities/receipt_entity.dart';

/// Receipt repository interface defining all receipt-related operations
/// This interface is implemented by the data layer and used by use cases
abstract class IReceiptRepository {
  /// Stream of receipts for a specific user
  /// Returns real-time updates when receipts are added, updated, or deleted
  /// [userId] - User ID to filter receipts
  /// [filters] - Optional filters to apply
  Stream<List<ReceiptEntity>> watchUserReceipts({
    required String userId,
    ReceiptFilters? filters,
  });

  /// Get receipts for a user with pagination
  /// [userId] - User ID to filter receipts
  /// [filters] - Optional filters to apply
  /// [pagination] - Pagination parameters
  /// Returns paginated list of receipts
  Future<PaginatedResult<ReceiptEntity>> getUserReceipts({
    required String userId,
    ReceiptFilters? filters,
    PaginationParams? pagination,
  });

  /// Get a specific receipt by ID
  /// [receiptId] - Receipt ID to fetch
  /// Returns receipt entity or null if not found
  Future<ReceiptEntity?> getReceiptById(String receiptId);

  /// Create a new receipt
  /// [receipt] - Receipt entity to create
  /// Returns created receipt with generated ID
  Future<ReceiptEntity> createReceipt(ReceiptEntity receipt);

  /// Update an existing receipt
  /// [receipt] - Updated receipt entity
  /// Returns updated receipt entity
  Future<ReceiptEntity> updateReceipt(ReceiptEntity receipt);

  /// Delete a receipt
  /// [receiptId] - ID of receipt to delete
  Future<void> deleteReceipt(String receiptId);

  /// Bulk delete receipts
  /// [receiptIds] - List of receipt IDs to delete
  /// Returns number of successfully deleted receipts
  Future<int> bulkDeleteReceipts(List<String> receiptIds);

  /// Upload receipt image
  /// [imageFile] - Image file to upload
  /// [userId] - User ID for organizing files
  /// [fileName] - Optional custom file name
  /// Returns uploaded image information
  Future<ReceiptImage> uploadReceiptImage({
    required File imageFile,
    required String userId,
    String? fileName,
  });

  /// Process receipt image with OCR
  /// [imageFile] - Image file to process
  /// [userId] - User ID for context
  /// Returns OCR processing result
  Future<OCRResult> processReceiptOCR({
    required File imageFile,
    required String userId,
  });

  /// Reprocess existing receipt with OCR
  /// [receiptId] - Receipt ID to reprocess
  /// Returns updated receipt with new OCR data
  Future<ReceiptEntity> reprocessReceiptOCR(String receiptId);

  /// Search receipts by text
  /// [userId] - User ID to filter receipts
  /// [query] - Search query
  /// [filters] - Optional additional filters
  /// [pagination] - Pagination parameters
  /// Returns search results
  Future<PaginatedResult<ReceiptEntity>> searchReceipts({
    required String userId,
    required String query,
    ReceiptFilters? filters,
    PaginationParams? pagination,
  });

  /// Get receipts by category
  /// [userId] - User ID to filter receipts
  /// [category] - Category to filter by
  /// [pagination] - Pagination parameters
  /// Returns receipts in specified category
  Future<PaginatedResult<ReceiptEntity>> getReceiptsByCategory({
    required String userId,
    required String category,
    PaginationParams? pagination,
  });

  /// Get receipts by date range
  /// [userId] - User ID to filter receipts
  /// [startDate] - Start date (inclusive)
  /// [endDate] - End date (inclusive)
  /// [pagination] - Pagination parameters
  /// Returns receipts in date range
  Future<PaginatedResult<ReceiptEntity>> getReceiptsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    PaginationParams? pagination,
  });

  /// Get receipts by vendor
  /// [userId] - User ID to filter receipts
  /// [vendor] - Vendor name to filter by
  /// [pagination] - Pagination parameters
  /// Returns receipts from specified vendor
  Future<PaginatedResult<ReceiptEntity>> getReceiptsByVendor({
    required String userId,
    required String vendor,
    PaginationParams? pagination,
  });

  /// Get receipts by project
  /// [userId] - User ID to filter receipts
  /// [projectId] - Project ID to filter by
  /// [pagination] - Pagination parameters
  /// Returns receipts for specified project
  Future<PaginatedResult<ReceiptEntity>> getReceiptsByProject({
    required String userId,
    required String projectId,
    PaginationParams? pagination,
  });

  /// Get receipts by client
  /// [userId] - User ID to filter receipts
  /// [clientId] - Client ID to filter by
  /// [pagination] - Pagination parameters
  /// Returns receipts for specified client
  Future<PaginatedResult<ReceiptEntity>> getReceiptsByClient({
    required String userId,
    required String clientId,
    PaginationParams? pagination,
  });

  /// Get receipts that need review
  /// [userId] - User ID to filter receipts
  /// [pagination] - Pagination parameters
  /// Returns receipts with low OCR confidence or validation errors
  Future<PaginatedResult<ReceiptEntity>> getReceiptsNeedingReview({
    required String userId,
    PaginationParams? pagination,
  });

  /// Get recent receipts
  /// [userId] - User ID to filter receipts
  /// [limit] - Maximum number of receipts to return
  /// Returns most recently created receipts
  Future<List<ReceiptEntity>> getRecentReceipts({
    required String userId,
    int limit = 10,
  });

  /// Get receipts by tags
  /// [userId] - User ID to filter receipts
  /// [tags] - List of tags to filter by
  /// [matchAll] - If true, receipt must have all tags; if false, any tag
  /// [pagination] - Pagination parameters
  /// Returns receipts with specified tags
  Future<PaginatedResult<ReceiptEntity>> getReceiptsByTags({
    required String userId,
    required List<String> tags,
    bool matchAll = false,
    PaginationParams? pagination,
  });

  /// Bulk update receipt category
  /// [receiptIds] - List of receipt IDs to update
  /// [category] - New category to assign
  /// Returns number of successfully updated receipts
  Future<int> bulkUpdateCategory({
    required List<String> receiptIds,
    required String category,
  });

  /// Bulk update receipt tags
  /// [receiptIds] - List of receipt IDs to update
  /// [tags] - Tags to add or remove
  /// [action] - Whether to add or remove tags
  /// Returns number of successfully updated receipts
  Future<int> bulkUpdateTags({
    required List<String> receiptIds,
    required List<String> tags,
    required TagAction action,
  });

  /// Bulk assign receipts to project
  /// [receiptIds] - List of receipt IDs to update
  /// [projectId] - Project ID to assign
  /// Returns number of successfully updated receipts
  Future<int> bulkAssignToProject({
    required List<String> receiptIds,
    required String projectId,
  });

  /// Bulk assign receipts to client
  /// [receiptIds] - List of receipt IDs to update
  /// [clientId] - Client ID to assign
  /// Returns number of successfully updated receipts
  Future<int> bulkAssignToClient({
    required List<String> receiptIds,
    required String clientId,
  });

  /// Mark receipt as billable
  /// [receiptId] - Receipt ID to update
  /// [isBillable] - Whether receipt is billable
  /// [clientId] - Client ID if billable
  /// [projectId] - Project ID if billable
  /// Returns updated receipt
  Future<ReceiptEntity> markAsBillable({
    required String receiptId,
    required bool isBillable,
    String? clientId,
    String? projectId,
  });

  /// Export receipts to various formats
  /// [userId] - User ID to filter receipts
  /// [format] - Export format (PDF, CSV, Excel)
  /// [filters] - Optional filters to apply
  /// [dateRange] - Optional date range
  /// Returns export result with file path or URL
  Future<ExportResult> exportReceipts({
    required String userId,
    required ExportFormat format,
    ReceiptFilters? filters,
    DateRange? dateRange,
  });

  /// Get receipt statistics for a user
  /// [userId] - User ID to get statistics for
  /// [dateRange] - Optional date range to filter
  /// Returns comprehensive receipt statistics
  Future<ReceiptStatistics> getReceiptStatistics({
    required String userId,
    DateRange? dateRange,
  });

  /// Get spending by category
  /// [userId] - User ID to get statistics for
  /// [dateRange] - Optional date range to filter
  /// Returns spending breakdown by category
  Future<Map<String, double>> getSpendingByCategory({
    required String userId,
    DateRange? dateRange,
  });

  /// Get spending by vendor
  /// [userId] - User ID to get statistics for
  /// [dateRange] - Optional date range to filter
  /// [limit] - Maximum number of vendors to return
  /// Returns top vendors by spending
  Future<Map<String, double>> getSpendingByVendor({
    required String userId,
    DateRange? dateRange,
    int limit = 10,
  });

  /// Get monthly spending trend
  /// [userId] - User ID to get statistics for
  /// [months] - Number of months to include
  /// Returns monthly spending data
  Future<List<MonthlySpending>> getMonthlySpendingTrend({
    required String userId,
    int months = 12,
  });

  /// Get all unique categories used by user
  /// [userId] - User ID to get categories for
  /// Returns list of categories with usage count
  Future<List<CategoryUsage>> getUserCategories(String userId);

  /// Get all unique vendors used by user
  /// [userId] - User ID to get vendors for
  /// [limit] - Maximum number of vendors to return
  /// Returns list of vendors with frequency
  Future<List<VendorUsage>> getUserVendors({
    required String userId,
    int limit = 50,
  });

  /// Get all unique tags used by user
  /// [userId] - User ID to get tags for
  /// Returns list of tags with usage count
  Future<List<TagUsage>> getUserTags(String userId);

  /// Sync receipts with cloud storage
  /// [userId] - User ID to sync receipts for
  /// [force] - Force sync even if no changes detected
  /// Returns sync result with status and statistics
  Future<SyncResult> syncReceipts({required String userId, bool force = false});

  /// Get sync status for user receipts
  /// [userId] - User ID to check sync status for
  /// Returns current sync status and pending operations
  Future<SyncStatus> getSyncStatus(String userId);

  /// Clear local receipt cache
  /// [userId] - User ID to clear cache for
  /// [olderThan] - Optional date to keep newer receipts
  Future<void> clearReceiptCache({required String userId, DateTime? olderThan});

  /// Get offline receipts (not yet synced)
  /// [userId] - User ID to get offline receipts for
  /// Returns list of receipts pending sync
  Future<List<ReceiptEntity>> getOfflineReceipts(String userId);

  /// Retry failed receipt operations
  /// [userId] - User ID to retry operations for
  /// Returns list of successfully retried operations
  Future<List<String>> retryFailedOperations(String userId);
}

/// Filters for receipt queries
class ReceiptFilters {
  final List<String>? categories;
  final List<String>? vendors;
  final List<String>? tags;
  final List<ReceiptStatus>? statuses;
  final List<ReceiptSource>? sources;
  final DateRange? dateRange;
  final AmountRange? amountRange;
  final String? projectId;
  final String? clientId;
  final bool? isBillable;
  final bool? isReimbursable;
  final bool? hasAttachments;
  final double? minOcrConfidence;

  const ReceiptFilters({
    this.categories,
    this.vendors,
    this.tags,
    this.statuses,
    this.sources,
    this.dateRange,
    this.amountRange,
    this.projectId,
    this.clientId,
    this.isBillable,
    this.isReimbursable,
    this.hasAttachments,
    this.minOcrConfidence,
  });

  /// Check if any filters are applied
  bool get hasFilters {
    return categories != null ||
        vendors != null ||
        tags != null ||
        statuses != null ||
        sources != null ||
        dateRange != null ||
        amountRange != null ||
        projectId != null ||
        clientId != null ||
        isBillable != null ||
        isReimbursable != null ||
        hasAttachments != null ||
        minOcrConfidence != null;
  }

  /// Convert to map for API calls
  Map<String, dynamic> toMap() {
    return {
      if (categories != null) 'categories': categories,
      if (vendors != null) 'vendors': vendors,
      if (tags != null) 'tags': tags,
      if (statuses != null)
        'statuses': statuses?.map((s) => s.toString()).toList(),
      if (sources != null)
        'sources': sources?.map((s) => s.toString()).toList(),
      if (dateRange != null) 'dateRange': dateRange!.toMap(),
      if (amountRange != null) 'amountRange': amountRange!.toMap(),
      if (projectId != null) 'projectId': projectId,
      if (clientId != null) 'clientId': clientId,
      if (isBillable != null) 'isBillable': isBillable,
      if (isReimbursable != null) 'isReimbursable': isReimbursable,
      if (hasAttachments != null) 'hasAttachments': hasAttachments,
      if (minOcrConfidence != null) 'minOcrConfidence': minOcrConfidence,
    };
  }

  ReceiptFilters copyWith({
    List<String>? categories,
    List<String>? vendors,
    List<String>? tags,
    List<ReceiptStatus>? statuses,
    List<ReceiptSource>? sources,
    DateRange? dateRange,
    AmountRange? amountRange,
    String? projectId,
    String? clientId,
    bool? isBillable,
    bool? isReimbursable,
    bool? hasAttachments,
    double? minOcrConfidence,
  }) {
    return ReceiptFilters(
      categories: categories ?? this.categories,
      vendors: vendors ?? this.vendors,
      tags: tags ?? this.tags,
      statuses: statuses ?? this.statuses,
      sources: sources ?? this.sources,
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      isBillable: isBillable ?? this.isBillable,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      minOcrConfidence: minOcrConfidence ?? this.minOcrConfidence,
    );
  }
}

/// Pagination parameters
class PaginationParams {
  final int page;
  final int limit;
  final String? sortBy;
  final SortOrder sortOrder;
  final String? cursor; // For cursor-based pagination

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder = SortOrder.desc,
    this.cursor,
  });

  /// Get offset for SQL queries
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

  /// Get total number of pages
  int get totalPages => (totalCount / limit).ceil();

  /// Check if result is empty
  bool get isEmpty => items.isEmpty;

  /// Check if result is not empty
  bool get isNotEmpty => items.isNotEmpty;
}

/// Date range filter
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// Check if date range is valid
  bool get isValid => !start.isAfter(end);

  /// Get duration of date range
  Duration get duration => end.difference(start);

  /// Check if date is within range
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

  /// Create date range for current month
  factory DateRange.currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// Create date range for last month
  factory DateRange.lastMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// Create date range for current year
  factory DateRange.currentYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return DateRange(start: start, end: end);
  }
}

/// Amount range filter
class AmountRange {
  final double? min;
  final double? max;

  const AmountRange({this.min, this.max});

  /// Check if amount range is valid
  bool get isValid {
    if (min != null && max != null) {
      return min! <= max!;
    }
    return true;
  }

  /// Check if amount is within range
  bool contains(double amount) {
    if (min != null && amount < min!) return false;
    if (max != null && amount > max!) return false;
    return true;
  }

  Map<String, dynamic> toMap() {
    return {if (min != null) 'min': min, if (max != null) 'max': max};
  }
}

/// OCR processing result
class OCRResult {
  final bool success;
  final OCRData? data;
  final String? error;
  final double processingTime;

  const OCRResult({
    required this.success,
    this.data,
    this.error,
    this.processingTime = 0.0,
  });

  factory OCRResult.success(OCRData data, {double processingTime = 0.0}) {
    return OCRResult(success: true, data: data, processingTime: processingTime);
  }

  factory OCRResult.failure(String error, {double processingTime = 0.0}) {
    return OCRResult(
      success: false,
      error: error,
      processingTime: processingTime,
    );
  }
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

/// Receipt statistics
class ReceiptStatistics {
  final int totalReceipts;
  final double totalAmount;
  final double averageAmount;
  final double largestAmount;
  final double smallestAmount;
  final Map<String, int> receiptsByCategory;
  final Map<String, double> amountByCategory;
  final Map<String, int> receiptsByVendor;
  final Map<String, int> receiptsByMonth;
  final int receiptsNeedingReview;
  final double averageOcrConfidence;

  const ReceiptStatistics({
    required this.totalReceipts,
    required this.totalAmount,
    required this.averageAmount,
    required this.largestAmount,
    required this.smallestAmount,
    required this.receiptsByCategory,
    required this.amountByCategory,
    required this.receiptsByVendor,
    required this.receiptsByMonth,
    required this.receiptsNeedingReview,
    required this.averageOcrConfidence,
  });
}

/// Monthly spending data
class MonthlySpending {
  final int year;
  final int month;
  final double amount;
  final int receiptCount;

  const MonthlySpending({
    required this.year,
    required this.month,
    required this.amount,
    required this.receiptCount,
  });

  /// Get month name
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

  /// Get formatted date (e.g., "Jan 2024")
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[month - 1]} $year';
  }
}

/// Category usage statistics
class CategoryUsage {
  final String category;
  final int count;
  final double totalAmount;
  final double percentage;

  const CategoryUsage({
    required this.category,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });
}

/// Vendor usage statistics
class VendorUsage {
  final String vendor;
  final int frequency;
  final double totalAmount;
  final DateTime lastUsed;

  const VendorUsage({
    required this.vendor,
    required this.frequency,
    required this.totalAmount,
    required this.lastUsed,
  });
}

/// Tag usage statistics
class TagUsage {
  final String tag;
  final int count;
  final double percentage;

  const TagUsage({
    required this.tag,
    required this.count,
    required this.percentage,
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

  /// Get sync summary
  String get summary {
    return 'Synced: $synced, Failed: $failed, Conflicts: $conflicts';
  }
}

/// Sync status
class SyncStatus {
  final bool isSyncing;
  final int pendingOperations;
  final DateTime? lastSyncAt;
  final List<String> failedOperations;

  const SyncStatus({
    required this.isSyncing,
    required this.pendingOperations,
    this.lastSyncAt,
    required this.failedOperations,
  });

  /// Check if sync is needed
  bool get needsSync {
    return pendingOperations > 0 || failedOperations.isNotEmpty;
  }
}

/// Enums for receipt operations
enum SortOrder { asc, desc }

enum TagAction { add, remove }

enum ExportFormat { pdf, csv, excel, json }

/// Receipt repository exceptions
class ReceiptException implements Exception {
  final String message;
  final ReceiptErrorCode code;
  final dynamic originalException;

  const ReceiptException({
    required this.message,
    required this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'ReceiptException: $message (code: $code)';
  }

  /// Create custom receipt exception
  factory ReceiptException.custom({
    required String message,
    required ReceiptErrorCode code,
  }) {
    return ReceiptException(message: message, code: code);
  }

  /// Common exception factories
  factory ReceiptException.notFound(String receiptId) {
    return ReceiptException(
      message: 'Receipt not found: $receiptId',
      code: ReceiptErrorCode.notFound,
    );
  }

  factory ReceiptException.invalidImage() {
    return ReceiptException(
      message: 'Invalid image format or corrupted file',
      code: ReceiptErrorCode.invalidImage,
    );
  }

  factory ReceiptException.ocrFailed(String reason) {
    return ReceiptException(
      message: 'OCR processing failed: $reason',
      code: ReceiptErrorCode.ocrFailed,
    );
  }

  factory ReceiptException.syncFailed(String reason) {
    return ReceiptException(
      message: 'Sync failed: $reason',
      code: ReceiptErrorCode.syncFailed,
    );
  }

  factory ReceiptException.permissionDenied() {
    return ReceiptException(
      message: 'Permission denied: user cannot access this receipt',
      code: ReceiptErrorCode.permissionDenied,
    );
  }

  factory ReceiptException.quotaExceeded() {
    return ReceiptException(
      message: 'Receipt quota exceeded for current subscription',
      code: ReceiptErrorCode.quotaExceeded,
    );
  }
}

/// Receipt error codes
enum ReceiptErrorCode {
  notFound,
  permissionDenied,
  invalidData,
  invalidImage,
  ocrFailed,
  uploadFailed,
  syncFailed,
  exportFailed,
  quotaExceeded,
  networkError,
  storageError,
  validationError,
  unknown,
}
