// lib/data/datasources/local/sync_queue_datasource.dart
import 'dart:convert';
import '../../../core/errors/exceptions.dart';
import '../../models/sync/sync_queue_model.dart';
import 'local_database.dart';

class SyncQueueDataSource {
  final LocalDatabase _database;

  SyncQueueDataSource(this._database);

  // Add item to sync queue
  Future<int> addToQueue(SyncQueueModel item) async {
    try {
      final queueData = item.toJson();

      // Convert dates to timestamps
      if (queueData['createdAt'] is DateTime) {
        queueData['created_at'] =
            (queueData['createdAt'] as DateTime).millisecondsSinceEpoch;
        queueData.remove('createdAt');
      }

      if (queueData['scheduledFor'] is DateTime) {
        queueData['scheduled_for'] =
            (queueData['scheduledFor'] as DateTime).millisecondsSinceEpoch;
        queueData.remove('scheduledFor');
      }

      if (queueData['syncedAt'] is DateTime) {
        queueData['synced_at'] =
            (queueData['syncedAt'] as DateTime).millisecondsSinceEpoch;
        queueData.remove('syncedAt');
      }

      // Map model fields to database fields
      _mapModelFieldsToDatabase(queueData);

      final db = await _database.database;
      final id = await db.insert(LocalDatabase.syncQueueTable, queueData);

      return id;
    } catch (e) {
      throw LocalDataException('Failed to add item to sync queue: $e');
    }
  }

  // Get pending sync items
  Future<List<SyncQueueModel>> getPendingItems({
    int? limit,
    String? tableName,
    int priority = 0,
  }) async {
    try {
      String whereClause = 'synced_at IS NULL';
      List<dynamic> whereArgs = [];

      // Filter by table name
      if (tableName != null && tableName.isNotEmpty) {
        whereClause += ' AND table_name = ?';
        whereArgs.add(tableName);
      }

      // Filter by priority
      if (priority > 0) {
        whereClause += ' AND priority >= ?';
        whereArgs.add(priority);
      }

      // Check if scheduled time has passed
      final now = DateTime.now().millisecondsSinceEpoch;
      whereClause += ' AND (scheduled_for IS NULL OR scheduled_for <= ?)';
      whereArgs.add(now);

      // Don't include items that have exceeded max retries
      whereClause += ' AND retry_count < max_retries';

      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'priority DESC, created_at ASC',
        limit: limit,
      );

      return results.map((json) => _mapToSyncQueueModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get pending sync items: $e');
    }
  }

