// lib/core/network/interceptors/error_interceptor.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/exceptions.dart';
import '../network_info.dart' as network_info;

/// Error interceptor that handles and transforms network errors
class ErrorInterceptor extends Interceptor {
  final bool enableCrashReporting;
  final void Function(String, dynamic)? errorCallback;

  ErrorInterceptor({this.enableCrashReporting = true, this.errorCallback});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _handleDioError(err);

    // Log error for debugging
    _logError(err, appException);

    // Report to crash analytics if enabled
    if (enableCrashReporting && !kDebugMode) {
      _reportError(err, appException);
    }

    // Call custom error handler if provided
    errorCallback?.call('API Error', appException);

    // Transform DioException to custom exception
    final customException = DioException(
      requestOptions: err.requestOptions,
      error: appException,
      type: err.type,
      response: err.response,
    );

    handler.next(customException);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check for API-level errors in successful HTTP responses
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;

      // Handle API error responses with 200 status code
      if (data.containsKey('success') && data['success'] == false) {
        final errorMessage = data['message'] ?? 'Unknown API error';
        final errorCode = data['code'];
        final errors = data['errors'] as List<dynamic>?;

        final exception = ServerException(
          errorMessage,
          'Server returned error response',
          response.statusCode,
        );

        final dioException = DioException(
          requestOptions: response.requestOptions,
          error: exception,
          response: response,
          type: DioExceptionType.badResponse,
        );

        handler.reject(dioException);
        return;
      }
    }

    handler.next(response);
  }

  /// Handle different types of Dio errors
  ReceiptslyException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ConnectionTimeoutException(
          'Request timeout. Please check your internet connection and try again.',
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return NetworkException(
          'Request was cancelled',
          'The network request was cancelled by the user',
        );

      case DioExceptionType.connectionError:
        return _handleConnectionError(error);

      case DioExceptionType.badCertificate:
        return NetworkException(
          'SSL certificate verification failed',
          'This might be a security issue',
        );

      case DioExceptionType.unknown:
      default:
        return _handleUnknownError(error);
    }
  }

  /// Handle HTTP response errors (4xx, 5xx)
  ReceiptslyException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'An error occurred';
    String? errorCode;
    List<String>? errors;

    // Extract error information from response
    if (responseData is Map<String, dynamic>) {
      message =
          responseData['message'] ??
          responseData['error'] ??
          responseData['detail'] ??
          message;
      errorCode = responseData['code']?.toString();

      // Handle validation errors
      if (responseData['errors'] is List) {
        errors = (responseData['errors'] as List).cast<String>();
      } else if (responseData['errors'] is Map) {
        final errorMap = responseData['errors'] as Map<String, dynamic>;
        errors = errorMap.values
            .expand((e) => e is List ? e : [e])
            .cast<String>()
            .toList();
      }
    } else if (responseData is String) {
      message = responseData;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message.isEmpty ? 'Invalid request data' : message,
        );

      case 401:
        return UnauthorizedException(
          message.isEmpty ? 'Authentication required' : message,
        );

      case 403:
        return ForbiddenException(message.isEmpty ? 'Access denied' : message);

      case 404:
        return NotFoundException(
          message.isEmpty ? 'Resource not found' : message,
        );

      case 409:
        return NetworkException(
          message.isEmpty ? 'Resource conflict occurred' : message,
          'HTTP 409 Conflict',
          409,
        );

      case 422:
        return ValidationException(
          message.isEmpty ? 'Validation failed' : message,
          errors?.join(', '),
        );

      case 429:
        return RateLimitExceededException(
          message.isEmpty
              ? 'Too many requests. Please try again later.'
              : message,
        );

      case 500:
        return ServerException(
          message.isEmpty ? 'Internal server error occurred' : message,
          'Server Error',
          statusCode,
        );

      default:
        return ServerException(
          message.isEmpty ? 'Unexpected error occurred' : message,
          'Unknown Server Error',
          statusCode,
        );
    }
  }

  /// Handle connection errors
  ReceiptslyException _handleConnectionError(DioException error) {
    final originalError = error.error;

    if (originalError is SocketException) {
      if (originalError.osError?.errorCode == 7) {
        // No address associated with hostname
        return NoInternetException(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (originalError.osError?.errorCode == 111) {
        // Connection refused
        return ServerException(
          'Server is not responding. Please try again later.',
          'Connection Refused',
        );
      }
    }

    return NoInternetException(
      'Network connection failed. Please check your internet connection.',
    );
  }

  /// Handle unknown errors
  ReceiptslyException _handleUnknownError(DioException error) {
    final originalError = error.error;

    if (originalError is ReceiptslyException) {
      return originalError;
    }

    if (originalError is FormatException) {
      return InvalidDataFormatException('Failed to parse server response');
    }

    return ServerException(
      originalError?.toString() ?? 'An unexpected error occurred',
      'Unknown Error',
    );
  }

  /// Log error details
  void _logError(DioException dioError, ReceiptslyException appException) {
    if (kDebugMode) {
      debugPrint('🔴 API Error occurred:');
      debugPrint('URL: ${dioError.requestOptions.uri}');
      debugPrint('Method: ${dioError.requestOptions.method}');
      debugPrint('Status Code: ${dioError.response?.statusCode}');
      debugPrint('Error Type: ${dioError.type}');
      debugPrint('App Exception: ${appException.runtimeType}');
      debugPrint('Message: ${appException.message}');

      if (appException is ValidationException && appException.field != null) {
        debugPrint('Validation Field: ${appException.field}');
      }

      if (dioError.requestOptions.data != null) {
        debugPrint('Request Data: ${dioError.requestOptions.data}');
      }

      if (dioError.response?.data != null) {
        debugPrint('Response Data: ${dioError.response?.data}');
      }
    }
  }

  /// Report error to crash analytics
  void _reportError(DioException dioError, ReceiptslyException appException) {
    try {
      // This would integrate with your crash reporting service
      // Examples: Firebase Crashlytics, Sentry, Bugsnag

      final errorData = {
        'url': dioError.requestOptions.uri.toString(),
        'method': dioError.requestOptions.method,
        'statusCode': dioError.response?.statusCode,
        'errorType': dioError.type.toString(),
        'appExceptionType': appException.runtimeType.toString(),
        'message': appException.message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Example: FirebaseCrashlytics.instance.recordError(appException, null, information: errorData);
      // Example: Sentry.captureException(appException, extra: errorData);

      debugPrint('Error reported to analytics: ${errorData['message']}');
    } catch (e) {
      debugPrint('Failed to report error to analytics: $e');
    }
  }
}

/// Enhanced error interceptor with additional features
class EnhancedErrorInterceptor extends ErrorInterceptor {
  final Duration rateLimitResetDuration;
  final int maxRetryAttempts;
  final Map<String, DateTime> _rateLimitResetTimes = {};

  EnhancedErrorInterceptor({
    super.enableCrashReporting,
    super.errorCallback,
    this.rateLimitResetDuration = const Duration(minutes: 1),
    this.maxRetryAttempts = 3,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle rate limiting
    if (err.response?.statusCode == 429) {
      _handleRateLimit(err);
    }

    // Check if request should be retried
    if (_shouldRetry(err)) {
      _scheduleRetry(err, handler);
      return;
    }

    super.onError(err, handler);
  }

  /// Handle rate limiting
  void _handleRateLimit(DioException error) {
    final endpoint = error.requestOptions.path;
    final retryAfter = error.response?.headers.value('Retry-After');

    Duration resetDuration = rateLimitResetDuration;
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        resetDuration = Duration(seconds: seconds);
      }
    }

    _rateLimitResetTimes[endpoint] = DateTime.now().add(resetDuration);
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException error) {
    final retryCount = error.requestOptions.extra['retryCount'] ?? 0;

    if (retryCount >= maxRetryAttempts) {
      return false;
    }

    // Retry on network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on server errors (5xx)
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500) {
      return true;
    }

    return false;
  }

  /// Schedule retry attempt
  void _scheduleRetry(DioException error, ErrorInterceptorHandler handler) {
    final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
    final delay = Duration(
      seconds: (retryCount + 1) * 2,
    ); // Exponential backoff

    Timer(delay, () async {
      try {
        error.requestOptions.extra['retryCount'] = retryCount + 1;

        final dio = Dio();
        final response = await dio.fetch(error.requestOptions);
        handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          onError(e, handler);
        } else {
          handler.reject(error);
        }
      }
    });
  }

  /// Check if endpoint is rate limited
  bool isRateLimited(String endpoint) {
    final resetTime = _rateLimitResetTimes[endpoint];
    if (resetTime == null) return false;

    if (DateTime.now().isAfter(resetTime)) {
      _rateLimitResetTimes.remove(endpoint);
      return false;
    }

    return true;
  }

  /// Get rate limit reset time for endpoint
  DateTime? getRateLimitResetTime(String endpoint) {
    return _rateLimitResetTimes[endpoint];
  }
}

