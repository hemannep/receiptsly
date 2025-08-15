// lib/core/utils/logger.dart
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Application logger utility with multiple output targets
/// Supports console, file, and remote logging based on configuration
class AppLogger {
  static Logger? _logger;
  static File? _logFile;
  static bool _isInitialized = false;

  /// Logger levels
  static const Level debug = Level.FINE;
  static const Level info = Level.INFO;
  static const Level warning = Level.WARNING;
  static const Level error = Level.SEVERE;
  static const Level critical = Level.SHOUT;

  /// Initialize the logger with configuration
  static Future<void> initialize({
    String loggerName = 'Receiptsly',
    Level level = Level.INFO,
    bool enableFileLogging = true,
    bool enableConsoleLogging = true,
  }) async {
    if (_isInitialized) return;

    try {
      // Create logger instance
      _logger = Logger(loggerName);

      // Set logging level based on build mode
      Logger.root.level = kDebugMode ? Level.ALL : level;

      // Set up log file if enabled
      if (enableFileLogging && !kIsWeb) {
        await _initializeFileLogging();
      }

      // Configure log record handler
      Logger.root.onRecord.listen((LogRecord record) {
        final formattedMessage = _formatLogMessage(record);

        // Console logging
        if (enableConsoleLogging) {
          _logToConsole(record, formattedMessage);
        }

        // File logging
        if (enableFileLogging && _logFile != null && !kIsWeb) {
          _logToFile(formattedMessage);
        }

        // Remote logging for production
        if (!kDebugMode && record.level >= Level.WARNING) {
          _logToRemote(record, formattedMessage);
        }
      });

      _isInitialized = true;

      // Log initialization success
      logInfo('Logger initialized successfully');
      logInfo('Environment: ${kDebugMode ? 'Development' : 'Production'}');
      logInfo('File logging: ${enableFileLogging && _logFile != null}');
      logInfo('Console logging: $enableConsoleLogging');
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
    }
  }

  /// Initialize file logging
  static Future<void> _initializeFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final fileName =
          'receiptsly_${DateTime.now().toIso8601String().split('T')[0]}.log';
      _logFile = File('${logsDir.path}/$fileName');

