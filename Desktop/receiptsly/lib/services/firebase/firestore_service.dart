// lib/services/firebase/firestore_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../local/database_service.dart';

/// Service for managing Firestore operations
/// Handles CRUD operations, real-time listeners, and offline support
class FirestoreService {
  static FirestoreService? _instance;
  late FirebaseFirestore _firestore;
  final DatabaseService _localDb =
      DatabaseService.getInstance() as DatabaseService;

  // Collection names
  static const String collectionUsers = 'users';
  static const String collectionReceipts = 'receipts';
  static const String collectionInvoices = 'invoices';
  static const String collectionClients = 'clients';
  static const String collectionCategories = 'categories';
  static const String collectionSubscriptions = 'subscriptions';
  static const String collectionAnalytics = 'analytics';

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _streamControllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  // Singleton pattern
  FirestoreService._();

  static FirestoreService getInstance() {
    _instance ??= FirestoreService._();
    return _instance!;
  }

  /// Initialize Firestore service
  Future<void> initialize() async {
    try {
      _firestore = FirebaseFirestore.instance;

      // Configure Firestore settings
      await _configureFirestore();

      debugPrint('FirestoreService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FirestoreService: $e');
      rethrow;
    }
  }

  /// Configure Firestore settings
  Future<void> _configureFirestore() async {
    try {
      // Enable offline persistence
      await _firestore.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );

      // Set cache size (50MB)
      _firestore.settings = const Settings(
        cacheSizeBytes: 50 * 1024 * 1024,
        persistenceEnabled: true,
      );

      debugPrint('Firestore configured with offline persistence');
    } catch (e) {
      debugPrint('Error configuring Firestore: $e');
      // Continue without offline persistence if it fails
    }
  }

  // Generic CRUD Operations

  /// Create document
  Future<String> createDocument(
    String collection,
    Map<String, dynamic> data, {
    String? documentId,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      data['createdAt'] = timestamp;
      data['updatedAt'] = timestamp;

      DocumentReference docRef;
      if (documentId != null) {
        docRef = _firestore.collection(collection).doc(documentId);
        await docRef.set(data);
      } else {
        docRef = await _firestore.collection(collection).add(data);
      }

      debugPrint('Document created in $collection: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating document in $collection: $e');
      rethrow;
    }
  }

  /// Read document by ID
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting document from $collection: $e');
      return null;
    }
  }

  /// Update document
  Future<bool> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(collection).doc(documentId).update(data);

      debugPrint('Document updated in $collection: $documentId');
      return true;
    } catch (e) {
      debugPrint('Error updating document in $collection: $e');
      return false;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();

      debugPrint('Document deleted from $collection: $documentId');
      return true;
    } catch (e) {
      debugPrint('Error deleting document from $collection: $e');
      return false;
    }
  }

  /// Soft delete document
  Future<bool> softDeleteDocument(String collection, String documentId) async {
    try {
      await updateDocument(collection, documentId, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error soft deleting document: $e');
      return false;
    }
  }

  /// Query documents
  Future<List<Map<String, dynamic>>> queryDocuments(
    String collection, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error querying documents from $collection: $e');
      return [];
    }
  }

  /// Listen to document changes
  Stream<Map<String, dynamic>?> listenToDocument(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        data['id'] = snapshot.id;
        return data;
      }
      return null;
    });
  }

  /// Listen to collection changes
  Stream<List<Map<String, dynamic>>> listenToCollection(
    String collection, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // User Operations

  /// Create user profile
  Future<bool> createUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await createDocument(collectionUsers, userData, documentId: userId);

      // Create default categories for user
      await _createDefaultUserCategories(userId);

      return true;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await getDocument(collectionUsers, userId);
  }

  /// Update user profile
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return await updateDocument(collectionUsers, userId, updates);
  }

  /// Create default categories for new user
  Future<void> _createDefaultUserCategories(String userId) async {
    try {
      final defaultCategories = [
        {
          'name': 'Food & Dining',
          'color': '#FF6B6B',
          'icon': 'restaurant',
          'userId': userId,
          'isDefault': true,
        },
        {
          'name': 'Transportation',
          'color': '#4ECDC4',
          'icon': 'directions_car',
          'userId': userId,
          'isDefault': true,
        },
        {
          'name': 'Office Supplies',
          'color': '#45B7D1',
          'icon': 'business',
          'userId': userId,
          'isDefault': true,
        },
        {
          'name': 'Software & Technology',
          'color': '#96CEB4',
          'icon': 'computer',
          'userId': userId,
          'isDefault': true,
        },
        {
          'name': 'General',
          'color': '#A8A8A8',
          'icon': 'category',
          'userId': userId,
          'isDefault': true,
        },
      ];

      for (final category in defaultCategories) {
        await createDocument(collectionCategories, category);
      }

      debugPrint('Default categories created for user: $userId');
    } catch (e) {
      debugPrint('Error creating default categories: $e');
    }
  }

  // Receipt Operations

  /// Create receipt
  Future<String?> createReceipt(Map<String, dynamic> receiptData) async {
    try {
      return await createDocument(collectionReceipts, receiptData);
    } catch (e) {
      debugPrint('Error creating receipt: $e');
      return null;
    }
  }

  /// Get receipts for user
  Future<List<Map<String, dynamic>>> getUserReceipts(
    String userId, {
    int? limit,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final filters = <QueryFilter>[
        QueryFilter('userId', isEqualTo: userId),
        QueryFilter('isDeleted', isEqualTo: false),
      ];

      if (category != null) {
        filters.add(QueryFilter('category', isEqualTo: category));
      }

      if (startDate != null) {
        filters.add(
          QueryFilter(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          ),
        );
      }

      if (endDate != null) {
        filters.add(
          QueryFilter('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate)),
        );
      }

      return await queryDocuments(
        collectionReceipts,
        filters: filters,
        orderBy: [QueryOrder('date', descending: true)],
        limit: limit,
        startAfter: startAfter,
      );
    } catch (e) {
      debugPrint('Error getting user receipts: $e');
      return [];
    }
  }

  /// Update receipt
  Future<bool> updateReceipt(
    String receiptId,
    Map<String, dynamic> updates,
  ) async {
    return await updateDocument(collectionReceipts, receiptId, updates);
  }

  /// Delete receipt
  Future<bool> deleteReceipt(String receiptId) async {
    return await softDeleteDocument(collectionReceipts, receiptId);
  }

  /// Listen to user receipts
  Stream<List<Map<String, dynamic>>> listenToUserReceipts(String userId) {
    return listenToCollection(
      collectionReceipts,
      filters: [
        QueryFilter('userId', isEqualTo: userId),
        QueryFilter('isDeleted', isEqualTo: false),
      ],
      orderBy: [QueryOrder('createdAt', descending: true)],
      limit: 50,
    );
  }

  // Invoice Operations

  /// Create invoice
  Future<String?> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      return await createDocument(collectionInvoices, invoiceData);
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      return null;
    }
  }

  /// Get invoices for user
  Future<List<Map<String, dynamic>>> getUserInvoices(
    String userId, {
    String? status,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final filters = <QueryFilter>[
        QueryFilter('userId', isEqualTo: userId),
        QueryFilter('isDeleted', isEqualTo: false),
      ];

      if (status != null) {
        filters.add(QueryFilter('status', isEqualTo: status));
      }

      return await queryDocuments(
        collectionInvoices,
        filters: filters,
        orderBy: [QueryOrder('createdAt', descending: true)],
        limit: limit,
        startAfter: startAfter,
      );
    } catch (e) {
      debugPrint('Error getting user invoices: $e');
      return [];
    }
  }

  /// Update invoice
  Future<bool> updateInvoice(
    String invoiceId,
    Map<String, dynamic> updates,
  ) async {
    return await updateDocument(collectionInvoices, invoiceId, updates);
  }

  /// Listen to user invoices
  Stream<List<Map<String, dynamic>>> listenToUserInvoices(String userId) {
    return listenToCollection(
      collectionInvoices,
      filters: [
        QueryFilter('userId', isEqualTo: userId),
        QueryFilter('isDeleted', isEqualTo: false),
      ],
      orderBy: [QueryOrder('createdAt', descending: true)],
      limit: 50,
    );
  }

  // Client Operations

  /// Create client
  Future<String?> createClient(Map<String, dynamic> clientData) async {
    try {
      return await createDocument(collectionClients, clientData);
    } catch (e) {
      debugPrint('Error creating client: $e');
      return null;
    }
  }

  /// Get clients for user
  Future<List<Map<String, dynamic>>> getUserClients(String userId) async {
    try {
      return await queryDocuments(
        collectionClients,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter('isDeleted', isEqualTo: false),
        ],
        orderBy: [QueryOrder('name')],
      );
    } catch (e) {
      debugPrint('Error getting user clients: $e');
      return [];
    }
  }

  /// Update client
  Future<bool> updateClient(
    String clientId,
    Map<String, dynamic> updates,
  ) async {
    return await updateDocument(collectionClients, clientId, updates);
  }

  /// Delete client
  Future<bool> deleteClient(String clientId) async {
    return await softDeleteDocument(collectionClients, clientId);
  }

  // Category Operations

  /// Create category
  Future<String?> createCategory(Map<String, dynamic> categoryData) async {
    try {
      return await createDocument(collectionCategories, categoryData);
    } catch (e) {
      debugPrint('Error creating category: $e');
      return null;
    }
  }

  /// Get categories for user
  Future<List<Map<String, dynamic>>> getUserCategories(String userId) async {
    try {
      return await queryDocuments(
        collectionCategories,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter('isDeleted', isEqualTo: false),
        ],
        orderBy: [QueryOrder('name')],
      );
    } catch (e) {
      debugPrint('Error getting user categories: $e');
      return [];
    }
  }

  // Batch Operations

  /// Batch write operations
  Future<bool> batchWrite(List<BatchOperation> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _firestore
            .collection(operation.collection)
            .doc(operation.documentId);

        switch (operation.type) {
          case BatchOperationType.create:
          case BatchOperationType.set:
            batch.set(docRef, operation.data!);
            break;
          case BatchOperationType.update:
            batch.update(docRef, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      debugPrint(
        'Batch operation completed with ${operations.length} operations',
      );
      return true;
    } catch (e) {
      debugPrint('Error in batch operation: $e');
      return false;
    }
  }

  // Transaction Operations

  /// Run transaction
  Future<T?> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      debugPrint('Error in transaction: $e');
      return null;
    }
  }

  // Search Operations

  /// Search receipts
  Future<List<Map<String, dynamic>>> searchReceipts(
    String userId,
    String searchTerm, {
    int? limit = 20,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation using array-contains
      // For production, consider using Algolia or similar service

      final searchTermLower = searchTerm.toLowerCase();

      // Search by vendor name
      final vendorResults = await queryDocuments(
        collectionReceipts,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter('isDeleted', isEqualTo: false),
          QueryFilter('vendorLower', isGreaterThanOrEqualTo: searchTermLower),
          QueryFilter('vendorLower', isLessThan: searchTermLower + '\uf8ff'),
        ],
        limit: limit,
      );

      return vendorResults;
    } catch (e) {
      debugPrint('Error searching receipts: $e');
      return [];
    }
  }

  // Analytics Operations

  /// Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final receipts = await queryDocuments(
        collectionReceipts,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter('isDeleted', isEqualTo: false),
          QueryFilter(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          ),
          QueryFilter('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate)),
        ],
      );

      final invoices = await queryDocuments(
        collectionInvoices,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter('isDeleted', isEqualTo: false),
          QueryFilter(
            'issueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          ),
          QueryFilter(
            'issueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          ),
        ],
      );

      // Calculate analytics
      double totalExpenses = 0;
      double totalIncome = 0;
      final categoryBreakdown = <String, double>{};
      int receiptCount = receipts.length;
      int invoiceCount = invoices.length;

      for (final receipt in receipts) {
        final amount = (receipt['amount'] as num?)?.toDouble() ?? 0;
        totalExpenses += amount;

        final category = receipt['category'] as String? ?? 'Uncategorized';
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0) + amount;
      }

      for (final invoice in invoices) {
        final amount = (invoice['totalAmount'] as num?)?.toDouble() ?? 0;
        totalIncome += amount;
      }

      return {
        'totalExpenses': totalExpenses,
        'totalIncome': totalIncome,
        'netIncome': totalIncome - totalExpenses,
        'receiptCount': receiptCount,
        'invoiceCount': invoiceCount,
        'categoryBreakdown': categoryBreakdown,
        'period': {
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': endDate.millisecondsSinceEpoch,
        },
      };
    } catch (e) {
      debugPrint('Error getting user analytics: $e');
      return {};
    }
  }

  // Sync Operations

  /// Get documents that need sync
  Future<List<Map<String, dynamic>>> getDocumentsToSync(
    String userId,
    DateTime lastSyncTime,
  ) async {
    try {
      final documents = <Map<String, dynamic>>[];

      // Get receipts updated after last sync
      final receipts = await queryDocuments(
        collectionReceipts,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter(
            'updatedAt',
            isGreaterThan: Timestamp.fromDate(lastSyncTime),
          ),
        ],
      );

      for (final receipt in receipts) {
        receipt['_collection'] = collectionReceipts;
        documents.add(receipt);
      }

      // Get invoices updated after last sync
      final invoices = await queryDocuments(
        collectionInvoices,
        filters: [
          QueryFilter('userId', isEqualTo: userId),
          QueryFilter(
            'updatedAt',
            isGreaterThan: Timestamp.fromDate(lastSyncTime),
          ),
        ],
      );

      for (final invoice in invoices) {
        invoice['_collection'] = collectionInvoices;
        documents.add(invoice);
      }

      return documents;
    } catch (e) {
      debugPrint('Error getting documents to sync: $e');
      return [];
    }
  }

  // Offline Support

  /// Enable offline persistence
  Future<void> enableOffline() async {
    try {
      await _firestore.enablePersistence();
      debugPrint('Offline persistence enabled');
    } catch (e) {
      debugPrint('Error enabling offline persistence: $e');
    }
  }

  /// Disable offline persistence
  Future<void> disableOffline() async {
    try {
      await _firestore.disablePersistence();
      debugPrint('Offline persistence disabled');
    } catch (e) {
      debugPrint('Error disabling offline persistence: $e');
    }
  }

  /// Wait for pending writes
  Future<void> waitForPendingWrites() async {
    try {
      await _firestore.waitForPendingWrites();
      debugPrint('All pending writes completed');
    } catch (e) {
      debugPrint('Error waiting for pending writes: $e');
    }
  }

  // Real-time Subscriptions Management

  /// Subscribe to real-time updates
  void subscribeToRealTimeUpdates(String userId) {
    try {
      // Subscribe to receipts
      _subscriptions['receipts'] = listenToUserReceipts(userId).listen(
        (receipts) {
          _handleReceiptsUpdate(receipts);
        },
        onError: (error) {
          debugPrint('Error in receipts subscription: $error');
        },
      );

      // Subscribe to invoices
      _subscriptions['invoices'] = listenToUserInvoices(userId).listen(
        (invoices) {
          _handleInvoicesUpdate(invoices);
        },
        onError: (error) {
          debugPrint('Error in invoices subscription: $error');
        },
      );

      debugPrint('Subscribed to real-time updates for user: $userId');
    } catch (e) {
      debugPrint('Error subscribing to real-time updates: $e');
    }
  }

  /// Handle receipts update
  void _handleReceiptsUpdate(List<Map<String, dynamic>> receipts) {
    try {
      // Update local database
      for (final receipt in receipts) {
        _localDb.updateReceipt(receipt['id'], receipt);
      }
      debugPrint(
        'Receipts updated from real-time listener: ${receipts.length}',
      );
    } catch (e) {
      debugPrint('Error handling receipts update: $e');
    }
  }

  /// Handle invoices update
  void _handleInvoicesUpdate(List<Map<String, dynamic>> invoices) {
    try {
      // Update local database
      for (final invoice in invoices) {
        _localDb.updateInvoice(invoice['id'], invoice);
      }
      debugPrint(
        'Invoices updated from real-time listener: ${invoices.length}',
      );
    } catch (e) {
      debugPrint('Error handling invoices update: $e');
    }
  }

  /// Unsubscribe from real-time updates
  void unsubscribeFromRealTimeUpdates() {
    try {
      for (final subscription in _subscriptions.values) {
        subscription.cancel();
      }
      _subscriptions.clear();
      debugPrint('Unsubscribed from all real-time updates');
    } catch (e) {
      debugPrint('Error unsubscribing from real-time updates: $e');
    }
  }

  // Utility Methods

  /// Get document count
  Future<int> getDocumentCount(
    String collection, {
    List<QueryFilter>? filters,
  }) async {
    try {
      final docs = await queryDocuments(collection, filters: filters);
      return docs.length;
    } catch (e) {
      debugPrint('Error getting document count: $e');
      return 0;
    }
  }

  /// Check if document exists
  Future<bool> documentExists(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking document existence: $e');
      return false;
    }
  }

  /// Get last document in collection
  Future<Map<String, dynamic>?> getLastDocument(
    String collection, {
    List<QueryFilter>? filters,
    String orderByField = 'createdAt',
  }) async {
    try {
      final docs = await queryDocuments(
        collection,
        filters: filters,
        orderBy: [QueryOrder(orderByField, descending: true)],
        limit: 1,
      );
      return docs.isNotEmpty ? docs.first : null;
    } catch (e) {
      debugPrint('Error getting last document: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    unsubscribeFromRealTimeUpdates();
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _instance = null;
  }
}

/// Query filter class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter(
    this.field, {
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Query order class
class QueryOrder {
  final String field;
  final bool descending;

  QueryOrder(this.field, {this.descending = false});
}

/// Batch operation class
class BatchOperation {
  final BatchOperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.type,
    required this.collection,
    required this.documentId,
    this.data,
  });
}

/// Batch operation types
enum BatchOperationType { create, set, update, delete }
