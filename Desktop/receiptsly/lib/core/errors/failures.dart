// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';
import 'exceptions.dart';

/// Abstract base class for all failures in the application
/// Failures represent the result of failed operations and are used
/// to communicate errors across different layers of the architecture
abstract class Failure extends Equatable {
  const Failure(this.message, [this.details]);

  final String message;
  final String? details;

  @override
  List<Object?> get props => [message, details];

  @override
  String toString() =>
      'Failure: $message${details != null ? ' - $details' : ''}';
}

/// General failure for unexpected errors
class GeneralFailure extends Failure {
  const GeneralFailure(String message, [String? details])
    : super(message, details);
}

/// Authentication related failures
abstract class AuthFailure extends Failure {
  const AuthFailure(String message, [String? details])
    : super(message, details);
}

/// Invalid credentials failure
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([String? details])
    : super('Invalid email or password', details);
}

/// User not found failure
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([String? details])
    : super('No account found with this email', details);
}

/// Account disabled failure
class AccountDisabledFailure extends AuthFailure {
  const AccountDisabledFailure([String? details])
    : super('This account has been disabled', details);
}

/// Email not verified failure
class EmailNotVerifiedFailure extends AuthFailure {
  const EmailNotVerifiedFailure([String? details])
    : super('Please verify your email address before signing in', details);
}

/// Too many requests failure
class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure([String? details])
    : super('Too many failed attempts. Please try again later', details);
}

/// Weak password failure
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([String? details])
    : super('Password is too weak. Please choose a stronger password', details);
}

/// Email already in use failure
class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([String? details])
    : super('An account already exists with this email address', details);
}

/// Phone verification failure
class PhoneVerificationFailure extends AuthFailure {
  const PhoneVerificationFailure([String? details])
    : super('Phone number verification failed', details);
}

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, [String? details, this.statusCode])
    : super(message, details);

  final int? statusCode;

  @override
  List<Object?> get props => [message, details, statusCode];
}

/// No internet connection failure
class NoInternetFailure extends NetworkFailure {
  const NoInternetFailure([String? details])
    : super(
        'No internet connection. Please check your network settings',
        details,
      );
}

/// Connection timeout failure
class ConnectionTimeoutFailure extends NetworkFailure {
  const ConnectionTimeoutFailure([String? details])
    : super('Connection timed out. Please try again', details, 408);
}

/// Server error failure
class ServerFailure extends NetworkFailure {
  const ServerFailure([String? details, int? statusCode])
    : super('Server error. Please try again later', details, statusCode);
}

/// Bad request failure
class BadRequestFailure extends NetworkFailure {
  const BadRequestFailure([String? details])
    : super('Invalid request. Please check your input', details, 400);
}

/// Unauthorized failure
class UnauthorizedFailure extends NetworkFailure {
  const UnauthorizedFailure([String? details])
    : super('You are not authorized to perform this action', details, 401);
}

/// Forbidden failure
class ForbiddenFailure extends NetworkFailure {
  const ForbiddenFailure([String? details])
    : super(
        'Access denied. You do not have permission for this action',
        details,
        403,
      );
}

/// Not found failure
class NotFoundFailure extends NetworkFailure {
  const NotFoundFailure([String? details])
    : super('The requested resource was not found', details, 404);
}

/// Rate limit exceeded failure
class RateLimitFailure extends NetworkFailure {
  const RateLimitFailure([String? details])
    : super('Too many requests. Please wait before trying again', details, 429);
}

/// Data related failures
abstract class DataFailure extends Failure {
  const DataFailure(String message, [String? details])
    : super(message, details);
}

/// Invalid data format failure
class InvalidDataFormatFailure extends DataFailure {
  const InvalidDataFormatFailure([String? details])
    : super('Invalid data format received', details);
}

/// Parsing failure
class ParsingFailure extends DataFailure {
  const ParsingFailure([String? details])
    : super('Failed to parse data', details);
}

