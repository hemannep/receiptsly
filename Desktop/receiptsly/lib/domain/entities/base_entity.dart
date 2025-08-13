abstract class BaseEntity {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();
}

// core/errors/failures.dart
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

class CaptureFailure extends Failure {
  const CaptureFailure(String message) : super(message);
}

class OCRProcessingFailure extends Failure {
  const OCRProcessingFailure(String message) : super(message);
}

class CategorizationFailure extends Failure {
  const CategorizationFailure(String message) : super(message);
}

class SyncFailure extends Failure {
  const SyncFailure(String message) : super(message);
}

class InvoiceCreationFailure extends Failure {
  const InvoiceCreationFailure(String message) : super(message);
}

class InvoiceSendingFailure extends Failure {
  const InvoiceSendingFailure(String message) : super(message);
}

class EmailSendingFailure extends Failure {
  const EmailSendingFailure(String message) : super(message);
}

class PaymentTrackingFailure extends Failure {
  const PaymentTrackingFailure(String message) : super(message);
}
