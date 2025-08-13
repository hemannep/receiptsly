// lib/data/repositories/invoice_repository.dart
import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/i_invoice_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/models/invoice/invoice_model.dart';
import '../../domain/models/invoice/invoice_item_model.dart';
import '../../domain/datasources/local/invoice_local_datasource.dart';
import '../../domain/datasources/remote/firebase/invoice_remote_datasource.dart';
import '../../services/sync/sync_service.dart';
import '../../services/export/pdf_generator.dart';
import '../../services/notification/local_notification_service.dart';

class InvoiceRepository implements IInvoiceRepository {
  final InvoiceLocalDatasource _localDatasource;
  final InvoiceRemoteDatasource _remoteDatasource;
  final SyncService _syncService;
  final PDFGenerator _pdfGenerator;
  final LocalNotificationService _notificationService;
  final Connectivity _connectivity;

  InvoiceRepository({
    required InvoiceLocalDatasource localDatasource,
    required InvoiceRemoteDatasource remoteDatasource,
    required SyncService syncService,
    required PDFGenerator pdfGenerator,
    required LocalNotificationService notificationService,
    required Connectivity connectivity,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _syncService = syncService,
       _pdfGenerator = pdfGenerator,
       _notificationService = notificationService,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, InvoiceEntity>> createInvoice({
    required String userId,
    required String clientId,
    required String invoiceNumber,
    required DateTime issueDate,
    required DateTime dueDate,
    required List<InvoiceItemEntity> items,
    double tax = 0.0,
    double discount = 0.0,
    String? notes,
    String? terms,
  }) async {
    try {
      final invoiceId = _generateInvoiceId();

      // Calculate totals
      final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
      final discountAmount = discount;
      final taxAmount = (subtotal - discountAmount) * (tax / 100);
      final total = subtotal - discountAmount + taxAmount;

      // Create invoice model
      final invoiceModel = InvoiceModel(
        id: invoiceId,
        userId: userId,
        clientId: clientId,
        invoiceNumber: invoiceNumber,
        issueDate: issueDate,
        dueDate: dueDate,
        items: items.map((item) => InvoiceItemModel.fromEntity(item)).toList(),
        subtotal: subtotal,
        tax: tax,
        taxAmount: taxAmount,
        discount: discount,
        discountAmount: discountAmount,
        total: total,
        notes: notes ?? '',
        terms: terms ?? 'Payment due within 30 days',
        status: InvoiceStatus.draft,
        pdfUrl: '',
        sentAt: null,
        paidAt: null,
        remindersSent: 0,
        lastReminderAt: null,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await _localDatasource.insertInvoice(invoiceModel);

      // Check connectivity and sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.createInvoice(invoiceModel);

          // Mark as synced
          final syncedModel = invoiceModel.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.updateInvoice(syncedModel);

          return Right(syncedModel.toEntity());
        } catch (e) {
          // Add to sync queue if remote save fails
          await _syncService.addToSyncQueue(
            action: 'CREATE',
            collection: 'invoices',
            data: invoiceModel.toJson(),
          );
        }
      } else {
        // Add to sync queue for offline creation
        await _syncService.addToSyncQueue(
          action: 'CREATE',
          collection: 'invoices',
          data: invoiceModel.toJson(),
        );
      }

      return Right(invoiceModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to create invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> updateInvoice(
    String invoiceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final currentInvoice = await _localDatasource.getInvoiceById(invoiceId);
      if (currentInvoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      // Parse items if provided
      List<InvoiceItemModel>? items;
      if (updates['items'] != null) {
        items = (updates['items'] as List)
            .map((item) => InvoiceItemModel.fromJson(item))
            .toList();
      }

      // Recalculate totals if items, tax, or discount changed
      double? subtotal, taxAmount, discountAmount, total;
      if (items != null ||
          updates['tax'] != null ||
          updates['discount'] != null) {
        final invoiceItems = items ?? currentInvoice.items;
        subtotal = invoiceItems.fold<double>(
          0,
          (sum, item) => sum + item.total,
        );
        final discount = updates['discount'] ?? currentInvoice.discount;
        final tax = updates['tax'] ?? currentInvoice.tax;
        discountAmount = discount;
        taxAmount = (subtotal - discountAmount) * (tax / 100);
        total = subtotal - discountAmount + taxAmount;
      }

      // Apply updates
      final updatedModel = currentInvoice.copyWith(
        clientId: updates['clientId'] ?? currentInvoice.clientId,
        invoiceNumber: updates['invoiceNumber'] ?? currentInvoice.invoiceNumber,
        issueDate: updates['issueDate'] ?? currentInvoice.issueDate,
        dueDate: updates['dueDate'] ?? currentInvoice.dueDate,
        items: items ?? currentInvoice.items,
        subtotal: subtotal ?? currentInvoice.subtotal,
        tax: updates['tax'] ?? currentInvoice.tax,
        taxAmount: taxAmount ?? currentInvoice.taxAmount,
        discount: updates['discount'] ?? currentInvoice.discount,
        discountAmount: discountAmount ?? currentInvoice.discountAmount,
        total: total ?? currentInvoice.total,
        notes: updates['notes'] ?? currentInvoice.notes,
        terms: updates['terms'] ?? currentInvoice.terms,
        status: updates['status'] != null
            ? InvoiceStatus.values.firstWhere(
                (e) => e.name == updates['status'],
              )
            : currentInvoice.status,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      // Update locally
      await _localDatasource.updateInvoice(updatedModel);

      // Check connectivity and sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.updateInvoice(updatedModel);

          // Mark as synced
          final syncedModel = updatedModel.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.updateInvoice(syncedModel);

          return Right(syncedModel.toEntity());
        } catch (e) {
          // Add to sync queue if remote update fails
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'invoices',
            documentId: invoiceId,
            data: updatedModel.toJson(),
          );
        }
      } else {
        // Add to sync queue for offline updates
        await _syncService.addToSyncQueue(
          action: 'UPDATE',
          collection: 'invoices',
          documentId: invoiceId,
          data: updatedModel.toJson(),
        );
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to update invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String invoiceId) async {
    try {
      // Get invoice to access PDF file
      final invoice = await _localDatasource.getInvoiceById(invoiceId);
      if (invoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      // Delete PDF file if exists
      if (invoice.pdfUrl.isNotEmpty) {
        try {
          final file = File(invoice.pdfUrl);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Log error but continue with deletion
          print('Failed to delete PDF file: $e');
        }
      }

      // Delete from local database
      await _localDatasource.deleteInvoice(invoiceId);

      // Check connectivity and delete from remote if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.deleteInvoice(invoiceId);
        } catch (e) {
          // Add to sync queue if remote delete fails
          await _syncService.addToSyncQueue(
            action: 'DELETE',
            collection: 'invoices',
            documentId: invoiceId,
            data: {'id': invoiceId},
          );
        }
      } else {
        // Add to sync queue for offline deletes
        await _syncService.addToSyncQueue(
          action: 'DELETE',
          collection: 'invoices',
          documentId: invoiceId,
          data: {'id': invoiceId},
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity?>> getInvoiceById(
    String invoiceId,
  ) async {
    try {
      // Try local first
      final localInvoice = await _localDatasource.getInvoiceById(invoiceId);
      if (localInvoice != null) {
        return Right(localInvoice.toEntity());
      }

      // Try remote if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteInvoice = await _remoteDatasource.getInvoiceById(invoiceId);
        if (remoteInvoice != null) {
          // Cache locally
          await _localDatasource.insertInvoice(remoteInvoice);
          return Right(remoteInvoice.toEntity());
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({
    required String userId,
    int? limit,
    String? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
    InvoiceStatus? status,
    String? searchQuery,
  }) async {
    try {
      // Get from local database
      final localInvoices = await _localDatasource.getInvoices(
        userId: userId,
        limit: limit,
        startAfter: startAfter,
        startDate: startDate,
        endDate: endDate,
        clientId: clientId,
        status: status,
        searchQuery: searchQuery,
      );

      // Convert to entities
      final localEntities = localInvoices
          .map((model) => model.toEntity())
          .toList();

      // Try to fetch updates from remote if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          final remoteInvoices = await _remoteDatasource.getInvoices(
            userId: userId,
            limit: limit,
            startAfter: startAfter,
            startDate: startDate,
            endDate: endDate,
            clientId: clientId,
            status: status,
            searchQuery: searchQuery,
          );

          // Merge remote data with local
          final mergedInvoices = await _mergeInvoiceData(
            localInvoices,
            remoteInvoices,
          );
          final mergedEntities = mergedInvoices
              .map((model) => model.toEntity())
              .toList();

          return Right(mergedEntities);
        } catch (e) {
          // Return local data if remote fetch fails
          return Right(localEntities);
        }
      }

      return Right(localEntities);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, File>> generateInvoicePDF({
    required String invoiceId,
    String? templateName,
  }) async {
    try {
      final invoice = await _localDatasource.getInvoiceById(invoiceId);
      if (invoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      // Generate PDF
      final pdfFile = await _pdfGenerator.generateInvoicePDF(
        invoice: invoice,
        templateName: templateName,
      );

      // Update invoice with PDF URL
      final updatedInvoice = invoice.copyWith(
        pdfUrl: pdfFile.path,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateInvoice(updatedInvoice);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'invoices',
        documentId: invoiceId,
        data: updatedInvoice.toJson(),
      );

      return Right(pdfFile);
    } catch (e) {
      return Left(ProcessingFailure('Failed to generate PDF: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendInvoice({
    required String invoiceId,
    required String recipientEmail,
    String? subject,
    String? message,
  }) async {
    try {
      final invoice = await _localDatasource.getInvoiceById(invoiceId);
      if (invoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      // Generate PDF if not exists
      File? pdfFile;
      if (invoice.pdfUrl.isEmpty) {
        final pdfResult = await generateInvoicePDF(invoiceId: invoiceId);
        pdfResult.fold(
          (failure) => throw Exception('Failed to generate PDF'),
          (file) => pdfFile = file,
        );
      } else {
        pdfFile = File(invoice.pdfUrl);
      }

      if (pdfFile == null || !await pdfFile.exists()) {
        return Left(ProcessingFailure('PDF file not found'));
      }

      // Send email via remote service
      await _remoteDatasource.sendInvoiceEmail(
        invoiceId: invoiceId,
        recipientEmail: recipientEmail,
        subject: subject ?? 'Invoice ${invoice.invoiceNumber}',
        message:
            message ?? 'Please find attached invoice ${invoice.invoiceNumber}.',
        pdfFile: pdfFile,
      );

      // Update invoice status
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.sent,
        sentAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateInvoice(updatedInvoice);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'invoices',
        documentId: invoiceId,
        data: updatedInvoice.toJson(),
      );

      // Schedule reminder notifications
      await _schedulePaymentReminders(updatedInvoice);

      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure('Failed to send invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsPaid({
    required String invoiceId,
    DateTime? paidDate,
  }) async {
    try {
      final invoice = await _localDatasource.getInvoiceById(invoiceId);
      if (invoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.paid,
        paidAt: paidDate ?? DateTime.now(),
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateInvoice(updatedInvoice);

      // Cancel any scheduled reminders
      await _notificationService.cancelInvoiceReminders(invoiceId);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'invoices',
        documentId: invoiceId,
        data: updatedInvoice.toJson(),
      );

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to mark invoice as paid: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> sendPaymentReminder(String invoiceId) async {
    try {
      final invoice = await _localDatasource.getInvoiceById(invoiceId);
      if (invoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      if (invoice.status == InvoiceStatus.paid) {
        return Left(BusinessLogicFailure('Invoice is already paid'));
      }

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      // Send reminder via remote service
      await _remoteDatasource.sendPaymentReminder(invoiceId);

      // Update reminder count
      final updatedInvoice = invoice.copyWith(
        remindersSent: invoice.remindersSent + 1,
        lastReminderAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateInvoice(updatedInvoice);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'invoices',
        documentId: invoiceId,
        data: updatedInvoice.toJson(),
      );

      return const Right(null);
    } catch (e) {
      return Left(
        NetworkFailure('Failed to send payment reminder: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getInvoiceStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statistics = await _localDatasource.getInvoiceStatistics(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(statistics);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get invoice statistics: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getOverdueInvoices({
    required String userId,
  }) async {
    try {
      final overdueInvoices = await _localDatasource.getOverdueInvoices(userId);
      final entities = overdueInvoices
          .map((model) => model.toEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get overdue invoices: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getDraftInvoices({
    required String userId,
  }) async {
    try {
      final draftInvoices = await _localDatasource.getDraftInvoices(userId);
      final entities = draftInvoices.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get draft invoices: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getUnpaidInvoices({
    required String userId,
    DateTime? beforeDate,
  }) async {
    try {
      final unpaidInvoices = await _localDatasource.getUnpaidInvoices(
        userId,
        beforeDate: beforeDate,
      );
      final entities = unpaidInvoices.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get unpaid invoices: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> duplicateInvoice({
    required String invoiceId,
    String? newInvoiceNumber,
    DateTime? newIssueDate,
    DateTime? newDueDate,
  }) async {
    try {
      final originalInvoice = await _localDatasource.getInvoiceById(invoiceId);
      if (originalInvoice == null) {
        return Left(DatabaseFailure('Original invoice not found'));
      }

      final newId = _generateInvoiceId();
      final issueDate = newIssueDate ?? DateTime.now();
      final dueDate = newDueDate ?? issueDate.add(const Duration(days: 30));

      final duplicatedInvoice = originalInvoice.copyWith(
        id: newId,
        invoiceNumber: newInvoiceNumber ?? _generateInvoiceNumber(),
        issueDate: issueDate,
        dueDate: dueDate,
        status: InvoiceStatus.draft,
        pdfUrl: '',
        sentAt: null,
        paidAt: null,
        remindersSent: 0,
        lastReminderAt: null,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally
      await _localDatasource.insertInvoice(duplicatedInvoice);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'CREATE',
        collection: 'invoices',
        data: duplicatedInvoice.toJson(),
      );

      return Right(duplicatedInvoice.toEntity());
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to duplicate invoice: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncInvoices(String userId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      // Get unsynced invoices
      final unsyncedInvoices = await _localDatasource.getUnsyncedInvoices(
        userId,
      );

      for (final invoice in unsyncedInvoices) {
        try {
          if (invoice.syncStatus == SyncStatus.pending) {
            // Save to remote
            await _remoteDatasource.createInvoice(invoice);

            // Update local as synced
            final syncedInvoice = invoice.copyWith(
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now(),
            );
            await _localDatasource.updateInvoice(syncedInvoice);
          }
        } catch (e) {
          // Log error but continue with other invoices
          print('Failed to sync invoice ${invoice.id}: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to sync invoices: ${e.toString()}'));
    }
  }

  @override
  Stream<List<InvoiceEntity>> watchInvoices({
    required String userId,
    String? clientId,
    InvoiceStatus? status,
  }) {
    return _localDatasource
        .watchInvoices(userId: userId, clientId: clientId, status: status)
        .map((invoices) => invoices.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Either<Failure, String>> getNextInvoiceNumber(String userId) async {
    try {
      final nextNumber = await _localDatasource.getNextInvoiceNumber(userId);
      return Right(nextNumber);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get next invoice number: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> searchInvoices({
    required String userId,
    required String query,
    InvoiceStatus? status,
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final invoices = await _localDatasource.searchInvoices(
        userId: userId,
        query: query,
        status: status,
        clientId: clientId,
        startDate: startDate,
        endDate: endDate,
      );

      final entities = invoices.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to search invoices: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> bulkUpdateInvoiceStatus({
    required List<String> invoiceIds,
    required InvoiceStatus newStatus,
    DateTime? paidDate,
  }) async {
    try {
      for (final invoiceId in invoiceIds) {
        final invoice = await _localDatasource.getInvoiceById(invoiceId);
        if (invoice != null) {
          final updatedInvoice = invoice.copyWith(
            status: newStatus,
            paidAt: newStatus == InvoiceStatus.paid
                ? (paidDate ?? DateTime.now())
                : null,
            syncStatus: SyncStatus.pending,
            updatedAt: DateTime.now(),
          );

          await _localDatasource.updateInvoice(updatedInvoice);

          // Cancel reminders if marked as paid
          if (newStatus == InvoiceStatus.paid) {
            await _notificationService.cancelInvoiceReminders(invoiceId);
          }

          // Add to sync queue
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'invoices',
            documentId: invoiceId,
            data: updatedInvoice.toJson(),
          );
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure(
          'Failed to bulk update invoice status: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> scheduleAutomaticReminders({
    required String invoiceId,
    List<int> reminderDays = const [7, 3, 1], // Days before due date
  }) async {
    try {
      final invoice = await _localDatasource.getInvoiceById(invoiceId);
      if (invoice == null) {
        return Left(DatabaseFailure('Invoice not found'));
      }

      await _schedulePaymentReminders(invoice, reminderDays: reminderDays);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to schedule reminders: ${e.toString()}'),
      );
    }
  }

  // Private helper methods
  String _generateInvoiceId() {
    return 'invoice_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'INV-$year$month-$timestamp';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[random % chars.length],
    ).join();
  }

  Future<List<InvoiceModel>> _mergeInvoiceData(
    List<InvoiceModel> localInvoices,
    List<InvoiceModel> remoteInvoices,
  ) async {
    final Map<String, InvoiceModel> merged = {};

    // Add local invoices
    for (final invoice in localInvoices) {
      merged[invoice.id] = invoice;
    }

    // Merge remote invoices
    for (final remoteInvoice in remoteInvoices) {
      final localInvoice = merged[remoteInvoice.id];

      if (localInvoice == null) {
        // New remote invoice - cache it locally
        merged[remoteInvoice.id] = remoteInvoice;
        await _localDatasource.insertInvoice(remoteInvoice);
      } else {
        // Check which is newer
        if (remoteInvoice.updatedAt.isAfter(localInvoice.updatedAt)) {
          // Remote is newer - update local
          merged[remoteInvoice.id] = remoteInvoice;
          await _localDatasource.updateInvoice(remoteInvoice);
        } else if (localInvoice.updatedAt.isAfter(remoteInvoice.updatedAt) &&
            localInvoice.syncStatus == SyncStatus.pending) {
          // Local is newer and unsynced - add to sync queue
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'invoices',
            documentId: localInvoice.id,
            data: localInvoice.toJson(),
          );
        }
      }
    }

    return merged.values.toList();
  }

  Future<void> _schedulePaymentReminders(
    InvoiceModel invoice, {
    List<int> reminderDays = const [7, 3, 1],
  }) async {
    if (invoice.status == InvoiceStatus.paid) return;

    for (final days in reminderDays) {
      final reminderDate = invoice.dueDate.subtract(Duration(days: days));

      // Only schedule if reminder date is in the future
      if (reminderDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleInvoiceReminder(
          invoiceId: invoice.id,
          reminderDate: reminderDate,
          invoiceNumber: invoice.invoiceNumber,
          clientId: invoice.clientId,
          amount: invoice.total,
          daysUntilDue: days,
        );
      }
    }
  }
}