      // Clean up old log files (keep last 7 days)
      await _cleanupOldLogFiles(logsDir);
    } catch (e) {
      debugPrint('Failed to initialize file logging: $e');
    }
  }

  /// Clean up old log files
  static Future<void> _cleanupOldLogFiles(Directory logsDir) async {
    try {
      final files = await logsDir.list().toList();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old log files: $e');
    }
  }

  /// Format log message with timestamp and metadata
  static String _formatLogMessage(LogRecord record) {
    final timestamp = DateTime.now().toIso8601String();
    final level = record.level.name.padRight(7);
    final loggerName = record.loggerName.padRight(10);
    final message = record.message;

    var formatted = '[$timestamp] $level [$loggerName] $message';

    // Add error details if present
    if (record.error != null) {
      formatted += '\nError: ${record.error}';
    }

    // Add stack trace if present
    if (record.stackTrace != null) {
      formatted += '\nStack trace:\n${record.stackTrace}';
    }

    return formatted;
  }

  /// Log to console with appropriate colors/formatting
  static void _logToConsole(LogRecord record, String formattedMessage) {
    if (kDebugMode) {
      // Use developer.log for better debugging experience
      developer.log(
        record.message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    } else {
      // Simple print for release builds
      debugPrint(formattedMessage);
    }
  }

  /// Log to file
  static void _logToFile(String formattedMessage) {
    try {
      _logFile?.writeAsStringSync('$formattedMessage\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  /// Log to remote service (implement based on your needs)
  static void _logToRemote(LogRecord record, String formattedMessage) {
    // TODO: Implement remote logging (e.g., to your backend, Sentry, etc.)
    // This could send logs to your server, analytics service, or error tracking

    // Example implementation:
    // if (record.level >= Level.SEVERE) {
    //   FirebaseCrashlytics.instance.log(formattedMessage);
    // }
  }

  /// Debug level logging
  static void debugLog(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _ensureInitialized();
    _logger?.fine(_buildMessage(message, extra), error, stackTrace);
  }

  /// Info level logging
  static void logInfo(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _ensureInitialized();
    _logger?.info(_buildMessage(message, extra), error, stackTrace);
  }

  /// Warning level logging
  static void LogWarning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _ensureInitialized();
    _logger?.warning(_buildMessage(message, extra), error, stackTrace);
  }

  /// Error level logging
  static void LogError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _ensureInitialized();
    _logger?.severe(_buildMessage(message, extra), error, stackTrace);
  }

  /// Critical level logging
  static void LogCritical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _ensureInitialized();
    _logger?.shout(_buildMessage(message, extra), error, stackTrace);
  }

  /// Build message with extra data
  static String _buildMessage(String message, Map<String, dynamic>? extra) {
    if (extra == null || extra.isEmpty) {
      return message;
    }

    final extraString = extra.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    return '$message | $extraString';
  }

  /// Ensure logger is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      // Initialize with default settings if not already done
      initialize();
    }
  }

  /// Get log file path
  static String? get logFilePath => _logFile?.path;

  /// Check if logger is initialized
  static bool get isInitialized => _isInitialized;

  /// Get logger instance (for advanced usage)
  static Logger? get instance => _logger;

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? extra,
  }) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    logInfo(message, extra: extra);
  }

  /// Log network requests
  static void network(
    String method,
    String url,
    int statusCode,
    Duration duration, {
    Map<String, dynamic>? extra,
  }) {
    final message =
        'Network: $method $url -> $statusCode (${duration.inMilliseconds}ms)';
    logInfo(message, extra: extra);
  }

  /// Log user actions
  static void userAction(
    String action, {
    String? userId,
    Map<String, dynamic>? extra,
  }) {
    final extraData = <String, dynamic>{
      if (userId != null) 'user_id': userId,
      ...?extra,
    };
    logInfo('User action: $action', extra: extraData);
  }

  /// Log business events
  static void business(String event, {Map<String, dynamic>? data}) {
    logInfo('Business event: $event', extra: data);
  }

  /// Log security events
  static void security(
    String event, {
    String? userId,
    String? ip,
    Map<String, dynamic>? extra,
  }) {
    final extraData = <String, dynamic>{
      if (userId != null) 'user_id': userId,
      if (ip != null) 'ip': ip,
      ...?extra,
    };
    LogWarning('Security event: $event', extra: extraData);
  }

  /// Flush logs (ensure all logs are written)
  static Future<void> flush() async {
    // No explicit flush needed for Dart File writes.
    // This method is kept for API compatibility.
  }

  /// Get recent logs for debugging
  static Future<List<String>> getRecentLogs({int lines = 100}) async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return [];
      }

      final content = await _logFile!.readAsString();
      final allLines = content.split('\n');

      // Return last N lines (excluding empty lines)
      return allLines
          .where((line) => line.trim().isNotEmpty)
          .toList()
          .reversed
          .take(lines)
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('Failed to get recent logs: $e');
      return [];
    }
  }

  /// Clear all logs
  static Future<void> clearLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
        await _initializeFileLogging();
      }
      logInfo('Logs cleared');
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  /// Export logs for sharing or debugging
  static Future<File?> exportLogs() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportFile = File(
        '${exportDir.path}/receiptsly_logs_$timestamp.log',
      );

      await _logFile!.copy(exportFile.path);

      logInfo('Logs exported to: ${exportFile.path}');
      return exportFile;
    } catch (e) {
      LogError('Failed to export logs', error: e);
      return null;
    }
  }

  /// Get log statistics
  static Future<Map<String, dynamic>> getLogStatistics() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return {};
      }

      final content = await _logFile!.readAsString();
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty);

      final stats = <String, int>{};
      for (final line in lines) {
        // Extract log level from formatted message
        final levelMatch = RegExp(
          r'\[(DEBUG|INFO|WARNING|SEVERE|SHOUT)\]',
        ).firstMatch(line);
        if (levelMatch != null) {
          final level = levelMatch.group(1)!;
          stats[level] = (stats[level] ?? 0) + 1;
        }
      }

      final fileSize = await _logFile!.length();

      return {
        'total_lines': lines.length,
        'file_size_bytes': fileSize,
        'file_size_mb': (fileSize / (1024 * 1024)).toStringAsFixed(2),
        'levels': stats,
        'file_path': _logFile!.path,
        'last_modified': (await _logFile!.lastModified()).toIso8601String(),
      };
    } catch (e) {
      LogError('Failed to get log statistics', error: e);
      return {};
    }
  }

  /// Dispose logger resources
  static void dispose() {
    if (_isInitialized) {
      logInfo('Logger disposed');
      _isInitialized = false;
      _logger = null;
      _logFile = null;
    }
  }
}