/// Validation failures
abstract class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? details, this.field])
    : super(message, details);

  final String? field;

  @override
  List<Object?> get props => [message, details, field];
}

/// Required field failure
class RequiredFieldFailure extends ValidationFailure {
  const RequiredFieldFailure(String fieldName, [String? details])
    : super('$fieldName is required', details, fieldName);
}

/// Invalid email failure
class InvalidEmailFailure extends ValidationFailure {
  const InvalidEmailFailure([String? details])
    : super('Please enter a valid email address', details, 'email');
}

/// Invalid phone number failure
class InvalidPhoneNumberFailure extends ValidationFailure {
  const InvalidPhoneNumberFailure([String? details])
    : super('Please enter a valid phone number', details, 'phone');
}

/// Invalid amount failure
class InvalidAmountFailure extends ValidationFailure {
  const InvalidAmountFailure([String? details])
    : super('Please enter a valid amount', details, 'amount');
}

/// Invalid date failure
class InvalidDateFailure extends ValidationFailure {
  const InvalidDateFailure([String? details])
    : super('Please enter a valid date', details, 'date');
}

/// Storage related failures
abstract class StorageFailure extends Failure {
  const StorageFailure(String message, [String? details])
    : super(message, details);
}

/// File not found failure
class FileNotFoundFailure extends StorageFailure {
  const FileNotFoundFailure([String? details])
    : super('File not found', details);
}

/// File too large failure
class FileTooLargeFailure extends StorageFailure {
  const FileTooLargeFailure(int maxSizeMB, [String? details])
    : super(
        'File is too large. Maximum size allowed is ${maxSizeMB}MB',
        details,
      );
}

/// Invalid file type failure
class InvalidFileTypeFailure extends StorageFailure {
  InvalidFileTypeFailure(List<String> allowedTypes, [String? details])
    : super(
        'Invalid file type. Allowed types: ${allowedTypes.join(", ")}',
        details,
      );
}

/// Storage quota exceeded failure
class StorageQuotaExceededFailure extends StorageFailure {
  const StorageQuotaExceededFailure([String? details])
    : super(
        'Storage quota exceeded. Please upgrade your plan or delete some files',
        details,
      );
}

/// Upload failed failure
class UploadFailedFailure extends StorageFailure {
  const UploadFailedFailure([String? details])
    : super('File upload failed. Please try again', details);
}

/// Download failed failure
class DownloadFailedFailure extends StorageFailure {
  const DownloadFailedFailure([String? details])
    : super('File download failed. Please try again', details);
}

/// OCR related failures
abstract class OCRFailure extends Failure {
  const OCRFailure(String message, [String? details]) : super(message, details);
}

/// OCR processing failed failure
class OCRProcessingFailedFailure extends OCRFailure {
  const OCRProcessingFailedFailure([String? details])
    : super(
        'Failed to process receipt. Please try with a clearer image',
        details,
      );
}

/// Low confidence OCR failure
class LowConfidenceOCRFailure extends OCRFailure {
  LowConfidenceOCRFailure(double confidence, [String? details])
    : super(
        'Receipt text recognition confidence is low (${(confidence * 100).toStringAsFixed(1)}%). Please verify the extracted information',
        details,
      );
}

/// Unsupported language failure
class UnsupportedLanguageOCRFailure extends OCRFailure {
  const UnsupportedLanguageOCRFailure(String language, [String? details])
    : super(
        'Language "$language" is not supported for text recognition',
        details,
      );
}

/// Image quality too poor failure
class ImageQualityToorFailure extends OCRFailure {
  const ImageQualityToorFailure([String? details])
    : super(
        'Image quality is too poor for text recognition. Please take a clearer photo',
        details,
      );
}

/// Payment related failures
abstract class PaymentFailure extends Failure {
  const PaymentFailure(String message, [String? details, this.code])
    : super(message, details);

  final String? code;

  @override
  List<Object?> get props => [message, details, code];
}

