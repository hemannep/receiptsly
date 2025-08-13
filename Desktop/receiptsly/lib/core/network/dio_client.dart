// lib/core/network/dio_client.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:receiptsly/core/config/app_config.dart';

import '../config/environment.dart';
import '../constants/api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Dummy certificate pinning interceptor (replace with your real implementation if needed)
class CertificatePinningInterceptor extends Interceptor {
  final List<String> allowedSHAFingerprints;
  CertificatePinningInterceptor({required this.allowedSHAFingerprints});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // NOTE: Implement actual certificate pinning here if required.
    handler.next(options);
  }
}

/// Dio client configuration and setup
class DioClient {
  static Dio? _instance;

  /// Get singleton Dio instance
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  /// Create and configure Dio instance
  static Dio _createDio() {
    final dio = Dio();

    dio.options = BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': _getUserAgent(),
        'X-App-Version': AppConfig.instance.appVersion,
        'X-Platform': Platform.operatingSystem,
      },
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    );

    _addInterceptors(dio);
    return dio;
  }

  /// Add interceptors
  static void _addInterceptors(Dio dio) {
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(ErrorInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    dio.interceptors.add(RetryInterceptor(dio));
    dio.interceptors.add(CacheInterceptor());
  }

  static String _getUserAgent() {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    return 'Receiptsly/${AppConfig.instance.appVersion} ($platform $version)';
  }

  static void updateBaseUrl(String baseUrl) {
    instance.options.baseUrl = baseUrl;
  }

  static void addGlobalHeader(String key, String value) {
    instance.options.headers[key] = value;
  }

  static void removeGlobalHeader(String key) {
    instance.options.headers.remove(key);
  }

  static void setAuthToken(String token) {
    instance.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    instance.options.headers.remove('Authorization');
  }

  static void reset() {
    _instance?.close();
    _instance = null;
  }
}

/// Retry interceptor for network failures
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;

  RetryInterceptor(
    this.dio, {
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final retryCount = request.extra['retryCount'] ?? 0;

    if (_shouldRetry(err, retryCount)) {
      try {
        await Future.delayed(retryDelay * (retryCount + 1));
        request.extra['retryCount'] = retryCount + 1;
        final response = await dio.fetch(request);
        handler.resolve(response);
        return;
      } catch (_) {}
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err, int retryCount) {
    if (retryCount >= maxRetries) return false;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    if (err.response?.statusCode != null &&
        retryStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }

    if (err.type == DioExceptionType.connectionError) {
      return true;
    }
    return false;
  }
}

/// Cache interceptor for GET requests
class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration defaultCacheDuration = const Duration(minutes: 5);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toLowerCase() == 'get') {
      final cacheKey = _generateCacheKey(options);
      final cacheEntry = _cache[cacheKey];

      if (cacheEntry != null && !cacheEntry.isExpired) {
        final response = Response(
          data: cacheEntry.data,
          statusCode: 200,
          requestOptions: options,
          headers: Headers.fromMap({
            'x-cache': ['HIT'],
          }),
        );
        handler.resolve(response);
        return;
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (options.method.toLowerCase() == 'get' &&
        response.statusCode == 200 &&
        response.data != null) {
      final cacheKey = _generateCacheKey(options);
      final cacheDuration = _getCacheDuration(options);
      _cache[cacheKey] = CacheEntry(
        data: response.data,
        expiry: DateTime.now().add(cacheDuration),
      );
      _cleanupExpiredEntries();
    }
    handler.next(response);
  }

  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final params = jsonEncode(options.queryParameters);
    return '$uri-$params';
  }

  Duration _getCacheDuration(RequestOptions options) {
    final cacheControl = options.headers['Cache-Control'];
    if (cacheControl != null && cacheControl.contains('max-age=')) {
      final maxAge = RegExp(
        r'max-age=(\d+)',
      ).firstMatch(cacheControl)?.group(1);
      if (maxAge != null) {
        return Duration(seconds: int.parse(maxAge));
      }
    }
    return defaultCacheDuration;
  }

  void _cleanupExpiredEntries() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  CacheEntry({required this.data, required this.expiry});
  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Dio environment configuration
class DioConfiguration {
  static Dio createDevelopmentDio() {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    dio.interceptors.addAll([
      LoggingInterceptor(),
      PrettyDioLogger(requestBody: true, responseBody: true),
    ]);
    return dio;
  }

  static Dio createProductionDio() {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': DioClient._getUserAgent(),
      },
    );
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      CertificatePinningInterceptor(
        allowedSHAFingerprints: AppConfig.instance.certificateFingerprints,
      ),
      RetryInterceptor(dio),
      CacheInterceptor(),
    ]);
    return dio;
  }

  static Dio createTestDio() {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: 'http://localhost:3000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    );
    return dio;
  }
}

/// Riverpod provider
final dioProvider = Provider<Dio>((ref) {
  switch (AppConfig.instance.environment) {
    case Environment.development:
      return DioConfiguration.createDevelopmentDio();
    case Environment.staging:
      return DioConfiguration.createProductionDio();
    case Environment.production:
      return DioConfiguration.createProductionDio();
  }
});
