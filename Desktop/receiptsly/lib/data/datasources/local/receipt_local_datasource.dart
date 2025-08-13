// lib/data/datasources/local/receipt_local_datasource.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/receipt/receipt_model.dart';
import 'local_database.dart';

class ReceiptLocalDataSource {
  final LocalDatabase _database;
  final Uuid _uuid = const Uuid();

  ReceiptLocalDataSource(this._database);

  // Create a new receipt
  Future<String> createReceipt(ReceiptModel receipt) async {
    try {
      final receiptData = receipt.toJson();
      receiptData['id'] = receipt.id ?? _uuid.v4();
      receiptData['is_synced'] = 0;
      receiptData['sync_status'] = 'pending';

      // Convert OCR data to JSON string
      if (receiptData['ocrData'] != null) {
        receiptData['ocr_data'] = jsonEncode(receiptData['ocrData']);
        receiptData.remove('ocrData');
      }

      // Convert date to timestamp
      if (receiptData['date'] is DateTime) {
        receiptData['date'] =
            (receiptData['date'] as DateTime).millisecondsSinceEpoch;
      }

      await _database.insert(LocalDatabase.receiptsTable, receiptData);

      return receiptData['id'] as String;
    } catch (e) {
      throw LocalDataException('Failed to create receipt: $e');
    }
  }

  // Get receipt by ID
  Future<ReceiptModel?> getReceiptById(String id) async {
    try {
      final result = await _database.getById(LocalDatabase.receiptsTable, id);

      if (result == null) return null;

      return _mapToReceiptModel(result);
    } catch (e) {
      throw LocalDataException('Failed to get receipt: $e');
    }
  }

