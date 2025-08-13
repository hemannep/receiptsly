// lib/data/datasources/local/invoice_local_datasource.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/invoice/invoice_model.dart';
import 'local_database.dart';

class InvoiceLocalDataSource {
  final LocalDatabase _database;
  final Uuid _uuid = const Uuid();

  InvoiceLocalDataSource(this._database);

  // Create a new invoice
  Future<String> createInvoice(InvoiceModel invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData['id'] = invoice.id ?? _uuid.v4();
      invoiceData['is_synced'] = 0;
      invoiceData['sync_status'] = 'pending';

      // Convert items to JSON string
      if (invoiceData['items'] != null) {
        invoiceData['items'] = jsonEncode(invoiceData['items']);
      }

      // Convert dates to timestamps
      if (invoiceData['issueDate'] is DateTime) {
        invoiceData['issue_date'] =
            (invoiceData['issueDate'] as DateTime).millisecondsSinceEpoch;
        invoiceData.remove('issueDate');
      }

      if (invoiceData['dueDate'] is DateTime) {
        invoiceData['due_date'] =
            (invoiceData['dueDate'] as DateTime).millisecondsSinceEpoch;
        invoiceData.remove('dueDate');
      }

      // Map field names to database column names
      _mapModelFieldsToDatabase(invoiceData);

      await _database.insert(LocalDatabase.invoicesTable, invoiceData);

      return invoiceData['id'] as String;
    } catch (e) {
      throw LocalDataException('Failed to create invoice: $e');
    }
  }

  // Get invoice by ID
  Future<InvoiceModel?> getInvoiceById(String id) async {
    try {
      final result = await _database.getById(LocalDatabase.invoicesTable, id);

      if (result == null) return null;

      return _mapToInvoiceModel(result);
    } catch (e) {
      throw LocalDataException('Failed to get invoice: $e');
    }
  }

  // Get all invoices for a user
  Future<List<InvoiceModel>> getInvoicesByUserId(
    String userId, {
    int? limit,
    int? offset,
    String? status,
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy = 'issue_date DESC',
  }) async {
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      // Add status filter
      if (status != null && status.isNotEmpty) {
        whereClause += ' AND status = ?';
        whereArgs.add(status);
      }

      // Add client filter
      if (clientId != null && clientId.isNotEmpty) {
        whereClause += ' AND client_id = ?';
        whereArgs.add(clientId);
      }

      // Add date range filter
      if (startDate != null) {
        whereClause += ' AND issue_date >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause += ' AND issue_date <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final results = await _database.query(
        LocalDatabase.invoicesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      return results.map((json) => _mapToInvoiceModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get invoices: $e');
    }
  }

  // Update invoice
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData['is_synced'] = 0;
      invoiceData['sync_status'] = 'pending';

      // Convert items to JSON string
      if (invoiceData['items'] != null) {
        invoiceData['items'] = jsonEncode(invoiceData['items']);
      }

      // Convert dates to timestamps
      if (invoiceData['issueDate'] is DateTime) {
        invoiceData['issue_date'] =
            (invoiceData['issueDate'] as DateTime).millisecondsSinceEpoch;
        invoiceData.remove('issueDate');
      }

      if (invoiceData['dueDate'] is DateTime) {
        invoiceData['due_date'] =
            (invoiceData['dueDate'] as DateTime).millisecondsSinceEpoch;
        invoiceData.remove('dueDate');
      }

      // Map field names to database column names
      _mapModelFieldsToDatabase(invoiceData);

      final result = await _database.update(
        LocalDatabase.invoicesTable,
        invoiceData,
        invoice.id!,
      );

      if (result == 0) {
        throw LocalDataException('Invoice not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to update invoice: $e');
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(String id) async {
    try {
      final result = await _database.delete(LocalDatabase.invoicesTable, id);

      if (result == 0) {
        throw LocalDataException('Invoice not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to delete invoice: $e');
    }
  }

  // Get unsynced invoices
  Future<List<InvoiceModel>> getUnsyncedInvoices() async {
    try {
      final results = await _database.query(
        LocalDatabase.invoicesTable,
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return results.map((json) => _mapToInvoiceModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get unsynced invoices: $e');
    }
  }

  // Mark invoice as synced
  Future<void> markAsSynced(String id) async {
    try {
      await _database.update(LocalDatabase.invoicesTable, {
        'is_synced': 1,
        'sync_status': 'synced',
      }, id);
    } catch (e) {
      throw LocalDataException('Failed to mark invoice as synced: $e');
    }
  }

  // Mark invoice as sync failed
  Future<void> markSyncFailed(String id, String error) async {
    try {
      await _database.update(LocalDatabase.invoicesTable, {
        'sync_status': 'failed',
      }, id);
    } catch (e) {
      throw LocalDataException('Failed to mark sync failed: $e');
    }
  }

  // Search invoices
  Future<List<InvoiceModel>> searchInvoices(
    String userId,
    String query, {
    int? limit = 20,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.invoicesTable,
        where: '''
          user_id = ? AND (
            invoice_number LIKE ? OR 
            notes LIKE ?
          )
        ''',
        whereArgs: [userId, '%$query%', '%$query%'],
        orderBy: 'issue_date DESC',
        limit: limit,
      );

      return results.map((json) => _mapToInvoiceModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to search invoices: $e');
    }
  }

  // Get invoice statistics
  Future<Map<String, dynamic>> getInvoiceStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      if (startDate != null) {
        whereClause += ' AND issue_date >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause += ' AND issue_date <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final db = await _database.database;

      // Get total count and amount
      final totalResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_count,
          SUM(total_amount) as total_amount,
          AVG(total_amount) as average_amount
        FROM ${LocalDatabase.invoicesTable}
        WHERE $whereClause
      ''', whereArgs);

      // Get status breakdown
      final statusResult = await db.rawQuery('''
        SELECT 
          status,
          COUNT(*) as count,
          SUM(total_amount) as amount
        FROM ${LocalDatabase.invoicesTable}
        WHERE $whereClause
        GROUP BY status
        ORDER BY amount DESC
      ''', whereArgs);

      // Get overdue invoices
      final now = DateTime.now().millisecondsSinceEpoch;
      final overdueResult = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as overdue_count,
          SUM(total_amount) as overdue_amount
        FROM ${LocalDatabase.invoicesTable}
        WHERE $whereClause AND status != 'paid' AND due_date < ?
      ''',
        [...whereArgs, now],
      );

      // Get monthly breakdown
      final monthlyResult = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', datetime(issue_date/1000, 'unixepoch')) as month,
          COUNT(*) as count,
          SUM(total_amount) as amount
        FROM ${LocalDatabase.invoicesTable}
        WHERE $whereClause
        GROUP BY month
        ORDER BY month DESC
      ''', whereArgs);

      return {
        'total': totalResult.first,
        'status': statusResult,
        'overdue': overdueResult.first,
        'monthly': monthlyResult,
      };
    } catch (e) {
      throw LocalDataException('Failed to get invoice stats: $e');
    }
  }

  // Get invoices by status
  Future<List<InvoiceModel>> getInvoicesByStatus(
    String userId,
    String status, {
    int? limit,
    int? offset,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.invoicesTable,
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, status],
        orderBy: 'issue_date DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((json) => _mapToInvoiceModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get invoices by status: $e');
    }
  }

  // Get overdue invoices
  Future<List<InvoiceModel>> getOverdueInvoices(String userId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final results = await _database.query(
        LocalDatabase.invoicesTable,
        where: 'user_id = ? AND status != ? AND due_date < ?',
        whereArgs: [userId, 'paid', now],
        orderBy: 'due_date ASC',
      );

      return results.map((json) => _mapToInvoiceModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get overdue invoices: $e');
    }
  }

  // Get recent invoices
  Future<List<InvoiceModel>> getRecentInvoices(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final results = await _database.query(
        LocalDatabase.invoicesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((json) => _mapToInvoiceModel(json)).toList();
    } catch (e) {
      throw LocalDataException('Failed to get recent invoices: $e');
    }
  }

  // Get next invoice number
  Future<String> getNextInvoiceNumber(String userId) async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        '''
        SELECT invoice_number
        FROM ${LocalDatabase.invoicesTable}
        WHERE user_id = ? AND invoice_number LIKE 'INV-%'
        ORDER BY created_at DESC
        LIMIT 1
      ''',
        [userId],
      );

      if (result.isEmpty) {
        return 'INV-001';
      }

      final lastNumber = result.first['invoice_number'] as String;
      final match = RegExp(r'INV-(\d+)').firstMatch(lastNumber);

      if (match != null) {
        final number = int.parse(match.group(1)!);
        return 'INV-${(number + 1).toString().padLeft(3, '0')}';
      }

      return 'INV-001';
    } catch (e) {
      throw LocalDataException('Failed to get next invoice number: $e');
    }
  }

  // Get invoice count by status
  Future<Map<String, int>> getInvoiceCountByStatus(String userId) async {
    try {
      final db = await _database.database;
      final results = await db.rawQuery(
        '''
        SELECT 
          status,
          COUNT(*) as count
        FROM ${LocalDatabase.invoicesTable}
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
      throw LocalDataException('Failed to get invoice count by status: $e');
    }
  }

  // Get total revenue for period
  Future<double> getTotalRevenueForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        '''
        SELECT SUM(total_amount) as total
        FROM ${LocalDatabase.invoicesTable}
        WHERE user_id = ? AND status = 'paid' AND issue_date >= ? AND issue_date <= ?
      ''',
        [
          userId,
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
      );

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw LocalDataException('Failed to get total revenue: $e');
    }
  }

  // Get outstanding amount
  Future<double> getOutstandingAmount(String userId) async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        '''
        SELECT SUM(total_amount) as total
        FROM ${LocalDatabase.invoicesTable}
        WHERE user_id = ? AND status != 'paid'
      ''',
        [userId],
      );

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw LocalDataException('Failed to get outstanding amount: $e');
    }
  }

  // Bulk create invoices
  Future<void> bulkCreateInvoices(List<InvoiceModel> invoices) async {
    try {
      final operations = invoices.map((invoice) {
        final invoiceData = invoice.toJson();
        invoiceData['id'] = invoice.id ?? _uuid.v4();
        invoiceData['is_synced'] = 0;
        invoiceData['sync_status'] = 'pending';

        // Convert items to JSON string
        if (invoiceData['items'] != null) {
          invoiceData['items'] = jsonEncode(invoiceData['items']);
        }

        // Convert dates to timestamps
        if (invoiceData['issueDate'] is DateTime) {
          invoiceData['issue_date'] =
              (invoiceData['issueDate'] as DateTime).millisecondsSinceEpoch;
          invoiceData.remove('issueDate');
        }

        if (invoiceData['dueDate'] is DateTime) {
          invoiceData['due_date'] =
              (invoiceData['dueDate'] as DateTime).millisecondsSinceEpoch;
          invoiceData.remove('dueDate');
        }

        // Map field names to database column names
        _mapModelFieldsToDatabase(invoiceData);

        return {
          'type': 'insert',
          'table': LocalDatabase.invoicesTable,
          'data': invoiceData,
        };
      }).toList();

      await _database.batchOperation(operations);
    } catch (e) {
      throw LocalDataException('Failed to bulk create invoices: $e');
    }
  }

  // Clear all invoices for user
  Future<void> clearUserInvoices(String userId) async {
    try {
      final db = await _database.database;
      await db.delete(
        LocalDatabase.invoicesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw LocalDataException('Failed to clear user invoices: $e');
    }
  }

  // Get revenue trends
  Future<List<Map<String, dynamic>>> getRevenueTrends(
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
          strftime('%Y-%m', datetime(issue_date/1000, 'unixepoch')) as month,
          SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END) as paid_amount,
          SUM(CASE WHEN status != 'paid' THEN total_amount ELSE 0 END) as pending_amount,
          COUNT(*) as total_count,
          COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_count
        FROM ${LocalDatabase.invoicesTable}
        WHERE user_id = ? AND issue_date >= ?
        GROUP BY month
        ORDER BY month ASC
      ''',
        [userId, startDate.millisecondsSinceEpoch],
      );

      return results
          .map(
            (row) => {
              'month': row['month'],
              'paidAmount': (row['paid_amount'] as num?)?.toDouble() ?? 0.0,
              'pendingAmount':
                  (row['pending_amount'] as num?)?.toDouble() ?? 0.0,
              'totalCount': row['total_count'] as int,
              'paidCount': row['paid_count'] as int,
            },
          )
          .toList();
    } catch (e) {
      throw LocalDataException('Failed to get revenue trends: $e');
    }
  }

  // Helper method to map model fields to database fields
  void _mapModelFieldsToDatabase(Map<String, dynamic> data) {
    data['user_id'] = data.remove('userId');
    data['client_id'] = data.remove('clientId');
    data['invoice_number'] = data.remove('invoiceNumber');
    data['total_amount'] = data.remove('totalAmount');
    data['subtotal'] = data.remove('subtotal');
    data['tax_rate'] = data.remove('taxRate');
    data['tax_amount'] = data.remove('taxAmount');
    data['discount_amount'] = data.remove('discountAmount');
    data['pdf_url'] = data.remove('pdfUrl');
  }

  // Helper method to map database result to InvoiceModel
  InvoiceModel _mapToInvoiceModel(Map<String, dynamic> json) {
    // Convert timestamps back to DateTime
    if (json['issue_date'] is int) {
      json['issueDate'] = DateTime.fromMillisecondsSinceEpoch(
        json['issue_date'] as int,
      );
    }

    if (json['due_date'] is int) {
      json['dueDate'] = DateTime.fromMillisecondsSinceEpoch(
        json['due_date'] as int,
      );
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

    // Convert items from JSON string
    if (json['items'] != null && json['items'] is String) {
      try {
        json['items'] = jsonDecode(json['items'] as String);
      } catch (e) {
        json['items'] = [];
      }
    }

    // Clean up database-specific fields
    json.remove('is_synced');
    json.remove('sync_status');
    json.remove('created_at');
    json.remove('updated_at');
    json.remove('issue_date');
    json.remove('due_date');

    // Map database field names to model field names
    json['userId'] = json.remove('user_id');
    json['clientId'] = json.remove('client_id');
    json['invoiceNumber'] = json.remove('invoice_number');
    json['totalAmount'] = json.remove('total_amount');
    json['taxRate'] = json.remove('tax_rate');
    json['taxAmount'] = json.remove('tax_amount');
    json['discountAmount'] = json.remove('discount_amount');
    json['pdfUrl'] = json.remove('pdf_url');

    return InvoiceModel.fromJson(json);
  }
}
