// lib/data/models/sync/sync_queue_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'sync_queue_model.freezed.dart';
part 'sync_queue_model.g.dart';

@freezed
class SyncQueueModel with _$SyncQueueModel {
  const factory SyncQueueModel({
    required String id,
    required String userId,
    required String action, // CREATE, UPDATE, DELETE
    required String collection, // receipts, invoices, clients, etc.
    String? documentId,
    required Map<String, dynamic> data,
    required SyncQueueStatus status,
    @Default(0) int retryCount,
    @Default(3) int maxRetries,
    @Default(0) int priority, // Higher number = higher priority
    String? error,
    String? conflictResolution, // local_wins, remote_wins, manual
    Map<String, dynamic>? conflictData,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? scheduledAt,
    @TimestampConverter() DateTime? lastAttemptAt,
    @TimestampConverter() DateTime? completedAt,
    @TimestampConverter() DateTime? nextRetryAt,
    String? batchId, // For grouping related operations
    @Default([]) List<String> dependencies, // IDs of items this depends on
    Map<String, dynamic>? metadata,
    @Default(1) int version,
  }) = _SyncQueueModel;

  factory SyncQueueModel.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueModelFromJson(json);
}

enum SyncQueueStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('scheduled')
  scheduled,

  @JsonValue('processing')
  processing,

  @JsonValue('completed')
  completed,

  @JsonValue('failed')
  failed,

  @JsonValue('cancelled')
  cancelled,

  @JsonValue('conflict')
  conflict,

  @JsonValue('waiting_dependencies')
  waitingDependencies;

  /// Display-friendly label for the status
  String get label {
    switch (this) {
      case SyncQueueStatus.pending:
        return 'Pending';
      case SyncQueueStatus.scheduled:
        return 'Scheduled';
      case SyncQueueStatus.processing:
        return 'Processing';
      case SyncQueueStatus.completed:
        return 'Completed';
      case SyncQueueStatus.failed:
        return 'Failed';
      case SyncQueueStatus.cancelled:
        return 'Cancelled';
      case SyncQueueStatus.conflict:
        return 'Conflict';
      case SyncQueueStatus.waitingDependencies:
        return 'Waiting Dependencies';
    }
  }

  /// Description of the status
  String get description {
    switch (this) {
      case SyncQueueStatus.pending:
        return 'Waiting to be processed';
      case SyncQueueStatus.scheduled:
        return 'Scheduled for future processing';
      case SyncQueueStatus.processing:
        return 'Currently being processed';
      case SyncQueueStatus.completed:
        return 'Successfully completed';
      case SyncQueueStatus.failed:
        return 'Processing failed';
      case SyncQueueStatus.cancelled:
        return 'Operation was cancelled';
      case SyncQueueStatus.conflict:
        return 'Data conflict detected';
      case SyncQueueStatus.waitingDependencies:
        return 'Waiting for dependencies to complete';
    }
  }

  /// Color associated with the status
  String get colorHex {
    switch (this) {
      case SyncQueueStatus.pending:
        return '#FF9800'; // Orange
      case SyncQueueStatus.scheduled:
        return '#2196F3'; // Blue
      case SyncQueueStatus.processing:
        return '#03A9F4'; // Light Blue
      case SyncQueueStatus.completed:
        return '#4CAF50'; // Green
      case SyncQueueStatus.failed:
        return '#F44336'; // Red
      case SyncQueueStatus.cancelled:
        return '#9E9E9E'; // Grey
      case SyncQueueStatus.conflict:
        return '#E91E63'; // Pink
      case SyncQueueStatus.waitingDependencies:
        return '#FF5722'; // Deep Orange
    }
  }

  /// Icon name for the status
  String get iconName {
    switch (this) {
      case SyncQueueStatus.pending:
        return 'schedule';
      case SyncQueueStatus.scheduled:
        return 'event';
      case SyncQueueStatus.processing:
        return 'sync';
      case SyncQueueStatus.completed:
        return 'check_circle';
      case SyncQueueStatus.failed:
        return 'error';
      case SyncQueueStatus.cancelled:
        return 'cancel';
      case SyncQueueStatus.conflict:
        return 'warning';
      case SyncQueueStatus.waitingDependencies:
        return 'hourglass_empty';
    }
  }

  /// Whether the status indicates completion (success or failure)
  bool get isCompleted {
    switch (this) {
      case SyncQueueStatus.completed:
      case SyncQueueStatus.failed:
      case SyncQueueStatus.cancelled:
        return true;
      case SyncQueueStatus.pending:
      case SyncQueueStatus.scheduled:
      case SyncQueueStatus.processing:
      case SyncQueueStatus.conflict:
      case SyncQueueStatus.waitingDependencies:
        return false;
    }
  }

  /// Whether the status indicates an active operation
  bool get isActive {
    switch (this) {
      case SyncQueueStatus.pending:
      case SyncQueueStatus.scheduled:
      case SyncQueueStatus.processing:
      case SyncQueueStatus.waitingDependencies:
        return true;
      case SyncQueueStatus.completed:
      case SyncQueueStatus.failed:
      case SyncQueueStatus.cancelled:
      case SyncQueueStatus.conflict:
        return false;
    }
  }

  /// Whether the operation can be retried
  bool get canRetry {
    switch (this) {
      case SyncQueueStatus.failed:
      case SyncQueueStatus.conflict:
        return true;
      case SyncQueueStatus.pending:
      case SyncQueueStatus.scheduled:
      case SyncQueueStatus.processing:
      case SyncQueueStatus.completed:
      case SyncQueueStatus.cancelled:
      case SyncQueueStatus.waitingDependencies:
        return false;
    }
  }

  /// Whether the operation can be cancelled
  bool get canCancel {
    switch (this) {
      case SyncQueueStatus.pending:
      case SyncQueueStatus.scheduled:
      case SyncQueueStatus.waitingDependencies:
        return true;
      case SyncQueueStatus.processing:
      case SyncQueueStatus.completed:
      case SyncQueueStatus.failed:
      case SyncQueueStatus.cancelled:
      case SyncQueueStatus.conflict:
        return false;
    }
  }
}

