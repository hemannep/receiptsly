import 'package:dartz/dartz.dart';
import '../../entities/invoice_entity.dart';
import '../../entities/client_entity.dart';
import '../../repositories/i_invoice_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/email/email_service.dart';
import '../../../services/notification/notification_service.dart';
import '../../../services/pdf/pdf_service.dart';

class SendInvoiceUseCase {
  final IInvoiceRepository _invoiceRepository;
  final EmailService _emailService;
  final NotificationService _notificationService;
  final PDFService _pdfService;

  SendInvoiceUseCase(
    this._invoiceRepository,
    this._emailService,
    this._notificationService,
    this._pdfService,
  );

  Future<Either<Failure, InvoiceEntity>> call(SendInvoiceParams params) async {
    try {
      // Get invoice
      final invoiceResult = await _invoiceRepository.getById(params.invoiceId);

      return invoiceResult.fold((failure) => Left(failure), (invoice) async {
        // Validate invoice can be sent
        final validationResult = _validateInvoiceForSending(invoice);
        if (validationResult != null) {
          return Left(ValidationFailure(validationResult));
        }

        // Generate PDF if not exists
        await _ensurePDFExists(invoice);

        // Send invoice based on delivery method
        final sendResult = await _sendInvoice(invoice, params);

        return sendResult.fold(
          (failure) => Left(failure),
          (sentInvoice) => Right(sentInvoice),
        );
      });
    } catch (e) {
      return Left(
        InvoiceSendingFailure('Failed to send invoice: ${e.toString()}'),
      );
    }
  }

  String? _validateInvoiceForSending(InvoiceEntity invoice) {
    // Check invoice status
    if (invoice.status == InvoiceStatus.paid) {
      return 'Cannot send a paid invoice';
    }

    if (invoice.status == InvoiceStatus.cancelled) {
      return 'Cannot send a cancelled invoice';
    }

    // Check client information
    if (invoice.client == null) {
      return 'Invoice must have a valid client';
    }

    if (invoice.client!.email == null || invoice.client!.email!.isEmpty) {
      return 'Client must have a valid email address';
    }

    // Check invoice items
    if (invoice.items.isEmpty) {
      return 'Invoice must have at least one item';
    }

    // Check total amount
    if (invoice.total <= 0) {
      return 'Invoice total must be greater than zero';
    }

    return null;
  }

  Future<void> _ensurePDFExists(InvoiceEntity invoice) async {
    try {
      // Check if PDF already exists
      final pdfExists = await _invoiceRepository.pdfExists(invoice.id);

      if (!pdfExists) {
        // Generate PDF
        await _invoiceRepository.generatePDF(invoice.id);
      }
    } catch (e) {
      throw Exception('Failed to generate PDF: ${e.toString()}');
    }
  }

