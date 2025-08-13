// lib/core/errors/error_handler.dart
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';
import '../config/app_config.dart';
import '../config/firebase_config.dart';

/// Centralized error handler for the Receiptsly application
/// Handles all types of errors, logging, reporting, and user notifications
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._internal();

  ErrorHandler._internal();

  // Error reporting configuration
  bool _isInitialized = false;
  final List<ErrorReporter> _reporters = [];
  final List<ErrorInterceptor> _interceptors = [];

  /// Initialize the error handler with reporters and interceptors
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Add default reporters
      _addDefaultReporters();

      // Add default interceptors
      _addDefaultInterceptors();

      // Setup global error handling
      _setupGlobalErrorHandling();

      _isInitialized = true;

      if (kDebugMode) {
        print('🛡️ ErrorHandler initialized');
        print('📊 Reporters: ${_reporters.length}');
        print('🔍 Interceptors: ${_interceptors.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ErrorHandler initialization failed: $e');
      }
    }
  }

  /// Add default error reporters
  void _addDefaultReporters() {
    // Console reporter (always enabled in debug)
    if (kDebugMode) {
      _reporters.add(ConsoleErrorReporter());
    }

    // Crashlytics reporter (production only)
    if (AppConfig.instance.isCrashlyticsEnabled &&
        FirebaseConfig.instance.isInitialized) {
      _reporters.add(CrashlyticsErrorReporter());
    }

    // Analytics reporter (if analytics enabled)
    if (AppConfig.instance.isAnalyticsEnabled &&
        FirebaseConfig.instance.isInitialized) {
      _reporters.add(AnalyticsErrorReporter());
    }

    // Local file reporter (staging and production)
    if (!kDebugMode) {
      _reporters.add(FileErrorReporter());
    }
  }

  /// Add default error interceptors
  void _addDefaultInterceptors() {
    // Network error interceptor
    _interceptors.add(NetworkErrorInterceptor());

    // Authentication error interceptor
    _interceptors.add(AuthErrorInterceptor());

    // Business logic error interceptor
    _interceptors.add(BusinessLogicErrorInterceptor());

    // Rate limiting interceptor
    _interceptors.add(RateLimitErrorInterceptor());
  }

  /// Setup global error handling for uncaught exceptions
  void _setupGlobalErrorHandling() {
    // Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      handleFlutterError(details);
    };

    // Platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      handleError(
        error,
        stackTrace: stack,
        context: ErrorContext(
          location: 'Platform',
          operation: 'PlatformDispatcher',
          severity: ErrorSeverity.critical,
        ),
      );
      return true;
    };

    // Isolate error handling
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        await handleError(
          errorAndStacktrace.first,
          stackTrace: errorAndStacktrace.length > 1
              ? errorAndStacktrace[1]
              : null,
          context: ErrorContext(
            location: 'Isolate',
            operation: 'IsolateError',
            severity: ErrorSeverity.critical,
          ),
        );
      }).sendPort,
    );
  }

  /// Handle Flutter framework errors
  Future<void> handleFlutterError(FlutterErrorDetails details) async {
    final context = ErrorContext(
      location: 'Flutter Framework',
      operation: details.context?.toString() ?? 'Unknown',
      severity: details.silent ? ErrorSeverity.warning : ErrorSeverity.error,
      additionalData: {
        'library': details.library,
        'stack': details.stack?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    await handleError(
      details.exception,
      stackTrace: details.stack,
      context: context,
    );
  }

  /// Main error handling method
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorContext? context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('⚠️ ErrorHandler not initialized, falling back to basic logging');
        print('Error: $error');
        if (stackTrace != null) print('Stack: $stackTrace');
      }
      return;
    }

    try {
      // Create error context if not provided
      context ??= ErrorContext(
        location: 'Unknown',
        operation: 'handleError',
        severity: _determineSeverity(error),
      );

      // Add additional data to context
      if (additionalData != null) {
        context = context.copyWith(
          additionalData: {...context.additionalData, ...additionalData},
        );
      }

      // Convert to standard exception if needed
      final exception = _normalizeError(error);

      // Apply interceptors
      var processedError = ProcessedError(
        exception: exception,
        stackTrace: stackTrace,
        context: context,
        timestamp: DateTime.now(),
      );

      for (final interceptor in _interceptors) {
        processedError = await interceptor.intercept(processedError);

        // If interceptor marked as handled, stop processing
        if (processedError.isHandled) {
          break;
        }
      }

      // Report to all reporters if not handled by interceptor
      if (!processedError.isHandled) {
        await _reportToAllReporters(processedError);
      }
    } catch (e, s) {
      // Fallback error handling
      if (kDebugMode) {
        print('❌ Error in ErrorHandler: $e');
        print('Original error: $error');
        print('ErrorHandler stack: $s');
      }
    }
  }

  /// Handle network errors specifically
  Future<NetworkFailure> handleNetworkError(DioException error) async {
    final context = ErrorContext(
      location: 'Network',
      operation: '${error.requestOptions.method} ${error.requestOptions.path}',
      severity: _getNetworkErrorSeverity(error),
      additionalData: {
        'statusCode': error.response?.statusCode,
        'requestUrl': error.requestOptions.uri.toString(),
        'requestMethod': error.requestOptions.method,
        'responseData': error.response?.data?.toString(),
      },
    );

    await handleError(error, context: context);

    return _mapDioErrorToFailure(error);
  }

  /// Handle authentication errors specifically
  Future<AuthFailure> handleAuthError(Exception error) async {
    final context = ErrorContext(
      location: 'Authentication',
      operation: 'AuthOperation',
      severity: ErrorSeverity.error,
    );

    await handleError(error, context: context);

    if (error is AuthException) {
      return FailureConverter.fromException(error) as AuthFailure;
    }

    return InvalidCredentialsFailure(error.toString());
  }

  /// Handle validation errors
  Future<ValidationFailure> handleValidationError(
    String field,
    String message, {
    Map<String, dynamic>? additionalData,
  }) async {
    final exception = ValidationException(message, null, field);

    final context = ErrorContext(
      location: 'Validation',
      operation: 'Field validation',
      severity: ErrorSeverity.warning,
      additionalData: additionalData ?? {},
    );

    await handleError(exception, context: context);

    return FailureConverter.fromException(exception) as ValidationFailure;
  }

  /// Handle business logic errors
  Future<BusinessLogicFailure> handleBusinessLogicError(
    String message, {
    String? details,
    Map<String, dynamic>? additionalData,
  }) async {
    final exception = DataException(message, details);

    final context = ErrorContext(
      location: 'Business Logic',
      operation: 'Business rule validation',
      severity: ErrorSeverity.warning,
      additionalData: additionalData ?? {},
    );

    await handleError(exception, context: context);

    // Map to appropriate business logic failure
    if (message.toLowerCase().contains('duplicate')) {
      return DuplicateReceiptFailure(details);
    } else if (message.toLowerCase().contains('limit')) {
      return ClientLimitExceededFailure(0, details);
    }

    return GeneralFailure(message, details) as BusinessLogicFailure;
  }

  /// Report error to all configured reporters
  Future<void> _reportToAllReporters(ProcessedError processedError) async {
    final reportTasks = _reporters.map((reporter) async {
      try {
        await reporter.report(processedError);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Reporter ${reporter.runtimeType} failed: $e');
        }
      }
    });

    await Future.wait(reportTasks);
  }

  /// Normalize different error types to exceptions
  Exception _normalizeError(dynamic error) {
    if (error is Exception) {
      return error;
    }

    if (error is Error) {
      return Exception(error.toString());
    }

    return Exception(error.toString());
  }

  /// Determine error severity based on error type
  ErrorSeverity _determineSeverity(dynamic error) {
    if (error is ValidationException) {
      return ErrorSeverity.warning;
    }

    if (error is NetworkException) {
      if (error.statusCode != null && error.statusCode! >= 500) {
        return ErrorSeverity.error;
      }
      return ErrorSeverity.warning;
    }

    if (error is DatabaseException || error is StorageException) {
      return ErrorSeverity.critical;
    }

    if (error is AuthException) {
      return ErrorSeverity.error;
    }

    return ErrorSeverity.error;
  }

  /// Get network error severity
  ErrorSeverity _getNetworkErrorSeverity(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ErrorSeverity.warning;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode >= 500) {
          return ErrorSeverity.error;
        } else if (statusCode >= 400) {
          return ErrorSeverity.warning;
        }
        return ErrorSeverity.info;

      case DioExceptionType.cancel:
        return ErrorSeverity.info;

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ErrorSeverity.error;

      default:
        return ErrorSeverity.warning;
    }
  }

  /// Map Dio exceptions to network failures
  NetworkFailure _mapDioErrorToFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ConnectionTimeoutFailure(error.message);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        switch (statusCode) {
          case 400:
            return BadRequestFailure(error.response?.data?.toString());
          case 401:
            return UnauthorizedFailure(error.response?.data?.toString());
          case 403:
            return ForbiddenFailure(error.response?.data?.toString());
          case 404:
            return NotFoundFailure(error.response?.data?.toString());
          case 429:
            return RateLimitFailure(error.response?.data?.toString());
          default:
            if (statusCode >= 500) {
              return ServerFailure(
                error.response?.data?.toString(),
                statusCode,
              );
            }
            return NetworkFailure('Network error', error.message, statusCode);
        }

      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled', error.message);

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return NoInternetFailure(error.message);
        }
        return NetworkFailure('Connection error', error.message);

      case DioExceptionType.unknown:
      default:
        return NetworkFailure('Unknown network error', error.message);
    }
  }

  /// Add custom error reporter
  void addReporter(ErrorReporter reporter) {
    _reporters.add(reporter);
  }

  /// Add custom error interceptor
  void addInterceptor(ErrorInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Remove error reporter
  void removeReporter(ErrorReporter reporter) {
    _reporters.remove(reporter);
  }

  /// Remove error interceptor
  void removeInterceptor(ErrorInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    // This would typically be implemented with actual statistics tracking
    return {
      'reportersCount': _reporters.length,
      'interceptorsCount': _interceptors.length,
      'isInitialized': _isInitialized,
    };
  }
}