  // Get item by ID
  Future<SyncQueueModel?> getItemById(int id) async {
    try {
      final db = await _database.database;
      final results = await db.query(
        LocalDatabase.syncQueueTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapToSyncQueueModel(results.first);
    } catch (e) {
      throw LocalDataException('Failed to get sync queue item: $e');
    }
  }

  // Update sync item
  Future<void> updateItem(SyncQueueModel item) async {
    try {
      final queueData = item.toJson();

      // Convert dates to timestamps
      if (queueData['createdAt'] is DateTime) {
        queueData['created_at'] =
            (queueData['createdAt'] as DateTime).millisecondsSinceEpoch;
        queueData.remove('createdAt');
      }

      if (queueData['scheduledFor'] is DateTime) {
        queueData['scheduled_for'] =
            (queueData['scheduledFor'] as DateTime).millisecondsSinceEpoch;
        queueData.remove('scheduledFor');
      }

      if (queueData['syncedAt'] is DateTime) {
        queueData['synced_at'] =
            (queueData['syncedAt'] as DateTime).millisecondsSinceEpoch;
        queueData.remove('syncedAt');
      }

      // Map model fields to database fields
      _mapModelFieldsToDatabase(queueData);

      final db = await _database.database;
      final result = await db.update(
        LocalDatabase.syncQueueTable,
        queueData,
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (result == 0) {
        throw LocalDataException('Sync queue item not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to update sync queue item: $e');
    }
  }

  // Mark item as synced
  Future<void> markAsSynced(int id) async {
    try {
      final db = await _database.database;
      await db.update(
        LocalDatabase.syncQueueTable,
        {'synced_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDataException('Failed to mark item as synced: $e');
    }
  }

  // Mark item as failed
  Future<void> markAsFailed(int id, String errorMessage) async {
    try {
      final db = await _database.database;
      await db.rawUpdate(
        '''
        UPDATE ${LocalDatabase.syncQueueTable}
        SET retry_count = retry_count + 1,
            error_message = ?,
            scheduled_for = ?
        WHERE id = ?
      ''',
        [errorMessage, _calculateNextRetry(), id],
      );
    } catch (e) {
      throw LocalDataException('Failed to mark item as failed: $e');
    }
  }

  // Delete sync item
  Future<void> deleteItem(int id) async {
    try {
      final db = await _database.database;
      final result = await db.delete(
        LocalDatabase.syncQueueTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result == 0) {
        throw LocalDataException('Sync queue item not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to delete sync queue item: $e');
    }
  }

  // Get queue statistics
  Future<Map<String, dynamic>> getQueueStats() async {
    try {
      final db = await _database.database;

      // Get total count
      final totalResult = await db.rawQuery('''
        SELECT COUNT(*) as total_count
        FROM ${LocalDatabase.syncQueueTable}
      ''');

      // Get pending count
      final pendingResult = await db.rawQuery('''
        SELECT COUNT(*) as pending_count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE synced_at IS NULL AND retry_count < max_retries
      ''');

      // Get failed count
      final failedResult = await db.rawQuery('''
        SELECT COUNT(*) as failed_count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE synced_at IS NULL AND retry_count >= max_retries
      ''');

      // Get synced count
      final syncedResult = await db.rawQuery('''
        SELECT COUNT(*) as synced_count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE synced_at IS NOT NULL
      ''');

      // Get counts by action
      final actionResult = await db.rawQuery('''
        SELECT 
          action,
          COUNT(*) as count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE synced_at IS NULL
        GROUP BY action
      ''');

      // Get counts by table
      final tableResult = await db.rawQuery('''
        SELECT 
          table_name,
          COUNT(*) as count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE synced_at IS NULL
        GROUP BY table_name
      ''');

      return {
        'total': totalResult.first['total_count'] as int,
        'pending': pendingResult.first['pending_count'] as int,
        'failed': failedResult.first['failed_count'] as int,
        'synced': syncedResult.first['synced_count'] as int,
        'by_action': actionResult,
        'by_table': tableResult,
      };
    } catch (e) {
      throw LocalDataException('Failed to get queue statistics: $e');
    }
  }

  // Get failed items
  Future<List<SyncQueueModel>> getFailedItems({int? limit}) async {
    try {
      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where: 'synced_at IS NULL AND retry_count >= max_retries',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((json) => _mapToSyncQueueModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get failed sync items: $e');
    }
  }

  // Retry failed items
  Future<void> retryFailedItems({String? tableName}) async {
    try {
      final db = await _database.database;
      String whereClause = 'synced_at IS NULL AND retry_count >= max_retries';
      List<dynamic> whereArgs = [];

      if (tableName != null && tableName.isNotEmpty) {
        whereClause += ' AND table_name = ?';
        whereArgs.add(tableName);
      }

      await db.update(
        LocalDatabase.syncQueueTable,
        {'retry_count': 0, 'error_message': null, 'scheduled_for': null},
        where: whereClause,
        whereArgs: whereArgs,
      );
    } catch (e) {
      throw LocalDataException('Failed to retry failed items: $e');
    }
  }

  // Clear synced items
  Future<void> clearSyncedItems() async {
    try {
      final db = await _database.database;
      await db.delete(
        LocalDatabase.syncQueueTable,
        where: 'synced_at IS NOT NULL',
      );
    } catch (e) {
      throw LocalDataException('Failed to clear synced items: $e');
    }
  }

  // Clear all items
  Future<void> clearAllItems() async {
    try {
      final db = await _database.database;
      await db.delete(LocalDatabase.syncQueueTable);
    } catch (e) {
      throw LocalDataException('Failed to clear all sync items: $e');
    }
  }

  // Get items by table and record ID
  Future<List<SyncQueueModel>> getItemsByRecord(
    String tableName,
    String recordId,
  ) async {
    try {
      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where: 'table_name = ? AND record_id = ?',
        whereArgs: [tableName, recordId],
        orderBy: 'created_at DESC',
      );

      return results.map((json) => _mapToSyncQueueModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get items by record: $e');
    }
  }

  // Check if record has pending sync
  Future<bool> hasPendingSync(String tableName, String recordId) async {
    try {
      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where: 'table_name = ? AND record_id = ? AND synced_at IS NULL',
        whereArgs: [tableName, recordId],
      );

      return results.isNotEmpty;
    } catch (e) {
      throw LocalDataException('Failed to check pending sync: $e');
    }
  }

  // Bulk add to queue
  Future<void> bulkAddToQueue(List<SyncQueueModel> items) async {
    try {
      final operations = items.map((item) {
        final queueData = item.toJson();

        // Convert dates to timestamps
        if (queueData['createdAt'] is DateTime) {
          queueData['created_at'] =
              (queueData['createdAt'] as DateTime).millisecondsSinceEpoch;
          queueData.remove('createdAt');
        }

        if (queueData['scheduledFor'] is DateTime) {
          queueData['scheduled_for'] =
              (queueData['scheduledFor'] as DateTime).millisecondsSinceEpoch;
          queueData.remove('scheduledFor');
        }

        // Map model fields to database fields
        _mapModelFieldsToDatabase(queueData);

        return {
          'type': 'insert',
          'table': LocalDatabase.syncQueueTable,
          'data': queueData,
        };
      }).toList();

      await _database.batchOperation(operations);
    } catch (e) {
      throw LocalDataException('Failed to bulk add to sync queue: $e');
    }
  }

  // Get items scheduled for now or past
  Future<List<SyncQueueModel>> getScheduledItems({int? limit}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where:
            'synced_at IS NULL AND scheduled_for IS NOT NULL AND scheduled_for <= ?',
        whereArgs: [now],
        orderBy: 'priority DESC, scheduled_for ASC',
        limit: limit,
      );

      return results.map((json) => _mapToSyncQueueModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get scheduled items: $e');
    }
  }

  // Update priority
  Future<void> updatePriority(int id, int priority) async {
    try {
      final db = await _database.database;
      await db.update(
        LocalDatabase.syncQueueTable,
        {'priority': priority},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDataException('Failed to update priority: $e');
    }
  }

  // Schedule item for later
  Future<void> scheduleItem(int id, DateTime scheduledFor) async {
    try {
      final db = await _database.database;
      await db.update(
        LocalDatabase.syncQueueTable,
        {'scheduled_for': scheduledFor.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDataException('Failed to schedule item: $e');
    }
  }

  // Get oldest pending item
  Future<SyncQueueModel?> getOldestPendingItem() async {
    try {
      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where: 'synced_at IS NULL AND retry_count < max_retries',
        orderBy: 'created_at ASC',
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapToSyncQueueModel(results.first);
    } catch (e) {
      throw LocalDataException('Failed to get oldest pending item: $e');
    }
  }

  // Get high priority items
  Future<List<SyncQueueModel>> getHighPriorityItems({
    int minPriority = 5,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.syncQueueTable,
        where:
            'synced_at IS NULL AND priority >= ? AND retry_count < max_retries',
        whereArgs: [minPriority],
        orderBy: 'priority DESC, created_at ASC',
      );

      return results.map((json) => _mapToSyncQueueModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get high priority items: $e');
    }
  }

  // Clean up old synced items
  Future<void> cleanupOldItems({int daysOld = 7}) async {
    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysOld))
          .millisecondsSinceEpoch;

      final db = await _database.database;
      await db.delete(
        LocalDatabase.syncQueueTable,
        where: 'synced_at IS NOT NULL AND synced_at < ?',
        whereArgs: [cutoffTime],
      );
    } catch (e) {
      throw LocalDataException('Failed to cleanup old items: $e');
    }
  }

  // Get sync performance metrics
  Future<Map<String, dynamic>> getSyncMetrics({int days = 7}) async {
    try {
      final db = await _database.database;
      final startTime = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch;

      // Get success rate
      final successResult = await db.rawQuery(
        '''
        SELECT 
          COUNT(CASE WHEN synced_at IS NOT NULL THEN 1 END) as success_count,
          COUNT(CASE WHEN retry_count >= max_retries THEN 1 END) as failed_count,
          COUNT(*) as total_count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE created_at >= ?
      ''',
        [startTime],
      );

      // Get average sync time
      final timeResult = await db.rawQuery(
        '''
        SELECT 
          AVG(synced_at - created_at) as avg_sync_time
        FROM ${LocalDatabase.syncQueueTable}
        WHERE synced_at IS NOT NULL AND created_at >= ?
      ''',
        [startTime],
      );

      // Get retry statistics
      final retryResult = await db.rawQuery(
        '''
        SELECT 
          retry_count,
          COUNT(*) as count
        FROM ${LocalDatabase.syncQueueTable}
        WHERE created_at >= ?
        GROUP BY retry_count
        ORDER BY retry_count
      ''',
        [startTime],
      );

      final success = successResult.first;
      final totalCount = success['total_count'] as int;
      final successCount = success['success_count'] as int;
      final failedCount = success['failed_count'] as int;

      return {
        'total_items': totalCount,
        'success_count': successCount,
        'failed_count': failedCount,
        'success_rate': totalCount > 0
            ? (successCount / totalCount) * 100
            : 0.0,
        'avg_sync_time_ms':
            (timeResult.first['avg_sync_time'] as num?)?.toInt() ?? 0,
        'retry_distribution': retryResult,
      };
    } catch (e) {
      throw LocalDataException('Failed to get sync metrics: $e');
    }
  }

  // Calculate next retry time with exponential backoff
  int _calculateNextRetry() {
    final baseDelay = Duration(minutes: 1); // Start with 1 minute
    final maxDelay = Duration(hours: 1); // Max 1 hour

    // Exponential backoff: 1min, 2min, 4min, 8min, 16min, 32min, 60min
    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * 2).clamp(
        baseDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );

    return DateTime.now().add(delay).millisecondsSinceEpoch;
  }

  // Helper method to map model fields to database fields
  void _mapModelFieldsToDatabase(Map<String, dynamic> data) {
    data['table_name'] = data.remove('tableName');
    data['record_id'] = data.remove('recordId');
    data['retry_count'] = data.remove('retryCount');
    data['max_retries'] = data.remove('maxRetries');
    data['error_message'] = data.remove('errorMessage');
  }

  // Helper method to map database result to SyncQueueModel
  SyncQueueModel _mapToSyncQueueModel(Map<String, dynamic> json) {
    // Convert timestamps back to DateTime
    if (json['created_at'] is int) {
      json['createdAt'] = DateTime.fromMillisecondsSinceEpoch(
        json['created_at'] as int,
      );
    }

    if (json['scheduled_for'] is int) {
      json['scheduledFor'] = DateTime.fromMillisecondsSinceEpoch(
        json['scheduled_for'] as int,
      );
    }

    if (json['synced_at'] is int) {
      json['syncedAt'] = DateTime.fromMillisecondsSinceEpoch(
        json['synced_at'] as int,
      );
    }

    // Clean up database-specific fields
    json.remove('created_at');
    json.remove('scheduled_for');
    json.remove('synced_at');

    // Map database field names to model field names
    json['tableName'] = json.remove('table_name');
    json['recordId'] = json.remove('record_id');
    json['retryCount'] = json.remove('retry_count');
    json['maxRetries'] = json.remove('max_retries');
    json['errorMessage'] = json.remove('error_message');

    return SyncQueueModel.fromJson(json);
  }
}