// Extension methods for SyncQueueModel
extension SyncQueueModelExtension on SyncQueueModel {
  /// Check if the operation has exceeded max retries
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  /// Check if the operation is ready to be retried
  bool get isReadyForRetry {
    if (!status.canRetry || hasExceededMaxRetries) return false;

    if (nextRetryAt == null) return true;

    return DateTime.now().isAfter(nextRetryAt!);
  }

  /// Check if the operation is overdue for processing
  bool get isOverdue {
    if (!status.isActive) return false;

    final now = DateTime.now();

    // Check if scheduled time has passed
    if (scheduledAt != null && now.isAfter(scheduledAt!)) {
      return true;
    }

    // Check if it's been too long since creation
    final maxWaitTime = Duration(hours: priority > 5 ? 1 : 24);
    return now.difference(createdAt) > maxWaitTime;
  }

  /// Get the time until next retry
  Duration? get timeUntilRetry {
    if (nextRetryAt == null) return null;

    final now = DateTime.now();
    if (now.isAfter(nextRetryAt!)) return Duration.zero;

    return nextRetryAt!.difference(now);
  }

  /// Get the total processing time (if completed)
  Duration? get processingTime {
    if (completedAt == null) return null;

    final startTime = lastAttemptAt ?? createdAt;
    return completedAt!.difference(startTime);
  }

  /// Get the wait time before first attempt
  Duration get waitTime {
    final startTime = lastAttemptAt ?? createdAt;
    return startTime.difference(createdAt);
  }

  /// Check if this operation has dependencies
  bool get hasDependencies => dependencies.isNotEmpty;

  /// Check if this operation is high priority
  bool get isHighPriority => priority >= 8;

  /// Check if this operation is low priority
  bool get isLowPriority => priority <= 2;

  /// Get priority label
  String get priorityLabel {
    if (priority >= 8) return 'High';
    if (priority >= 5) return 'Medium';
    if (priority >= 2) return 'Normal';
    return 'Low';
  }

