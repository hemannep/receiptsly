import 'package:dartz/dartz.dart';
import '../../entities/invoice_entity.dart';
import '../../entities/payment_entity.dart';
import '../../repositories/i_invoice_repository.dart';
import '../../repositories/i_payment_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/notification/notification_service.dart';
import '../../../services/analytics/analytics_service.dart';

class TrackPaymentUseCase {
  final IInvoiceRepository _invoiceRepository;
  final IPaymentRepository _paymentRepository;
  final NotificationService _notificationService;
  final AnalyticsService _analyticsService;

  TrackPaymentUseCase(
    this._invoiceRepository,
    this._paymentRepository,
    this._notificationService,
    this._analyticsService,
  );

  Future<Either<Failure, InvoiceEntity>> call(TrackPaymentParams params) async {
    try {
      // Get invoice
      final invoiceResult = await _invoiceRepository.getById(params.invoiceId);

      return invoiceResult.fold((failure) => Left(failure), (invoice) async {
        // Validate payment can be recorded
        final validationResult = _validatePayment(invoice, params);
        if (validationResult != null) {
          return Left(ValidationFailure(validationResult));
        }

        // Record payment
        final paymentResult = await _recordPayment(invoice, params);

        return paymentResult.fold(
          (failure) => Left(failure),
          (updatedInvoice) => Right(updatedInvoice),
        );
      });
    } catch (e) {
      return Left(
        PaymentTrackingFailure('Failed to track payment: ${e.toString()}'),
      );
    }
  }

  String? _validatePayment(InvoiceEntity invoice, TrackPaymentParams params) {
    // Check invoice status
    if (invoice.status == InvoiceStatus.cancelled) {
      return 'Cannot record payment for cancelled invoice';
    }

    if (invoice.status == InvoiceStatus.paid && params.amount > 0) {
      return 'Invoice is already fully paid';
    }

    // Validate payment amount
    if (params.amount < 0) {
      return 'Payment amount cannot be negative';
    }

    final remainingAmount = invoice.total - (invoice.paidAmount ?? 0.0);
    if (params.amount > remainingAmount + 0.01) {
      // Allow small rounding differences
      return 'Payment amount cannot exceed remaining balance';
    }

    // Validate payment date
    if (params.paymentDate.isAfter(
      DateTime.now().add(const Duration(days: 1)),
    )) {
      return 'Payment date cannot be in the future';
    }

    // Validate payment method
    if (params.paymentMethod.trim().isEmpty) {
      return 'Payment method is required';
    }

    return null;
  }

  Future<Either<Failure, InvoiceEntity>> _recordPayment(
    InvoiceEntity invoice,
    TrackPaymentParams params,
  ) async {
    try {
      // Create payment record
      final payment = PaymentEntity(
        id: _generatePaymentId(),
        invoiceId: invoice.id,
        amount: params.amount,
        paymentDate: params.paymentDate,
        paymentMethod: params.paymentMethod,
        transactionId: params.transactionId,
        notes: params.notes,
        recordedBy: params.recordedBy,
        createdAt: DateTime.now(),
      );

      // Save payment
      final paymentResult = await _paymentRepository.create(payment);

      return paymentResult.fold((failure) => Left(failure), (
        savedPayment,
      ) async {
        // Calculate new payment totals
        final newPaidAmount = (invoice.paidAmount ?? 0.0) + params.amount;
        final isFullyPaid =
            newPaidAmount >= invoice.total - 0.01; // Allow small rounding

        // Update invoice status
        final updatedInvoice = invoice.copyWith(
          paidAmount: newPaidAmount,
          status: isFullyPaid
              ? InvoiceStatus.paid
              : InvoiceStatus.partiallyPaid,
          paidAt: isFullyPaid ? DateTime.now() : invoice.paidAt,
          updatedAt: DateTime.now(),
        );

        // Save updated invoice
        final saveResult = await _invoiceRepository.update(updatedInvoice);

        return saveResult.fold((failure) => Left(failure), (
          finalInvoice,
        ) async {
          // Send notifications and track analytics
          await _handlePaymentRecorded(finalInvoice, savedPayment, isFullyPaid);

          return Right(finalInvoice);
        });
      });
    } catch (e) {
      return Left(
        PaymentTrackingFailure('Payment recording failed: ${e.toString()}'),
      );
    }
  }

  Future<void> _handlePaymentRecorded(
    InvoiceEntity invoice,
    PaymentEntity payment,
    bool isFullyPaid,
  ) async {
    try {
      // Send notification to user
      await _notificationService.notifyPaymentReceived(
        userId: invoice.userId,
        invoiceNumber: invoice.invoiceNumber,
        clientName: invoice.client?.name ?? 'Unknown Client',
        amount: payment.amount,
        currency: invoice.currency,
        isFullyPaid: isFullyPaid,
      );

      // Send thank you email to client if fully paid
      if (isFullyPaid && invoice.client?.email != null) {
        await _sendPaymentConfirmation(invoice, payment);
      }

      // Track analytics
      await _analyticsService.trackPaymentReceived(
        invoiceId: invoice.id,
        amount: payment.amount,
        paymentMethod: payment.paymentMethod,
        isFullyPaid: isFullyPaid,
        daysToPay: invoice.sentAt != null
            ? payment.paymentDate.difference(invoice.sentAt!).inDays
            : null,
      );

      // Cancel scheduled reminders if fully paid
      if (isFullyPaid) {
        await _notificationService.cancelScheduledReminders(invoice.id);
      }
    } catch (e) {
      print('Post-payment processing failed: $e');
      // Non-critical, don't fail the main operation
    }
  }