/// Payment processing failed failure
class PaymentProcessingFailedFailure extends PaymentFailure {
  const PaymentProcessingFailedFailure([String? details, String? code])
    : super('Payment processing failed. Please try again', details, code);
}

/// Payment cancelled failure
class PaymentCancelledFailure extends PaymentFailure {
  const PaymentCancelledFailure([String? details])
    : super('Payment was cancelled', details, 'cancelled');
}

/// Invalid payment method failure
class InvalidPaymentMethodFailure extends PaymentFailure {
  const InvalidPaymentMethodFailure([String? details])
    : super(
        'Invalid payment method. Please check your payment details',
        details,
        'invalid_payment_method',
      );
}

/// Insufficient funds failure
class InsufficientFundsFailure extends PaymentFailure {
  const InsufficientFundsFailure([String? details])
    : super(
        'Insufficient funds. Please use a different payment method',
        details,
        'insufficient_funds',
      );
}

/// Card declined failure
class CardDeclinedFailure extends PaymentFailure {
  const CardDeclinedFailure([String? details])
    : super(
        'Your card was declined. Please try a different card',
        details,
        'card_declined',
      );
}

/// Card expired failure
class CardExpiredFailure extends PaymentFailure {
  const CardExpiredFailure([String? details])
    : super(
        'Your card has expired. Please use a different card',
        details,
        'card_expired',
      );
}

/// Subscription related failures
abstract class SubscriptionFailure extends Failure {
  const SubscriptionFailure(String message, [String? details])
    : super(message, details);
}

/// Subscription not found failure
class SubscriptionNotFoundFailure extends SubscriptionFailure {
  const SubscriptionNotFoundFailure([String? details])
    : super('No active subscription found', details);
}

/// Subscription expired failure
class SubscriptionExpiredFailure extends SubscriptionFailure {
  const SubscriptionExpiredFailure([String? details])
    : super(
        'Your subscription has expired. Please renew to continue using premium features',
        details,
      );
}

/// Subscription limit exceeded failure
class SubscriptionLimitExceededFailure extends SubscriptionFailure {
  const SubscriptionLimitExceededFailure(String resource, [String? details])
    : super(
        'You have reached the limit for $resource. Please upgrade your plan',
        details,
      );
}

/// Subscription upgrade required failure
class SubscriptionUpgradeRequiredFailure extends SubscriptionFailure {
  const SubscriptionUpgradeRequiredFailure(String feature, [String? details])
    : super(
        '$feature requires a premium subscription. Please upgrade your plan',
        details,
      );
}

/// Sync related failures
abstract class SyncFailure extends Failure {
  const SyncFailure(String message, [String? details])
    : super(message, details);
}

/// Sync conflict failure
class SyncConflictFailure extends SyncFailure {
  const SyncConflictFailure(String resourceType, [String? details])
    : super(
        'Sync conflict detected for $resourceType. Manual resolution required',
        details,
      );
}

/// Sync failed failure
class SyncFailedFailure extends SyncFailure {
  const SyncFailedFailure([String? details])
    : super(
        'Synchronization failed. Your data will sync when connection is restored',
        details,
      );
}

/// Offline mode failure
class OfflineModeFailure extends SyncFailure {
  const OfflineModeFailure([String? details])
    : super('This action requires an internet connection', details);
}

/// Local database related failures
abstract class DatabaseFailure extends Failure {
  const DatabaseFailure(String message, [String? details])
    : super(message, details);
}

/// Database connection failed failure
class DatabaseConnectionFailedFailure extends DatabaseFailure {
  const DatabaseConnectionFailedFailure([String? details])
    : super('Database connection failed. Please restart the app', details);
}

/// Database migration failed failure
class DatabaseMigrationFailedFailure extends DatabaseFailure {
  const DatabaseMigrationFailedFailure([String? details])
    : super('Database migration failed. Please reinstall the app', details);
}

