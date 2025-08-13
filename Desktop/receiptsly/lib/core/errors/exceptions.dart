// lib/core/errors/exceptions.dart
import 'package:flutter/foundation.dart';

/// Base exception class for all custom exceptions in Receiptsly
abstract class ReceiptslyException implements Exception {
  const ReceiptslyException(this.message, [this.details]);

  final String message;
  final String? details;

  @override
  String toString() =>
      'ReceiptslyException: $message${details != null ? ' - $details' : ''}';
}

/// Authentication related exceptions
class AuthException extends ReceiptslyException {
  const AuthException(String message, [String? details, this.code])
    : super(message, details);

  final String? code;

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}${details != null ? ' - $details' : ''}';
}

/// Invalid credentials exception
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([String? details])
    : super('Invalid credentials provided', details, 'invalid_credentials');
}

/// User not found exception
class UserNotFoundException extends AuthException {
  const UserNotFoundException([String? details])
    : super('User not found', details, 'user_not_found');
}

/// Account disabled exception
class AccountDisabledException extends AuthException {
  const AccountDisabledException([String? details])
    : super('Account has been disabled', details, 'account_disabled');
}

/// Email not verified exception
class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException([String? details])
    : super('Email address not verified', details, 'email_not_verified');
}

/// Too many requests exception
class TooManyRequestsException extends AuthException {
  const TooManyRequestsException([String? details])
    : super('Too many authentication attempts', details, 'too_many_requests');
}

/// Network related exceptions
class NetworkException extends ReceiptslyException {
  const NetworkException(String message, [String? details, this.statusCode])
    : super(message, details);

  final int? statusCode;

  @override
  String toString() =>
      'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? ' - $details' : ''}';
}

/// No internet connection exception
class NoInternetException extends NetworkException {
  const NoInternetException([String? details])
    : super('No internet connection available', details);
}

/// Connection timeout exception
class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException([String? details])
    : super('Connection timeout', details, 408);
}

/// Server error exception
class ServerException extends NetworkException {
  const ServerException(String message, [String? details, int? statusCode])
    : super(message, details, statusCode);
}

/// Bad request exception
class BadRequestException extends NetworkException {
  const BadRequestException([String? details])
    : super('Bad request', details, 400);
}

/// Unauthorized exception
class UnauthorizedException extends NetworkException {
  const UnauthorizedException([String? details])
    : super('Unauthorized access', details, 401);
}

/// Forbidden exception
class ForbiddenException extends NetworkException {
  const ForbiddenException([String? details])
    : super('Access forbidden', details, 403);
}

/// Not found exception
class NotFoundException extends NetworkException {
  const NotFoundException([String? details])
    : super('Resource not found', details, 404);
}

/// Rate limit exceeded exception
class RateLimitExceededException extends NetworkException {
  const RateLimitExceededException([String? details])
    : super('Rate limit exceeded', details, 429);
}

/// Data related exceptions
class DataException extends ReceiptslyException {
  const DataException(String message, [String? details])
    : super(message, details);
}

/// Invalid data format exception
class InvalidDataFormatException extends DataException {
  const InvalidDataFormatException([String? details])
    : super('Invalid data format', details);
}

/// Data validation exception
class ValidationException extends DataException {
  const ValidationException(String message, [String? details, this.field])
    : super(message, details);

  final String? field;

  @override
  String toString() =>
      'ValidationException: $message${field != null ? ' (Field: $field)' : ''}${details != null ? ' - $details' : ''}';
}

/// Required field exception
class RequiredFieldException extends ValidationException {
  const RequiredFieldException(String field, [String? details])
    : super('Required field is missing', details, field);
}

/// Invalid email format exception
class InvalidEmailException extends ValidationException {
  const InvalidEmailException([String? details])
    : super('Invalid email format', details, 'email');
}

/// Invalid phone number exception
class InvalidPhoneNumberException extends ValidationException {
  const InvalidPhoneNumberException([String? details])
    : super('Invalid phone number format', details, 'phone');
}

/// Weak password exception
class WeakPasswordException extends ValidationException {
  const WeakPasswordException([String? details])
    : super('Password is too weak', details, 'password');
}

/// Storage related exceptions
class StorageException extends ReceiptslyException {
  const StorageException(String message, [String? details])
    : super(message, details);
}

/// File not found exception
class FileNotFoundException extends StorageException {
  const FileNotFoundException([String? details])
    : super('File not found', details);
}

/// File too large exception
class FileTooLargeException extends StorageException {
  const FileTooLargeException(int size, int maxSize, [String? details])
    : super(
        'File size ($size bytes) exceeds maximum allowed size ($maxSize bytes)',
        details,
      );
}

/// Invalid file type exception
class InvalidFileTypeException extends StorageException {
  const InvalidFileTypeException(String fileType, [String? details])
    : super('Invalid file type: $fileType', details);
}

/// Storage quota exceeded exception
class StorageQuotaExceededException extends StorageException {
  const StorageQuotaExceededException([String? details])
    : super('Storage quota exceeded', details);
}