  Future<void> _sendPaymentConfirmation(
    InvoiceEntity invoice,
    PaymentEntity payment,
  ) async {
    try {
      final subject = 'Payment Received - Invoice ${invoice.invoiceNumber}';
      final body =
          '''
Dear ${invoice.client!.name},

Thank you for your payment!

Payment Details:
- Invoice Number: ${invoice.invoiceNumber}
- Amount Paid: ${invoice.currency} ${payment.amount.toStringAsFixed(2)}
- Payment Date: ${_formatDate(payment.paymentDate)}
- Payment Method: ${payment.paymentMethod}

Your invoice has been marked as paid in our records.

Thank you for your business!

Best regards,
${invoice.businessName ?? "Your Business"}
      ''';

      await _notificationService.sendEmail(
        to: invoice.client!.email!,
        subject: subject,
        body: body,
      );
    } catch (e) {
      print('Failed to send payment confirmation: $e');
    }
  }

  // Get payment history for an invoice
  Future<Either<Failure, List<PaymentEntity>>> getPaymentHistory(
    String invoiceId,
  ) async {
    try {
      return await _paymentRepository.getByInvoiceId(invoiceId);
    } catch (e) {
      return Left(
        PaymentTrackingFailure(
          'Failed to get payment history: ${e.toString()}',
        ),
      );
    }
  }

  // Send payment reminder
  Future<Either<Failure, void>> sendPaymentReminder(
    SendReminderParams params,
  ) async {
    try {
      final invoiceResult = await _invoiceRepository.getById(params.invoiceId);

      return invoiceResult.fold((failure) => Left(failure), (invoice) async {
        // Validate reminder can be sent
        if (invoice.status == InvoiceStatus.paid) {
          return Left(
            ValidationFailure('Cannot send reminder for paid invoice'),
          );
        }

        if (invoice.client?.email == null) {
          return Left(ValidationFailure('Client email not available'));
        }

        // Calculate days overdue
        final daysOverdue = DateTime.now().isAfter(invoice.dueDate)
            ? DateTime.now().difference(invoice.dueDate).inDays
            : 0;

        // Send reminder
        final reminderResult = await _sendPaymentReminder(
          invoice,
          params,
          daysOverdue,
        );

        return reminderResult.fold((failure) => Left(failure), (_) async {
          // Update last reminder sent timestamp
          await _invoiceRepository.updateLastReminderSent(
            invoice.id,
            DateTime.now(),
          );

          return const Right(null);
        });
      });
    } catch (e) {
      return Left(
        PaymentTrackingFailure('Failed to send reminder: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> _sendPaymentReminder(
    InvoiceEntity invoice,
    SendReminderParams params,
    int daysOverdue,
  ) async {
    try {
      final remainingAmount = invoice.total - (invoice.paidAmount ?? 0.0);

      final subject = daysOverdue > 0
          ? 'Payment Overdue - Invoice ${invoice.invoiceNumber}'
          : 'Payment Reminder - Invoice ${invoice.invoiceNumber}';

      final body =
          params.customMessage ??
          _getDefaultReminderTemplate(invoice, remainingAmount, daysOverdue);

      final result = await _notificationService.sendEmail(
        to: invoice.client!.email!,
        subject: subject,
        body: body,
      );

      return result.fold((failure) => Left(failure), (_) => const Right(null));
    } catch (e) {
      return Left(
        PaymentTrackingFailure('Reminder sending failed: ${e.toString()}'),
      );
    }
  }

  String _getDefaultReminderTemplate(
    InvoiceEntity invoice,
    double remainingAmount,
    int daysOverdue,
  ) {
    final greeting = daysOverdue > 0
        ? 'I hope this email finds you well.'
        : 'I hope you are doing well.';
    final urgency = daysOverdue > 0 ? 'overdue' : 'due soon';
    final tone = daysOverdue > 7 ? 'urgent attention' : 'attention';

    return '''
Dear ${invoice.client!.name},

$greeting

This is a friendly reminder that invoice ${invoice.invoiceNumber} is $urgency and requires your $tone.

Invoice Details:
- Invoice Number: ${invoice.invoiceNumber}
- Original Amount: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}
- Amount Remaining: ${invoice.currency} ${remainingAmount.toStringAsFixed(2)}
- Due Date: ${_formatDate(invoice.dueDate)}
${daysOverdue > 0 ? '- Days Overdue: $daysOverdue\n' : ''}

Please process the payment at your earliest convenience. If you have already sent the payment, please disregard this reminder.

If you have any questions or concerns regarding this invoice, please don't hesitate to contact me.

Thank you for your prompt attention to this matter.

Best regards,
${invoice.businessName ?? "Your Business"}
    ''';
  }

  String _generatePaymentId() {
    return 'payment_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecond % chars.length],
    ).join();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class TrackPaymentParams {
  final String invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? transactionId;
  final String? notes;
  final String recordedBy;

  TrackPaymentParams({
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.transactionId,
    this.notes,
    required this.recordedBy,
  });
}

class SendReminderParams {
  final String invoiceId;
  final String? customMessage;
  final bool sendCopy;

  SendReminderParams({
    required this.invoiceId,
    this.customMessage,
    this.sendCopy = false,
  });
}