/// Database corruption failure
class DatabaseCorruptionFailure extends DatabaseFailure {
  const DatabaseCorruptionFailure([String? details])
    : super('Database corruption detected. Please reinstall the app', details);
}

/// Database operation failed failure
class DatabaseOperationFailedFailure extends DatabaseFailure {
  const DatabaseOperationFailedFailure(String operation, [String? details])
    : super('Database $operation operation failed', details);
}

/// Export related failures
abstract class ExportFailure extends Failure {
  const ExportFailure(String message, [String? details])
    : super(message, details);
}

/// Export failed failure
class ExportFailedFailure extends ExportFailure {
  const ExportFailedFailure(String format, [String? details])
    : super('Failed to export data as $format. Please try again', details);
}

/// Unsupported export format failure
class UnsupportedExportFormatFailure extends ExportFailure {
  const UnsupportedExportFormatFailure(String format, [String? details])
    : super('Export format $format is not supported', details);
}

/// No data to export failure
class NoDataToExportFailure extends ExportFailure {
  const NoDataToExportFailure([String? details])
    : super('No data available to export', details);
}

/// Chat bot related failures
abstract class ChatBotFailure extends Failure {
  const ChatBotFailure(String message, [String? details])
    : super(message, details);
}

/// Bot not connected failure
class BotNotConnectedFailure extends ChatBotFailure {
  const BotNotConnectedFailure(String platform, [String? details])
    : super(
        '$platform bot is not connected. Please connect in settings',
        details,
      );
}

/// Message send failed failure
class MessageSendFailedFailure extends ChatBotFailure {
  const MessageSendFailedFailure([String? details])
    : super('Failed to send message. Please try again', details);
}

/// Bot configuration invalid failure
class BotConfigurationInvalidFailure extends ChatBotFailure {
  const BotConfigurationInvalidFailure(String platform, [String? details])
    : super(
        '$platform bot configuration is invalid. Please reconfigure in settings',
        details,
      );
}

/// Permission related failures
abstract class PermissionFailure extends Failure {
  const PermissionFailure(String message, [String? details])
    : super(message, details);
}

/// Camera permission denied failure
class CameraPermissionDeniedFailure extends PermissionFailure {
  const CameraPermissionDeniedFailure([String? details])
    : super(
        'Camera permission is required to capture receipts. Please enable it in settings',
        details,
      );
}

/// Storage permission denied failure
class StoragePermissionDeniedFailure extends PermissionFailure {
  const StoragePermissionDeniedFailure([String? details])
    : super(
        'Storage permission is required to save files. Please enable it in settings',
        details,
      );
}

/// Notification permission denied failure
class NotificationPermissionDeniedFailure extends PermissionFailure {
  const NotificationPermissionDeniedFailure([String? details])
    : super(
        'Notification permission is required for alerts. Please enable it in settings',
        details,
      );
}

/// Biometric permission denied failure
class BiometricPermissionDeniedFailure extends PermissionFailure {
  const BiometricPermissionDeniedFailure([String? details])
    : super(
        'Biometric authentication is not available. Please enable it in settings',
        details,
      );
}

/// Session related failures
abstract class SessionFailure extends Failure {
  const SessionFailure(String message, [String? details])
    : super(message, details);
}

/// Session expired failure
class SessionExpiredFailure extends SessionFailure {
  const SessionExpiredFailure([String? details])
    : super('Your session has expired. Please sign in again', details);
}

/// Session invalid failure
class SessionInvalidFailure extends SessionFailure {
  const SessionInvalidFailure([String? details])
    : super('Invalid session. Please sign in again', details);
}

/// Concurrent session failure
class ConcurrentSessionFailure extends SessionFailure {
  const ConcurrentSessionFailure([String? details])
    : super(
        'Another session is active for this account. Please sign out from other devices',
        details,
      );
}

/// Feature related failures
abstract class FeatureFailure extends Failure {
  const FeatureFailure(String message, [String? details])
    : super(message, details);
}