  /// Get action label
  String get actionLabel {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return 'Create';
      case 'UPDATE':
        return 'Update';
      case 'DELETE':
        return 'Delete';
      case 'SYNC':
        return 'Sync';
      case 'BACKUP':
        return 'Backup';
      case 'RESTORE':
        return 'Restore';
      default:
        return action;
    }
  }

  /// Get collection label
  String get collectionLabel {
    switch (collection.toLowerCase()) {
      case 'receipts':
        return 'Receipt';
      case 'invoices':
        return 'Invoice';
      case 'clients':
        return 'Client';
      case 'categories':
        return 'Category';
      case 'users':
        return 'User';
      case 'projects':
        return 'Project';
      default:
        return collection;
    }
  }

  /// Get operation description
  String get operationDescription {
    return '${actionLabel} ${collectionLabel}';
  }

  /// Calculate next retry time based on exponential backoff
  DateTime calculateNextRetryTime() {
    final baseDelay = Duration(minutes: 5); // 5 minutes base delay
    final exponentialDelay = Duration(
      minutes: (5 * (1 << retryCount)).clamp(5, 480), // Max 8 hours
    );

    return DateTime.now().add(exponentialDelay);
  }

  /// Create a copy with updated status
  SyncQueueModel updateStatus(
    SyncQueueStatus newStatus, {
    String? errorMessage,
  }) {
    final now = DateTime.now();

    return copyWith(
      status: newStatus,
      lastAttemptAt: now,
      error: errorMessage,
      completedAt: newStatus.isCompleted ? now : null,
      nextRetryAt: newStatus == SyncQueueStatus.failed
          ? calculateNextRetryTime()
          : null,
    );
  }

  /// Create a copy with incremented retry count
  SyncQueueModel incrementRetry({String? errorMessage}) {
    return copyWith(
      retryCount: retryCount + 1,
      status: retryCount + 1 >= maxRetries
          ? SyncQueueStatus.failed
          : SyncQueueStatus.pending,
      error: errorMessage,
      lastAttemptAt: DateTime.now(),
      nextRetryAt: calculateNextRetryTime(),
    );
  }

  /// Create a copy marking as completed
  SyncQueueModel markCompleted() {
    return copyWith(
      status: SyncQueueStatus.completed,
      completedAt: DateTime.now(),
      error: null,
      nextRetryAt: null,
    );
  }

  /// Create a copy marking as failed
  SyncQueueModel markFailed(String errorMessage) {
    return copyWith(
      status: SyncQueueStatus.failed,
      error: errorMessage,
      completedAt: DateTime.now(),
      nextRetryAt: hasExceededMaxRetries ? null : calculateNextRetryTime(),
    );
  }

  /// Create a copy marking as conflict
  SyncQueueModel markConflict(Map<String, dynamic> conflictData) {
    return copyWith(
      status: SyncQueueStatus.conflict,
      conflictData: conflictData,
      lastAttemptAt: DateTime.now(),
    );
  }

  /// Create a copy with conflict resolution
  SyncQueueModel resolveConflict(
    String resolution,
    Map<String, dynamic> resolvedData,
  ) {
    return copyWith(
      status: SyncQueueStatus.pending,
      conflictResolution: resolution,
      data: resolvedData,
      conflictData: null,
      retryCount: 0, // Reset retry count after manual resolution
    );
  }

  /// Validate the sync queue model
  List<String> validate() {
    final errors = <String>[];

    if (userId.trim().isEmpty) {
      errors.add('User ID is required');
    }

    if (action.trim().isEmpty) {
      errors.add('Action is required');
    }

    if (collection.trim().isEmpty) {
      errors.add('Collection is required');
    }

    if (data.isEmpty && action.toUpperCase() != 'DELETE') {
      errors.add('Data is required for non-delete operations');
    }

    if (retryCount < 0) {
      errors.add('Retry count cannot be negative');
    }

    if (maxRetries < 0) {
      errors.add('Max retries cannot be negative');
    }

    if (priority < 0 || priority > 10) {
      errors.add('Priority must be between 0 and 10');
    }

    return errors;
  }

  /// Check if the sync queue item is valid
  bool get isValid => validate().isEmpty;

  /// Convert to map for local database storage
  Map<String, dynamic> toLocalDb() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'collection': collection,
      'document_id': documentId,
      'data': data,
      'status': status.name,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'priority': priority,
      'error': error,
      'conflict_resolution': conflictResolution,
      'conflict_data': conflictData,
      'created_at': createdAt.millisecondsSinceEpoch,
      'scheduled_at': scheduledAt?.millisecondsSinceEpoch,
      'last_attempt_at': lastAttemptAt?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'next_retry_at': nextRetryAt?.millisecondsSinceEpoch,
      'batch_id': batchId,
      'dependencies': dependencies,
      'metadata': metadata,
      'version': version,
    };
  }

  /// Create SyncQueueModel from local database map
  static SyncQueueModel fromLocalDb(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'],
      userId: map['user_id'],
      action: map['action'],
      collection: map['collection'],
      documentId: map['document_id'],
      data: Map<String, dynamic>.from(map['data']),
      status: SyncQueueStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SyncQueueStatus.pending,
      ),
      retryCount: map['retry_count'] ?? 0,
      maxRetries: map['max_retries'] ?? 3,
      priority: map['priority'] ?? 0,
      error: map['error'],
      conflictResolution: map['conflict_resolution'],
      conflictData: map['conflict_data'] != null
          ? Map<String, dynamic>.from(map['conflict_data'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'])
          : null,
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_attempt_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      nextRetryAt: map['next_retry_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['next_retry_at'])
          : null,
      batchId: map['batch_id'],
      dependencies: List<String>.from(map['dependencies'] ?? []),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      version: map['version'] ?? 1,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    final json = toJson();

    // Convert DateTime objects to Timestamps for Firestore
    json['createdAt'] = TimestampConverter().toJson(createdAt);

    if (scheduledAt != null) {
      json['scheduledAt'] = TimestampConverter().toJson(scheduledAt!);
    }
    if (lastAttemptAt != null) {
      json['lastAttemptAt'] = TimestampConverter().toJson(lastAttemptAt!);
    }
    if (completedAt != null) {
      json['completedAt'] = TimestampConverter().toJson(completedAt!);
    }
    if (nextRetryAt != null) {
      json['nextRetryAt'] = TimestampConverter().toJson(nextRetryAt!);
    }

    return json;
  }

  /// Create SyncQueueModel from Firestore document
  static SyncQueueModel fromFirestore(Map<String, dynamic> data) {
    return SyncQueueModel.fromJson(data);
  }
}

// Helper class for creating sync queue items
class SyncQueueBuilder {
  String? _id;
  String? _userId;
  String? _action;
  String? _collection;
  String? _documentId;
  Map<String, dynamic>? _data;
  int? _priority;
  DateTime? _scheduledAt;
  List<String>? _dependencies;

  SyncQueueBuilder setId(String id) {
    _id = id;
    return this;
  }

  SyncQueueBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  SyncQueueBuilder setAction(String action) {
    _action = action;
    return this;
  }

  SyncQueueBuilder setCollection(String collection) {
    _collection = collection;
    return this;
  }

  SyncQueueBuilder setDocumentId(String documentId) {
    _documentId = documentId;
    return this;
  }

  SyncQueueBuilder setData(Map<String, dynamic> data) {
    _data = data;
    return this;
  }

  SyncQueueBuilder setPriority(int priority) {
    _priority = priority;
    return this;
  }

  SyncQueueBuilder setScheduledAt(DateTime scheduledAt) {
    _scheduledAt = scheduledAt;
    return this;
  }

  SyncQueueBuilder setDependencies(List<String> dependencies) {
    _dependencies = dependencies;
    return this;
  }

  SyncQueueModel build() {
    final now = DateTime.now();

    return SyncQueueModel(
      id: _id ?? now.millisecondsSinceEpoch.toString(),
      userId: _userId ?? '',
      action: _action ?? '',
      collection: _collection ?? '',
      documentId: _documentId,
      data: _data ?? {},
      status: _scheduledAt != null && _scheduledAt!.isAfter(now)
          ? SyncQueueStatus.scheduled
          : SyncQueueStatus.pending,
      priority: _priority ?? 5,
      scheduledAt: _scheduledAt,
      dependencies: _dependencies ?? [],
      createdAt: now,
    );
  }
}

// Predefined sync operations
class SyncOperations {
  /// Create a sync operation for creating a receipt
  static SyncQueueModel createReceipt({
    required String userId,
    required String receiptId,
    required Map<String, dynamic> receiptData,
    int priority = 7,
  }) {
    return SyncQueueBuilder()
        .setUserId(userId)
        .setAction('CREATE')
        .setCollection('receipts')
        .setDocumentId(receiptId)
        .setData(receiptData)
        .setPriority(priority)
        .build();
  }

  /// Create a sync operation for updating a receipt
  static SyncQueueModel updateReceipt({
    required String userId,
    required String receiptId,
    required Map<String, dynamic> receiptData,
    int priority = 6,
  }) {
    return SyncQueueBuilder()
        .setUserId(userId)
        .setAction('UPDATE')
        .setCollection('receipts')
        .setDocumentId(receiptId)
        .setData(receiptData)
        .setPriority(priority)
        .build();
  }

  /// Create a sync operation for deleting a receipt
  static SyncQueueModel deleteReceipt({
    required String userId,
    required String receiptId,
    int priority = 5,
  }) {
    return SyncQueueBuilder()
        .setUserId(userId)
        .setAction('DELETE')
        .setCollection('receipts')
        .setDocumentId(receiptId)
        .setData({})
        .setPriority(priority)
        .build();
  }

  /// Create a sync operation for creating an invoice
  static SyncQueueModel createInvoice({
    required String userId,
    required String invoiceId,
    required Map<String, dynamic> invoiceData,
    int priority = 8,
  }) {
    return SyncQueueBuilder()
        .setUserId(userId)
        .setAction('CREATE')
        .setCollection('invoices')
        .setDocumentId(invoiceId)
        .setData(invoiceData)
        .setPriority(priority)
        .build();
  }

  /// Create a sync operation for updating user preferences
  static SyncQueueModel updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferencesData,
    int priority = 4,
  }) {
    return SyncQueueBuilder()
        .setUserId(userId)
        .setAction('UPDATE')
        .setCollection('users')
        .setDocumentId(userId)
        .setData(preferencesData)
        .setPriority(priority)
        .build();
  }

  /// Create a batch of related sync operations
  static List<SyncQueueModel> createBatch({
    required String batchId,
    required List<SyncQueueModel> operations,
  }) {
    return operations.map((op) => op.copyWith(batchId: batchId)).toList();
  }
}
