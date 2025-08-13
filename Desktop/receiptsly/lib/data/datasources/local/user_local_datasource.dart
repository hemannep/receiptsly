// lib/data/datasources/local/user_local_datasource.dart
import 'dart:convert';
import '../../../core/errors/exceptions.dart';
import '../../models/user/user_model.dart';
import 'local_database.dart';

class UserLocalDataSource {
  final LocalDatabase _database;

  UserLocalDataSource(this._database);

  // Create or update user
  Future<void> saveUser(UserModel user) async {
    try {
      final userData = user.toJson();
      userData['is_synced'] = 0;

      // Map model fields to database fields
      _mapModelFieldsToDatabase(userData);

      // Check if user exists
      final existingUser = await _database.getById(
        LocalDatabase.usersTable,
        user.uid,
      );

      if (existingUser != null) {
        await _database.update(LocalDatabase.usersTable, userData, user.uid);
      } else {
        await _database.insert(LocalDatabase.usersTable, userData);
      }
    } catch (e) {
      throw LocalDataException('Failed to save user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final result = await _database.getById(LocalDatabase.usersTable, uid);

      if (result == null) return null;

      return _mapToUserModel(result);
    } catch (e) {
      throw LocalDataException('Failed to get user: $e');
    }
  }

  // Get current user (there should only be one)
  Future<UserModel?> getCurrentUser() async {
    try {
      final results = await _database.query(
        LocalDatabase.usersTable,
        limit: 1,
        orderBy: 'updated_at DESC',
      );

      if (results.isEmpty) return null;

      return _mapToUserModel(results.first);
    } catch (e) {
      throw LocalDataException('Failed to get current user: $e');
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      final userData = user.toJson();
      userData['is_synced'] = 0;

      // Map model fields to database fields
      _mapModelFieldsToDatabase(userData);

      final result = await _database.update(
        LocalDatabase.usersTable,
        userData,
        user.uid,
      );

      if (result == 0) {
        throw LocalDataException('User not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      final result = await _database.delete(LocalDatabase.usersTable, uid);

      if (result == 0) {
        throw LocalDataException('User not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to delete user: $e');
    }
  }

  // Check if user is synced
  Future<bool> isUserSynced(String uid) async {
    try {
      final result = await _database.query(
        LocalDatabase.usersTable,
        where: 'id = ? AND is_synced = ?',
        whereArgs: [uid, 1],
      );

      return result.isNotEmpty;
    } catch (e) {
      throw LocalDataException('Failed to check user sync status: $e');
    }
  }

  // Mark user as synced
  Future<void> markAsSynced(String uid) async {
    try {
      await _database.update(LocalDatabase.usersTable, {'is_synced': 1}, uid);
    } catch (e) {
      throw LocalDataException('Failed to mark user as synced: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(
    String uid,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final user = await getUserById(uid);
      if (user == null) {
        throw LocalDataException('User not found');
      }

      final updatedUser = user.copyWith(preferences: preferences);

      await updateUser(updatedUser);
    } catch (e) {
      throw LocalDataException('Failed to update user preferences: $e');
    }
  }

  // Update subscription info
  Future<void> updateSubscription(
    String uid,
    String plan,
    DateTime? validUntil,
    int monthlyLimit,
  ) async {
    try {
      final subscriptionData = {
        'subscription_plan': plan,
        'subscription_valid_until': validUntil?.millisecondsSinceEpoch,
        'monthly_receipt_limit': monthlyLimit,
        'is_synced': 0,
      };

      final result = await _database.update(
        LocalDatabase.usersTable,
        subscriptionData,
        uid,
      );

      if (result == 0) {
        throw LocalDataException('User not found');
      }
    } catch (e) {
      throw LocalDataException('Failed to update subscription: $e');
    }
  }

  // Increment receipt count
  Future<void> incrementReceiptCount(String uid) async {
    try {
      final db = await _database.database;
      await db.rawUpdate(
        '''
        UPDATE ${LocalDatabase.usersTable} 
        SET receipt_count = receipt_count + 1, 
            is_synced = 0,
            updated_at = ?
        WHERE id = ?
      ''',
        [DateTime.now().millisecondsSinceEpoch, uid],
      );
    } catch (e) {
      throw LocalDataException('Failed to increment receipt count: $e');
    }
  }

  // Reset monthly receipt count
  Future<void> resetMonthlyReceiptCount(String uid) async {
    try {
      await _database.update(LocalDatabase.usersTable, {
        'receipt_count': 0,
        'is_synced': 0,
      }, uid);
    } catch (e) {
      throw LocalDataException('Failed to reset receipt count: $e');
    }
  }

  // Check if user has reached monthly limit
  Future<bool> hasReachedMonthlyLimit(String uid) async {
    try {
      final result = await _database.query(
        LocalDatabase.usersTable,
        where: 'id = ?',
        whereArgs: [uid],
      );

      if (result.isEmpty) return true;

      final user = result.first;
      final receiptCount = user['receipt_count'] as int;
      final monthlyLimit = user['monthly_receipt_limit'] as int;

      return receiptCount >= monthlyLimit;
    } catch (e) {
      throw LocalDataException('Failed to check monthly limit: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      final db = await _database.database;

      // Get basic user info
      final userResult = await db.query(
        LocalDatabase.usersTable,
        where: 'id = ?',
        whereArgs: [uid],
      );

      if (userResult.isEmpty) {
        throw LocalDataException('User not found');
      }

      final user = userResult.first;

      // Get receipt count
      final receiptResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as total_receipts
        FROM ${LocalDatabase.receiptsTable}
        WHERE user_id = ?
      ''',
        [uid],
      );

      // Get invoice count
      final invoiceResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as total_invoices
        FROM ${LocalDatabase.invoicesTable}
        WHERE user_id = ?
      ''',
        [uid],
      );

      // Get client count
      final clientResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as total_clients
        FROM ${LocalDatabase.clientsTable}
        WHERE user_id = ?
      ''',
        [uid],
      );

      // Get total expenses
      final expenseResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total_expenses
        FROM ${LocalDatabase.receiptsTable}
        WHERE user_id = ?
      ''',
        [uid],
      );

      // Get total revenue
      final revenueResult = await db.rawQuery(
        '''
        SELECT SUM(total_amount) as total_revenue
        FROM ${LocalDatabase.invoicesTable}
        WHERE user_id = ? AND status = 'paid'
      ''',
        [uid],
      );

      return {
        'subscription_plan': user['subscription_plan'],
        'monthly_receipt_limit': user['monthly_receipt_limit'],
        'receipt_count': user['receipt_count'],
        'total_receipts': receiptResult.first['total_receipts'] as int,
        'total_invoices': invoiceResult.first['total_invoices'] as int,
        'total_clients': clientResult.first['total_clients'] as int,
        'total_expenses':
            (expenseResult.first['total_expenses'] as num?)?.toDouble() ?? 0.0,
        'total_revenue':
            (revenueResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw LocalDataException('Failed to get user stats: $e');
    }
  }

  // Update chat integration status
  Future<void> updateChatIntegration(
    String uid,
    String platform,
    bool connected, {
    Map<String, dynamic>? settings,
  }) async {
    try {
      final user = await getUserById(uid);
      if (user == null) {
        throw LocalDataException('User not found');
      }

      final chatIntegrations = Map<String, dynamic>.from(
        user.chatIntegrations ?? {},
      );
      chatIntegrations[platform] = {
        'connected': connected,
        if (settings != null) ...settings,
      };

      final updatedUser = user.copyWith(chatIntegrations: chatIntegrations);

      await updateUser(updatedUser);
    } catch (e) {
      throw LocalDataException('Failed to update chat integration: $e');
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final results = await _database.query(
        LocalDatabase.usersTable,
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapToUserModel(results.first);
    } catch (e) {
      throw LocalDataException('Failed to get user by email: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final results = await _database.query(
        LocalDatabase.usersTable,
        where: 'email = ?',
        whereArgs: [email],
      );

      return results.isNotEmpty;
    } catch (e) {
      throw LocalDataException('Failed to check email existence: $e');
    }
  }

  // Update last login
  Future<void> updateLastLogin(String uid) async {
    try {
      await _database.update(LocalDatabase.usersTable, {
        'last_login': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      }, uid);
    } catch (e) {
      throw LocalDataException('Failed to update last login: $e');
    }
  }

  // Clear all user data
  Future<void> clearAllUserData() async {
    try {
      final db = await _database.database;
      await db.delete(LocalDatabase.usersTable);
    } catch (e) {
      throw LocalDataException('Failed to clear user data: $e');
    }
  }

  // Export user data
  Future<Map<String, dynamic>> exportUserData(String uid) async {
    try {
      final user = await getUserById(uid);
      if (user == null) {
        throw LocalDataException('User not found');
      }

      final db = await _database.database;

      // Get all receipts
      final receipts = await db.query(
        LocalDatabase.receiptsTable,
        where: 'user_id = ?',
        whereArgs: [uid],
      );

      // Get all invoices
      final invoices = await db.query(
        LocalDatabase.invoicesTable,
        where: 'user_id = ?',
        whereArgs: [uid],
      );

      // Get all clients
      final clients = await db.query(
        LocalDatabase.clientsTable,
        where: 'user_id = ?',
        whereArgs: [uid],
      );

      return {
        'user': user.toJson(),
        'receipts': receipts,
        'invoices': invoices,
        'clients': clients,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw LocalDataException('Failed to export user data: $e');
    }
  }

  // Import user data
  Future<void> importUserData(Map<String, dynamic> userData) async {
    try {
      await _database.transaction((txn) async {
        // Import user
        if (userData['user'] != null) {
          final userMap = userData['user'] as Map<String, dynamic>;
          _mapModelFieldsToDatabase(userMap);
          await txn.insert(LocalDatabase.usersTable, userMap);
        }

        // Import receipts
        if (userData['receipts'] != null) {
          final receipts = userData['receipts'] as List<dynamic>;
          for (final receipt in receipts) {
            await txn.insert(
              LocalDatabase.receiptsTable,
              receipt as Map<String, dynamic>,
            );
          }
        }

        // Import invoices
        if (userData['invoices'] != null) {
          final invoices = userData['invoices'] as List<dynamic>;
          for (final invoice in invoices) {
            await txn.insert(
              LocalDatabase.invoicesTable,
              invoice as Map<String, dynamic>,
            );
          }
        }

        // Import clients
        if (userData['clients'] != null) {
          final clients = userData['clients'] as List<dynamic>;
          for (final client in clients) {
            await txn.insert(
              LocalDatabase.clientsTable,
              client as Map<String, dynamic>,
            );
          }
        }
      });
    } catch (e) {
      throw LocalDataException('Failed to import user data: $e');
    }
  }

  // Helper method to map model fields to database fields
  void _mapModelFieldsToDatabase(Map<String, dynamic> data) {
    data['business_name'] = data.remove('businessName');
    data['business_type'] = data.remove('businessType');
    data['subscription_plan'] = data.remove('subscriptionPlan');
    data['subscription_valid_until'] = data.remove('subscriptionValidUntil');
    data['monthly_receipt_limit'] = data.remove('monthlyReceiptLimit');
    data['receipt_count'] = data.remove('receiptCount');

    // Handle complex objects
    if (data['preferences'] != null) {
      data['preferences'] = jsonEncode(data['preferences']);
    }

    if (data['chatIntegrations'] != null) {
      data['chat_integrations'] = jsonEncode(data['chatIntegrations']);
      data.remove('chatIntegrations');
    }

    // Handle dates
    if (data['createdAt'] is DateTime) {
      data['created_at'] =
          (data['createdAt'] as DateTime).millisecondsSinceEpoch;
      data.remove('createdAt');
    }

    if (data['updatedAt'] is DateTime) {
      data['updated_at'] =
          (data['updatedAt'] as DateTime).millisecondsSinceEpoch;
      data.remove('updatedAt');
    }

    if (data['subscriptionValidUntil'] is DateTime) {
      data['subscription_valid_until'] =
          (data['subscriptionValidUntil'] as DateTime).millisecondsSinceEpoch;
    }
  }

  // Helper method to map database result to UserModel
  UserModel _mapToUserModel(Map<String, dynamic> json) {
    // Convert timestamps back to DateTime
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

    if (json['subscription_valid_until'] is int) {
      json['subscriptionValidUntil'] = DateTime.fromMillisecondsSinceEpoch(
        json['subscription_valid_until'] as int,
      );
    }

    // Convert JSON strings back to objects
    if (json['preferences'] != null && json['preferences'] is String) {
      try {
        json['preferences'] = jsonDecode(json['preferences'] as String);
      } catch (e) {
        json['preferences'] = <String, dynamic>{};
      }
    }

    if (json['chat_integrations'] != null &&
        json['chat_integrations'] is String) {
      try {
        json['chatIntegrations'] = jsonDecode(
          json['chat_integrations'] as String,
        );
      } catch (e) {
        json['chatIntegrations'] = <String, dynamic>{};
      }
    }

    // Clean up database-specific fields
    json.remove('is_synced');
    json.remove('created_at');
    json.remove('updated_at');
    json.remove('chat_integrations');

    // Map database field names to model field names
    json['uid'] = json.remove('id') ?? json['uid'];
    json['businessName'] = json.remove('business_name');
    json['businessType'] = json.remove('business_type');
    json['subscriptionPlan'] = json.remove('subscription_plan');
    json['subscriptionValidUntil'] = json.remove('subscription_valid_until');
    json['monthlyReceiptLimit'] = json.remove('monthly_receipt_limit');
    json['receiptCount'] = json.remove('receipt_count');

    return UserModel.fromJson(json);
  }
}
