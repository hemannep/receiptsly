// lib/services/sync/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus { idle, syncing, success, error, offline }

enum SyncAction { create, update, delete }

enum SyncPriority { low, normal, high, urgent }

class SyncQueueItem {
  final String id;
  final SyncAction action;
  final String collection;
  final String? documentId;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastRetryAt;
  final String? errorMessage;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.collection,
    this.documentId,
    required this.data,
    this.priority = SyncPriority.normal,
    this.retryCount = 0,
    required this.createdAt,
    this.lastRetryAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action.name,
      'collection': collection,
      'document_id': documentId,
      'data': jsonEncode(data),
      'priority': priority.index,
      'retry_count': retryCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_retry_at': lastRetryAt?.millisecondsSinceEpoch,
      'error_message': errorMessage,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      action: SyncAction.values.firstWhere((e) => e.name == map['action']),
      collection: map['collection'],
      documentId: map['document_id'],
      data: jsonDecode(map['data']),
      priority: SyncPriority.values[map['priority'] ?? 1],
      retryCount: map['retry_count'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastRetryAt: map['last_retry_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_retry_at'])
          : null,
      errorMessage: map['error_message'],
    );
  }
}

class SyncResult {
  final bool success;
  final String? error;
  final int processedItems;
  final int failedItems;
  final Duration duration;

  SyncResult({
    required this.success,
    this.error,
    required this.processedItems,
    required this.failedItems,
    required this.duration,
  });
}

class SyncService {
  static const String _dbName = 'receiptsly_sync.db';
  static const int _dbVersion = 1;
  static const int _maxRetries = 3;
  static const int _batchSize = 20;
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryDelay = Duration(seconds: 30);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  Database? _database;
  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<User?>? _authSubscription;

  final StreamController<SyncStatus> _statusController =
      StreamController.broadcast();
  final StreamController<int> _pendingItemsController =
      StreamController.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<int> get pendingItemsStream => _pendingItemsController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  bool _isInitialized = false;
  bool _isSyncing = false;

  // Initialize the sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeDatabase();
      await _setupConnectivityListener();
      await _setupAuthListener();
      await _startPeriodicSync();

