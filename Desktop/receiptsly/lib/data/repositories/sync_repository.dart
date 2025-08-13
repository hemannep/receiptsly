// lib/data/repositories/sync_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/i_sync_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/models/sync/sync_queue_model.dart';
import '../../domain/datasources/local/sync_queue_datasource.dart';
import '../../domain/datasources/remote/firebase/receipt_remote_datasource.dart';
import '../../domain/datasources/remote/firebase/invoice_remote_datasource.dart';
import '../../domain/datasources/remote/firebase/client_remote_datasource.dart';
import '../../domain/datasources/remote/firebase/user_remote_datasource.dart';
import '../../domain/datasources/local/receipt_local_datasource.dart';
import '../../domain/datasources/local/invoice_local_datasource.dart';
import '../../domain/datasources/local/client_local_datasource.dart';
import '../../domain/datasources/local/user_local_datasource.dart';

class SyncRepository implements ISyncRepository {
  final SyncQueueDatasource _syncQueueDatasource;
  final ReceiptRemoteDatasource _receiptRemoteDatasource;
  final InvoiceRemoteDatasource _invoiceRemoteDatasource;
  final ClientRemoteDatasource _clientRemoteDatasource;
  final UserRemoteDatasource _userRemoteDatasource;
  final ReceiptLocalDatasource _receiptLocalDatasource;
  final InvoiceLocalDatasource _invoiceLocalDatasource;
  final ClientLocalDatasource _clientLocalDatasource;
  final UserLocalDatasource _userLocalDatasource;
  final Connectivity _connectivity;
  final SharedPreferences _preferences;

  bool _isSyncing = false;
  final _syncController = StreamController<SyncStatus>.broadcast();
  Timer? _periodicSyncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  SyncRepository({
    required SyncQueueDatasource syncQueueDatasource,
    required ReceiptRemoteDatasource receiptRemoteDatasource,
    required InvoiceRemoteDatasource invoiceRemoteDatasource,
    required ClientRemoteDatasource clientRemoteDatasource,
    required UserRemoteDatasource userRemoteDatasource,
    required ReceiptLocalDatasource receiptLocalDatasource,
    required InvoiceLocalDatasource invoiceLocalDatasource,
    required ClientLocalDatasource clientLocalDatasource,
    required UserLocalDatasource userLocalDatasource,
    required Connectivity connectivity,
    required SharedPreferences preferences,
  }) : _syncQueueDatasource = syncQueueDatasource,
       _receiptRemoteDatasource = receiptRemoteDatasource,
       _invoiceRemoteDatasource = invoiceRemoteDatasource,
       _clientRemoteDatasource = clientRemoteDatasource,
       _userRemoteDatasource = userRemoteDatasource,
       _receiptLocalDatasource = receiptLocalDatasource,
       _invoiceLocalDatasource = invoiceLocalDatasource,
       _clientLocalDatasource = clientLocalDatasource,
       _userLocalDatasource = userLocalDatasource,
       _connectivity = connectivity,
       _preferences = preferences;

