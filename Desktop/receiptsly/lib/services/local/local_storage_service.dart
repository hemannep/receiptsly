// lib/services/local/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for handling local storage operations using SharedPreferences
/// Provides type-safe methods for storing and retrieving data
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  static const String _keyPrefix = 'receiptsly_';

  // Storage Keys
  static const String keyUserData = '${_keyPrefix}user_data';
  static const String keyUserPreferences = '${_keyPrefix}user_preferences';
  static const String keyAppSettings = '${_keyPrefix}app_settings';
  static const String keyLastSyncTime = '${_keyPrefix}last_sync_time';
  static const String keyOfflineQueue = '${_keyPrefix}offline_queue';
  static const String keySelectedCurrency = '${_keyPrefix}selected_currency';
  static const String keyDefaultCategory = '${_keyPrefix}default_category';
  static const String keyAutoSync = '${_keyPrefix}auto_sync';
  static const String keyNotificationsEnabled =
      '${_keyPrefix}notifications_enabled';
  static const String keyThemeMode = '${_keyPrefix}theme_mode';
  static const String keyLanguageCode = '${_keyPrefix}language_code';
  static const String keyOnboardingCompleted =
      '${_keyPrefix}onboarding_completed';
  static const String keyBiometricEnabled = '${_keyPrefix}biometric_enabled';
  static const String keyCacheExpiry = '${_keyPrefix}cache_expiry';
  static const String keyReceiptCategories = '${_keyPrefix}receipt_categories';
  static const String keyRecentVendors = '${_keyPrefix}recent_vendors';
  static const String keyQuickActions = '${_keyPrefix}quick_actions';

  // Singleton pattern
  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      await _performMaintenance();
      debugPrint('LocalStorageService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocalStorageService: $e');
      rethrow;
    }
  }

  /// Perform maintenance tasks like cleaning expired cache
  Future<void> _performMaintenance() async {
    try {
      await _cleanExpiredCache();
      await _validateStoredData();
    } catch (e) {
      debugPrint('Error during storage maintenance: $e');
    }
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      final keys = _preferences!.getKeys();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final key in keys) {
        if (key.contains('_cache_') && key.endsWith('_expiry')) {
          final expiry = _preferences!.getInt(key);
          if (expiry != null && expiry < now) {
            final dataKey = key.replaceAll('_expiry', '');
            await remove(dataKey);
            await remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning expired cache: $e');
    }
  }

  /// Validate stored data integrity
  Future<void> _validateStoredData() async {
    try {
      // Validate critical data structures
      final userData = await getMap(keyUserData);
      if (userData != null && !userData.containsKey('uid')) {
        await remove(keyUserData);
        debugPrint('Invalid user data removed');
      }
    } catch (e) {
      debugPrint('Error validating stored data: $e');
    }
  }

  // Basic Operations

  /// Store a string value
  Future<bool> setString(String key, String value) async {
    try {
      return await _preferences!.setString(key, value);
    } catch (e) {
      debugPrint('Error storing string for key $key: $e');
      return false;
    }
  }

  /// Retrieve a string value
  String? getString(String key, {String? defaultValue}) {
    try {
      return _preferences!.getString(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error retrieving string for key $key: $e');
      return defaultValue;
    }
  }

  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    try {
      return await _preferences!.setInt(key, value);
    } catch (e) {
      debugPrint('Error storing int for key $key: $e');
      return false;
    }
  }

  /// Retrieve an integer value
  int? getInt(String key, {int? defaultValue}) {
    try {
      return _preferences!.getInt(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error retrieving int for key $key: $e');
      return defaultValue;
    }
  }

  /// Store a double value
  Future<bool> setDouble(String key, double value) async {
    try {
      return await _preferences!.setDouble(key, value);
    } catch (e) {
      debugPrint('Error storing double for key $key: $e');
      return false;
    }
  }

  /// Retrieve a double value
  double? getDouble(String key, {double? defaultValue}) {
    try {
      return _preferences!.getDouble(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error retrieving double for key $key: $e');
      return defaultValue;
    }
  }

  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _preferences!.setBool(key, value);
    } catch (e) {
      debugPrint('Error storing bool for key $key: $e');
      return false;
    }
  }

  /// Retrieve a boolean value
  bool? getBool(String key, {bool? defaultValue}) {
    try {
      return _preferences!.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error retrieving bool for key $key: $e');
      return defaultValue;
    }
  }

  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _preferences!.setStringList(key, value);
    } catch (e) {
      debugPrint('Error storing string list for key $key: $e');
      return false;
    }
  }

  /// Retrieve a list of strings
  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    try {
      return _preferences!.getStringList(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error retrieving string list for key $key: $e');
      return defaultValue;
    }
  }

  // Complex Data Operations

  /// Store a Map as JSON
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('Error storing map for key $key: $e');
      return false;
    }
  }

  /// Retrieve a Map from JSON
  Map<String, dynamic>? getMap(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error retrieving map for key $key: $e');
      return null;
    }
  }

  /// Store a List as JSON
  Future<bool> setList(String key, List<dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('Error storing list for key $key: $e');
      return false;
    }
  }

  /// Retrieve a List from JSON
  List<dynamic>? getList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      debugPrint('Error retrieving list for key $key: $e');
      return null;
    }
  }

  // Cache Operations with Expiry

  /// Store data with expiry time
  Future<bool> setWithExpiry(String key, dynamic value, Duration expiry) async {
    try {
      final expiryTime = DateTime.now().add(expiry).millisecondsSinceEpoch;
      final success = await _storeValue(key, value);
      if (success) {
        await setInt('${key}_expiry', expiryTime);
      }
      return success;
    } catch (e) {
      debugPrint('Error storing value with expiry for key $key: $e');
      return false;
    }
  }

  /// Retrieve cached data if not expired
  T? getCached<T>(String key) {
    try {
      final expiryTime = getInt('${key}_expiry');
      if (expiryTime == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > expiryTime) {
        // Cache expired, remove it
        remove(key);
        remove('${key}_expiry');
        return null;
      }

      return _retrieveValue<T>(key);
    } catch (e) {
      debugPrint('Error retrieving cached value for key $key: $e');
      return null;
    }
  }

  /// Helper method to store different types of values
  Future<bool> _storeValue(String key, dynamic value) async {
    if (value is String) {
      return await setString(key, value);
    } else if (value is int) {
      return await setInt(key, value);
    } else if (value is double) {
      return await setDouble(key, value);
    } else if (value is bool) {
      return await setBool(key, value);
    } else if (value is List<String>) {
      return await setStringList(key, value);
    } else if (value is Map<String, dynamic>) {
      return await setMap(key, value);
    } else if (value is List) {
      return await setList(key, value);
    } else {
      // Convert to JSON string as fallback
      return await setString(key, jsonEncode(value));
    }
  }

  /// Helper method to retrieve different types of values
  T? _retrieveValue<T>(String key) {
    if (T == String) {
      return getString(key) as T?;
    } else if (T == int) {
      return getInt(key) as T?;
    } else if (T == double) {
      return getDouble(key) as T?;
    } else if (T == bool) {
      return getBool(key) as T?;
    } else if (T == List<String>) {
      return getStringList(key) as T?;
    } else if (T == Map<String, dynamic>) {
      return getMap(key) as T?;
    } else if (T == List) {
      return getList(key) as T?;
    } else {
      // Try to decode from JSON string
      final jsonString = getString(key);
      if (jsonString == null) return null;
      try {
        return jsonDecode(jsonString) as T;
      } catch (e) {
        debugPrint('Error decoding JSON for key $key: $e');
        return null;
      }
    }
  }

  // App-Specific Methods

  /// Store user data
  Future<bool> setUserData(Map<String, dynamic> userData) async {
    return await setMap(keyUserData, userData);
  }

  /// Retrieve user data
  Map<String, dynamic>? getUserData() {
    return getMap(keyUserData);
  }

  /// Store user preferences
  Future<bool> setUserPreferences(Map<String, dynamic> preferences) async {
    return await setMap(keyUserPreferences, preferences);
  }

  /// Retrieve user preferences
  Map<String, dynamic>? getUserPreferences() {
    return getMap(keyUserPreferences);
  }

  /// Set last sync time
  Future<bool> setLastSyncTime(DateTime dateTime) async {
    return await setInt(keyLastSyncTime, dateTime.millisecondsSinceEpoch);
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final timestamp = getInt(keyLastSyncTime);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Add item to offline queue
  Future<bool> addToOfflineQueue(Map<String, dynamic> item) async {
    try {
      final queue = getList(keyOfflineQueue) ?? [];
      queue.add(item);
      return await setList(keyOfflineQueue, queue);
    } catch (e) {
      debugPrint('Error adding to offline queue: $e');
      return false;
    }
  }

  /// Get offline queue
  List<dynamic> getOfflineQueue() {
    return getList(keyOfflineQueue) ?? [];
  }

  /// Clear offline queue
  Future<bool> clearOfflineQueue() async {
    return await remove(keyOfflineQueue);
  }

  /// Store recent vendors
  Future<bool> addRecentVendor(String vendor) async {
    try {
      final recent = getStringList(keyRecentVendors) ?? [];
      recent.remove(vendor); // Remove if exists
      recent.insert(0, vendor); // Add to beginning

      // Keep only last 20 vendors
      if (recent.length > 20) {
        recent.removeRange(20, recent.length);
      }

      return await setStringList(keyRecentVendors, recent);
    } catch (e) {
      debugPrint('Error adding recent vendor: $e');
      return false;
    }
  }

  /// Get recent vendors
  List<String> getRecentVendors() {
    return getStringList(keyRecentVendors) ?? [];
  }

  // Utility Methods

  /// Check if key exists
  bool containsKey(String key) {
    try {
      return _preferences!.containsKey(key);
    } catch (e) {
      debugPrint('Error checking key existence for $key: $e');
      return false;
    }
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    try {
      return await _preferences!.remove(key);
    } catch (e) {
      debugPrint('Error removing key $key: $e');
      return false;
    }
  }

  /// Clear all data
  Future<bool> clear() async {
    try {
      return await _preferences!.clear();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      return false;
    }
  }

  /// Get all keys
  Set<String> getAllKeys() {
    try {
      return _preferences!.getKeys();
    } catch (e) {
      debugPrint('Error getting all keys: $e');
      return <String>{};
    }
  }

  /// Get storage size estimate
  int getStorageSizeEstimate() {
    try {
      int totalSize = 0;
      final keys = _preferences!.getKeys();

      for (final key in keys) {
        final value = _preferences!.get(key);
        if (value is String) {
          totalSize += value.length * 2; // UTF-16 encoding
        } else {
          totalSize += value.toString().length * 2;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage size: $e');
      return 0;
    }
  }

  /// Export all data
  Map<String, dynamic> exportData() {
    try {
      final keys = _preferences!.getKeys();
      final data = <String, dynamic>{};

      for (final key in keys) {
        data[key] = _preferences!.get(key);
      }

      return data;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return {};
    }
  }

  /// Import data
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      for (final entry in data.entries) {
        await _storeValue(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    try {
      await clear();

      // Set default values
      await setBool(keyAutoSync, true);
      await setBool(keyNotificationsEnabled, true);
      await setString(keyThemeMode, 'system');
      await setString(keyDefaultCategory, 'General');
      await setString(keySelectedCurrency, 'USD');
      await setBool(keyOnboardingCompleted, false);
      await setBool(keyBiometricEnabled, false);

      debugPrint('Storage reset to defaults');
    } catch (e) {
      debugPrint('Error resetting to defaults: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _instance = null;
    _preferences = null;
  }
}