/// Feature not available failure
class FeatureNotAvailableFailure extends FeatureFailure {
  const FeatureNotAvailableFailure(String feature, [String? details])
    : super('$feature is not available on this device', details);
}

/// Feature disabled failure
class FeatureDisabledFailure extends FeatureFailure {
  const FeatureDisabledFailure(String feature, [String? details])
    : super('$feature is currently disabled', details);
}

/// Premium feature failure
class PremiumFeatureFailure extends FeatureFailure {
  const PremiumFeatureFailure(String feature, [String? details])
    : super(
        '$feature is a premium feature. Please upgrade your subscription',
        details,
      );
}

/// Configuration related failures
abstract class ConfigurationFailure extends Failure {
  const ConfigurationFailure(String message, [String? details])
    : super(message, details);
}

/// Missing configuration failure
class MissingConfigurationFailure extends ConfigurationFailure {
  const MissingConfigurationFailure(String config, [String? details])
    : super('Missing configuration: $config', details);
}

/// Invalid configuration failure
class InvalidConfigurationFailure extends ConfigurationFailure {
  const InvalidConfigurationFailure(String config, [String? details])
    : super('Invalid configuration: $config', details);
}

/// Business logic failures
abstract class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure(String message, [String? details])
    : super(message, details);
}

/// Duplicate receipt failure
class DuplicateReceiptFailure extends BusinessLogicFailure {
  const DuplicateReceiptFailure([String? details])
    : super('This receipt has already been uploaded', details);
}

/// Invalid invoice state failure
class InvalidInvoiceStateFailure extends BusinessLogicFailure {
  const InvalidInvoiceStateFailure(
    String action,
    String currentState, [
    String? details,
  ]) : super('Cannot $action invoice in $currentState state', details);
}

/// Client limit exceeded failure
class ClientLimitExceededFailure extends BusinessLogicFailure {
  const ClientLimitExceededFailure(int limit, [String? details])
    : super(
        'You have reached the maximum number of clients ($limit) for your plan',
        details,
      );
}

/// Receipt limit exceeded failure
class ReceiptLimitExceededFailure extends BusinessLogicFailure {
  const ReceiptLimitExceededFailure(int limit, [String? details])
    : super(
        'You have reached the maximum number of receipts ($limit) for this month',
        details,
      );
}

/// Invoice limit exceeded failure
class InvoiceLimitExceededFailure extends BusinessLogicFailure {
  const InvoiceLimitExceededFailure(int limit, [String? details])
    : super(
        'You have reached the maximum number of invoices ($limit) for your plan',
        details,
      );
}

