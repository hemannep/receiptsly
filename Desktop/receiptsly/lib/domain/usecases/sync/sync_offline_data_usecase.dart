import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../repositories/i_receipt_repository.dart';
import '../../repositories/i_invoice_repository.dart';
import '../../repositories/i_sync_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/local/local_storage_service.dart';

class SyncOfflineDataUseCase {
  final ISyncRepository _syncRepository;
  final IReceiptRepository _receiptRepository;
  final IInvoiceRepository _invoiceRepository;
  final SyncService _syncService;
  final LocalStorageService _localStorageService;
  final Connectivity _connectivity;

  SyncOfflineDataUseCase(
    this._syncRepository,
    this._receiptRepository,
    this._invoiceRepository,
    this._syncService,
    this._localStorageService,
    this._connectivity,
  );

  Future<Either<Failure, CompleteSyncResult>> call(
    SyncOfflineDataParams params,
  ) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none &&
          !params.allowPartialSync) {
        return Left(
          NetworkFailure('Device is offline and partial sync is not allowed'),
        );
      }

      final isOnline = connectivityResult != ConnectivityResult.none;

      // Initialize sync result
      final syncResult = CompleteSyncResult(
        startTime: DateTime.now(),
        isOnline: isOnline,
      );

      // Phase 1: Prepare local data for sync
      await _prepareLocalDataForSync(params.userId, syncResult);

      // Phase 2: Upload local changes (if online)
      if (isOnline) {
        await _uploadLocalChanges(params.userId, syncResult);
      }

      // Phase 3: Download remote changes (if online)
      if (isOnline) {
        await _downloadRemoteChanges(params.userId, syncResult);
      }

      // Phase 4: Process offline queue
      await _processOfflineQueue(params.userId, syncResult);

      // Phase 5: Update sync metadata
      await _updateSyncMetadata(params.userId, syncResult);

      // Complete sync
      syncResult.endTime = DateTime.now();
      syncResult.duration = syncResult.endTime!.difference(
        syncResult.startTime,
      );
      syncResult.success = _evaluateSyncSuccess(syncResult);

      return Right(syncResult);
    } catch (e) {
      return Left(SyncFailure('Offline data sync failed: ${e.toString()}'));
    }
  }

  Future<void> _prepareLocalDataForSync(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Get pending sync items count
      final pendingReceipts = await _receiptRepository.getPendingSyncCount(
        userId,
      );
      final pendingInvoices = await _invoiceRepository.getPendingSyncCount(
        userId,
      );

      pendingReceipts.fold(
        (failure) => result.errors.add(
          'Failed to count pending receipts: ${failure.message}',
        ),
        (count) => result.pendingReceiptsCount = count,
      );

      pendingInvoices.fold(
        (failure) => result.errors.add(
          'Failed to count pending invoices: ${failure.message}',
        ),
        (count) => result.pendingInvoicesCount = count,
      );

      // Validate local data integrity
      await _validateLocalDataIntegrity(userId, result);

      // Clean up corrupted entries
      await _cleanupCorruptedEntries(userId, result);
    } catch (e) {
      result.errors.add('Data preparation failed: ${e.toString()}');
    }
  }

  Future<void> _uploadLocalChanges(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Upload receipts
      final receiptUploadResult = await _uploadPendingReceipts(userId);
      receiptUploadResult.fold(
        (failure) =>
            result.errors.add('Receipt upload failed: ${failure.message}'),
        (count) => result.uploadedReceiptsCount = count,
      );

      // Upload invoices
      final invoiceUploadResult = await _uploadPendingInvoices(userId);
      invoiceUploadResult.fold(
        (failure) =>
            result.errors.add('Invoice upload failed: ${failure.message}'),
        (count) => result.uploadedInvoicesCount = count,
      );

      // Upload images
      final imageUploadResult = await _uploadPendingImages(userId);
      imageUploadResult.fold(
        (failure) =>
            result.errors.add('Image upload failed: ${failure.message}'),
        (count) => result.uploadedImagesCount = count,
      );
    } catch (e) {
      result.errors.add('Upload phase failed: ${e.toString()}');
    }
  }

  Future<void> _downloadRemoteChanges(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Get last sync timestamp
      final lastSyncTime = await _localStorageService.getLastSyncTime();

      // Download receipt changes
      final receiptDownloadResult = await _downloadReceiptChanges(
        userId,
        lastSyncTime,
      );
      receiptDownloadResult.fold(
        (failure) =>
            result.errors.add('Receipt download failed: ${failure.message}'),
        (count) => result.downloadedReceiptsCount = count,
      );

      // Download invoice changes
      final invoiceDownloadResult = await _downloadInvoiceChanges(
        userId,
        lastSyncTime,
      );
      invoiceDownloadResult.fold(
        (failure) =>
            result.errors.add('Invoice download failed: ${failure.message}'),
        (count) => result.downloadedInvoicesCount = count,
      );

      // Download user profile changes
      await _downloadUserProfileChanges(userId, result);
    } catch (e) {
      result.errors.add('Download phase failed: ${e.toString()}');
    }
  }

  Future<void> _processOfflineQueue(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Get offline queue items
      final queueResult = await _syncRepository.getOfflineQueue(userId);

      await queueResult.fold(
        (failure) async => result.errors.add(
          'Failed to get offline queue: ${failure.message}',
        ),
        (queueItems) async {
          result.queuedItemsCount = queueItems.length;

          for (final item in queueItems) {
            try {
              await _processQueueItem(item, result);
            } catch (e) {
              result.errors.add(
                'Failed to process queue item ${item.id}: ${e.toString()}',
              );
            }
          }
        },
      );
    } catch (e) {
      result.errors.add('Queue processing failed: ${e.toString()}');
    }
  }

  Future<void> _processQueueItem(
    SyncQueueItem item,
    CompleteSyncResult result,
  ) async {
    switch (item.operation) {
      case SyncOperation.create:
        await _processCreateOperation(item, result);
        break;
      case SyncOperation.update:
        await _processUpdateOperation(item, result);
        break;
      case SyncOperation.delete:
        await _processDeleteOperation(item, result);
        break;
      case SyncOperation.upload:
        await _processUploadOperation(item, result);
        break;
    }
  }

  Future<void> _processCreateOperation(
    SyncQueueItem item,
    CompleteSyncResult result,
  ) async {
    try {
      switch (item.entityType) {
        case 'receipt':
          final createResult = await _receiptRepository.createRemote(item.data);
          createResult.fold((failure) => throw Exception(failure.message), (
            receipt,
          ) async {
            await _syncRepository.markQueueItemCompleted(item.id);
            result.processedQueueItems++;
          });
          break;
        case 'invoice':
          final createResult = await _invoiceRepository.createRemote(item.data);
          createResult.fold((failure) => throw Exception(failure.message), (
            invoice,
          ) async {
            await _syncRepository.markQueueItemCompleted(item.id);
            result.processedQueueItems++;
          });
          break;
      }
    } catch (e) {
      await _syncRepository.markQueueItemFailed(item.id, e.toString());
      result.failedQueueItems++;
    }
  }

  Future<void> _processUpdateOperation(
    SyncQueueItem item,
    CompleteSyncResult result,
  ) async {
    try {
      switch (item.entityType) {
        case 'receipt':
          final updateResult = await _receiptRepository.updateRemote(
            item.entityId,
            item.data,
          );
          updateResult.fold((failure) => throw Exception(failure.message), (
            receipt,
          ) async {
            await _syncRepository.markQueueItemCompleted(item.id);
            result.processedQueueItems++;
          });
          break;
        case 'invoice':
          final updateResult = await _invoiceRepository.updateRemote(
            item.entityId,
            item.data,
          );
          updateResult.fold((failure) => throw Exception(failure.message), (
            invoice,
          ) async {
            await _syncRepository.markQueueItemCompleted(item.id);
            result.processedQueueItems++;
          });
          break;
      }
    } catch (e) {
      await _syncRepository.markQueueItemFailed(item.id, e.toString());
      result.failedQueueItems++;
    }
  }

  Future<void> _processDeleteOperation(
    SyncQueueItem item,
    CompleteSyncResult result,
  ) async {
    try {
      switch (item.entityType) {
        case 'receipt':
          final deleteResult = await _receiptRepository.deleteRemote(
            item.entityId,
          );
          deleteResult.fold((failure) => throw Exception(failure.message), (
            _,
          ) async {
            await _syncRepository.markQueueItemCompleted(item.id);
            result.processedQueueItems++;
          });
          break;
        case 'invoice':
          final deleteResult = await _invoiceRepository.deleteRemote(
            item.entityId,
          );
          deleteResult.fold((failure) => throw Exception(failure.message), (
            _,
          ) async {
            await _syncRepository.markQueueItemCompleted(item.id);
            result.processedQueueItems++;
          });
          break;
      }
    } catch (e) {
      await _syncRepository.markQueueItemFailed(item.id, e.toString());
      result.failedQueueItems++;
    }
  }

  Future<void> _processUploadOperation(
    SyncQueueItem item,
    CompleteSyncResult result,
  ) async {
    try {
      if (item.entityType == 'image') {
        final uploadResult = await _receiptRepository.uploadImageFile(
          item.entityId,
          item.filePath!,
        );
        uploadResult.fold((failure) => throw Exception(failure.message), (
          imageUrl,
        ) async {
          await _syncRepository.markQueueItemCompleted(item.id);
          result.processedQueueItems++;
        });
      }
    } catch (e) {
      await _syncRepository.markQueueItemFailed(item.id, e.toString());
      result.failedQueueItems++;
    }
  }

  Future<Either<Failure, int>> _uploadPendingReceipts(String userId) async {
    try {
      final pendingResult = await _receiptRepository.getPendingSyncReceipts(
        userId,
      );

      return pendingResult.fold((failure) => Left(failure), (receipts) async {
        int uploadedCount = 0;

        for (final receipt in receipts) {
          final uploadResult = await _receiptRepository.uploadToRemote(receipt);
          uploadResult.fold(
            (failure) => print(
              'Failed to upload receipt ${receipt.id}: ${failure.message}',
            ),
            (uploadedReceipt) {
              uploadedCount++;
            },
          );
        }

        return Right(uploadedCount);
      });
    } catch (e) {
      return Left(SyncFailure('Receipt upload failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, int>> _uploadPendingInvoices(String userId) async {
    try {
      final pendingResult = await _invoiceRepository.getPendingSyncInvoices(
        userId,
      );

      return pendingResult.fold((failure) => Left(failure), (invoices) async {
        int uploadedCount = 0;

        for (final invoice in invoices) {
          final uploadResult = await _invoiceRepository.uploadToRemote(invoice);
          uploadResult.fold(
            (failure) => print(
              'Failed to upload invoice ${invoice.id}: ${failure.message}',
            ),
            (uploadedInvoice) {
              uploadedCount++;
            },
          );
        }

        return Right(uploadedCount);
      });
    } catch (e) {
      return Left(SyncFailure('Invoice upload failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, int>> _uploadPendingImages(String userId) async {
    try {
      final pendingResult = await _receiptRepository.getPendingImageUploads(
        userId,
      );

      return pendingResult.fold((failure) => Left(failure), (
        imageUploads,
      ) async {
        int uploadedCount = 0;

        for (final upload in imageUploads) {
          final uploadResult = await _receiptRepository.uploadImageFile(
            upload.receiptId,
            upload.localPath,
          );
          uploadResult.fold(
            (failure) => print(
              'Failed to upload image ${upload.receiptId}: ${failure.message}',
            ),
            (imageUrl) {
              uploadedCount++;
            },
          );
        }

        return Right(uploadedCount);
      });
    } catch (e) {
      return Left(SyncFailure('Image upload failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, int>> _downloadReceiptChanges(
    String userId,
    DateTime? lastSyncTime,
  ) async {
    try {
      final changesResult = await _receiptRepository.getRemoteChanges(
        userId: userId,
        since: lastSyncTime,
        limit: 100,
      );

      return changesResult.fold((failure) => Left(failure), (
        remoteReceipts,
      ) async {
        int downloadedCount = 0;

        for (final remoteReceipt in remoteReceipts) {
          try {
            // Check if receipt exists locally
            final localResult = await _receiptRepository.getById(
              remoteReceipt.id,
            );

            await localResult.fold(
              (failure) async {
                // New receipt, save locally
                await _receiptRepository.saveToLocal(remoteReceipt);
                downloadedCount++;
              },
              (localReceipt) async {
                // Existing receipt, handle potential conflict
                if (remoteReceipt.updatedAt.isAfter(localReceipt.updatedAt)) {
                  if (localReceipt.syncStatus == SyncStatus.modified) {
                    // Conflict detected
                    await _syncRepository.createConflict(
                      localReceipt,
                      remoteReceipt,
                    );
                  } else {
                    // Safe to update
                    await _receiptRepository.update(remoteReceipt);
                    downloadedCount++;
                  }
                }
              },
            );
          } catch (e) {
            print('Failed to process remote receipt ${remoteReceipt.id}: $e');
          }
        }

        return Right(downloadedCount);
      });
    } catch (e) {
      return Left(SyncFailure('Receipt download failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, int>> _downloadInvoiceChanges(
    String userId,
    DateTime? lastSyncTime,
  ) async {
    try {
      final changesResult = await _invoiceRepository.getRemoteChanges(
        userId: userId,
        since: lastSyncTime,
        limit: 100,
      );

      return changesResult.fold((failure) => Left(failure), (
        remoteInvoices,
      ) async {
        int downloadedCount = 0;

        for (final remoteInvoice in remoteInvoices) {
          try {
            final localResult = await _invoiceRepository.getById(
              remoteInvoice.id,
            );

            await localResult.fold(
              (failure) async {
                await _invoiceRepository.saveToLocal(remoteInvoice);
                downloadedCount++;
              },
              (localInvoice) async {
                if (remoteInvoice.updatedAt.isAfter(localInvoice.updatedAt)) {
                  if (localInvoice.syncStatus == SyncStatus.modified) {
                    await _syncRepository.createConflict(
                      localInvoice,
                      remoteInvoice,
                    );
                  } else {
                    await _invoiceRepository.update(remoteInvoice);
                    downloadedCount++;
                  }
                }
              },
            );
          } catch (e) {
            print('Failed to process remote invoice ${remoteInvoice.id}: $e');
          }
        }

        return Right(downloadedCount);
      });
    } catch (e) {
      return Left(SyncFailure('Invoice download failed: ${e.toString()}'));
    }
  }

  Future<void> _downloadUserProfileChanges(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Implementation for downloading user profile changes
      // This would sync user preferences, subscription status, etc.
    } catch (e) {
      result.errors.add('User profile sync failed: ${e.toString()}');
    }
  }

  Future<void> _validateLocalDataIntegrity(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Validate receipt data integrity
      final receiptValidation = await _receiptRepository.validateDataIntegrity(
        userId,
      );
      receiptValidation.fold(
        (failure) => result.errors.add(
          'Receipt data validation failed: ${failure.message}',
        ),
        (issues) => result.dataIntegrityIssues.addAll(issues),
      );

      // Validate invoice data integrity
      final invoiceValidation = await _invoiceRepository.validateDataIntegrity(
        userId,
      );
      invoiceValidation.fold(
        (failure) => result.errors.add(
          'Invoice data validation failed: ${failure.message}',
        ),
        (issues) => result.dataIntegrityIssues.addAll(issues),
      );
    } catch (e) {
      result.errors.add('Data integrity validation failed: ${e.toString()}');
    }
  }

  Future<void> _cleanupCorruptedEntries(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Clean up corrupted receipts
      final receiptCleanup = await _receiptRepository.cleanupCorruptedEntries(
        userId,
      );
      receiptCleanup.fold(
        (failure) =>
            result.errors.add('Receipt cleanup failed: ${failure.message}'),
        (cleanedCount) => result.cleanedCorruptedEntries += cleanedCount,
      );

      // Clean up corrupted invoices
      final invoiceCleanup = await _invoiceRepository.cleanupCorruptedEntries(
        userId,
      );
      invoiceCleanup.fold(
        (failure) =>
            result.errors.add('Invoice cleanup failed: ${failure.message}'),
        (cleanedCount) => result.cleanedCorruptedEntries += cleanedCount,
      );
    } catch (e) {
      result.errors.add('Corrupted entry cleanup failed: ${e.toString()}');
    }
  }

  Future<void> _updateSyncMetadata(
    String userId,
    CompleteSyncResult result,
  ) async {
    try {
      // Update last sync time
      await _localStorageService.setLastSyncTime(DateTime.now());

      // Update sync statistics
      await _syncRepository.updateSyncStatistics(
        SyncStatistics(
          userId: userId,
          lastSyncTime: DateTime.now(),
          totalSyncs: result.totalSyncs + 1,
          successfulSyncs: result.successfulSyncs + (result.success ? 1 : 0),
          totalItemsSynced: result.totalItemsSynced,
          lastSyncDuration: result.duration,
        ),
      );
    } catch (e) {
      result.errors.add('Sync metadata update failed: ${e.toString()}');
    }
  }

  bool _evaluateSyncSuccess(CompleteSyncResult result) {
    // Consider sync successful if:
    // 1. No critical errors occurred
    // 2. At least 80% of operations succeeded
    // 3. All high-priority items were processed

    final totalOperations =
        result.pendingReceiptsCount +
        result.pendingInvoicesCount +
        result.queuedItemsCount;

    if (totalOperations == 0) {
      return result.errors.isEmpty; // Nothing to sync
    }

    final successfulOperations =
        result.uploadedReceiptsCount +
        result.uploadedInvoicesCount +
        result.downloadedReceiptsCount +
        result.downloadedInvoicesCount +
        result.processedQueueItems;

    final successRate = successfulOperations / totalOperations;

    return successRate >= 0.8 && result.errors.length < 5;
  }
}

class SyncOfflineDataParams {
  final String userId;
  final bool allowPartialSync;
  final bool forceFullSync;
  final int maxRetries;
  final Duration timeout;

  SyncOfflineDataParams({
    required this.userId,
    this.allowPartialSync = true,
    this.forceFullSync = false,
    this.maxRetries = 3,
    this.timeout = const Duration(minutes: 10),
  });
}

class CompleteSyncResult {
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  final bool isOnline;
  bool success = false;

  // Counts
  int pendingReceiptsCount = 0;
  int pendingInvoicesCount = 0;
  int uploadedReceiptsCount = 0;
  int uploadedInvoicesCount = 0;
  int uploadedImagesCount = 0;
  int downloadedReceiptsCount = 0;
  int downloadedInvoicesCount = 0;
  int queuedItemsCount = 0;
  int processedQueueItems = 0;
  int failedQueueItems = 0;
  int cleanedCorruptedEntries = 0;

  // Sync history
  int totalSyncs = 0;
  int successfulSyncs = 0;
  int totalItemsSynced = 0;

  // Issues
  List<String> errors = [];
  List<String> dataIntegrityIssues = [];

  CompleteSyncResult({required this.startTime, required this.isOnline});

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'isOnline': isOnline,
      'success': success,
      'pendingReceiptsCount': pendingReceiptsCount,
      'pendingInvoicesCount': pendingInvoicesCount,
      'uploadedReceiptsCount': uploadedReceiptsCount,
      'uploadedInvoicesCount': uploadedInvoicesCount,
      'uploadedImagesCount': uploadedImagesCount,
      'downloadedReceiptsCount': downloadedReceiptsCount,
      'downloadedInvoicesCount': downloadedInvoicesCount,
      'queuedItemsCount': queuedItemsCount,
      'processedQueueItems': processedQueueItems,
      'failedQueueItems': failedQueueItems,
      'cleanedCorruptedEntries': cleanedCorruptedEntries,
      'errors': errors,
      'dataIntegrityIssues': dataIntegrityIssues,
    };
  }
}

enum SyncOperation { create, update, delete, upload }

enum SyncStatus { synced, modified, deleted, pending, failed }

class SyncQueueItem {
  final String id;
  final String userId;
  final SyncOperation operation;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
  final String? filePath;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncQueueItem({
    required this.id,
    required this.userId,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.data,
    this.filePath,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });
}

class SyncStatistics {
  final String userId;
  final DateTime lastSyncTime;
  final int totalSyncs;
  final int successfulSyncs;
  final int totalItemsSynced;
  final Duration? lastSyncDuration;

  SyncStatistics({
    required this.userId,
    required this.lastSyncTime,
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.totalItemsSynced,
    this.lastSyncDuration,
  });
}
