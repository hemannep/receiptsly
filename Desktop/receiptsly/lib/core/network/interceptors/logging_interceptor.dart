// lib/core/network/interceptors/logging_interceptor.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced logging interceptor for HTTP requests and responses
class LoggingInterceptor extends Interceptor {
  final bool logRequest;
  final bool logRequestHeader;
  final bool logRequestBody;
  final bool logResponse;
  final bool logResponseHeader;
  final bool logResponseBody;
  final bool logError;
  final int maxBodyLength;
  final bool compactLogs;
  final String Function(String)? logPrint;
  final bool enableInProduction;

  LoggingInterceptor({
    this.logRequest = true,
    this.logRequestHeader = true,
    this.logRequestBody = true,
    this.logResponse = true,
    this.logResponseHeader = false,
    this.logResponseBody = true,
    this.logError = true,
    this.maxBodyLength = 2048,
    this.compactLogs = false,
    this.logPrint,
    this.enableInProduction = false,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldLog()) {
      _logRequest(options);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldLog()) {
      _logResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldLog() && logError) {
      _logError(err);
    }
    handler.next(err);
  }

  /// Check if logging should be enabled
  bool _shouldLog() {
    if (kDebugMode) return true;
    return enableInProduction;
  }

  /// Log HTTP request
  void _logRequest(RequestOptions options) {
    final startTime = DateTime.now();
    options.extra['startTime'] = startTime.millisecondsSinceEpoch;

    if (compactLogs) {
      _logCompactRequest(options);
    } else {
      _logDetailedRequest(options);
    }
  }

  /// Log HTTP response
  void _logResponse(Response response) {
    final startTime = response.requestOptions.extra['startTime'] as int?;
    final duration = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : null;

    if (compactLogs) {
      _logCompactResponse(response, duration);
    } else {
      _logDetailedResponse(response, duration);
    }
  }

  /// Log HTTP error
  void _logError(DioException error) {
    if (compactLogs) {
      _logCompactError(error);
    } else {
      _logDetailedError(error);
    }
  }

  /// Log compact request format
  void _logCompactRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    final uri = options.uri.toString();
    final hasData = options.data != null;

