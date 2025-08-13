// lib/data/datasources/local/local_database.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _database;

  LocalDatabase._internal();

  factory LocalDatabase() {
    _instance ??= LocalDatabase._internal();
    return _instance!;
  }

  static const String _databaseName = 'receiptsly_local.db';
  static const int _databaseVersion = 3;

  // Table names
  static const String receiptsTable = 'receipts';
  static const String invoicesTable = 'invoices';
  static const String usersTable = 'users';
  static const String syncQueueTable = 'sync_queue';
  static const String conflictsTable = 'conflicts';
  static const String categoriesTable = 'categories';
  static const String clientsTable = 'clients';
  static const String settingsTable = 'settings';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
    // Enable WAL mode for better concurrency
    await db.execute('PRAGMA journal_mode = WAL');
    // Set cache size
    await db.execute('PRAGMA cache_size = 10000');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Users table
    batch.execute('''
      CREATE TABLE $usersTable (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        name TEXT,
        business_name TEXT,
        business_type TEXT,
        country TEXT,
        currency TEXT DEFAULT 'USD',
        subscription_plan TEXT DEFAULT 'free',
        subscription_valid_until INTEGER,
        monthly_receipt_limit INTEGER DEFAULT 50,
        receipt_count INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Receipts table
    batch.execute('''
      CREATE TABLE $receiptsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        vendor TEXT,
        amount REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'USD',
        date INTEGER NOT NULL,
        category TEXT DEFAULT 'General',
        description TEXT,
        image_url TEXT,
        local_image_path TEXT,
        ocr_data TEXT,
        ocr_confidence REAL DEFAULT 0.0,
        status TEXT DEFAULT 'pending',
        is_synced INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Invoices table
    batch.execute('''
      CREATE TABLE $invoicesTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT,
        invoice_number TEXT,
        issue_date INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        status TEXT DEFAULT 'draft',
        subtotal REAL DEFAULT 0.0,
        tax_rate REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        total_amount REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'USD',
        notes TEXT,
        terms TEXT,
        items TEXT,
        pdf_url TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Clients table
    batch.execute('''
      CREATE TABLE $clientsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        company TEXT,
        tax_id TEXT,
        payment_terms INTEGER DEFAULT 30,
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Categories table
    batch.execute('''
      CREATE TABLE $categoriesTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT,
        icon TEXT,
        is_default INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Sync queue table
    batch.execute('''
      CREATE TABLE $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 3,
        priority INTEGER DEFAULT 0,
        scheduled_for INTEGER,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    // Conflicts table
    batch.execute('''
      CREATE TABLE $conflictsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        resolution_strategy TEXT,
        resolved INTEGER DEFAULT 0,
        resolved_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Settings table
    batch.execute('''
      CREATE TABLE $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    _createIndexes(batch);

    await batch.commit();

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  void _createIndexes(Batch batch) {
    // Receipts indexes
    batch.execute(
      'CREATE INDEX idx_receipts_user_id ON $receiptsTable (user_id)',
    );
    batch.execute('CREATE INDEX idx_receipts_date ON $receiptsTable (date)');
    batch.execute(
      'CREATE INDEX idx_receipts_category ON $receiptsTable (category)',
    );
    batch.execute(
      'CREATE INDEX idx_receipts_sync_status ON $receiptsTable (sync_status)',
    );
    batch.execute(
      'CREATE INDEX idx_receipts_is_synced ON $receiptsTable (is_synced)',
    );

    // Invoices indexes
    batch.execute(
      'CREATE INDEX idx_invoices_user_id ON $invoicesTable (user_id)',
    );
    batch.execute(
      'CREATE INDEX idx_invoices_client_id ON $invoicesTable (client_id)',
    );
    batch.execute(
      'CREATE INDEX idx_invoices_status ON $invoicesTable (status)',
    );
    batch.execute(
      'CREATE INDEX idx_invoices_due_date ON $invoicesTable (due_date)',
    );
    batch.execute(
      'CREATE INDEX idx_invoices_is_synced ON $invoicesTable (is_synced)',
    );

    // Clients indexes
    batch.execute(
      'CREATE INDEX idx_clients_user_id ON $clientsTable (user_id)',
    );
    batch.execute('CREATE INDEX idx_clients_name ON $clientsTable (name)');

    // Sync queue indexes
    batch.execute(
      'CREATE INDEX idx_sync_queue_action ON $syncQueueTable (action)',
    );
    batch.execute(
      'CREATE INDEX idx_sync_queue_synced_at ON $syncQueueTable (synced_at)',
    );
    batch.execute(
      'CREATE INDEX idx_sync_queue_priority ON $syncQueueTable (priority DESC)',
    );
    batch.execute(
      'CREATE INDEX idx_sync_queue_scheduled_for ON $syncQueueTable (scheduled_for)',
    );

    // Categories indexes
    batch.execute(
      'CREATE INDEX idx_categories_user_id ON $categoriesTable (user_id)',
    );
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Office Supplies', 'color': '#2196F3', 'icon': 'office'},
      {'name': 'Food & Dining', 'color': '#FF9800', 'icon': 'restaurant'},
      {'name': 'Transportation', 'color': '#4CAF50', 'icon': 'directions_car'},
      {'name': 'Software & Technology', 'color': '#9C27B0', 'icon': 'computer'},
      {
        'name': 'Marketing & Advertising',
        'color': '#E91E63',
        'icon': 'campaign',
      },
      {'name': 'Travel & Accommodation', 'color': '#00BCD4', 'icon': 'flight'},
      {'name': 'Professional Services', 'color': '#795548', 'icon': 'business'},
      {'name': 'Equipment & Supplies', 'color': '#607D8B', 'icon': 'hardware'},
      {'name': 'Utilities', 'color': '#FFC107', 'icon': 'electrical_services'},
      {'name': 'General', 'color': '#757575', 'icon': 'category'},
    ];

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i];
      batch.insert(categoriesTable, {
        'id': 'default_${i + 1}',
        'user_id': 'system',
        'name': category['name'],
        'color': category['color'],
        'icon': category['icon'],
        'is_default': 1,
        'is_synced': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    await batch.commit();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute(
        'ALTER TABLE $receiptsTable ADD COLUMN sync_status TEXT DEFAULT "pending"',
      );
      await db.execute(
        'ALTER TABLE $invoicesTable ADD COLUMN sync_status TEXT DEFAULT "pending"',
      );
    }

    if (oldVersion < 3) {
      // Add clients table for version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $clientsTable (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          address TEXT,
          company TEXT,
          tax_id TEXT,
          payment_terms INTEGER DEFAULT 30,
          is_synced INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES $usersTable (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_clients_user_id ON $clientsTable (user_id)',
      );
      await db.execute('CREATE INDEX idx_clients_name ON $clientsTable (name)');
    }
  }

  // Generic CRUD operations
  Future<String> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      data['created_at'] = DateTime.now().millisecondsSinceEpoch;
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return data['id'] as String;
    } catch (e) {
      throw DatabaseException('Failed to insert into $table: $e');
    }
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    try {
      final db = await database;
      final results = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException('Failed to get from $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseException('Failed to query $table: $e');
    }
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    try {
      final db = await database;
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to update $table: $e');
    }
  }

  Future<int> delete(String table, String id) async {
    try {
      final db = await database;
      return await db.delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete from $table: $e');
    }
  }

  // Batch operations
  Future<void> batchOperation(List<Map<String, dynamic>> operations) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final table = operation['table'] as String;
        final data = operation['data'] as Map<String, dynamic>;

        switch (type) {
          case 'insert':
            data['created_at'] = DateTime.now().millisecondsSinceEpoch;
            data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
            batch.insert(
              table,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            break;
          case 'update':
            data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
            batch.update(table, data, where: 'id = ?', whereArgs: [data['id']]);
            break;
          case 'delete':
            batch.delete(table, where: 'id = ?', whereArgs: [data['id']]);
            break;
        }
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw DatabaseException('Batch operation failed: $e');
    }
  }

  // Transaction wrapper
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      final db = await database;
      return await db.transaction(action);
    } catch (e) {
      throw DatabaseException('Transaction failed: $e');
    }
  }

  // Database maintenance
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
    } catch (e) {
      throw DatabaseException('Vacuum operation failed: $e');
    }
  }

  Future<Map<String, int>> getTableCounts() async {
    try {
      final db = await database;
      final counts = <String, int>{};

      final tables = [
        receiptsTable,
        invoicesTable,
        usersTable,
        clientsTable,
        categoriesTable,
        syncQueueTable,
        conflictsTable,
      ];

      for (final table in tables) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $table',
        );
        counts[table] = result.first['count'] as int;
      }

      return counts;
    } catch (e) {
      throw DatabaseException('Failed to get table counts: $e');
    }
  }

  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Clear all data (for logout/reset)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      final batch = db.batch();

      // Clear user data tables
      batch.delete(receiptsTable);
      batch.delete(invoicesTable);
      batch.delete(clientsTable);
      batch.delete(usersTable);
      batch.delete(syncQueueTable);
      batch.delete(conflictsTable);

      await batch.commit(noResult: true);

      // Re-insert default categories
      await _insertDefaultCategories(db);
    } catch (e) {
      throw DatabaseException('Failed to clear database: $e');
    }
  }

  // Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Delete database file
  Future<void> deleteDatabase() async {
    try {
      await close();
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw DatabaseException('Failed to delete database: $e');
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
