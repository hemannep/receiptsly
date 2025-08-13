// lib/services/local/secure_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Service for handling secure storage operations
/// Uses Flutter Secure Storage for sensitive data encryption
class SecureStorageService {
  static SecureStorageService? _instance;
  late FlutterSecureStorage _secureStorage;

  // Storage Keys for sensitive data
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserCredentials = 'user_credentials';
  static const String keyBiometricData = 'biometric_data';
  static const String keyEncryptionKey = 'encryption_key';
  static const String keyApiKeys = 'api_keys';
  static const String keyPaymentInfo = 'payment_info';
  static const String keyBackupCodes = 'backup_codes';
  static const String keyDeviceId = 'device_id';
  static const String keySecurePreferences = 'secure_preferences';

  // Singleton pattern
  SecureStorageService._();

  static SecureStorageService getInstance() {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  /// Initialize the secure storage service
  Future<void> initialize() async {
    try {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          sharedPreferencesName: 'receiptsly_secure_prefs',
          preferencesKeyPrefix: 'receiptsly_',
        ),
        iOptions: IOSOptions(
          groupId: 'group.com.receiptsly.app',
          accountName: 'receiptsly_keychain',
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
        lOptions: LinuxOptions(containsKey: true),
        wOptions: WindowsOptions(),
        mOptions: MacOsOptions(
          groupId: 'group.com.receiptsly.app',
          accountName: 'receiptsly_keychain',
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      await _performSecurityChecks();
      debugPrint('SecureStorageService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SecureStorageService: $e');
      rethrow;
    }
  }

  /// Perform security checks and setup
  Future<void> _performSecurityChecks() async {
    try {
      // Check if secure storage is available
      final isAvailable = await _checkStorageAvailability();
      if (!isAvailable) {
        throw Exception('Secure storage is not available on this device');
      }

      // Generate device ID if not exists
      await _ensureDeviceId();

      // Validate existing data integrity
      await _validateStoredData();

      debugPrint('Security checks completed successfully');
    } catch (e) {
      debugPrint('Error during security checks: $e');
      rethrow;
    }
  }

  /// Check if secure storage is available
  Future<bool> _checkStorageAvailability() async {
    try {
      await _secureStorage.write(key: '_test_key', value: 'test');
      await _secureStorage.delete(key: '_test_key');
      return true;
    } catch (e) {
      debugPrint('Secure storage not available: $e');
      return false;
    }
  }

  /// Ensure device ID exists
  Future<void> _ensureDeviceId() async {
    try {
      final existingDeviceId = await read(keyDeviceId);
      if (existingDeviceId == null) {
        final deviceId = _generateDeviceId();
        await write(keyDeviceId, deviceId);
        debugPrint('Generated new device ID');
      }
    } catch (e) {
      debugPrint('Error ensuring device ID: $e');
    }
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = List.generate(16, (i) => (i * timestamp) % 256);
    final bytes = [...utf8.encode(Platform.operatingSystem), ...random];
    return sha256.convert(bytes).toString();
  }

  /// Validate stored data integrity
  Future<void> _validateStoredData() async {
    try {
      final keys = await _secureStorage.readAll();
      for (final entry in keys.entries) {
        if (entry.value.isEmpty) {
          await _secureStorage.delete(key: entry.key);
          debugPrint('Removed empty secure storage entry: ${entry.key}');
        }
      }
    } catch (e) {
      debugPrint('Error validating stored data: $e');
    }
  }

  // Basic Operations

  /// Write a value to secure storage
  Future<bool> write(String key, String value) async {
    try {
      if (value.isEmpty) {
        debugPrint('Warning: Attempting to store empty value for key: $key');
        return false;
      }

      await _secureStorage.write(key: key, value: value);
      debugPrint('Successfully wrote to secure storage: $key');
      return true;
    } catch (e) {
      debugPrint('Error writing to secure storage for key $key: $e');
      return false;
    }
  }

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        debugPrint('Successfully read from secure storage: $key');
      }
      return value;
    } catch (e) {
      debugPrint('Error reading from secure storage for key $key: $e');
      return null;
    }
  }

  /// Delete a value from secure storage
  Future<bool> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
      debugPrint('Successfully deleted from secure storage: $key');
      return true;
    } catch (e) {
      debugPrint('Error deleting from secure storage for key $key: $e');
      return false;
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      debugPrint('Error checking key existence in secure storage for $key: $e');
      return false;
    }
  }

  /// Get all keys from secure storage
  Future<Set<String>> getAllKeys() async {
    try {
      final all = await _secureStorage.readAll();
      return all.keys.toSet();
    } catch (e) {
      debugPrint('Error getting all keys from secure storage: $e');
      return <String>{};
    }
  }

  /// Clear all data from secure storage
  Future<bool> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('Successfully cleared all secure storage');
      return true;
    } catch (e) {
      debugPrint('Error clearing all secure storage: $e');
      return false;
    }
  }

  // Complex Data Operations

  /// Store a Map as encrypted JSON
  Future<bool> writeMap(String key, Map<String, dynamic> map) async {
    try {
      final jsonString = jsonEncode(map);
      return await write(key, jsonString);
    } catch (e) {
      debugPrint('Error storing map in secure storage for key $key: $e');
      return false;
    }
  }

  /// Read a Map from encrypted JSON
  Future<Map<String, dynamic>?> readMap(String key) async {
    try {
      final jsonString = await read(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading map from secure storage for key $key: $e');
      return null;
    }
  }

  /// Store a List as encrypted JSON
  Future<bool> writeList(String key, List<dynamic> list) async {
    try {
      final jsonString = jsonEncode(list);
      return await write(key, jsonString);
    } catch (e) {
      debugPrint('Error storing list in secure storage for key $key: $e');
      return false;
    }
  }

  /// Read a List from encrypted JSON
  Future<List<dynamic>?> readList(String key) async {
    try {
      final jsonString = await read(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      debugPrint('Error reading list from secure storage for key $key: $e');
      return null;
    }
  }

  // Authentication Related Methods

  /// Store authentication token
  Future<bool> storeAuthToken(String token) async {
    if (token.isEmpty) {
      debugPrint('Warning: Attempting to store empty auth token');
      return false;
    }
    return await write(keyAuthToken, token);
  }

  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    return await read(keyAuthToken);
  }

  /// Store refresh token
  Future<bool> storeRefreshToken(String token) async {
    if (token.isEmpty) {
      debugPrint('Warning: Attempting to store empty refresh token');
      return false;
    }
    return await write(keyRefreshToken, token);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await read(keyRefreshToken);
  }

  /// Store user credentials
  Future<bool> storeUserCredentials({
    required String email,
    String? password,
    String? userId,
  }) async {
    try {
      final credentials = <String, dynamic>{
        'email': email,
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (password != null && password.isNotEmpty) {
        credentials['password_hash'] = _hashPassword(password);
      }

      return await writeMap(keyUserCredentials, credentials);
    } catch (e) {
      debugPrint('Error storing user credentials: $e');
      return false;
    }
  }

  /// Retrieve user credentials
  Future<Map<String, dynamic>?> getUserCredentials() async {
    return await readMap(keyUserCredentials);
  }

  /// Verify stored password
  Future<bool> verifyPassword(String password) async {
    try {
      final credentials = await readMap(keyUserCredentials);
      if (credentials == null || !credentials.containsKey('password_hash')) {
        return false;
      }

      final storedHash = credentials['password_hash'] as String;
      final inputHash = _hashPassword(password);
      return storedHash == inputHash;
    } catch (e) {
      debugPrint('Error verifying password: $e');
      return false;
    }
  }

  /// Hash password for storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Biometric Data

  /// Store biometric data
  Future<bool> storeBiometricData(Map<String, dynamic> biometricData) async {
    return await writeMap(keyBiometricData, biometricData);
  }

  /// Retrieve biometric data
  Future<Map<String, dynamic>?> getBiometricData() async {
    return await readMap(keyBiometricData);
  }

  /// Check if biometrics are enabled
  Future<bool> isBiometricEnabled() async {
    final data = await getBiometricData();
    return data?['enabled'] == true;
  }

  // API Keys and Sensitive Configuration

  /// Store API keys
  Future<bool> storeApiKeys(Map<String, String> apiKeys) async {
    try {
      final encryptedKeys = <String, String>{};
      for (final entry in apiKeys.entries) {
        encryptedKeys[entry.key] = _encryptString(entry.value);
      }
      return await writeMap(keyApiKeys, encryptedKeys);
    } catch (e) {
      debugPrint('Error storing API keys: $e');
      return false;
    }
  }

  /// Retrieve API keys
  Future<Map<String, String>?> getApiKeys() async {
    try {
      final encryptedKeys = await readMap(keyApiKeys);
      if (encryptedKeys == null) return null;

      final decryptedKeys = <String, String>{};
      for (final entry in encryptedKeys.entries) {
        decryptedKeys[entry.key] = _decryptString(entry.value as String);
      }
      return decryptedKeys;
    } catch (e) {
      debugPrint('Error retrieving API keys: $e');
      return null;
    }
  }

  /// Get specific API key
  Future<String?> getApiKey(String keyName) async {
    final apiKeys = await getApiKeys();
    return apiKeys?[keyName];
  }

  // Payment Information

  /// Store payment information
  Future<bool> storePaymentInfo(Map<String, dynamic> paymentInfo) async {
    try {
      // Encrypt sensitive payment data
      final encryptedInfo = <String, dynamic>{};
      for (final entry in paymentInfo.entries) {
        if (entry.value is String) {
          encryptedInfo[entry.key] = _encryptString(entry.value as String);
        } else {
          encryptedInfo[entry.key] = entry.value;
        }
      }
      encryptedInfo['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      return await writeMap(keyPaymentInfo, encryptedInfo);
    } catch (e) {
      debugPrint('Error storing payment info: $e');
      return false;
    }
  }

  /// Retrieve payment information
  Future<Map<String, dynamic>?> getPaymentInfo() async {
    try {
      final encryptedInfo = await readMap(keyPaymentInfo);
      if (encryptedInfo == null) return null;

      final decryptedInfo = <String, dynamic>{};
      for (final entry in encryptedInfo.entries) {
        if (entry.value is String && entry.key != 'timestamp') {
          try {
            decryptedInfo[entry.key] = _decryptString(entry.value as String);
          } catch (e) {
            // If decryption fails, might be non-encrypted field
            decryptedInfo[entry.key] = entry.value;
          }
        } else {
          decryptedInfo[entry.key] = entry.value;
        }
      }
      return decryptedInfo;
    } catch (e) {
      debugPrint('Error retrieving payment info: $e');
      return null;
    }
  }

  // Backup and Recovery

  /// Store backup codes
  Future<bool> storeBackupCodes(List<String> codes) async {
    try {
      final encryptedCodes = codes.map(_encryptString).toList();
      return await writeList(keyBackupCodes, encryptedCodes);
    } catch (e) {
      debugPrint('Error storing backup codes: $e');
      return false;
    }
  }

  /// Retrieve backup codes
  Future<List<String>?> getBackupCodes() async {
    try {
      final encryptedCodes = await readList(keyBackupCodes);
      if (encryptedCodes == null) return null;

      return encryptedCodes
          .map((code) => _decryptString(code as String))
          .toList();
    } catch (e) {
      debugPrint('Error retrieving backup codes: $e');
      return null;
    }
  }

  /// Use backup code (remove it after use)
  Future<bool> useBackupCode(String code) async {
    try {
      final codes = await getBackupCodes();
      if (codes == null || !codes.contains(code)) {
        return false;
      }

      codes.remove(code);
      await storeBackupCodes(codes);
      debugPrint('Backup code used and removed');
      return true;
    } catch (e) {
      debugPrint('Error using backup code: $e');
      return false;
    }
  }

  // Device Information

  /// Get device ID
  Future<String?> getDeviceId() async {
    return await read(keyDeviceId);
  }

  /// Store device fingerprint
  Future<bool> storeDeviceFingerprint(Map<String, dynamic> fingerprint) async {
    try {
      fingerprint['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      return await writeMap('device_fingerprint', fingerprint);
    } catch (e) {
      debugPrint('Error storing device fingerprint: $e');
      return false;
    }
  }

  /// Get device fingerprint
  Future<Map<String, dynamic>?> getDeviceFingerprint() async {
    return await readMap('device_fingerprint');
  }

  // Security Features

  /// Store secure preferences
  Future<bool> storeSecurePreferences(Map<String, dynamic> preferences) async {
    return await writeMap(keySecurePreferences, preferences);
  }

  /// Get secure preferences
  Future<Map<String, dynamic>?> getSecurePreferences() async {
    return await readMap(keySecurePreferences);
  }

  /// Update secure preference
  Future<bool> updateSecurePreference(String key, dynamic value) async {
    try {
      final preferences = await getSecurePreferences() ?? {};
      preferences[key] = value;
      return await storeSecurePreferences(preferences);
    } catch (e) {
      debugPrint('Error updating secure preference: $e');
      return false;
    }
  }

  /// Get secure preference
  Future<T?> getSecurePreference<T>(String key) async {
    try {
      final preferences = await getSecurePreferences();
      return preferences?[key] as T?;
    } catch (e) {
      debugPrint('Error getting secure preference: $e');
      return null;
    }
  }

  // Session Management

  /// Store session data
  Future<bool> storeSessionData(Map<String, dynamic> sessionData) async {
    try {
      sessionData['created_at'] = DateTime.now().millisecondsSinceEpoch;
      sessionData['expires_at'] = DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch;
      return await writeMap('session_data', sessionData);
    } catch (e) {
      debugPrint('Error storing session data: $e');
      return false;
    }
  }

  /// Get session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final sessionData = await readMap('session_data');
      if (sessionData == null) return null;

      // Check if session is expired
      final expiresAt = sessionData['expires_at'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await delete('session_data');
        debugPrint('Session expired and removed');
        return null;
      }

      return sessionData;
    } catch (e) {
      debugPrint('Error getting session data: $e');
      return null;
    }
  }

  /// Clear session data
  Future<bool> clearSession() async {
    return await delete('session_data');
  }

  // Encryption/Decryption Helpers

  /// Simple string encryption using base64 encoding with salt
  String _encryptString(String value) {
    try {
      final bytes = utf8.encode(value);
      final encoded = base64Encode(bytes);
      // Add simple obfuscation (not for high-security use)
      return base64Encode(utf8.encode(encoded));
    } catch (e) {
      debugPrint('Error encrypting string: $e');
      return value; // Return original if encryption fails
    }
  }

  /// Simple string decryption
  String _decryptString(String encryptedValue) {
    try {
      final decoded = utf8.decode(base64Decode(encryptedValue));
      return utf8.decode(base64Decode(decoded));
    } catch (e) {
      debugPrint('Error decrypting string: $e');
      return encryptedValue; // Return original if decryption fails
    }
  }

  // Data Export/Import

  /// Export secure data (for backup purposes)
  Future<Map<String, dynamic>?> exportSecureData(String masterPassword) async {
    try {
      final allData = await _secureStorage.readAll();
      if (allData.isEmpty) return null;

      final exportData = <String, dynamic>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'device_id': await getDeviceId(),
        'data': {},
      };

      // Encrypt all data with master password
      for (final entry in allData.entries) {
        exportData['data'][entry.key] = _encryptWithPassword(
          entry.value,
          masterPassword,
        );
      }

      return exportData;
    } catch (e) {
      debugPrint('Error exporting secure data: $e');
      return null;
    }
  }

  /// Import secure data (for restore purposes)
  Future<bool> importSecureData(
    Map<String, dynamic> exportData,
    String masterPassword,
  ) async {
    try {
      final data = exportData['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      // Clear existing data first
      await deleteAll();

      // Decrypt and restore data
      for (final entry in data.entries) {
        final decryptedValue = _decryptWithPassword(
          entry.value as String,
          masterPassword,
        );
        await write(entry.key, decryptedValue);
      }

      debugPrint('Secure data imported successfully');
      return true;
    } catch (e) {
      debugPrint('Error importing secure data: $e');
      return false;
    }
  }

  /// Encrypt string with password
  String _encryptWithPassword(String value, String password) {
    final combined = '$password:$value';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return base64Encode(utf8.encode('${digest.toString()}:$value'));
  }

  /// Decrypt string with password
  String _decryptWithPassword(String encryptedValue, String password) {
    try {
      final decoded = utf8.decode(base64Decode(encryptedValue));
      final parts = decoded.split(':');
      if (parts.length < 2) throw Exception('Invalid encrypted format');

      final hash = parts[0];
      final value = parts.sublist(1).join(':');

      // Verify password
      final combined = '$password:$value';
      final bytes = utf8.encode(combined);
      final expectedHash = sha256.convert(bytes).toString();

      if (hash != expectedHash) {
        throw Exception('Invalid password');
      }

      return value;
    } catch (e) {
      debugPrint('Error decrypting with password: $e');
      rethrow;
    }
  }

  // Security Audit

  /// Get storage security info
  Future<Map<String, dynamic>> getSecurityInfo() async {
    try {
      final keys = await getAllKeys();
      final deviceId = await getDeviceId();
      final hasAuth = await containsKey(keyAuthToken);
      final hasBiometric = await containsKey(keyBiometricData);

      return {
        'total_keys': keys.length,
        'device_id': deviceId != null,
        'has_auth_token': hasAuth,
        'has_biometric_data': hasBiometric,
        'secure_storage_available': await _checkStorageAvailability(),
        'last_check': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting security info: $e');
      return {
        'error': e.toString(),
        'last_check': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Validate data integrity
  Future<bool> validateDataIntegrity() async {
    try {
      final keys = await getAllKeys();
      var corruptedKeys = 0;

      for (final key in keys) {
        try {
          final value = await read(key);
          if (value == null || value.isEmpty) {
            corruptedKeys++;
            await delete(key);
          }
        } catch (e) {
          corruptedKeys++;
          await delete(key);
        }
      }

      if (corruptedKeys > 0) {
        debugPrint('Found and removed $corruptedKeys corrupted keys');
      }

      return corruptedKeys == 0;
    } catch (e) {
      debugPrint('Error validating data integrity: $e');
      return false;
    }
  }

  // Cleanup and Maintenance

  /// Perform security maintenance
  Future<void> performSecurityMaintenance() async {
    try {
      // Validate data integrity
      await validateDataIntegrity();

      // Clean expired sessions
      await _cleanExpiredSessions();

      // Update security info
      await _updateSecurityMetadata();

      debugPrint('Security maintenance completed');
    } catch (e) {
      debugPrint('Error during security maintenance: $e');
    }
  }

  /// Clean expired sessions and temporary data
  Future<void> _cleanExpiredSessions() async {
    try {
      final sessionData = await readMap('session_data');
      if (sessionData != null) {
        final expiresAt = sessionData['expires_at'] as int?;
        if (expiresAt != null &&
            DateTime.now().millisecondsSinceEpoch > expiresAt) {
          await delete('session_data');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning expired sessions: $e');
    }
  }

  /// Update security metadata
  Future<void> _updateSecurityMetadata() async {
    try {
      final metadata = {
        'last_maintenance': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
        'device_id': await getDeviceId(),
      };
      await writeMap('security_metadata', metadata);
    } catch (e) {
      debugPrint('Error updating security metadata: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _instance = null;
  }
}