  // Get all receipts for a user
  Future<List<ReceiptModel>> getReceiptsByUserId(
    String userId, {
    int? limit,
    int? offset,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? orderBy = 'date DESC',
  }) async {
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      // Add category filter
      if (category != null && category.isNotEmpty) {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }

      // Add date range filter
      if (startDate != null) {
        whereClause += ' AND date >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause += ' AND date <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      // Add status filter
      if (status != null && status.isNotEmpty) {
        whereClause += ' AND status = ?';
        whereArgs.add(status);
      }

      final results = await _database.query(
        LocalDatabase.receiptsTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      return results.map((json) => _mapToReceiptModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get receipts: $e');
    }
  }

  // Update receipt
  Future<void> updateReceipt(ReceiptModel receipt) async {
    try {
      final receiptData = receipt.toJson();
      receiptData['is_synced'] = 0;
      receiptData['sync_status'] = 'pending';

      // Convert OCR data to JSON string
      if (receiptData['ocrData'] != null) {
        receiptData['ocr_data'] = jsonEncode(receiptData['ocrData']);
        receiptData.remove('ocrData');
      }

      // Convert date to timestamp
      if (receiptData['date'] is DateTime) {
        receiptData['date'] =
            (receiptData['date'] as DateTime).millisecondsSinceEpoch;
      }

      final result = await _database.update(
        LocalDatabase.receiptsTable,
        receiptData,
        receipt.id!,
      );

      if (result == 0) {
        throw LocalDataException('Receipt not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to update receipt: $e');
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(String id) async {
    try {
      final result = await _database.delete(LocalDatabase.receiptsTable, id);

      if (result == 0) {
        throw LocalDataException('Receipt not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to delete receipt: $e');
    }
  }

  // Get unsynced receipts
  Future<List<ReceiptModel>> getUnsyncedReceipts() async {
    try {
      final results = await _database.query(
        LocalDatabase.receiptsTable,
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return results.map((json) => _mapToReceiptModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get unsynced receipts: $e');
    }
  }

  // Mark receipt as synced
  Future<void> markAsSynced(String id) async {
    try {
      await _database.update(LocalDatabase.receiptsTable, {
        'is_synced': 1,
        'sync_status': 'synced',
      }, id);
    } catch (e) {
      throw LocalDataException('Failed to mark receipt as synced: $e');
    }
  }

  // Mark receipt as sync failed
  Future<void> markSyncFailed(String id, String error) async {
    try {
      await _database.update(LocalDatabase.receiptsTable, {
        'sync_status': 'failed',
      }, id);
    } catch (e) {
      throw LocalDataException('Failed to mark sync failed: $e');
    }
  }

  // Search receipts
  Future<List<ReceiptModel>> searchReceipts(
    String userId,
    String query, {
    int? limit = 20,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.receiptsTable,
        where: '''
          user_id = ? AND (
            vendor LIKE ? OR 
            description LIKE ? OR 
            category LIKE ?
          )
        ''',
        whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
        orderBy: 'date DESC',
        limit: limit,
      );

      return results.map((json) => _mapToReceiptModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to search receipts: $e');
    }
  }

  // Get receipt statistics
  Future<Map<String, dynamic>> getReceiptStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      if (startDate != null) {
        whereClause += ' AND date >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause += ' AND date <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final db = await _database.database;

      // Get total count and amount
      final totalResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_count,
          SUM(amount) as total_amount,
          AVG(amount) as average_amount
        FROM ${LocalDatabase.receiptsTable}
        WHERE $whereClause
      ''', whereArgs);

      // Get category breakdown
      final categoryResult = await db.rawQuery('''
        SELECT 
          category,
          COUNT(*) as count,
          SUM(amount) as amount
        FROM ${LocalDatabase.receiptsTable}
        WHERE $whereClause
        GROUP BY category
        ORDER BY amount DESC
      ''', whereArgs);

      // Get monthly breakdown
      final monthlyResult = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', datetime(date/1000, 'unixepoch')) as month,
          COUNT(*) as count,
          SUM(amount) as amount
        FROM ${LocalDatabase.receiptsTable}
        WHERE $whereClause
        GROUP BY month
        ORDER BY month DESC
      ''', whereArgs);

      return {
        'total': totalResult.first,
        'categories': categoryResult,
        'monthly': monthlyResult,
      };
    } catch (e) {
      throw LocalDataException('Failed to get receipt stats: $e');
    }
  }

  // Get receipts by category
  Future<List<ReceiptModel>> getReceiptsByCategory(
    String userId,
    String category, {
    int? limit,
    int? offset,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.receiptsTable,
        where: 'user_id = ? AND category = ?',
        whereArgs: [userId, category],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((json) => _mapToReceiptModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get receipts by category: $e');
    }
  }

  // Get receipts by date range
  Future<List<ReceiptModel>> getReceiptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.receiptsTable,
        where: 'user_id = ? AND date >= ? AND date <= ?',
        whereArgs: [
          userId,
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((json) => _mapToReceiptModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get receipts by date range: $e');
    }
  }

  // Bulk create receipts
  Future<void> bulkCreateReceipts(List<ReceiptModel> receipts) async {
    try {
      final operations = receipts.map((receipt) {
        final receiptData = receipt.toJson();
        receiptData['id'] = receipt.id ?? _uuid.v4();
        receiptData['is_synced'] = 0;
        receiptData['sync_status'] = 'pending';

        // Convert OCR data to JSON string
        if (receiptData['ocrData'] != null) {
          receiptData['ocr_data'] = jsonEncode(receiptData['ocrData']);
          receiptData.remove('ocrData');
        }

        // Convert date to timestamp
        if (receiptData['date'] is DateTime) {
          receiptData['date'] =
              (receiptData['date'] as DateTime).millisecondsSinceEpoch;
        }

        return {
          'type': 'insert',
          'table': LocalDatabase.receiptsTable,
          'data': receiptData,
        };
      }).toList();

      await _database.batchOperation(operations);
    } catch (e) {
      throw LocalDataException('Failed to bulk create receipts: $e');
    }
  }

  // Bulk update receipts
  Future<void> bulkUpdateReceipts(List<ReceiptModel> receipts) async {
    try {
      final operations = receipts.map((receipt) {
        final receiptData = receipt.toJson();
        receiptData['is_synced'] = 0;
        receiptData['sync_status'] = 'pending';

        // Convert OCR data to JSON string
        if (receiptData['ocrData'] != null) {
          receiptData['ocr_data'] = jsonEncode(receiptData['ocrData']);
          receiptData.remove('ocrData');
        }

        // Convert date to timestamp
        if (receiptData['date'] is DateTime) {
          receiptData['date'] =
              (receiptData['date'] as DateTime).millisecondsSinceEpoch;
        }

        return {
          'type': 'update',
          'table': LocalDatabase.receiptsTable,
          'data': receiptData,
        };
      }).toList();

      await _database.batchOperation(operations);
    } catch (e) {
      throw LocalDataException('Failed to bulk update receipts: $e');
    }
  }

  // Get receipts count by status
  Future<Map<String, int>> getReceiptCountByStatus(String userId) async {
    try {
      final db = await _database.database;
      final results = await db.rawQuery(
        '''
        SELECT 
          status,
          COUNT(*) as count
        FROM ${LocalDatabase.receiptsTable}
        WHERE user_id = ?
        GROUP BY status
      ''',
        [userId],
      );

      final statusCounts = <String, int>{};
      for (final result in results) {
        statusCounts[result['status'] as String] = result['count'] as int;
      }

      return statusCounts;
    } catch (e) {
      throw LocalDataException('Failed to get receipt count by status: $e');
    }
  }

  // Get recent receipts
  Future<List<ReceiptModel>> getRecentReceipts(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.receiptsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((json) => _mapToReceiptModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get recent receipts: $e');
    }
  }

  // Get total amount for a period
  Future<double> getTotalAmountForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        '''
        SELECT SUM(amount) as total
        FROM ${LocalDatabase.receiptsTable}
        WHERE user_id = ? AND date >= ? AND date <= ?
      ''',
        [
          userId,
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
      );

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw LocalDataException('Failed to get total amount: $e');
    }
  }

  // Clear all receipts for user
  Future<void> clearUserReceipts(String userId) async {
    try {
      final db = await _database.database;
      await db.delete(
        LocalDatabase.receiptsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw LocalDataException('Failed to clear user receipts: $e');
    }
  }

  // Get expense trends
  Future<List<Map<String, dynamic>>> getExpenseTrends(
    String userId, {
    int months = 12,
  }) async {
    try {
      final db = await _database.database;
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months, 1);

      final results = await db.rawQuery(
        '''
        SELECT 
          strftime('%Y-%m', datetime(date/1000, 'unixepoch')) as month,
          SUM(amount) as total_amount,
          COUNT(*) as total_count,
          AVG(amount) as average_amount
        FROM ${LocalDatabase.receiptsTable}
        WHERE user_id = ? AND date >= ?
        GROUP BY month
        ORDER BY month ASC
      ''',
        [userId, startDate.millisecondsSinceEpoch],
      );

      return results
          .map(
            (row) => {
              'month': row['month'],
              'totalAmount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
              'totalCount': row['total_count'] as int,
              'averageAmount':
                  (row['average_amount'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();
    } catch (e) {
      throw LocalDataException('Failed to get expense trends: $e');
    }
  }

  // Helper method to map database result to ReceiptModel
  ReceiptModel _mapToReceiptModel(Map<String, dynamic> json) {
    // Convert timestamp back to DateTime
    if (json['date'] is int) {
      json['date'] = DateTime.fromMillisecondsSinceEpoch(json['date'] as int);
    }

    if (json['created_at'] is int) {
      json['createdAt'] = DateTime.fromMillisecondsSinceEpoch(
        json['created_at'] as int,
      );
    }

    if (json['updated_at'] is int) {
      json['updatedAt'] = DateTime.fromMillisecondsSinceEpoch(
        json['updated_at'] as int,
      );
    }

    // Convert OCR data from JSON string
    if (json['ocr_data'] != null && json['ocr_data'] is String) {
      try {
        json['ocrData'] = jsonDecode(json['ocr_data'] as String);
      } catch (e) {
        json['ocrData'] = null;
      }
    }

    // Clean up database-specific fields
    json.remove('ocr_data');
    json.remove('is_synced');
    json.remove('sync_status');
    json.remove('created_at');
    json.remove('updated_at');

    // Map database field names to model field names
    json['userId'] = json.remove('user_id');
    json['imageUrl'] = json.remove('image_url');
    json['localImagePath'] = json.remove('local_image_path');
    json['ocrConfidence'] = json.remove('ocr_confidence');

    return ReceiptModel.fromJson(json);
  }
}
