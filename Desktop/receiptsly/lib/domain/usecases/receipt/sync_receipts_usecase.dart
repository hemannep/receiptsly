import 'package:dartz/dartz.dart';
import '../../entities/receipt_entity.dart';
import '../../repositories/i_receipt_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/local/local_storage_service.dart';

class SyncReceiptsUseCase {
  final IReceiptRepository _receiptRepository;
  final SyncService _syncService;
  final LocalStorageService _localStorageService;

  SyncReceiptsUseCase(
    this._receiptRepository,
    this._syncService,
    this._localStorageService,
  );

  Future<Either<Failure, SyncResult>> call(SyncReceiptsParams params) async {
    try {
      // Check if online
      final isOnline = await _syncService.isOnline();
      if (!isOnline && !params.allowOfflineSync) {
        return Left(NetworkFailure('Device is offline'));
      }

      // Start sync process
      final syncResult = await _performSync(params);

      return syncResult.fold(
        (failure) => Left(failure),
        (result) => Right(result),
      );
    } catch (e) {
      return Left(SyncFailure('Sync failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, SyncResult>> _performSync(
    SyncReceiptsParams params,
  ) async {
    final syncResult = SyncResult();

    try {
      // Phase 1: Upload pending receipts
      if (params.syncDirection == SyncDirection.upload ||
          params.syncDirection == SyncDirection.bidirectional) {
        final uploadResult = await _uploadPendingReceipts(params.userId);
        uploadResult.fold(
          (failure) => syncResult.uploadFailures.add(failure.message),
          (uploaded) => syncResult.uploadedCount = uploaded,
        );
      }

      // Phase 2: Download remote changes
      if (params.syncDirection == SyncDirection.download ||
          params.syncDirection == SyncDirection.bidirectional) {
        final downloadResult = await _downloadRemoteChanges(params);
        downloadResult.fold(
          (failure) => syncResult.downloadFailures.add(failure.message),
          (downloaded) => syncResult.downloadedCount = downloaded,
        );
      }

      // Phase 3: Resolve conflicts
      if (params.resolveConflicts) {
        final conflictResult = await _resolveConflicts(params.userId);
        conflictResult.fold(
          (failure) => syncResult.conflictFailures.add(failure.message),
          (resolved) => syncResult.resolvedConflicts = resolved,
        );
      }

      // Phase 4: Clean up orphaned data
      if (params.cleanupOrphaned) {
        await _cleanupOrphanedData(params.userId);
      }

      // Update sync timestamp
      await _localStorageService.setLastSyncTime(DateTime.now());

      syncResult.success =
          syncResult.uploadFailures.isEmpty &&
          syncResult.downloadFailures.isEmpty &&
          syncResult.conflictFailures.isEmpty;

      return Right(syncResult);
    } catch (e) {
      return Left(SyncFailure('Sync process error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, int>> _uploadPendingReceipts(String userId) async {
    try {
      // Get pending receipts from local database
      final pendingResult = await _receiptRepository.getPendingSync(userId);

      return pendingResult.fold((failure) => Left(failure), (
        pendingReceipts,
      ) async {
        int uploadedCount = 0;

        for (final receipt in pendingReceipts) {
          try {
            // Upload image first if needed
            if (receipt.imageLocalPath != null && receipt.imageUrl == null) {
              final uploadImageResult = await _receiptRepository.uploadImage(
                receipt.id,
              );
              uploadImageResult.fold(
                (failure) =>
                    throw Exception('Image upload failed: ${failure.message}'),
                (imageUrl) => receipt.copyWith(imageUrl: imageUrl),
              );
            }

            // Upload receipt data
            final uploadResult = await _receiptRepository.uploadToRemote(
              receipt,
            );
            uploadResult.fold(
              (failure) =>
                  throw Exception('Receipt upload failed: ${failure.message}'),
              (uploadedReceipt) async {
                // Mark as synced locally
                await _receiptRepository.markAsSynced(receipt.id);
                uploadedCount++;
              },
            );
          } catch (e) {
            // Log individual failures but continue with batch
            print('Failed to upload receipt ${receipt.id}: $e');
          }
        }

        return Right(uploadedCount);
      });
    } catch (e) {
      return Left(
        SyncFailure('Upload pending receipts failed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, int>> _downloadRemoteChanges(
    SyncReceiptsParams params,
  ) async {
    try {
      // Get last sync timestamp
      final lastSyncTime = await _localStorageService.getLastSyncTime();

      // Download changes since last sync
      final changesResult = await _receiptRepository.getRemoteChanges(
        userId: params.userId,
        since: lastSyncTime,
        limit: params.batchSize,
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
                // Receipt doesn't exist locally, create it
                await _receiptRepository.saveToLocal(remoteReceipt);
                downloadedCount++;
              },
              (localReceipt) async {
                // Receipt exists, check for conflicts
                if (_hasConflict(localReceipt, remoteReceipt)) {
                  await _receiptRepository.saveConflict(
                    localReceipt,
                    remoteReceipt,
                  );
                } else if (remoteReceipt.updatedAt.isAfter(
                  localReceipt.updatedAt,
                )) {
                  // Remote is newer, update local
                  await _receiptRepository.update(remoteReceipt);
                  downloadedCount++;
                }
              },
            );
          } catch (e) {
            print('Failed to download receipt ${remoteReceipt.id}: $e');
          }
        }

        return Right(downloadedCount);
      });
    } catch (e) {
      return Left(
        SyncFailure('Download remote changes failed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, int>> _resolveConflicts(String userId) async {
    try {
      // Get all unresolved conflicts
      final conflictsResult = await _receiptRepository.getConflicts(userId);

      return conflictsResult.fold((failure) => Left(failure), (
        conflicts,
      ) async {
        int resolvedCount = 0;

        for (final conflict in conflicts) {
          try {
            final resolvedReceipt = _resolveConflict(conflict);

            // Save resolved receipt
            await _receiptRepository.update(resolvedReceipt);

            // Mark conflict as resolved
            await _receiptRepository.markConflictResolved(conflict.id);

            resolvedCount++;
          } catch (e) {
            print('Failed to resolve conflict ${conflict.id}: $e');
          }
        }

        return Right(resolvedCount);
      });
    } catch (e) {
      return Left(SyncFailure('Resolve conflicts failed: ${e.toString()}'));
    }
  }

  bool _hasConflict(ReceiptEntity local, ReceiptEntity remote) {
    // Check if both have been modified since last sync
    if (local.syncStatus == SyncStatus.modified &&
        remote.updatedAt.isAfter(local.lastSyncedAt ?? DateTime(1970))) {
      return true;
    }

    // Check for significant differences in key fields
    if (local.amount != remote.amount ||
        local.vendor != remote.vendor ||
        local.category != remote.category) {
      return true;
    }

    return false;
  }

  ReceiptEntity _resolveConflict(ReceiptConflictEntity conflict) {
    // Default strategy: Last Write Wins with manual review for significant changes
    final local = conflict.localVersion;
    final remote = conflict.remoteVersion;

    // If remote is significantly newer, use remote
    if (remote.updatedAt.difference(local.updatedAt).inMinutes > 30) {
      return remote.copyWith(
        status: ReceiptStatus.needsReview,
        conflictResolution: ConflictResolution.remoteWins,
      );
    }

    // If local has more complete data, prefer local
    if (_isMoreComplete(local, remote)) {
      return local.copyWith(
        updatedAt: DateTime.now(),
        conflictResolution: ConflictResolution.localWins,
      );
    }

    // Merge strategy for compatible changes
    return _mergeReceipts(local, remote);
  }

  bool _isMoreComplete(ReceiptEntity a, ReceiptEntity b) {
    int scoreA = _getCompletenessScore(a);
    int scoreB = _getCompletenessScore(b);
    return scoreA > scoreB;
  }

  int _getCompletenessScore(ReceiptEntity receipt) {
    int score = 0;

    if (receipt.vendor != null && receipt.vendor!.isNotEmpty) score++;
    if (receipt.amount != null && receipt.amount! > 0) score++;
    if (receipt.category != null && receipt.category != 'General') score++;
    if (receipt.ocrData != null) score++;
    if (receipt.ocrData?.items.isNotEmpty == true) score++;

    return score;
  }

  ReceiptEntity _mergeReceipts(ReceiptEntity local, ReceiptEntity remote) {
    return local.copyWith(
      // Use remote timestamps
      updatedAt: remote.updatedAt,

      // Keep local data if more complete, otherwise use remote
      vendor: _isNotEmpty(local.vendor) ? local.vendor : remote.vendor,
      amount: (local.amount ?? 0) > 0 ? local.amount : remote.amount,
      category: _isNotEmpty(local.category) && local.category != 'General'
          ? local.category
          : remote.category,

      // Merge OCR data
      ocrData: local.ocrData ?? remote.ocrData,

      // Mark as merged
      conflictResolution: ConflictResolution.merged,
      status: ReceiptStatus.needsReview,
    );
  }

  bool _isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> _cleanupOrphanedData(String userId) async {
    try {
      // Clean up orphaned local images
      await _receiptRepository.cleanupOrphanedImages(userId);

      // Clean up old temp files
      await _localStorageService.cleanupTempFiles();

      // Clean up resolved conflicts older than 30 days
      await _receiptRepository.cleanupOldConflicts(
        userId,
        DateTime.now().subtract(const Duration(days: 30)),
      );
    } catch (e) {
      print('Cleanup failed: $e');
      // Non-critical, continue
    }
  }
}

class SyncReceiptsParams {
  final String userId;
  final SyncDirection syncDirection;
  final bool resolveConflicts;
  final bool cleanupOrphaned;
  final bool allowOfflineSync;
  final int batchSize;

  SyncReceiptsParams({
    required this.userId,
    this.syncDirection = SyncDirection.bidirectional,
    this.resolveConflicts = true,
    this.cleanupOrphaned = false,
    this.allowOfflineSync = false,
    this.batchSize = 50,
  });
}

enum SyncDirection { upload, download, bidirectional }

class SyncResult {
  bool success = false;
  int uploadedCount = 0;
  int downloadedCount = 0;
  int resolvedConflicts = 0;
  List<String> uploadFailures = [];
  List<String> downloadFailures = [];
  List<String> conflictFailures = [];
  DateTime? completedAt;

  int get totalSynced => uploadedCount + downloadedCount;
  bool get hasFailures =>
      uploadFailures.isNotEmpty ||
      downloadFailures.isNotEmpty ||
      conflictFailures.isNotEmpty;
}

enum ConflictResolution { localWins, remoteWins, merged, manualReview }