  @override
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  @override
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        _startAutoSync();
      } else if (result == ConnectivityResult.none) {
        _stopPeriodicSync();
      }
    });

    // Check initial connectivity and start sync if online
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      _startAutoSync();
    }
  }

  @override
  Future<Either<Failure, void>> addToQueue({
    required String action,
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final queueItem = SyncQueueModel(
        id: _generateQueueId(),
        action: action,
        collection: collection,
        documentId: documentId,
        data: jsonEncode(data),
        retryCount: 0,
        priority: _getPriority(collection, action),
        createdAt: DateTime.now(),
        syncedAt: null,
      );

      await _syncQueueDatasource.insertQueueItem(queueItem);

      // Emit updated sync status
      _emitSyncStatus();

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to add to sync queue: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncNow({String? userId}) async {
    if (_isSyncing) {
      return Left(SyncFailure('Sync already in progress'));
    }

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await _performSync(userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Sync failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearQueue() async {
    try {
      await _syncQueueDatasource.clearQueue();
      _emitSyncStatus();
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to clear sync queue: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<SyncQueueModel>>> getPendingItems() async {
    try {
      final items = await _syncQueueDatasource.getPendingItems();
      return Right(items);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get pending items: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getPendingCount() async {
    try {
      final count = await _syncQueueDatasource.getPendingCount();
      return Right(count);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get pending count: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime() async {
    try {
      final timestamp = _preferences.getInt('last_sync_timestamp');
      final lastSync = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
      return Right(lastSync);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get last sync time: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setSyncInterval(Duration interval) async {
    try {
      await _preferences.setInt('sync_interval_minutes', interval.inMinutes);
      _stopPeriodicSync();
      _startPeriodicSync(interval);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set sync interval: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isAutoSyncEnabled() async {
    try {
      final isEnabled = _preferences.getBool('auto_sync_enabled') ?? true;
      return Right(isEnabled);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get auto sync status: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setAutoSyncEnabled(bool enabled) async {
    try {
      await _preferences.setBool('auto_sync_enabled', enabled);

      if (enabled) {
        _startAutoSync();
      } else {
        _stopPeriodicSync();
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to set auto sync: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> retryFailedItems() async {
    try {
      final failedItems = await _syncQueueDatasource.getFailedItems();

      for (final item in failedItems) {
        // Reset retry count and update timestamp
        final resetItem = item.copyWith(
          retryCount: 0,
          createdAt: DateTime.now(),
        );

        await _syncQueueDatasource.updateQueueItem(resetItem);
      }

      // Trigger sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        _startAutoSync();
      }

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to retry failed items: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> pullRemoteChanges({String? userId}) async {
    if (userId == null) return const Right(null);

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      final lastSyncTime = _preferences.getInt('last_pull_sync_timestamp') ?? 0;

      // Pull receipts
      await _pullReceiptChanges(userId, lastSyncTime);

      // Pull invoices
      await _pullInvoiceChanges(userId, lastSyncTime);

      // Pull clients
      await _pullClientChanges(userId, lastSyncTime);

      // Update last pull sync time
      await _preferences.setInt(
        'last_pull_sync_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      return const Right(null);
    } catch (e) {
      return Left(
        SyncFailure('Failed to pull remote changes: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resolveConflicts() async {
    try {
      final conflicts = await _syncQueueDatasource.getConflicts();

      for (final conflict in conflicts) {
        try {
          await _resolveConflict(conflict);
        } catch (e) {
          // Log error but continue with other conflicts
          print('Failed to resolve conflict ${conflict.id}: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Failed to resolve conflicts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> forceFullSync({String? userId}) async {
    try {
      // Clear last sync timestamps to force full sync
      await _preferences.remove('last_sync_timestamp');
      await _preferences.remove('last_pull_sync_timestamp');

      // Perform full sync
      await _performSync(userId: userId, isFullSync: true);

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Failed to perform full sync: ${e.toString()}'));
    }
  }

  @override
  void dispose() {
    _stopPeriodicSync();
    _connectivitySubscription?.cancel();
    _syncController.close();
  }

  // Private methods
  Future<void> _performSync({String? userId, bool isFullSync = false}) async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      _emitSyncStatus(isSyncing: true);

      // Step 1: Process local queue (push changes)
      await _processLocalQueue();

      // Step 2: Pull remote changes if user is provided
      if (userId != null) {
        await pullRemoteChanges(userId: userId);
      }

      // Step 3: Resolve any conflicts
      await resolveConflicts();

      // Update last sync time
      await _preferences.setInt(
        'last_sync_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      _emitSyncStatus(
        isSyncing: false,
        success: true,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      _emitSyncStatus(isSyncing: false, error: e.toString());
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processLocalQueue() async {
    final pendingItems = await _syncQueueDatasource.getPendingItems(limit: 50);

    for (final item in pendingItems) {
      try {
        await _processSyncItem(item);

        // Mark as synced
        await _syncQueueDatasource.markAsSynced(item.id);
      } catch (e) {
        // Increment retry count
        final updatedItem = item.copyWith(retryCount: item.retryCount + 1);

        if (updatedItem.retryCount >= 3) {
          // Mark as failed after max retries
          await _syncQueueDatasource.markAsFailed(item.id);
        } else {
          await _syncQueueDatasource.updateQueueItem(updatedItem);
        }

        print('Failed to sync item ${item.id}: $e');
      }
    }
  }

  Future<void> _processSyncItem(SyncQueueModel item) async {
    final data = jsonDecode(item.data);

    switch (item.collection) {
      case 'receipts':
        await _processReceiptSync(item.action, data, item.documentId);
        break;
      case 'invoices':
        await _processInvoiceSync(item.action, data, item.documentId);
        break;
      case 'clients':
        await _processClientSync(item.action, data, item.documentId);
        break;
      case 'users':
        await _processUserSync(item.action, data, item.documentId);
        break;
      default:
        throw Exception('Unknown collection: ${item.collection}');
    }
  }

  Future<void> _processReceiptSync(
    String action,
    Map<String, dynamic> data,
    String? documentId,
  ) async {
    switch (action) {
      case 'CREATE':
        final receipt = ReceiptModel.fromJson(data);
        await _receiptRemoteDatasource.createReceipt(receipt);
        break;
      case 'UPDATE':
        if (documentId == null)
          throw Exception('Document ID required for update');
        final receipt = ReceiptModel.fromJson(data);
        await _receiptRemoteDatasource.updateReceipt(receipt);
        break;
      case 'DELETE':
        if (documentId == null)
          throw Exception('Document ID required for delete');
        await _receiptRemoteDatasource.deleteReceipt(documentId);
        break;
    }
  }

  Future<void> _processInvoiceSync(
    String action,
    Map<String, dynamic> data,
    String? documentId,
  ) async {
    switch (action) {
      case 'CREATE':
        final invoice = InvoiceModel.fromJson(data);
        await _invoiceRemoteDatasource.createInvoice(invoice);
        break;
      case 'UPDATE':
        if (documentId == null)
          throw Exception('Document ID required for update');
        final invoice = InvoiceModel.fromJson(data);
        await _invoiceRemoteDatasource.updateInvoice(invoice);
        break;
      case 'DELETE':
        if (documentId == null)
          throw Exception('Document ID required for delete');
        await _invoiceRemoteDatasource.deleteInvoice(documentId);
        break;
    }
  }

  Future<void> _processClientSync(
    String action,
    Map<String, dynamic> data,
    String? documentId,
  ) async {
    switch (action) {
      case 'CREATE':
        final client = ClientModel.fromJson(data);
        await _clientRemoteDatasource.createClient(client);
        break;
      case 'UPDATE':
        if (documentId == null)
          throw Exception('Document ID required for update');
        final client = ClientModel.fromJson(data);
        await _clientRemoteDatasource.updateClient(client);
        break;
      case 'DELETE':
        if (documentId == null)
          throw Exception('Document ID required for delete');
        await _clientRemoteDatasource.deleteClient(documentId);
        break;
    }
  }

  Future<void> _processUserSync(
    String action,
    Map<String, dynamic> data,
    String? documentId,
  ) async {
    switch (action) {
      case 'UPDATE':
        if (documentId == null)
          throw Exception('Document ID required for update');
        final user = UserModel.fromJson(data);
        await _userRemoteDatasource.updateUser(user);
        break;
    }
  }

  Future<void> _pullReceiptChanges(String userId, int lastSyncTime) async {
    final remoteReceipts = await _receiptRemoteDatasource
        .getReceiptsUpdatedAfter(userId: userId, timestamp: lastSyncTime);

    for (final remoteReceipt in remoteReceipts) {
      final localReceipt = await _receiptLocalDatasource.getReceiptById(
        remoteReceipt.id,
      );

      if (localReceipt == null) {
        // New remote receipt
        await _receiptLocalDatasource.insertReceipt(remoteReceipt);
      } else {
        // Check for conflicts
        if (localReceipt.updatedAt.isAfter(remoteReceipt.updatedAt) &&
            localReceipt.syncStatus == SyncStatus.pending) {
          // Local is newer - create conflict
          await _createConflict(
            'receipts',
            remoteReceipt.id,
            localReceipt.toJson(),
            remoteReceipt.toJson(),
          );
        } else {
          // Remote is newer or local is already synced - update local
          await _receiptLocalDatasource.updateReceipt(remoteReceipt);
        }
      }
    }
  }

  Future<void> _pullInvoiceChanges(String userId, int lastSyncTime) async {
    final remoteInvoices = await _invoiceRemoteDatasource
        .getInvoicesUpdatedAfter(userId: userId, timestamp: lastSyncTime);

    for (final remoteInvoice in remoteInvoices) {
      final localInvoice = await _invoiceLocalDatasource.getInvoiceById(
        remoteInvoice.id,
      );

      if (localInvoice == null) {
        // New remote invoice
        await _invoiceLocalDatasource.insertInvoice(remoteInvoice);
      } else {
        // Check for conflicts
        if (localInvoice.updatedAt.isAfter(remoteInvoice.updatedAt) &&
            localInvoice.syncStatus == SyncStatus.pending) {
          // Local is newer - create conflict
          await _createConflict(
            'invoices',
            remoteInvoice.id,
            localInvoice.toJson(),
            remoteInvoice.toJson(),
          );
        } else {
          // Remote is newer or local is already synced - update local
          await _invoiceLocalDatasource.updateInvoice(remoteInvoice);
        }
      }
    }
  }

  Future<void> _pullClientChanges(String userId, int lastSyncTime) async {
    final remoteClients = await _clientRemoteDatasource.getClientsUpdatedAfter(
      userId: userId,
      timestamp: lastSyncTime,
    );

    for (final remoteClient in remoteClients) {
      final localClient = await _clientLocalDatasource.getClientById(
        remoteClient.id,
      );

      if (localClient == null) {
        // New remote client
        await _clientLocalDatasource.insertClient(remoteClient);
      } else {
        // Check for conflicts
        if (localClient.updatedAt.isAfter(remoteClient.updatedAt) &&
            localClient.syncStatus == SyncStatus.pending) {
          // Local is newer - create conflict
          await _createConflict(
            'clients',
            remoteClient.id,
            localClient.toJson(),
            remoteClient.toJson(),
          );
        } else {
          // Remote is newer or local is already synced - update local
          await _clientLocalDatasource.updateClient(remoteClient);
        }
      }
    }
  }

  Future<void> _createConflict(
    String collection,
    String documentId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    await _syncQueueDatasource.createConflict(
      collection: collection,
      documentId: documentId,
      localData: jsonEncode(localData),
      remoteData: jsonEncode(remoteData),
    );
  }

  Future<void> _resolveConflict(SyncConflictModel conflict) async {
    // Default resolution strategy: last-write-wins
    final localData = jsonDecode(conflict.localData);
    final remoteData = jsonDecode(conflict.remoteData);

    final localTimestamp = DateTime.parse(localData['updatedAt']);
    final remoteTimestamp = DateTime.parse(remoteData['updatedAt']);

    if (localTimestamp.isAfter(remoteTimestamp)) {
      // Keep local version - sync to remote
      await _syncLocalToRemote(
        conflict.collection,
        conflict.documentId,
        localData,
      );
    } else {
      // Keep remote version - update local
      await _syncRemoteToLocal(
        conflict.collection,
        conflict.documentId,
        remoteData,
      );
    }

    // Mark conflict as resolved
    await _syncQueueDatasource.markConflictResolved(conflict.id);
  }

  Future<void> _syncLocalToRemote(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    switch (collection) {
      case 'receipts':
        final receipt = ReceiptModel.fromJson(data);
        await _receiptRemoteDatasource.updateReceipt(receipt);
        break;
      case 'invoices':
        final invoice = InvoiceModel.fromJson(data);
        await _invoiceRemoteDatasource.updateInvoice(invoice);
        break;
      case 'clients':
        final client = ClientModel.fromJson(data);
        await _clientRemoteDatasource.updateClient(client);
        break;
    }
  }

  Future<void> _syncRemoteToLocal(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    switch (collection) {
      case 'receipts':
        final receipt = ReceiptModel.fromJson(data);
        await _receiptLocalDatasource.updateReceipt(receipt);
        break;
      case 'invoices':
        final invoice = InvoiceModel.fromJson(data);
        await _invoiceLocalDatasource.updateInvoice(invoice);
        break;
      case 'clients':
        final client = ClientModel.fromJson(data);
        await _clientLocalDatasource.updateClient(client);
        break;
    }
  }

  void _startAutoSync() async {
    final isAutoSyncEnabled = await this.isAutoSyncEnabled();
    if (isAutoSyncEnabled.isRight() &&
        isAutoSyncEnabled.getOrElse(() => false)) {
      _startPeriodicSync();
    }
  }

  void _startPeriodicSync([Duration? customInterval]) {
    _stopPeriodicSync();

    final intervalMinutes =
        customInterval?.inMinutes ??
        _preferences.getInt('sync_interval_minutes') ??
        30; // Default 30 minutes

    final interval = Duration(minutes: intervalMinutes);

    _periodicSyncTimer = Timer.periodic(interval, (timer) async {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none && !_isSyncing) {
        try {
          await _performSync();
        } catch (e) {
          print('Periodic sync failed: $e');
        }
      }
    });
  }

  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  void _emitSyncStatus({
    bool? isSyncing,
    bool? success,
    String? error,
    DateTime? lastSyncTime,
  }) async {
    final pendingCount = await _syncQueueDatasource.getPendingCount();
    final failedCount = await _syncQueueDatasource.getFailedCount();
    final lastSync =
        lastSyncTime ??
        ((_preferences.getInt('last_sync_timestamp') != null)
            ? DateTime.fromMillisecondsSinceEpoch(
                _preferences.getInt('last_sync_timestamp')!,
              )
            : null);

    final status = SyncStatus(
      isSyncing: isSyncing ?? _isSyncing,
      pendingItems: pendingCount,
      failedItems: failedCount,
      lastSyncTime: lastSync,
      success: success,
      error: error,
    );

    _syncController.add(status);
  }

  int _getPriority(String collection, String action) {
    // Higher priority for user data and creates
    switch (collection) {
      case 'users':
        return action == 'UPDATE' ? 1 : 5;
      case 'clients':
        return action == 'CREATE'
            ? 2
            : action == 'UPDATE'
            ? 3
            : 4;
      case 'receipts':
        return action == 'CREATE'
            ? 3
            : action == 'UPDATE'
            ? 4
            : 5;
      case 'invoices':
        return action == 'CREATE'
            ? 3
            : action == 'UPDATE'
            ? 4
            : 5;
      default:
        return 5;
    }
  }

  String _generateQueueId() {
    return 'queue_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[random % chars.length],
    ).join();
  }
}

// Sync Status Model
class SyncStatus {
  final bool isSyncing;
  final int pendingItems;
  final int failedItems;
  final DateTime? lastSyncTime;
  final bool? success;
  final String? error;

  const SyncStatus({
    required this.isSyncing,
    required this.pendingItems,
    required this.failedItems,
    this.lastSyncTime,
    this.success,
    this.error,
  });

  @override
  String toString() {
    return 'SyncStatus(isSyncing: $isSyncing, pending: $pendingItems, failed: $failedItems, '
        'lastSync: $lastSyncTime, success: $success, error: $error)';
  }
}

// Sync Conflict Model
class SyncConflictModel {
  final String id;
  final String collection;
  final String documentId;
  final String localData;
  final String remoteData;
  final bool resolved;
  final String? resolutionStrategy;
  final DateTime createdAt;

  const SyncConflictModel({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.localData,
    required this.remoteData,
    required this.resolved,
    this.resolutionStrategy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection': collection,
      'documentId': documentId,
      'localData': localData,
      'remoteData': remoteData,
      'resolved': resolved,
      'resolutionStrategy': resolutionStrategy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncConflictModel.fromJson(Map<String, dynamic> json) {
    return SyncConflictModel(
      id: json['id'],
      collection: json['collection'],
      documentId: json['documentId'],
      localData: json['localData'],
      remoteData: json['remoteData'],
      resolved: json['resolved'],
      resolutionStrategy: json['resolutionStrategy'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
