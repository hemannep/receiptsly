// lib/services/local/database_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing local SQLite database operations
/// Handles offline data storage, sync queue, and cache management
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  static const String _databaseName = 'receiptsly_local.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableReceipts = 'receipts';
  static const String tableInvoices = 'invoices';
  static const String tableClients = 'clients';
  static const String tableCategories = 'categories';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableOfflineActions = 'offline_actions';
  static const String tableUserSettings = 'user_settings';
  static const String tableCache = 'cache';
  static const String tableConflicts = 'conflicts';

  // Singleton pattern
  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    _instance ??= DatabaseService._();
    await _instance!._initDatabase();
    return _instance!;
  }

  /// Initialize the database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      debugPrint('Initializing database at: $path');

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
        onOpen: _onDatabaseOpen,
      );

      await _performInitialSetup();
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    final batch = db.batch();

    // Receipts table
    batch.execute('''
      CREATE TABLE $tableReceipts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        vendor TEXT,
        amount REAL,
        currency TEXT DEFAULT 'USD',
        date INTEGER,
        category TEXT,
        description TEXT,
        image_url TEXT,
        thumbnail_url TEXT,
        ocr_data TEXT,
        confidence_score REAL,
        status TEXT DEFAULT 'pending',
        tags TEXT,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    // Invoices table
    batch.execute('''
      CREATE TABLE $tableInvoices (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT,
        invoice_number TEXT,
        title TEXT,
        description TEXT,
        amount REAL,
        currency TEXT DEFAULT 'USD',
        tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        total_amount REAL,
        status TEXT DEFAULT 'draft',
        issue_date INTEGER,
        due_date INTEGER,
        paid_date INTEGER,
        line_items TEXT,
        notes TEXT,
        terms TEXT,
        payment_link TEXT,
        pdf_url TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    // Clients table
    batch.execute('''
      CREATE TABLE $tableClients (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        company TEXT,
        address TEXT,
        tax_id TEXT,
        payment_terms INTEGER DEFAULT 30,
        currency TEXT DEFAULT 'USD',
        notes TEXT,
        avatar_url TEXT,
        is_active INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    // Categories table
    batch.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT,
        icon TEXT,
        is_default INTEGER DEFAULT 0,
        parent_id TEXT,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    // Sync queue table
    batch.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 3,
        last_error TEXT,
        is_processed INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        processed_at INTEGER
      )
    ''');

    // Offline actions table
    batch.execute('''
      CREATE TABLE $tableOfflineActions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        target_table TEXT NOT NULL,
        target_id TEXT NOT NULL,
        action_data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0,
        conflict_resolution TEXT
      )
    ''');

    // User settings table
    batch.execute('''
      CREATE TABLE $tableUserSettings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        setting_key TEXT NOT NULL,
        setting_value TEXT NOT NULL,
        data_type TEXT DEFAULT 'string',
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(user_id, setting_key)
      )
    ''');

    // Cache table
    batch.execute('''
      CREATE TABLE $tableCache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cache_key TEXT UNIQUE NOT NULL,
        cache_value TEXT NOT NULL,
        cache_type TEXT DEFAULT 'json',
        expires_at INTEGER,
        created_at INTEGER NOT NULL,
        accessed_at INTEGER NOT NULL
      )
    ''');

    // Conflicts table
    batch.execute('''
      CREATE TABLE $tableConflicts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        resolution_strategy TEXT,
        is_resolved INTEGER DEFAULT 0,
        resolved_by TEXT,
        created_at INTEGER NOT NULL,
        resolved_at INTEGER
      )
    ''');

    // Create indexes for better performance
    batch.execute(
      'CREATE INDEX idx_receipts_user_id ON $tableReceipts(user_id)',
    );
    batch.execute('CREATE INDEX idx_receipts_date ON $tableReceipts(date)');
    batch.execute(
      'CREATE INDEX idx_receipts_category ON $tableReceipts(category)',
    );
    batch.execute(
      'CREATE INDEX idx_receipts_sync ON $tableReceipts(is_synced)',
    );

    batch.execute(
      'CREATE INDEX idx_invoices_user_id ON $tableInvoices(user_id)',
    );
    batch.execute(
      'CREATE INDEX idx_invoices_client_id ON $tableInvoices(client_id)',
    );
    batch.execute('CREATE INDEX idx_invoices_status ON $tableInvoices(status)');
    batch.execute(
      'CREATE INDEX idx_invoices_sync ON $tableInvoices(is_synced)',
    );

    batch.execute('CREATE INDEX idx_clients_user_id ON $tableClients(user_id)');
    batch.execute('CREATE INDEX idx_clients_sync ON $tableClients(is_synced)');

    batch.execute(
      'CREATE INDEX idx_categories_user_id ON $tableCategories(user_id)',
    );
    batch.execute(
      'CREATE INDEX idx_categories_parent ON $tableCategories(parent_id)',
    );

    batch.execute(
      'CREATE INDEX idx_sync_queue_processed ON $tableSyncQueue(is_processed)',
    );
    batch.execute(
      'CREATE INDEX idx_sync_queue_priority ON $tableSyncQueue(priority)',
    );

    batch.execute('CREATE INDEX idx_cache_key ON $tableCache(cache_key)');
    batch.execute('CREATE INDEX idx_cache_expires ON $tableCache(expires_at)');

    await batch.commit();
    debugPrint('Database tables created successfully');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    // Add migration logic here when needed
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE $tableReceipts ADD COLUMN new_column TEXT');
    }
  }

  /// Called when database is opened
  Future<void> _onDatabaseOpen(Database db) async {
    debugPrint('Database opened successfully');
    await _cleanupExpiredCache();
  }

  /// Perform initial setup
  Future<void> _performInitialSetup() async {
    try {
      await _createDefaultCategories();
      await _cleanupOrphanedRecords();
      debugPrint('Initial database setup completed');
    } catch (e) {
      debugPrint('Error during initial setup: $e');
    }
  }

  /// Create default expense categories
  Future<void> _createDefaultCategories() async {
    try {
      final count = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $tableCategories WHERE is_default = 1',
      );

      if ((count.first['count'] as int) > 0) return;

      final defaultCategories = [
        {'name': 'Food & Dining', 'color': '#FF6B6B', 'icon': 'restaurant'},
        {
          'name': 'Transportation',
          'color': '#4ECDC4',
          'icon': 'directions_car',
        },
        {'name': 'Office Supplies', 'color': '#45B7D1', 'icon': 'business'},
        {
          'name': 'Software & Technology',
          'color': '#96CEB4',
          'icon': 'computer',
        },
        {'name': 'Marketing', 'color': '#FFEAA7', 'icon': 'campaign'},
        {'name': 'Travel', 'color': '#DDA0DD', 'icon': 'flight'},
        {'name': 'Professional Services', 'color': '#98D8C8', 'icon': 'work'},
        {'name': 'General', 'color': '#A8A8A8', 'icon': 'category'},
      ];

      final batch = _database!.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < defaultCategories.length; i++) {
        final category = defaultCategories[i];
        batch.insert(tableCategories, {
          'id': 'default_category_$i',
          'user_id': 'system',
          'name': category['name'],
          'color': category['color'],
          'icon': category['icon'],
          'is_default': 1,
          'sort_order': i,
          'is_active': 1,
          'is_synced': 1,
          'created_at': now,
          'updated_at': now,
        });
      }

      await batch.commit();
      debugPrint('Default categories created');
    } catch (e) {
      debugPrint('Error creating default categories: $e');
    }
  }

  // CRUD Operations

  /// Insert a record
  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      data['created_at'] = DateTime.now().millisecondsSinceEpoch;
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      final result = await _database!.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Inserted record in $table with result: $result');
      return result;
    } catch (e) {
      debugPrint('Error inserting into $table: $e');
      rethrow;
    }
  }

  /// Update a record
  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    try {
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      final result = await _database!.update(
        table,
        data,
        where: whereClause,
        whereArgs: whereArgs,
      );

      debugPrint('Updated $result record(s) in $table');
      return result;
    } catch (e) {
      debugPrint('Error updating $table: $e');
      rethrow;
    }
  }

  /// Delete a record
  Future<int> delete(
    String table,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    try {
      final result = await _database!.delete(
        table,
        where: whereClause,
        whereArgs: whereArgs,
      );

      debugPrint('Deleted $result record(s) from $table');
      return result;
    } catch (e) {
      debugPrint('Error deleting from $table: $e');
      rethrow;
    }
  }

  /// Soft delete a record
  Future<int> softDelete(
    String table,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    return await update(table, {'is_deleted': 1}, whereClause, whereArgs);
  }

  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await _database!.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      return result;
    } catch (e) {
      debugPrint('Error querying $table: $e');
      rethrow;
    }
  }

  /// Raw query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    try {
      return await _database!.rawQuery(sql, arguments);
    } catch (e) {
      debugPrint('Error executing raw query: $e');
      rethrow;
    }
  }

  /// Execute raw SQL
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    try {
      await _database!.execute(sql, arguments);
    } catch (e) {
      debugPrint('Error executing SQL: $e');
      rethrow;
    }
  }

  // Receipt Operations

  /// Insert receipt
  Future<String> insertReceipt(Map<String, dynamic> receipt) async {
    try {
      receipt['id'] ??= _generateId();
      await insert(tableReceipts, receipt);
      return receipt['id'] as String;
    } catch (e) {
      debugPrint('Error inserting receipt: $e');
      rethrow;
    }
  }

  /// Get receipts for user
  Future<List<Map<String, dynamic>>> getReceipts(
    String userId, {
    int? limit,
    int? offset,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      var whereClause = 'user_id = ? AND is_deleted = 0';
      var whereArgs = <dynamic>[userId];

      if (category != null) {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }

      if (startDate != null) {
        whereClause += ' AND date >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause += ' AND date <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause +=
            ' AND (vendor LIKE ? OR description LIKE ? OR notes LIKE ?)';
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      return await query(
        tableReceipts,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'date DESC, created_at DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting receipts: $e');
      return [];
    }
  }

  /// Get receipt by ID
  Future<Map<String, dynamic>?> getReceiptById(String id) async {
    try {
      final results = await query(
        tableReceipts,
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('Error getting receipt by ID: $e');
      return null;
    }
  }

  /// Update receipt
  Future<bool> updateReceipt(String id, Map<String, dynamic> updates) async {
    try {
      final result = await update(tableReceipts, updates, 'id = ?', [id]);
      return result > 0;
    } catch (e) {
      debugPrint('Error updating receipt: $e');
      return false;
    }
  }

  /// Delete receipt
  Future<bool> deleteReceipt(String id) async {
    try {
      final result = await softDelete(tableReceipts, 'id = ?', [id]);
      return result > 0;
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
      return false;
    }
  }

  /// Get receipts statistics
  Future<Map<String, dynamic>> getReceiptStats(String userId) async {
    try {
      final results = await rawQuery(
        '''
        SELECT 
          COUNT(*) as total_count,
          SUM(amount) as total_amount,
          AVG(amount) as average_amount,
          COUNT(CASE WHEN is_synced = 0 THEN 1 END) as unsynced_count
        FROM $tableReceipts 
        WHERE user_id = ? AND is_deleted = 0
      ''',
        [userId],
      );

      return results.isNotEmpty ? results.first : {};
    } catch (e) {
      debugPrint('Error getting receipt stats: $e');
      return {};
    }
  }

  // Invoice Operations

  /// Insert invoice
  Future<String> insertInvoice(Map<String, dynamic> invoice) async {
    try {
      invoice['id'] ??= _generateId();
      await insert(tableInvoices, invoice);
      return invoice['id'] as String;
    } catch (e) {
      debugPrint('Error inserting invoice: $e');
      rethrow;
    }
  }

  /// Get invoices for user
  Future<List<Map<String, dynamic>>> getInvoices(
    String userId, {
    int? limit,
    int? offset,
    String? status,
    String? clientId,
  }) async {
    try {
      var whereClause = 'user_id = ? AND is_deleted = 0';
      var whereArgs = <dynamic>[userId];

      if (status != null) {
        whereClause += ' AND status = ?';
        whereArgs.add(status);
      }

      if (clientId != null) {
        whereClause += ' AND client_id = ?';
        whereArgs.add(clientId);
      }

      return await query(
        tableInvoices,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting invoices: $e');
      return [];
    }
  }

  /// Get invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String id) async {
    try {
      final results = await query(
        tableInvoices,
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('Error getting invoice by ID: $e');
      return null;
    }
  }

  /// Update invoice
  Future<bool> updateInvoice(String id, Map<String, dynamic> updates) async {
    try {
      final result = await update(tableInvoices, updates, 'id = ?', [id]);
      return result > 0;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  // Client Operations

  /// Insert client
  Future<String> insertClient(Map<String, dynamic> client) async {
    try {
      client['id'] ??= _generateId();
      await insert(tableClients, client);
      return client['id'] as String;
    } catch (e) {
      debugPrint('Error inserting client: $e');
      rethrow;
    }
  }

  /// Get clients for user
  Future<List<Map<String, dynamic>>> getClients(
    String userId, {
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      var whereClause = 'user_id = ? AND is_deleted = 0';
      var whereArgs = <dynamic>[userId];

      if (isActive != null) {
        whereClause += ' AND is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause += ' AND (name LIKE ? OR email LIKE ? OR company LIKE ?)';
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      return await query(
        tableClients,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );
    } catch (e) {
      debugPrint('Error getting clients: $e');
      return [];
    }
  }

  // Category Operations

  /// Get categories for user
  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    try {
      return await query(
        tableCategories,
        where:
            '(user_id = ? OR user_id = ?) AND is_deleted = 0 AND is_active = 1',
        whereArgs: [userId, 'system'],
        orderBy: 'sort_order ASC, name ASC',
      );
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  /// Insert category
  Future<String> insertCategory(Map<String, dynamic> category) async {
    try {
      category['id'] ??= _generateId();
      await insert(tableCategories, category);
      return category['id'] as String;
    } catch (e) {
      debugPrint('Error inserting category: $e');
      rethrow;
    }
  }

  // Sync Queue Operations

  /// Add to sync queue
  Future<void> addToSyncQueue({
    required String action,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    try {
      await insert(tableSyncQueue, {
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'data': jsonEncode(data),
        'priority': priority,
        'retry_count': 0,
        'is_processed': 0,
      });
      debugPrint('Added to sync queue: $action $tableName $recordId');
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }

  /// Get sync queue items
  Future<List<Map<String, dynamic>>> getSyncQueueItems({int? limit}) async {
    try {
      return await query(
        tableSyncQueue,
        where: 'is_processed = 0 AND retry_count < max_retries',
        orderBy: 'priority DESC, created_at ASC',
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting sync queue items: $e');
      return [];
    }
  }

  /// Mark sync queue item as processed
  Future<void> markSyncItemProcessed(int itemId) async {
    try {
      await update(
        tableSyncQueue,
        {
          'is_processed': 1,
          'processed_at': DateTime.now().millisecondsSinceEpoch,
        },
        'id = ?',
        [itemId],
      );
    } catch (e) {
      debugPrint('Error marking sync item as processed: $e');
    }
  }

  /// Increment sync retry count
  Future<void> incrementSyncRetry(int itemId, String error) async {
    try {
      await rawQuery(
        '''
        UPDATE $tableSyncQueue 
        SET retry_count = retry_count + 1, last_error = ? 
        WHERE id = ?
      ''',
        [error, itemId],
      );
    } catch (e) {
      debugPrint('Error incrementing sync retry: $e');
    }
  }

  // Cache Operations

  /// Set cache value
  Future<void> setCache(
    String key,
    dynamic value, {
    Duration? expiry,
    String type = 'json',
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = expiry != null
          ? DateTime.now().add(expiry).millisecondsSinceEpoch
          : null;

      String cacheValue;
      if (type == 'json') {
        cacheValue = jsonEncode(value);
      } else {
        cacheValue = value.toString();
      }

      await _database!.insert(tableCache, {
        'cache_key': key,
        'cache_value': cacheValue,
        'cache_type': type,
        'expires_at': expiresAt,
        'created_at': now,
        'accessed_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error setting cache: $e');
    }
  }

  /// Get cache value
  Future<T?> getCache<T>(String key) async {
    try {
      final results = await query(
        tableCache,
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final cache = results.first;
      final expiresAt = cache['expires_at'] as int?;

      // Check if expired
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await deleteCache(key);
        return null;
      }

      // Update access time
      await update(
        tableCache,
        {'accessed_at': DateTime.now().millisecondsSinceEpoch},
        'cache_key = ?',
        [key],
      );

      final value = cache['cache_value'] as String;
      final type = cache['cache_type'] as String;

      if (type == 'json') {
        return jsonDecode(value) as T;
      } else {
        return value as T;
      }
    } catch (e) {
      debugPrint('Error getting cache: $e');
      return null;
    }
  }

  /// Delete cache entry
  Future<void> deleteCache(String key) async {
    try {
      await delete(tableCache, 'cache_key = ?', [key]);
    } catch (e) {
      debugPrint('Error deleting cache: $e');
    }
  }

  /// Clean expired cache
  Future<void> _cleanupExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await delete(tableCache, 'expires_at IS NOT NULL AND expires_at < ?', [
        now,
      ]);
      debugPrint('Expired cache cleaned up');
    } catch (e) {
      debugPrint('Error cleaning expired cache: $e');
    }
  }

  // Conflict Resolution

  /// Add conflict
  Future<void> addConflict({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required String conflictType,
  }) async {
    try {
      await insert(tableConflicts, {
        'table_name': tableName,
        'record_id': recordId,
        'local_data': jsonEncode(localData),
        'remote_data': jsonEncode(remoteData),
        'conflict_type': conflictType,
        'is_resolved': 0,
      });
    } catch (e) {
      debugPrint('Error adding conflict: $e');
    }
  }

  /// Get unresolved conflicts
  Future<List<Map<String, dynamic>>> getUnresolvedConflicts() async {
    try {
      return await query(
        tableConflicts,
        where: 'is_resolved = 0',
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      debugPrint('Error getting unresolved conflicts: $e');
      return [];
    }
  }

  /// Resolve conflict
  Future<void> resolveConflict(
    int conflictId,
    String strategy,
    String resolvedBy,
  ) async {
    try {
      await update(
        tableConflicts,
        {
          'is_resolved': 1,
          'resolution_strategy': strategy,
          'resolved_by': resolvedBy,
          'resolved_at': DateTime.now().millisecondsSinceEpoch,
        },
        'id = ?',
        [conflictId],
      );
    } catch (e) {
      debugPrint('Error resolving conflict: $e');
    }
  }

  // Maintenance and Utilities

  /// Clean up orphaned records
  Future<void> _cleanupOrphanedRecords() async {
    try {
      // Remove receipts with invalid user_id (if needed)
      // Remove invoices without valid client_id (if needed)
      debugPrint('Orphaned records cleanup completed');
    } catch (e) {
      debugPrint('Error during orphaned records cleanup: $e');
    }
  }

  /// Get database size
  Future<int> getDatabaseSize() async {
    try {
      final file = File(_database!.path);
      return await file.length();
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  /// Vacuum database
  Future<void> vacuumDatabase() async {
    try {
      await _database!.execute('VACUUM');
      debugPrint('Database vacuumed successfully');
    } catch (e) {
      debugPrint('Error vacuuming database: $e');
    }
  }

  /// Get table row counts
  Future<Map<String, int>> getTableRowCounts() async {
    try {
      final tables = [
        tableReceipts,
        tableInvoices,
        tableClients,
        tableCategories,
        tableSyncQueue,
        tableCache,
        tableConflicts,
      ];

      final counts = <String, int>{};
      for (final table in tables) {
        final result = await rawQuery('SELECT COUNT(*) as count FROM $table');
        counts[table] = result.first['count'] as int;
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting table row counts: $e');
      return {};
    }
  }

  /// Backup database
  Future<String?> backupDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupPath = join(
        documentsDirectory.path,
        'receiptsly_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      final originalFile = File(_database!.path);
      await originalFile.copy(backupPath);

      debugPrint('Database backed up to: $backupPath');
      return backupPath;
    } catch (e) {
      debugPrint('Error backing up database: $e');
      return null;
    }
  }

  /// Restore database from backup
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        debugPrint('Backup file does not exist: $backupPath');
        return false;
      }

      // Close current database
      await _database!.close();

      // Replace with backup
      await backupFile.copy(_database!.path);

      // Reopen database
      await _initDatabase();

      debugPrint('Database restored from backup');
      return true;
    } catch (e) {
      debugPrint('Error restoring database: $e');
      return false;
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  /// Export data to JSON
  Future<Map<String, dynamic>> exportData(String userId) async {
    try {
      final data = <String, dynamic>{};

      data['receipts'] = await getReceipts(userId);
      data['invoices'] = await getInvoices(userId);
      data['clients'] = await getClients(userId);
      data['categories'] = await getCategories(userId);

      data['export_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      data['user_id'] = userId;

      return data;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return {};
    }
  }

  /// Import data from JSON
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      final batch = _database!.batch();

      // Import receipts
      if (data['receipts'] != null) {
        for (final receipt in data['receipts'] as List) {
          batch.insert(
            tableReceipts,
            receipt as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Import invoices
      if (data['invoices'] != null) {
        for (final invoice in data['invoices'] as List) {
          batch.insert(
            tableInvoices,
            invoice as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Import clients
      if (data['clients'] != null) {
        for (final client in data['clients'] as List) {
          batch.insert(
            tableClients,
            client as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Import categories
      if (data['categories'] != null) {
        for (final category in data['categories'] as List) {
          batch.insert(
            tableCategories,
            category as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit();
      debugPrint('Data imported successfully');
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  /// Close database
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
      debugPrint('Database closed');
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _instance = null;
  }
}