/// Utility class for converting exceptions to failures
class FailureConverter {
  /// Convert an exception to an appropriate failure
  static Failure fromException(Exception exception) {
    // Auth exceptions
    if (exception is InvalidCredentialsException) {
      return InvalidCredentialsFailure(exception.details);
    }
    if (exception is UserNotFoundException) {
      return UserNotFoundFailure(exception.details);
    }
    if (exception is AccountDisabledException) {
      return AccountDisabledFailure(exception.details);
    }
    if (exception is EmailNotVerifiedException) {
      return EmailNotVerifiedFailure(exception.details);
    }
    if (exception is TooManyRequestsException) {
      return TooManyRequestsFailure(exception.details);
    }
    if (exception is WeakPasswordException) {
      return WeakPasswordFailure(exception.details);
    }

    // Network exceptions
    if (exception is NoInternetException) {
      return NoInternetFailure(exception.details);
    }
    if (exception is ConnectionTimeoutException) {
      return ConnectionTimeoutFailure(exception.details);
    }
    if (exception is ServerException) {
      return ServerFailure(exception.details, exception.statusCode);
    }
    if (exception is BadRequestException) {
      return BadRequestFailure(exception.details);
    }
    if (exception is UnauthorizedException) {
      return UnauthorizedFailure(exception.details);
    }
    if (exception is ForbiddenException) {
      return ForbiddenFailure(exception.details);
    }
    if (exception is NotFoundException) {
      return NotFoundFailure(exception.details);
    }
    if (exception is RateLimitExceededException) {
      return RateLimitFailure(exception.details);
    }

    // Validation exceptions
    if (exception is RequiredFieldException) {
      return RequiredFieldFailure(exception.field!, exception.details);
    }
    if (exception is InvalidEmailException) {
      return InvalidEmailFailure(exception.details);
    }
    if (exception is InvalidPhoneNumberException) {
      return InvalidPhoneNumberFailure(exception.details);
    }

    // Storage exceptions
    if (exception is FileNotFoundException) {
      return FileNotFoundFailure(exception.details);
    }
    if (exception is FileTooLargeException) {
      return FileTooLargeFailure(10, exception.details); // Default max size
    }
    if (exception is InvalidFileTypeException) {
      return InvalidFileTypeFailure(['jpg', 'png', 'pdf'], exception.details);
    }
    if (exception is StorageQuotaExceededException) {
      return StorageQuotaExceededFailure(exception.details);
    }
    if (exception is UploadFailedException) {
      return UploadFailedFailure(exception.details);
    }
    if (exception is DownloadFailedException) {
      return DownloadFailedFailure(exception.details);
    }

    // OCR exceptions
    if (exception is OCRProcessingFailedException) {
      return OCRProcessingFailedFailure(exception.details);
    }
    if (exception is LowConfidenceOCRException) {
      return LowConfidenceOCRFailure(
        0.5,
        exception.details,
      ); // Default confidence
    }
    if (exception is UnsupportedLanguageException) {
      return UnsupportedLanguageOCRFailure('unknown', exception.details);
    }

    // Payment exceptions
    if (exception is PaymentFailedException) {
      return PaymentProcessingFailedFailure(exception.details, exception.code);
    }
    if (exception is PaymentCancelledException) {
      return PaymentCancelledFailure(exception.details);
    }
    if (exception is InvalidPaymentMethodException) {
      return InvalidPaymentMethodFailure(exception.details);
    }
    if (exception is InsufficientFundsException) {
      return InsufficientFundsFailure(exception.details);
    }
    if (exception is CardDeclinedException) {
      return CardDeclinedFailure(exception.details);
    }

    // Subscription exceptions
    if (exception is SubscriptionNotFoundException) {
      return SubscriptionNotFoundFailure(exception.details);
    }
    if (exception is SubscriptionExpiredException) {
      return SubscriptionExpiredFailure(exception.details);
    }
    if (exception is SubscriptionLimitExceededException) {
      return SubscriptionLimitExceededFailure('unknown', exception.details);
    }

    // Sync exceptions
    if (exception is SyncConflictException) {
      return SyncConflictFailure('data', exception.details);
    }
    if (exception is SyncFailedException) {
      return SyncFailedFailure(exception.details);
    }

    // Database exceptions
    if (exception is DatabaseConnectionFailedException) {
      return DatabaseConnectionFailedFailure(exception.details);
    }
    if (exception is DatabaseMigrationFailedException) {
      return DatabaseMigrationFailedFailure(exception.details);
    }
    if (exception is DatabaseCorruptionException) {
      return DatabaseCorruptionFailure(exception.details);
    }

    // Export exceptions
    if (exception is ExportFailedException) {
      return ExportFailedFailure('unknown', exception.details);
    }
    if (exception is UnsupportedExportFormatException) {
      return UnsupportedExportFormatFailure('unknown', exception.details);
    }

    // Chat bot exceptions
    if (exception is BotNotConnectedException) {
      return BotNotConnectedFailure('unknown', exception.details);
    }
    if (exception is MessageSendFailedException) {
      return MessageSendFailedFailure(exception.details);
    }

    // Permission exceptions
    if (exception is CameraPermissionDeniedException) {
      return CameraPermissionDeniedFailure(exception.details);
    }
    if (exception is StoragePermissionDeniedException) {
      return StoragePermissionDeniedFailure(exception.details);
    }
    if (exception is NotificationPermissionDeniedException) {
      return NotificationPermissionDeniedFailure(exception.details);
    }
    if (exception is BiometricPermissionDeniedException) {
      return BiometricPermissionDeniedFailure(exception.details);
    }

    // Session exceptions
    if (exception is SessionExpiredException) {
      return SessionExpiredFailure(exception.details);
    }
    if (exception is SessionInvalidException) {
      return SessionInvalidFailure(exception.details);
    }
    if (exception is ConcurrentSessionException) {
      return ConcurrentSessionFailure(exception.details);
    }

    // Feature exceptions
    if (exception is FeatureNotAvailableException) {
      return FeatureNotAvailableFailure('unknown', exception.details);
    }
    if (exception is FeatureDisabledException) {
      return FeatureDisabledFailure('unknown', exception.details);
    }
    if (exception is PremiumFeatureException) {
      return PremiumFeatureFailure('unknown', exception.details);
    }

    // Configuration exceptions
    if (exception is MissingConfigurationException) {
      return MissingConfigurationFailure('unknown', exception.details);
    }
    if (exception is InvalidConfigurationException) {
      return InvalidConfigurationFailure('unknown', exception.details);
    }

    // Generic handling for unknown exceptions
    if (exception is ReceiptslyException) {
      return GeneralFailure(exception.message, exception.details);
    }

    // Fallback for any other exception
    return GeneralFailure('An unexpected error occurred', exception.toString());
  }