      _isInitialized = true;
      debugPrint('SyncService: Initialized successfully');
    } catch (e) {
      debugPrint('SyncService: Initialization failed - $e');
      throw SyncException('Failed to initialize sync service: $e');
    }
  }

  // Initialize local database
  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      _dbName,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  // Create database tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        collection TEXT NOT NULL,
        document_id TEXT,
        data TEXT NOT NULL,
        priority INTEGER DEFAULT 1,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_retry_at INTEGER,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_priority_created 
      ON sync_queue(priority DESC, created_at ASC)
    ''');

    await db.execute('''
      CREATE TABLE sync_conflicts (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        collection TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        resolved INTEGER DEFAULT 0,
        resolution_strategy TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // Upgrade database tables
  Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Setup connectivity listener
  Future<void> _setupConnectivityListener() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
              (ConnectivityResult result) {
                    if (result != ConnectivityResult.none) {
                      _triggerSync();
                    }
                  }
                  as void Function(List<ConnectivityResult> event)?,
            )
            as StreamSubscription<ConnectivityResult>?;
  }

  // Setup auth state listener
  Future<void> _setupAuthListener() async {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _triggerSync();
      }
    });
  }

  // Start periodic sync
  Future<void> _startPeriodicSync() async {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _triggerSync();
    });
  }

  // Add item to sync queue
  Future<void> addToQueue({
    required SyncAction action,
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    if (!_isInitialized) {
      throw SyncException('Sync service not initialized');
    }

    final item = SyncQueueItem(
      id: _uuid.v4(),
      action: action,
      collection: collection,
      documentId: documentId,
      data: data,
      priority: priority,
      createdAt: DateTime.now(),
    );

    await _database!.insert('sync_queue', item.toMap());
    await _updatePendingItemsCount();

    debugPrint('SyncService: Added ${action.name} for $collection to queue');

    // Trigger immediate sync for high priority items
    if (priority == SyncPriority.high || priority == SyncPriority.urgent) {
      _triggerSync();
    }
  }

  // Trigger sync process
  void _triggerSync() {
    if (_isSyncing || !_isInitialized) return;

    Timer(const Duration(milliseconds: 100), () async {
      await performSync();
    });
  }

  // Main sync process
  Future<SyncResult> performSync() async {
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress');
      return SyncResult(
        success: false,
        error: 'Sync already in progress',
        processedItems: 0,
        failedItems: 0,
        duration: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    int processedItems = 0;
    int failedItems = 0;
    String? lastError;

    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _updateStatus(SyncStatus.offline);
        return SyncResult(
          success: false,
          error: 'No internet connection',
          processedItems: 0,
          failedItems: 0,
          duration: stopwatch.elapsed,
        );
      }

      // Check authentication
      if (_auth.currentUser == null) {
        debugPrint('SyncService: User not authenticated');
        return SyncResult(
          success: false,
          error: 'User not authenticated',
          processedItems: 0,
          failedItems: 0,
          duration: stopwatch.elapsed,
        );
      }

      // Process sync queue
      final queueItems = await _getQueueItems();
      debugPrint('SyncService: Processing ${queueItems.length} items');

      for (final item in queueItems) {
        try {
          await _processSyncItem(item);
          await _removeFromQueue(item.id);
          processedItems++;
        } catch (e) {
          debugPrint('SyncService: Failed to process item ${item.id}: $e');
          await _handleSyncFailure(item, e.toString());
          failedItems++;
          lastError = e.toString();
        }
      }

      // Pull remote changes
      await _pullRemoteChanges();

      stopwatch.stop();
      final success = failedItems == 0;

      _updateStatus(success ? SyncStatus.success : SyncStatus.error);

      return SyncResult(
        success: success,
        error: lastError,
        processedItems: processedItems,
        failedItems: failedItems,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('SyncService: Sync failed - $e');
      _updateStatus(SyncStatus.error);

      return SyncResult(
        success: false,
        error: e.toString(),
        processedItems: processedItems,
        failedItems: failedItems,
        duration: stopwatch.elapsed,
      );
    } finally {
      _isSyncing = false;
      await _updatePendingItemsCount();
    }
  }

  // Get items from sync queue
  Future<List<SyncQueueItem>> _getQueueItems() async {
    final result = await _database!.query(
      'sync_queue',
      orderBy: 'priority DESC, created_at ASC',
      limit: _batchSize,
    );

    return result.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  // Process individual sync item
  Future<void> _processSyncItem(SyncQueueItem item) async {
    final userId = _auth.currentUser!.uid;
    item.data['userId'] = userId;
    item.data['syncedAt'] = FieldValue.serverTimestamp();

    switch (item.action) {
      case SyncAction.create:
        await _syncCreate(item);
        break;
      case SyncAction.update:
        await _syncUpdate(item);
        break;
      case SyncAction.delete:
        await _syncDelete(item);
        break;
    }
  }

  // Sync create operation
  Future<void> _syncCreate(SyncQueueItem item) async {
    final docRef = _firestore.collection(item.collection).doc();
    item.data['id'] = docRef.id;

    await docRef.set(item.data);
    debugPrint(
      'SyncService: Created document ${docRef.id} in ${item.collection}',
    );
  }

  // Sync update operation
  Future<void> _syncUpdate(SyncQueueItem item) async {
    if (item.documentId == null) {
      throw SyncException('Document ID required for update operation');
    }

    final docRef = _firestore.collection(item.collection).doc(item.documentId);
    await docRef.update(item.data);
    debugPrint(
      'SyncService: Updated document ${item.documentId} in ${item.collection}',
    );
  }

  // Sync delete operation
  Future<void> _syncDelete(SyncQueueItem item) async {
    if (item.documentId == null) {
      throw SyncException('Document ID required for delete operation');
    }

    final docRef = _firestore.collection(item.collection).doc(item.documentId);
    await docRef.delete();
    debugPrint(
      'SyncService: Deleted document ${item.documentId} from ${item.collection}',
    );
  }

  // Handle sync failure
  Future<void> _handleSyncFailure(SyncQueueItem item, String error) async {
    final newRetryCount = item.retryCount + 1;

    if (newRetryCount >= _maxRetries) {
      debugPrint(
        'SyncService: Max retries reached for item ${item.id}, removing from queue',
      );
      await _removeFromQueue(item.id);

      // Log persistent failure
      await _logPersistentFailure(item, error);
    } else {
      // Update retry count and schedule retry
      await _database!.update(
        'sync_queue',
        {
          'retry_count': newRetryCount,
          'last_retry_at': DateTime.now().millisecondsSinceEpoch,
          'error_message': error,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );

      debugPrint(
        'SyncService: Scheduled retry ${newRetryCount}/$_maxRetries for item ${item.id}',
      );
    }
  }

  // Pull remote changes
  Future<void> _pullRemoteChanges() async {
    try {
      final userId = _auth.currentUser!.uid;
      final lastSyncTime = await _getLastSyncTime();

      // Get receipts changes
      await _pullCollectionChanges('receipts', userId, lastSyncTime);

      // Get invoices changes
      await _pullCollectionChanges('invoices', userId, lastSyncTime);

      // Get clients changes
      await _pullCollectionChanges('clients', userId, lastSyncTime);

      // Update last sync time
      await _setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('SyncService: Failed to pull remote changes - $e');
      throw SyncException('Failed to pull remote changes: $e');
    }
  }

  // Pull changes for specific collection
  Future<void> _pullCollectionChanges(
    String collection,
    String userId,
    DateTime lastSyncTime,
  ) async {
    final query = _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime))
        .orderBy('updatedAt')
        .limit(100);

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      // Check for conflicts with local data
      await _checkAndResolveConflicts(collection, doc);
    }
  }

  // Check and resolve conflicts
  Future<void> _checkAndResolveConflicts(
    String collection,
    QueryDocumentSnapshot doc,
  ) async {
    // Implementation depends on your conflict resolution strategy
    // For now, we'll use last-write-wins

    final remoteData = doc.data() as Map<String, dynamic>;
    final remoteUpdatedAt = (remoteData['updatedAt'] as Timestamp).toDate();

    // Check if document exists locally
    final localData = await _getLocalDocument(collection, doc.id);

    if (localData != null) {
      final localUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
        localData['updatedAt'] ?? 0,
      );

      if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
        // Local is newer, create conflict record
        await _createConflictRecord(collection, doc.id, localData, remoteData);
      } else {
        // Remote is newer, update local
        await _updateLocalDocument(collection, doc.id, remoteData);
      }
    } else {
      // New remote document, save locally
      await _saveLocalDocument(collection, doc.id, remoteData);
    }
  }

  // Create conflict record
  Future<void> _createConflictRecord(
    String collection,
    String documentId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    final conflict = {
      'id': _uuid.v4(),
      'document_id': documentId,
      'collection': collection,
      'local_data': jsonEncode(localData),
      'remote_data': jsonEncode(remoteData),
      'conflict_type': 'data_conflict',
      'resolved': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    await _database!.insert('sync_conflicts', conflict);
    debugPrint(
      'SyncService: Created conflict record for $collection/$documentId',
    );
  }

  // Get local document (placeholder - implement based on your local storage)
  Future<Map<String, dynamic>?> _getLocalDocument(
    String collection,
    String id,
  ) async {
    // Implement based on your local data storage strategy
    return null;
  }

  // Update local document (placeholder)
  Future<void> _updateLocalDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    // Implement based on your local data storage strategy
  }

  // Save local document (placeholder)
  Future<void> _saveLocalDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    // Implement based on your local data storage strategy
  }

  // Get last sync time
  Future<DateTime> _getLastSyncTime() async {
    final result = await _database!.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync_time'],
    );

    if (result.isNotEmpty) {
      final timestamp = int.parse(result.first['value'] as String);
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    // Default to 30 days ago for first sync
    return DateTime.now().subtract(const Duration(days: 30));
  }

  // Set last sync time
  Future<void> _setLastSyncTime(DateTime time) async {
    await _database!.insertOrReplace('sync_metadata', {
      'key': 'last_sync_time',
      'value': time.millisecondsSinceEpoch.toString(),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Remove item from queue
  Future<void> _removeFromQueue(String id) async {
    await _database!.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // Log persistent failure
  Future<void> _logPersistentFailure(SyncQueueItem item, String error) async {
    // Log to analytics or monitoring service
    debugPrint('SyncService: Persistent failure for ${item.id}: $error');
  }

  // Update status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // Update pending items count
  Future<void> _updatePendingItemsCount() async {
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue',
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    _pendingItemsController.add(count);
  }

  // Get current status
  SyncStatus get currentStatus => _currentStatus;

  // Get pending items count
  Future<int> getPendingItemsCount() async {
    if (!_isInitialized) return 0;

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Force sync
  Future<SyncResult> forceSync() async {
    debugPrint('SyncService: Force sync triggered');
    return await performSync();
  }

  // Clear sync queue
  Future<void> clearQueue() async {
    await _database!.delete('sync_queue');
    await _updatePendingItemsCount();
    debugPrint('SyncService: Sync queue cleared');
  }

  // Get sync conflicts
  Future<List<Map<String, dynamic>>> getConflicts() async {
    return await _database!.query(
      'sync_conflicts',
      where: 'resolved = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
  }

  // Resolve conflict
  Future<void> resolveConflict(String conflictId, String strategy) async {
    await _database!.update(
      'sync_conflicts',
      {'resolved': 1, 'resolution_strategy': strategy},
      where: 'id = ?',
      whereArgs: [conflictId],
    );
  }

  // Dispose resources
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    await _statusController.close();
    await _pendingItemsController.close();
    await _database?.close();
    _isInitialized = false;
    debugPrint('SyncService: Disposed');
  }
}

// Custom exception for sync errors
class SyncException implements Exception {
  final String message;

  SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