/// Upload failed exception
class UploadFailedException extends StorageException {
  const UploadFailedException([String? details])
    : super('File upload failed', details);
}

/// Download failed exception
class DownloadFailedException extends StorageException {
  const DownloadFailedException([String? details])
    : super('File download failed', details);
}

/// OCR related exceptions
class OCRException extends ReceiptslyException {
  const OCRException(String message, [String? details])
    : super(message, details);
}

/// OCR processing failed exception
class OCRProcessingFailedException extends OCRException {
  const OCRProcessingFailedException([String? details])
    : super('OCR processing failed', details);
}

/// Low confidence OCR exception
class LowConfidenceOCRException extends OCRException {
  LowConfidenceOCRException(double confidence, [String? details])
    : super(
        'OCR confidence too low: ${(confidence * 100).toStringAsFixed(1)}%',
        details,
      );
}

/// Unsupported language exception
class UnsupportedLanguageException extends OCRException {
  const UnsupportedLanguageException(String language, [String? details])
    : super('Unsupported OCR language: $language', details);
}

/// Payment related exceptions
class PaymentException extends ReceiptslyException {
  const PaymentException(String message, [String? details, this.code])
    : super(message, details);

  final String? code;

  @override
  String toString() =>
      'PaymentException: $message${code != null ? ' (Code: $code)' : ''}${details != null ? ' - $details' : ''}';
}

/// Payment failed exception
class PaymentFailedException extends PaymentException {
  const PaymentFailedException([String? details, String? code])
    : super('Payment failed', details, code);
}

/// Payment cancelled exception
class PaymentCancelledException extends PaymentException {
  const PaymentCancelledException([String? details])
    : super('Payment was cancelled by user', details, 'cancelled');
}

/// Invalid payment method exception
class InvalidPaymentMethodException extends PaymentException {
  const InvalidPaymentMethodException([String? details])
    : super('Invalid payment method', details, 'invalid_payment_method');
}

/// Insufficient funds exception
class InsufficientFundsException extends PaymentException {
  const InsufficientFundsException([String? details])
    : super('Insufficient funds', details, 'insufficient_funds');
}

/// Card declined exception
class CardDeclinedException extends PaymentException {
  const CardDeclinedException([String? details])
    : super('Card was declined', details, 'card_declined');
}

/// Subscription related exceptions
class SubscriptionException extends ReceiptslyException {
  const SubscriptionException(String message, [String? details])
    : super(message, details);
}

/// Subscription not found exception
class SubscriptionNotFoundException extends SubscriptionException {
  const SubscriptionNotFoundException([String? details])
    : super('Subscription not found', details);
}

/// Subscription expired exception
class SubscriptionExpiredException extends SubscriptionException {
  const SubscriptionExpiredException([String? details])
    : super('Subscription has expired', details);
}

/// Subscription limit exceeded exception
class SubscriptionLimitExceededException extends SubscriptionException {
  const SubscriptionLimitExceededException(String resource, [String? details])
    : super('Subscription limit exceeded for: $resource', details);
}

/// Sync related exceptions
class SyncException extends ReceiptslyException {
  const SyncException(String message, [String? details])
    : super(message, details);
}

/// Sync conflict exception
class SyncConflictException extends SyncException {
  const SyncConflictException(String resourceId, [String? details])
    : super('Sync conflict detected for resource: $resourceId', details);
}

/// Sync failed exception
class SyncFailedException extends SyncException {
  const SyncFailedException([String? details])
    : super('Synchronization failed', details);
}

/// Local database related exceptions
class DatabaseException extends ReceiptslyException {
  const DatabaseException(String message, [String? details])
    : super(message, details);
}

/// Database connection failed exception
class DatabaseConnectionFailedException extends DatabaseException {
  const DatabaseConnectionFailedException([String? details])
    : super('Database connection failed', details);
}

/// Database migration failed exception
class DatabaseMigrationFailedException extends DatabaseException {
  const DatabaseMigrationFailedException(
    int fromVersion,
    int toVersion, [
    String? details,
  ]) : super(
         'Database migration failed from version $fromVersion to $toVersion',
         details,
       );
}

/// Database corruption exception
class DatabaseCorruptionException extends DatabaseException {
  const DatabaseCorruptionException([String? details])
    : super('Database corruption detected', details);
}

/// Export related exceptions
class ExportException extends ReceiptslyException {
  const ExportException(String message, [String? details])
    : super(message, details);
}

/// Export failed exception
class ExportFailedException extends ExportException {
  const ExportFailedException(String format, [String? details])
    : super('Export to $format failed', details);
}

/// Unsupported export format exception
class UnsupportedExportFormatException extends ExportException {
  const UnsupportedExportFormatException(String format, [String? details])
    : super('Unsupported export format: $format', details);
}

/// Chat bot related exceptions
class ChatBotException extends ReceiptslyException {
  const ChatBotException(String message, [String? details])
    : super(message, details);
}