  /// Check if a failure is recoverable/retriable
  static bool isRecoverable(Failure failure) {
    // Network failures (except forbidden/unauthorized) are usually recoverable
    if (failure is NetworkFailure) {
      return failure is! UnauthorizedFailure &&
          failure is! ForbiddenFailure &&
          failure is! BadRequestFailure;
    }

    // OCR failures are recoverable (user can try with better image)
    if (failure is OCRFailure) {
      return true;
    }

    // Upload/download failures are recoverable
    if (failure is UploadFailedFailure || failure is DownloadFailedFailure) {
      return true;
    }

    // Sync failures are recoverable
    if (failure is SyncFailedFailure) {
      return true;
    }

    // Payment failures (except cancelled) might be recoverable
    if (failure is PaymentFailure) {
      return failure is! PaymentCancelledFailure;
    }

    return false;
  }

  /// Get user action suggestions for a failure
  static List<String> getActionSuggestions(Failure failure) {
    if (failure is NoInternetFailure) {
      return ['Check your internet connection', 'Try again when online'];
    }

    if (failure is ConnectionTimeoutFailure) {
      return ['Check your internet connection', 'Try again'];
    }

    if (failure is InvalidCredentialsFailure) {
      return ['Check your email and password', 'Reset your password if needed'];
    }

    if (failure is EmailNotVerifiedFailure) {
      return [
        'Check your email for verification link',
        'Resend verification email',
      ];
    }

    if (failure is CameraPermissionDeniedFailure) {
      return ['Enable camera permission in settings', 'Go to app settings'];
    }

    if (failure is OCRProcessingFailedFailure) {
      return [
        'Take a clearer photo',
        'Ensure good lighting',
        'Try again with better image quality',
      ];
    }

    if (failure is FileTooLargeFailure) {
      return [
        'Compress the image',
        'Use a smaller file',
        'Try a different image',
      ];
    }

    if (failure is SubscriptionExpiredFailure) {
      return [
        'Renew your subscription',
        'Upgrade your plan',
        'Contact support',
      ];
    }

    if (failure is SubscriptionLimitExceededFailure) {
      return ['Upgrade your plan', 'Delete old data', 'Contact support'];
    }

    return ['Try again', 'Contact support if the problem persists'];
  }
}