    _print('🚀 $method $uri ${hasData ? '(with body)' : ''}');
  }

  /// Log detailed request format
  void _logDetailedRequest(RequestOptions options) {
    final lines = <String>[];

    // Request line
    lines.add('┌─────────────────────────────────────────────────────────────');
    lines.add('│ 🚀 REQUEST');
    lines.add('├─────────────────────────────────────────────────────────────');
    lines.add('│ ${options.method.toUpperCase()} ${options.uri}');

    // Headers
    if (logRequestHeader && options.headers.isNotEmpty) {
      lines.add('├─ Headers:');
      options.headers.forEach((key, value) {
        if (_shouldLogHeader(key)) {
          lines.add('│   $key: ${_sanitizeHeaderValue(key, value)}');
        }
      });
    }

    // Query parameters
    if (options.queryParameters.isNotEmpty) {
      lines.add('├─ Query Parameters:');
      options.queryParameters.forEach((key, value) {
        lines.add('│   $key: $value');
      });
    }

    // Request body
    if (logRequestBody && options.data != null) {
      lines.add('├─ Body:');
      final bodyStr = _formatBody(options.data);
      lines.addAll(bodyStr.split('\n').map((line) => '│   $line'));
    }

    lines.add('└─────────────────────────────────────────────────────────────');

    for (final line in lines) {
      _print(line);
    }
  }

  /// Log compact response format
  void _logCompactResponse(Response response, int? duration) {
    final status = response.statusCode;
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri.toString();
    final durationStr = duration != null ? '${duration}ms' : '';
    final statusIcon = _getStatusIcon(status);

    _print('$statusIcon $status $method $uri $durationStr');
  }

  /// Log detailed response format
  void _logDetailedResponse(Response response, int? duration) {
    final lines = <String>[];
    final status = response.statusCode;
    final statusIcon = _getStatusIcon(status);

    lines.add('┌─────────────────────────────────────────────────────────────');
    lines.add('│ $statusIcon RESPONSE');
    lines.add('├─────────────────────────────────────────────────────────────');
    lines.add('│ Status: $status ${response.statusMessage ?? ''}');

    if (duration != null) {
      lines.add('│ Duration: ${duration}ms');
    }

    lines.add('│ URL: ${response.requestOptions.uri}');

    // Response headers
    if (logResponseHeader && response.headers.map.isNotEmpty) {
      lines.add('├─ Headers:');
      response.headers.forEach((key, values) {
        if (_shouldLogHeader(key)) {
          lines.add('│   $key: ${values.join(', ')}');
        }
      });
    }

    // Response body
    if (logResponseBody && response.data != null) {
      lines.add('├─ Body:');
      final bodyStr = _formatBody(response.data);
      lines.addAll(bodyStr.split('\n').map((line) => '│   $line'));
    }

    lines.add('└─────────────────────────────────────────────────────────────');

    for (final line in lines) {
      _print(line);
    }
  }

  /// Log compact error format
  void _logCompactError(DioException error) {
    final method = error.requestOptions.method.toUpperCase();
    final uri = error.requestOptions.uri.toString();
    final status = error.response?.statusCode;
    final errorType = error.type.toString().split('.').last;

    _print('❌ ${status ?? errorType} $method $uri - ${error.message}');
  }

  /// Log detailed error format
  void _logDetailedError(DioException error) {
    final lines = <String>[];

    lines.add('┌─────────────────────────────────────────────────────────────');
    lines.add('│ ❌ ERROR');
    lines.add('├─────────────────────────────────────────────────────────────');
    lines.add('│ Type: ${error.type}');
    lines.add('│ URL: ${error.requestOptions.uri}');
    lines.add('│ Method: ${error.requestOptions.method.toUpperCase()}');

    if (error.response != null) {
      lines.add('│ Status: ${error.response!.statusCode}');

      if (error.response!.data != null) {
        lines.add('├─ Error Response:');
        final bodyStr = _formatBody(error.response!.data);
        lines.addAll(bodyStr.split('\n').map((line) => '│   $line'));
      }
    }

    if (error.message != null) {
      lines.add('├─ Message:');
      lines.add('│   ${error.message}');
    }

    if (error.stackTrace != null) {
      lines.add('├─ Stack Trace:');
      final stackLines = error.stackTrace.toString().split('\n').take(5);
      lines.addAll(stackLines.map((line) => '│   $line'));
    }

    lines.add('└─────────────────────────────────────────────────────────────');

    for (final line in lines) {
      _print(line);
    }
  }

  /// Format request/response body for logging
  String _formatBody(dynamic body) {
    if (body == null) return 'null';

    String bodyStr;

    if (body is FormData) {
      bodyStr =
          'FormData(${body.fields.length} fields, ${body.files.length} files)';
    } else if (body is String) {
      bodyStr = body;
    } else {
      try {
        bodyStr = JsonEncoder.withIndent('  ').convert(body);
      } catch (e) {
        bodyStr = body.toString();
      }
    }

    // Truncate if too long
    if (bodyStr.length > maxBodyLength) {
      bodyStr = '${bodyStr.substring(0, maxBodyLength)}... (truncated)';
    }

    return bodyStr;
  }

  /// Get status icon based on HTTP status code
  String _getStatusIcon(int? status) {
    if (status == null) return '❓';

    if (status >= 200 && status < 300) return '✅';
    if (status >= 300 && status < 400) return '🔄';
    if (status >= 400 && status < 500) return '⚠️';
    if (status >= 500) return '🔥';

    return '❓';
  }

  /// Check if header should be logged (exclude sensitive headers)
  bool _shouldLogHeader(String headerName) {
    final lowerName = headerName.toLowerCase();
    const sensitiveHeaders = {
      'authorization',
      'cookie',
      'x-api-key',
      'x-auth-token',
      'access-token',
      'refresh-token',
    };

    return !sensitiveHeaders.contains(lowerName);
  }

  /// Sanitize header value for logging
  String _sanitizeHeaderValue(String headerName, dynamic value) {
    final lowerName = headerName.toLowerCase();
    const sensitiveHeaders = {
      'authorization',
      'cookie',
      'x-api-key',
      'x-auth-token',
      'access-token',
      'refresh-token',
    };

    if (sensitiveHeaders.contains(lowerName)) {
      return '***REDACTED***';
    }

    return value.toString();
  }

  /// Print log message
  void _print(String message) {
    if (logPrint != null) {
      logPrint!(message);
    } else {
      debugPrint(message);
    }
  }
}

