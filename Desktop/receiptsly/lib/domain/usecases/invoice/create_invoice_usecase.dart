import 'package:dartz/dartz.dart';
import '../../entities/invoice_entity.dart';
import '../../entities/client_entity.dart';
import '../../repositories/i_invoice_repository.dart';
import '../../repositories/i_client_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';

class CreateInvoiceUseCase {
  final IInvoiceRepository _invoiceRepository;
  final IClientRepository _clientRepository;

  CreateInvoiceUseCase(this._invoiceRepository, this._clientRepository);

  Future<Either<Failure, InvoiceEntity>> call(
    CreateInvoiceParams params,
  ) async {
    try {
      // Validate input parameters
      final validationResult = _validateParams(params);
      if (validationResult != null) {
        return Left(ValidationFailure(validationResult));
      }

      // Validate client exists
      final clientResult = await _clientRepository.getById(params.clientId);
      final client = await clientResult.fold(
        (failure) => throw Exception('Client not found'),
        (client) => client,
      );

      // Generate invoice number if not provided
      final invoiceNumber =
          params.invoiceNumber ?? await _generateInvoiceNumber(params.userId);

      // Calculate totals
      final calculations = _calculateInvoiceTotals(
        params.items,
        params.taxRate,
        params.discount,
      );

      // Create invoice entity
      final invoice = InvoiceEntity(
        id: _generateInvoiceId(),
        invoiceNumber: invoiceNumber,
        userId: params.userId,
        clientId: params.clientId,
        client: client,
        issueDate: params.issueDate,
        dueDate: params.dueDate,
        items: params.items,
        subtotal: calculations.subtotal,
        taxRate: params.taxRate,
        taxAmount: calculations.taxAmount,
        discount: params.discount,
        discountAmount: calculations.discountAmount,
        total: calculations.total,
        currency: params.currency,
        status: InvoiceStatus.draft,
        notes: params.notes,
        terms: params.terms,
        template: params.template,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save invoice
      final saveResult = await _invoiceRepository.create(invoice);

      return saveResult.fold((failure) => Left(failure), (savedInvoice) async {
        // Generate PDF in background
        _generatePDFInBackground(savedInvoice);

        return Right(savedInvoice);
      });
    } catch (e) {
      return Left(
        InvoiceCreationFailure('Failed to create invoice: ${e.toString()}'),
      );
    }
  }

  String? _validateParams(CreateInvoiceParams params) {
    // Validate client ID
    if (params.clientId.isEmpty) {
      return 'Client is required';
    }

    // Validate dates
    if (params.dueDate.isBefore(params.issueDate)) {
      return 'Due date cannot be before issue date';
    }

    // Validate items
    if (params.items.isEmpty) {
      return 'At least one invoice item is required';
    }

    for (int i = 0; i < params.items.length; i++) {
      final item = params.items[i];
      if (item.description.trim().isEmpty) {
        return 'Item ${i + 1}: Description is required';
      }
      if (item.quantity <= 0) {
        return 'Item ${i + 1}: Quantity must be greater than 0';
      }
      if (item.rate < 0) {
        return 'Item ${i + 1}: Rate cannot be negative';
      }
    }

    // Validate tax rate
    if (params.taxRate < 0 || params.taxRate > 100) {
      return 'Tax rate must be between 0 and 100';
    }

    // Validate discount
    if (params.discount < 0) {
      return 'Discount cannot be negative';
    }

    // Validate currency
    if (!Validators.isValidCurrency(params.currency)) {
      return 'Invalid currency code';
    }

    return null;
  }

  Future<String> _generateInvoiceNumber(String userId) async {
    try {
      // Get user's invoice count for this year
      final year = DateTime.now().year;
      final countResult = await _invoiceRepository.getInvoiceCountForYear(
        userId,
        year,
      );

      final count = countResult.fold((failure) => 1, (count) => count + 1);

      // Format: INV-YYYY-NNNN
      return 'INV-$year-${count.toString().padLeft(4, '0')}';
    } catch (e) {
      // Fallback to timestamp-based number
      return 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  String _generateInvoiceId() {
    return 'invoice_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecond % chars.length],
    ).join();
  }

  InvoiceCalculations _calculateInvoiceTotals(
    List<InvoiceItemEntity> items,
    double taxRate,
    double discount,
  ) {
    // Calculate subtotal
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.quantity * item.rate),
    );

    // Calculate discount amount
    final discountAmount = discount > 0 && discount <= 100
        ? (subtotal * discount / 100)
        : discount; // Assume fixed amount if > 100

    // Calculate taxable amount
    final taxableAmount = subtotal - discountAmount;

    // Calculate tax amount
    final taxAmount = taxableAmount * taxRate / 100;

    // Calculate total
    final total = taxableAmount + taxAmount;

    return InvoiceCalculations(
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
      taxAmount: double.parse(taxAmount.toStringAsFixed(2)),
      total: double.parse(total.toStringAsFixed(2)),
    );
  }

  void _generatePDFInBackground(InvoiceEntity invoice) async {
    try {
      await _invoiceRepository.generatePDF(invoice.id);
    } catch (e) {
      print('Background PDF generation failed: $e');
      // Non-critical, PDF can be generated on demand
    }
  }
}

class CreateInvoiceParams {
  final String userId;
  final String clientId;
  final String? invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItemEntity> items;
  final double taxRate;
  final double discount;
  final String currency;
  final String? notes;
  final String? terms;
  final String? template;

  CreateInvoiceParams({
    required this.userId,
    required this.clientId,
    this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    this.taxRate = 0.0,
    this.discount = 0.0,
    this.currency = 'USD',
    this.notes,
    this.terms,
    this.template,
  });
}

class InvoiceCalculations {
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;

  InvoiceCalculations({
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
  });
}