  Future<Either<Failure, InvoiceEntity>> _sendInvoice(
    InvoiceEntity invoice,
    SendInvoiceParams params,
  ) async {
    try {
      // Send via email
      final emailResult = await _sendViaEmail(invoice, params);

      if (emailResult.isLeft()) {
        return emailResult;
      }

      // Send via WhatsApp if requested
      if (params.sendViaWhatsApp && invoice.client!.phoneNumber != null) {
        await _sendViaWhatsApp(invoice, params);
      }

      // Update invoice status
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.sent,
        sentAt: DateTime.now(),
        sentBy: params.sentBy,
        deliveryMethod: _getDeliveryMethods(params),
        lastReminderSent: null,
        updatedAt: DateTime.now(),
      );

      // Save updated invoice
      final saveResult = await _invoiceRepository.update(updatedInvoice);

      return saveResult.fold((failure) => Left(failure), (savedInvoice) async {
        // Schedule payment reminder if requested
        if (params.scheduleReminder) {
          await _schedulePaymentReminder(savedInvoice);
        }

        // Send notification to user
        await _notifyUser(savedInvoice, params);

        return Right(savedInvoice);
      });
    } catch (e) {
      return Left(
        InvoiceSendingFailure('Send operation failed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> _sendViaEmail(
    InvoiceEntity invoice,
    SendInvoiceParams params,
  ) async {
    try {
      // Get PDF file
      final pdfResult = await _invoiceRepository.getPDFFile(invoice.id);

      return pdfResult.fold((failure) => Left(failure), (pdfFile) async {
        // Prepare email content
        final emailContent = _prepareEmailContent(invoice, params);

        // Send email
        final emailResult = await _emailService.sendInvoiceEmail(
          to: invoice.client!.email!,
          subject: emailContent.subject,
          body: emailContent.body,
          attachments: [pdfFile],
          cc: params.ccEmails,
          bcc: params.bccEmails,
        );

        return emailResult.fold(
          (failure) => Left(failure),
          (_) => const Right(null),
        );
      });
    } catch (e) {
      return Left(EmailSendingFailure('Email sending failed: ${e.toString()}'));
    }
  }

  Future<void> _sendViaWhatsApp(
    InvoiceEntity invoice,
    SendInvoiceParams params,
  ) async {
    try {
      // Get PDF file
      final pdfResult = await _invoiceRepository.getPDFFile(invoice.id);

      await pdfResult.fold((failure) => throw Exception('PDF not available'), (
        pdfFile,
      ) async {
        // Prepare WhatsApp message
        final message = _prepareWhatsAppMessage(invoice);

        // Send via WhatsApp service
        await _emailService.sendWhatsAppInvoice(
          phoneNumber: invoice.client!.phoneNumber!,
          message: message,
          pdfFile: pdfFile,
        );
      });
    } catch (e) {
      print('WhatsApp sending failed: $e');
      // Non-critical, continue with email
    }
  }

  EmailContent _prepareEmailContent(
    InvoiceEntity invoice,
    SendInvoiceParams params,
  ) {
    final client = invoice.client!;

    // Custom subject or default
    final subject =
        params.customSubject ??
        'Invoice ${invoice.invoiceNumber} from ${invoice.businessName ?? "Your Business"}';

    // Custom message or default template
    final body = params.customMessage ?? _getDefaultEmailTemplate(invoice);

    return EmailContent(
      subject: subject,
      body: body
          .replaceAll('{clientName}', client.name)
          .replaceAll('{invoiceNumber}', invoice.invoiceNumber)
          .replaceAll(
            '{total}',
            '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
          )
          .replaceAll('{dueDate}', _formatDate(invoice.dueDate)),
    );
  }

  String _getDefaultEmailTemplate(InvoiceEntity invoice) {
    return '''
Dear {clientName},

I hope this email finds you well.

Please find attached invoice {invoiceNumber} for the services provided. 

Invoice Details:
- Invoice Number: {invoiceNumber}
- Amount Due: {total}
- Due Date: {dueDate}

Payment can be made via the methods specified in the invoice. Please don't hesitate to contact me if you have any questions regarding this invoice.

Thank you for your business!

Best regards,
${invoice.businessName ?? "Your Business"}
    ''';
  }

  String _prepareWhatsAppMessage(InvoiceEntity invoice) {
    return '''
📄 *Invoice ${invoice.invoiceNumber}*

Hi ${invoice.client!.name},

Your invoice is ready! 

💰 Amount: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}
📅 Due Date: ${_formatDate(invoice.dueDate)}

Please find the invoice PDF attached. Let me know if you have any questions!

Thank you! 🙏
    ''';
  }

  List<String> _getDeliveryMethods(SendInvoiceParams params) {
    final methods = <String>['email'];

    if (params.sendViaWhatsApp) {
      methods.add('whatsapp');
    }

    return methods;
  }

  Future<void> _schedulePaymentReminder(InvoiceEntity invoice) async {
    try {
      // Schedule reminder 3 days before due date
      final reminderDate = invoice.dueDate.subtract(const Duration(days: 3));

      if (reminderDate.isAfter(DateTime.now())) {
        await _notificationService.schedulePaymentReminder(
          invoiceId: invoice.id,
          clientEmail: invoice.client!.email!,
          reminderDate: reminderDate,
          amount: invoice.total,
          currency: invoice.currency,
        );
      }
    } catch (e) {
      print('Failed to schedule reminder: $e');
      // Non-critical
    }
  }

  Future<void> _notifyUser(
    InvoiceEntity invoice,
    SendInvoiceParams params,
  ) async {
    try {
      await _notificationService.notifyInvoiceSent(
        userId: invoice.userId,
        invoiceNumber: invoice.invoiceNumber,
        clientName: invoice.client!.name,
        amount: invoice.total,
        currency: invoice.currency,
      );
    } catch (e) {
      print('Failed to notify user: $e');
      // Non-critical
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SendInvoiceParams {
  final String invoiceId;
  final String sentBy;
  final bool sendViaWhatsApp;
  final bool scheduleReminder;
  final String? customSubject;
  final String? customMessage;
  final List<String>? ccEmails;
  final List<String>? bccEmails;

  SendInvoiceParams({
    required this.invoiceId,
    required this.sentBy,
    this.sendViaWhatsApp = false,
    this.scheduleReminder = true,
    this.customSubject,
    this.customMessage,
    this.ccEmails,
    this.bccEmails,
  });
}

class EmailContent {
  final String subject;
  final String body;

  EmailContent({required this.subject, required this.body});
}