/// Error handler utility class
class ErrorHandler {
  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is ReceiptslyException) {
      return error.message;
    }

    if (error is DioException && error.error is ReceiptslyException) {
      return (error.error as ReceiptslyException).message;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is recoverable
  static bool isRecoverable(dynamic error) {
    if (error is NetworkException) {
      return error.statusCode == null || error.statusCode! >= 500;
    }

    if (error is ConnectionTimeoutException || error is NoInternetException) {
      return true;
    }

    if (error is ServerException) {
      return error.statusCode == null || error.statusCode! >= 500;
    }

    return false;
  }

  /// Get error category for analytics
  static String getErrorCategory(dynamic error) {
    if (error is NetworkException ||
        error is NoInternetException ||
        error is ConnectionTimeoutException) {
      return 'network';
    } else if (error is ValidationException) {
      return 'validation';
    } else if (error is UnauthorizedException) {
      return 'auth';
    } else if (error is ServerException) {
      return 'server';
    } else {
      return 'unknown';
    }
  }

  /// Check if error should be reported to analytics
  static bool shouldReport(dynamic error) {
    // Don't report client errors (4xx except 401, 403)
    if (error is NetworkException && error.statusCode != null) {
      final statusCode = error.statusCode!;
      return statusCode < 400 ||
          statusCode >= 500 ||
          statusCode == 401 ||
          statusCode == 403;
    }

    return true;
  }
}

// Riverpod providers
final errorInterceptorProvider = Provider<ErrorInterceptor>((ref) {
  return ErrorInterceptor(
    enableCrashReporting: !kDebugMode,
    errorCallback: (title, error) {
      // Handle global error notifications here
      debugPrint('Global Error: $title - $error');
    },
  );
});

final enhancedErrorInterceptorProvider = Provider<EnhancedErrorInterceptor>((
  ref,
) {
  return EnhancedErrorInterceptor(enableCrashReporting: !kDebugMode);
});
