import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/exceptions.dart';

class CacheManager {
  static CacheManager? _instance;
  SharedPreferences? _prefs;

  CacheManager._internal();

  factory CacheManager() {
    _instance ??= CacheManager._internal();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cache data with expiry
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    if (_prefs == null) await init();

    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };

    await _prefs!.setString(key, jsonEncode(cacheData));
  }

  // Get cached data
  T? getCachedData<T>(String key) {
    if (_prefs == null) return null;

    final cachedString = _prefs!.getString(key);
    if (cachedString == null) return null;

    try {
      final cacheData = jsonDecode(cachedString);
      final timestamp = cacheData['timestamp'] as int;
      final expiryMillis = cacheData['expiry'] as int?;

      // Check if expired
      if (expiryMillis != null) {
        final expiryTime = timestamp + expiryMillis;
        if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
          _prefs!.remove(key);
          return null;
        }
      }

      return cacheData['data'] as T;
    } catch (e) {
      _prefs!.remove(key);
      return null;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    if (_prefs == null) await init();
    await _prefs!.clear();
  }

  // Remove specific cache
  Future<void> removeCache(String key) async {
    if (_prefs == null) await init();
    await _prefs!.remove(key);
  }
}