/// Performance logging interceptor
class PerformanceLoggingInterceptor extends Interceptor {
  final Map<String, List<int>> _requestTimes = {};
  final bool logSlowRequests;
  final Duration slowRequestThreshold;

  PerformanceLoggingInterceptor({
    this.logSlowRequests = true,
    this.slowRequestThreshold = const Duration(seconds: 3),
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _recordRequestTime(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordRequestTime(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _recordRequestTime(RequestOptions options, int? statusCode) {
    final startTime = options.extra['startTime'] as int?;
    if (startTime == null) return;

    final duration = DateTime.now().millisecondsSinceEpoch - startTime;
    final endpoint = '${options.method} ${options.path}';

    _requestTimes.putIfAbsent(endpoint, () => []).add(duration);

    // Log slow requests
    if (logSlowRequests && duration > slowRequestThreshold.inMilliseconds) {
      debugPrint('🐌 Slow request detected: $endpoint took ${duration}ms');
    }

    // Periodically log performance stats
    if (_requestTimes[endpoint]!.length % 10 == 0) {
      _logPerformanceStats(endpoint);
    }
  }

  void _logPerformanceStats(String endpoint) {
    final times = _requestTimes[endpoint]!;
    if (times.isEmpty) return;

    final avg = times.reduce((a, b) => a + b) / times.length;
    final min = times.reduce((a, b) => a < b ? a : b);
    final max = times.reduce((a, b) => a > b ? a : b);

    times.sort();
    final median = times.length % 2 == 0
        ? (times[times.length ~/ 2 - 1] + times[times.length ~/ 2]) / 2
        : times[times.length ~/ 2].toDouble();

    debugPrint('📊 Performance stats for $endpoint:');
    debugPrint('   Requests: ${times.length}');
    debugPrint('   Average: ${avg.toStringAsFixed(1)}ms');
    debugPrint('   Median: ${median.toStringAsFixed(1)}ms');
    debugPrint('   Min: ${min}ms');
    debugPrint('   Max: ${max}ms');
  }

  /// Get performance statistics
  Map<String, Map<String, double>> getPerformanceStats() {
    final stats = <String, Map<String, double>>{};

    _requestTimes.forEach((endpoint, times) {
      if (times.isEmpty) return;

      final avg = times.reduce((a, b) => a + b) / times.length;
      final min = times.reduce((a, b) => a < b ? a : b).toDouble();
      final max = times.reduce((a, b) => a > b ? a : b).toDouble();

      times.sort();
      final median = times.length % 2 == 0
          ? (times[times.length ~/ 2 - 1] + times[times.length ~/ 2]) / 2
          : times[times.length ~/ 2].toDouble();

      stats[endpoint] = {
        'requests': times.length.toDouble(),
        'average': avg,
        'median': median,
        'min': min,
        'max': max,
      };
    });

    return stats;
  }

  /// Clear performance data
  void clearStats() {
    _requestTimes.clear();
  }
}

/// Request/Response size tracking interceptor
class SizeTrackingInterceptor extends Interceptor {
  int _totalRequestSize = 0;
  int _totalResponseSize = 0;
  int _requestCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final size = _calculateRequestSize(options);
    _totalRequestSize += size;
    _requestCount++;

    options.extra['requestSize'] = size;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final size = _calculateResponseSize(response);
    _totalResponseSize += size;

    final requestSize =
        response.requestOptions.extra['requestSize'] as int? ?? 0;

    if (kDebugMode) {
      debugPrint(
        '📊 Request size: ${_formatBytes(requestSize)}, '
        'Response size: ${_formatBytes(size)}',
      );
    }

    handler.next(response);
  }

  int _calculateRequestSize(RequestOptions options) {
    int size = 0;

    // Headers
    options.headers.forEach((key, value) {
      size += key.length + value.toString().length;
    });

    // Query parameters
    options.queryParameters.forEach((key, value) {
      size += key.length + value.toString().length;
    });

    // Body
    if (options.data != null) {
      if (options.data is String) {
        size += (options.data as String).length;
      } else if (options.data is List<int>) {
        size += (options.data as List<int>).length;
      } else {
        size += jsonEncode(options.data).length;
      }
    }

    return size;
  }

  int _calculateResponseSize(Response response) {
    int size = 0;

    // Headers
    response.headers.forEach((key, values) {
      size += key.length;
      for (final value in values) {
        size += value.length;
      }
    });

    // Body
    if (response.data != null) {
      if (response.data is String) {
        size += (response.data as String).length;
      } else if (response.data is List<int>) {
        size += (response.data as List<int>).length;
      } else {
        size += jsonEncode(response.data).length;
      }
    }

    return size;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Get total data usage statistics
  Map<String, dynamic> getDataUsageStats() {
    return {
      'totalRequestSize': _totalRequestSize,
      'totalResponseSize': _totalResponseSize,
      'totalDataSize': _totalRequestSize + _totalResponseSize,
      'requestCount': _requestCount,
      'averageRequestSize': _requestCount > 0
          ? _totalRequestSize / _requestCount
          : 0,
      'averageResponseSize': _requestCount > 0
          ? _totalResponseSize / _requestCount
          : 0,
      'formattedTotalRequest': _formatBytes(_totalRequestSize),
      'formattedTotalResponse': _formatBytes(_totalResponseSize),
      'formattedTotal': _formatBytes(_totalRequestSize + _totalResponseSize),
    };
  }

  /// Reset statistics
  void resetStats() {
    _totalRequestSize = 0;
    _totalResponseSize = 0;
    _requestCount = 0;
  }
}

/// Analytics logging interceptor for tracking API usage
class AnalyticsLoggingInterceptor extends Interceptor {
  final void Function(Map<String, dynamic>)? onEvent;
  final Map<String, int> _endpointCounts = {};
  final Map<int, int> _statusCodeCounts = {};

  AnalyticsLoggingInterceptor({this.onEvent});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _trackEvent(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _trackEvent(err.requestOptions, err.response?.statusCode ?? 0);
    handler.next(err);
  }

  void _trackEvent(RequestOptions options, int statusCode) {
    final endpoint = '${options.method} ${options.path}';

    // Count endpoint usage
    _endpointCounts[endpoint] = (_endpointCounts[endpoint] ?? 0) + 1;

    // Count status codes
    _statusCodeCounts[statusCode] = (_statusCodeCounts[statusCode] ?? 0) + 1;

    // Send analytics event
    final event = {
      'type': 'api_request',
      'endpoint': endpoint,
      'method': options.method,
      'path': options.path,
      'statusCode': statusCode,
      'timestamp': DateTime.now().toIso8601String(),
      'userAgent': options.headers['User-Agent'],
    };

    onEvent?.call(event);
  }

  /// Get endpoint usage statistics
  Map<String, int> get endpointStats => Map.unmodifiable(_endpointCounts);

  /// Get status code distribution
  Map<int, int> get statusCodeStats => Map.unmodifiable(_statusCodeCounts);

  /// Get most used endpoints
  List<MapEntry<String, int>> getMostUsedEndpoints({int limit = 10}) {
    final entries = _endpointCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Clear analytics data
  void clearStats() {
    _endpointCounts.clear();
    _statusCodeCounts.clear();
  }
}

/// Conditional logging interceptor that can be enabled/disabled
class ConditionalLoggingInterceptor extends LoggingInterceptor {
  bool _isEnabled;
  final List<String> _enabledEndpoints;
  final List<String> _disabledEndpoints;

  ConditionalLoggingInterceptor({
    bool isEnabled = true,
    List<String> enabledEndpoints = const [],
    List<String> disabledEndpoints = const [],
    super.logRequest,
    super.logRequestHeader,
    super.logRequestBody,
    super.logResponse,
    super.logResponseHeader,
    super.logResponseBody,
    super.logError,
    super.maxBodyLength,
    super.compactLogs,
    super.logPrint,
    super.enableInProduction,
  }) : _isEnabled = isEnabled,
       _enabledEndpoints = enabledEndpoints,
       _disabledEndpoints = disabledEndpoints;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldLogForEndpoint(options.path)) {
      super.onRequest(options, handler);
    } else {
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldLogForEndpoint(response.requestOptions.path)) {
      super.onResponse(response, handler);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldLogForEndpoint(err.requestOptions.path)) {
      super.onError(err, handler);
    } else {
      handler.next(err);
    }
  }

  bool _shouldLogForEndpoint(String path) {
    if (!_isEnabled) return false;

    // If specific endpoints are enabled, only log those
    if (_enabledEndpoints.isNotEmpty) {
      return _enabledEndpoints.any((endpoint) => path.contains(endpoint));
    }

    // If specific endpoints are disabled, exclude those
    if (_disabledEndpoints.isNotEmpty) {
      return !_disabledEndpoints.any((endpoint) => path.contains(endpoint));
    }

    return true;
  }

  /// Enable/disable logging
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Add endpoint to enabled list
  void enableEndpoint(String endpoint) {
    if (!_enabledEndpoints.contains(endpoint)) {
      _enabledEndpoints.add(endpoint);
    }
  }

  /// Remove endpoint from enabled list
  void disableEndpoint(String endpoint) {
    if (!_disabledEndpoints.contains(endpoint)) {
      _disabledEndpoints.add(endpoint);
    }
  }

  /// Clear all endpoint filters
  void clearEndpointFilters() {
    _enabledEndpoints.clear();
    _disabledEndpoints.clear();
  }
}

/// Custom log writer that can write to different outputs
abstract class LogWriter {
  void write(String message);
}

/// Console log writer
class ConsoleLogWriter implements LogWriter {
  @override
  void write(String message) {
    debugPrint(message);
  }
}

/// File log writer
class FileLogWriter implements LogWriter {
  final String filePath;

  FileLogWriter(this.filePath);

  @override
  void write(String message) {
    // Implementation would write to file
    // This is a simplified version
    developer.log(message, name: 'HTTP');
  }
}

/// Multi-output log writer
class MultiLogWriter implements LogWriter {
  final List<LogWriter> writers;

  MultiLogWriter(this.writers);

  @override
  void write(String message) {
    for (final writer in writers) {
      writer.write(message);
    }
  }
}

// Riverpod providers
final loggingInterceptorProvider = Provider<LoggingInterceptor>((ref) {
  return LoggingInterceptor(
    compactLogs: !kDebugMode,
    enableInProduction: false,
  );
});

final performanceLoggingInterceptorProvider =
    Provider<PerformanceLoggingInterceptor>((ref) {
      return PerformanceLoggingInterceptor();
    });

final sizeTrackingInterceptorProvider = Provider<SizeTrackingInterceptor>((
  ref,
) {
  return SizeTrackingInterceptor();
});

final analyticsLoggingInterceptorProvider =
    Provider<AnalyticsLoggingInterceptor>((ref) {
      return AnalyticsLoggingInterceptor(
        onEvent: (event) {
          // Send to analytics service
          debugPrint('Analytics Event: $event');
        },
      );
    });