/// Error severity levels
enum ErrorSeverity { info, warning, error, critical }

/// Error context information
class ErrorContext {
  const ErrorContext({
    required this.location,
    required this.operation,
    required this.severity,
    this.userId,
    this.sessionId,
    this.additionalData = const {},
  });

  final String location;
  final String operation;
  final ErrorSeverity severity;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic> additionalData;

  ErrorContext copyWith({
    String? location,
    String? operation,
    ErrorSeverity? severity,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? additionalData,
  }) {
    return ErrorContext(
      location: location ?? this.location,
      operation: operation ?? this.operation,
      severity: severity ?? this.severity,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

/// Processed error information
class ProcessedError {
  ProcessedError({
    required this.exception,
    required this.context,
    required this.timestamp,
    this.stackTrace,
    this.isHandled = false,
    this.userMessage,
  });

  final Exception exception;
  final StackTrace? stackTrace;
  final ErrorContext context;
  final DateTime timestamp;
  final bool isHandled;
  final String? userMessage;

  ProcessedError copyWith({
    Exception? exception,
    StackTrace? stackTrace,
    ErrorContext? context,
    DateTime? timestamp,
    bool? isHandled,
    String? userMessage,
  }) {
    return ProcessedError(
      exception: exception ?? this.exception,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
      isHandled: isHandled ?? this.isHandled,
      userMessage: userMessage ?? this.userMessage,
    );
  }
}

/// Abstract base class for error reporters
abstract class ErrorReporter {
  Future<void> report(ProcessedError error);
}

/// Console error reporter for debug mode
class ConsoleErrorReporter implements ErrorReporter {
  @override
  Future<void> report(ProcessedError error) async {
    if (!kDebugMode) return;

    final severity = error.context.severity.name.toUpperCase();
    final location = error.context.location;
    final operation = error.context.operation;

    print('\n🚨 [$severity] Error in $location during $operation');
    print('📝 Exception: ${error.exception}');
    print('⏰ Timestamp: ${error.timestamp.toIso8601String()}');

    if (error.context.userId != null) {
      print('👤 User ID: ${error.context.userId}');
    }

    if (error.context.additionalData.isNotEmpty) {
      print('📊 Additional Data: ${error.context.additionalData}');
    }

    if (error.stackTrace != null) {
      print('📍 Stack Trace:\n${error.stackTrace}');
    }

    print('${'=' * 50}\n');
  }
}

/// Crashlytics error reporter for production
class CrashlyticsErrorReporter implements ErrorReporter {
  @override
  Future<void> report(ProcessedError error) async {
    final crashlytics = FirebaseConfig.instance.crashlytics;
    if (crashlytics == null) return;

    // Set context information
    await crashlytics.setCustomKey('location', error.context.location);
    await crashlytics.setCustomKey('operation', error.context.operation);
    await crashlytics.setCustomKey('severity', error.context.severity.name);

    if (error.context.userId != null) {
      await crashlytics.setUserIdentifier(error.context.userId!);
    }

    // Add additional data as custom keys
    for (final entry in error.context.additionalData.entries) {
      await crashlytics.setCustomKey(entry.key, entry.value.toString());
    }

    // Report the error
    final isFatal = error.context.severity == ErrorSeverity.critical;
    await crashlytics.recordError(
      error.exception,
      error.stackTrace,
      fatal: isFatal,
    );
  }
}

/// Analytics error reporter for tracking error patterns
class AnalyticsErrorReporter implements ErrorReporter {
  @override
  Future<void> report(ProcessedError error) async {
    final analytics = FirebaseConfig.instance.analytics;
    if (analytics == null) return;

    await analytics.logEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': error.exception.runtimeType.toString(),
        'error_location': error.context.location,
        'error_operation': error.context.operation,
        'error_severity': error.context.severity.name,
        'error_message': error.exception.toString().substring(
          0,
          100,
        ), // Limit length
        if (error.context.userId != null) 'user_id': error.context.userId!,
      },
    );
  }
}

/// File error reporter for local logging
class FileErrorReporter implements ErrorReporter {
  @override
  Future<void> report(ProcessedError error) async {
    // Implementation would write to local file
    // This is a simplified version
    if (kDebugMode) {
      print('📁 Would write to file: ${error.exception}');
    }
  }
}

/// Abstract base class for error interceptors
abstract class ErrorInterceptor {
  Future<ProcessedError> intercept(ProcessedError error);
}

/// Network error interceptor
class NetworkErrorInterceptor implements ErrorInterceptor {
  @override
  Future<ProcessedError> intercept(ProcessedError error) async {
    if (error.exception is NetworkException) {
      // Add network-specific handling
      final networkError = error.exception as NetworkException;

      // Mark certain errors as handled
      if (networkError is NoInternetException) {
        return error.copyWith(
          isHandled: false, // Let this go through for user notification
          userMessage: 'Please check your internet connection and try again.',
        );
      }
    }

    return error;
  }
}

/// Authentication error interceptor
class AuthErrorInterceptor implements ErrorInterceptor {
  @override
  Future<ProcessedError> intercept(ProcessedError error) async {
    if (error.exception is AuthException) {
      final authError = error.exception as AuthException;

      // Handle specific auth errors
      if (authError is SessionExpiredException) {
        return error.copyWith(
          userMessage: 'Your session has expired. Please sign in again.',
        );
      }

      if (authError is InvalidCredentialsException) {
        return error.copyWith(
          userMessage: 'Invalid email or password. Please try again.',
        );
      }
    }

    return error;
  }
}

/// Business logic error interceptor
class BusinessLogicErrorInterceptor implements ErrorInterceptor {
  @override
  Future<ProcessedError> intercept(ProcessedError error) async {
    if (error.exception is ValidationException) {
      final validationError = error.exception as ValidationException;

      return error.copyWith(
        userMessage: validationError.message,
        isHandled: false, // Let validation errors show to user
      );
    }

    return error;
  }
}

/// Rate limiting error interceptor
class RateLimitErrorInterceptor implements ErrorInterceptor {
  @override
  Future<ProcessedError> intercept(ProcessedError error) async {
    if (error.exception is TooManyRequestsException ||
        error.exception is RateLimitExceededException) {
      return error.copyWith(
        userMessage:
            'Too many requests. Please wait a moment before trying again.',
      );
    }

    return error;
  }
}