/// Bot not connected exception
class BotNotConnectedException extends ChatBotException {
  const BotNotConnectedException(String platform, [String? details])
    : super('$platform bot is not connected', details);
}

/// Message send failed exception
class MessageSendFailedException extends ChatBotException {
  const MessageSendFailedException([String? details])
    : super('Failed to send message', details);
}

/// Configuration related exceptions
class ConfigurationException extends ReceiptslyException {
  const ConfigurationException(String message, [String? details])
    : super(message, details);
}

/// Missing configuration exception
class MissingConfigurationException extends ConfigurationException {
  const MissingConfigurationException(String configKey, [String? details])
    : super('Missing configuration: $configKey', details);
}

/// Invalid configuration exception
class InvalidConfigurationException extends ConfigurationException {
  const InvalidConfigurationException(String configKey, [String? details])
    : super('Invalid configuration: $configKey', details);
}

/// Permission related exceptions
class PermissionException extends ReceiptslyException {
  const PermissionException(String message, [String? details])
    : super(message, details);
}

/// Camera permission denied exception
class CameraPermissionDeniedException extends PermissionException {
  const CameraPermissionDeniedException([String? details])
    : super('Camera permission denied', details);
}

/// Storage permission denied exception
class StoragePermissionDeniedException extends PermissionException {
  const StoragePermissionDeniedException([String? details])
    : super('Storage permission denied', details);
}

/// Notification permission denied exception
class NotificationPermissionDeniedException extends PermissionException {
  const NotificationPermissionDeniedException([String? details])
    : super('Notification permission denied', details);
}

/// Biometric permission denied exception
class BiometricPermissionDeniedException extends PermissionException {
  const BiometricPermissionDeniedException([String? details])
    : super('Biometric permission denied', details);
}

/// Session related exceptions
class SessionException extends ReceiptslyException {
  const SessionException(String message, [String? details])
    : super(message, details);
}

/// Session expired exception
class SessionExpiredException extends SessionException {
  const SessionExpiredException([String? details])
    : super('User session has expired', details);
}

/// Session invalid exception
class SessionInvalidException extends SessionException {
  const SessionInvalidException([String? details])
    : super('Invalid user session', details);
}

/// Concurrent session exception
class ConcurrentSessionException extends SessionException {
  const ConcurrentSessionException([String? details])
    : super('Another session is active for this account', details);
}

/// Feature related exceptions
class FeatureException extends ReceiptslyException {
  const FeatureException(String message, [String? details])
    : super(message, details);
}

/// Feature not available exception
class FeatureNotAvailableException extends FeatureException {
  const FeatureNotAvailableException(String feature, [String? details])
    : super('Feature not available: $feature', details);
}

/// Feature disabled exception
class FeatureDisabledException extends FeatureException {
  const FeatureDisabledException(String feature, [String? details])
    : super('Feature is disabled: $feature', details);
}

/// Premium feature exception
class PremiumFeatureException extends FeatureException {
  const PremiumFeatureException(String feature, [String? details])
    : super('Premium feature requires subscription: $feature', details);
}

/// Utility class for exception handling
class ExceptionUtils {
  /// Convert a generic exception to a Receiptsly exception
  static ReceiptslyException fromException(dynamic exception) {
    if (exception is ReceiptslyException) {
      return exception;
    }

    final message = exception.toString();

    // Try to map common exceptions
    if (message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection')) {
      return NetworkException(message);
    }

    if (message.toLowerCase().contains('permission')) {
      return PermissionException(message);
    }

    if (message.toLowerCase().contains('auth')) {
      return AuthException(message);
    }

    if (message.toLowerCase().contains('payment')) {
      return PaymentException(message);
    }

    // Return generic exception
    return DataException('An unexpected error occurred', message);
  }

  /// Check if an exception is retriable
  static bool isRetriable(Exception exception) {
    if (exception is NetworkException) {
      return exception is ConnectionTimeoutException ||
          exception is ServerException ||
          (exception.statusCode != null && exception.statusCode! >= 500);
    }

    if (exception is SyncException) {
      return exception is! SyncConflictException;
    }

    if (exception is OCRException) {
      return exception is OCRProcessingFailedException;
    }

    return false;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(Exception exception) {
    if (exception is ReceiptslyException) {
      return exception.message;
    }

    // Map common Flutter/Dart exceptions to user-friendly messages
    final message = exception.toString().toLowerCase();

    if (message.contains('network') || message.contains('socket')) {
      return 'Network connection error. Please check your internet connection.';
    }

    if (message.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    }

    if (message.contains('permission')) {
      return 'Permission required. Please grant the necessary permissions.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Log exception with appropriate level
  static void logException(Exception exception, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ Exception: $exception');
      if (stackTrace != null) {
        print('📍 Stack trace: $stackTrace');
      }
    }

    // In production, you would send this to your crash reporting service
    // FirebaseConfig.instance.crashlytics?.recordError(exception, stackTrace);
  }
}
