// lib/data/repositories/receipt_repository.dart
import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/models/receipt/receipt_model.dart';
import '../../domain/datasources/local/receipt_local_datasource.dart';
import '../../domain/datasources/remote/firebase/receipt_remote_datasource.dart';
import '../../domain/datasources/cache/image_cache_manager.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/sync/sync_service.dart';

class ReceiptRepository implements IReceiptRepository {
  final ReceiptLocalDatasource _localDatasource;
  final ReceiptRemoteDatasource _remoteDatasource;
  final ImageCacheManager _imageCacheManager;
  final OCRService _ocrService;
  final SyncService _syncService;
  final Connectivity _connectivity;

  ReceiptRepository({
    required ReceiptLocalDatasource localDatasource,
    required ReceiptRemoteDatasource remoteDatasource,
    required ImageCacheManager imageCacheManager,
    required OCRService ocrService,
    required SyncService syncService,
    required Connectivity connectivity,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _imageCacheManager = imageCacheManager,
       _ocrService = ocrService,
       _syncService = syncService,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, ReceiptEntity>> createReceipt({
    required String userId,
    required File imageFile,
    String? vendor,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
  }) async {
    try {
      // Generate unique ID
      final receiptId = _generateReceiptId();

      // Process OCR if not manually provided
      OCRResult? ocrResult;
      if (vendor == null || amount == null) {
        final ocrResponse = await _ocrService.processReceiptImage(imageFile);
        if (ocrResponse.success) {
          ocrResult = ocrResponse;
        }
      }

      // Cache image locally
      final localImagePath = await _imageCacheManager.cacheImage(
        imageFile,
        'receipt_$receiptId',
      );

      // Create receipt model
      final receiptModel = ReceiptModel(
        id: receiptId,
        userId: userId,
        vendor: vendor ?? ocrResult?.data?.vendor ?? 'Unknown Vendor',
        amount: amount ?? ocrResult?.data?.amount ?? 0.0,
        date: date ?? ocrResult?.data?.date ?? DateTime.now(),
        category: category ?? ocrResult?.data?.category ?? 'General',
        notes: notes ?? '',
        imageUrl: '', // Will be set after upload
        localImagePath: localImagePath,
        ocrData: ocrResult?.data != null
            ? OCRDataModel.fromOCRData(ocrResult!.data!)
            : null,
        ocrConfidence: ocrResult?.confidence ?? 0.0,
        status: ReceiptStatus.pending,
        source: ReceiptSource.mobile,
        currency: ocrResult?.data?.currency ?? 'USD',
        taxAmount: ocrResult?.data?.taxAmount ?? 0.0,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await _localDatasource.insertReceipt(receiptModel);

      // Check connectivity and upload if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // Upload image to remote storage
          final imageUrl = await _remoteDatasource.uploadReceiptImage(
            imageFile,
            userId,
            receiptId,
          );

          // Update model with remote image URL
          final updatedModel = receiptModel.copyWith(
            imageUrl: imageUrl,
            syncStatus: SyncStatus.synced,
            updatedAt: DateTime.now(),
          );

          // Save to remote
          await _remoteDatasource.createReceipt(updatedModel);

          // Update local with synced status
          await _localDatasource.updateReceipt(updatedModel);

          return Right(updatedModel.toEntity());
        } catch (e) {
          // If remote save fails, add to sync queue
          await _syncService.addToSyncQueue(
            action: 'CREATE',
            collection: 'receipts',
            data: receiptModel.toJson(),
          );

          return Right(receiptModel.toEntity());
        }
      } else {
        // Offline mode - add to sync queue
        await _syncService.addToSyncQueue(
          action: 'CREATE',
          collection: 'receipts',
          data: receiptModel.toJson(),
        );

        return Right(receiptModel.toEntity());
      }
    } catch (e) {
      return Left(DatabaseFailure('Failed to create receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReceiptEntity>> updateReceipt(
    String receiptId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Get current receipt
      final currentReceipt = await _localDatasource.getReceiptById(receiptId);
      if (currentReceipt == null) {
        return Left(DatabaseFailure('Receipt not found'));
      }

      // Apply updates
      final updatedModel = currentReceipt.copyWith(
        vendor: updates['vendor'] ?? currentReceipt.vendor,
        amount: updates['amount'] ?? currentReceipt.amount,
        date: updates['date'] ?? currentReceipt.date,
        category: updates['category'] ?? currentReceipt.category,
        notes: updates['notes'] ?? currentReceipt.notes,
        status: updates['status'] != null
            ? ReceiptStatus.values.firstWhere(
                (e) => e.name == updates['status'],
              )
            : currentReceipt.status,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      // Update locally
      await _localDatasource.updateReceipt(updatedModel);

      // Check connectivity and sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.updateReceipt(updatedModel);

          // Mark as synced
          final syncedModel = updatedModel.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.updateReceipt(syncedModel);

          return Right(syncedModel.toEntity());
        } catch (e) {
          // Add to sync queue if remote update fails
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'receipts',
            documentId: receiptId,
            data: updatedModel.toJson(),
          );
        }
      } else {
        // Add to sync queue for offline updates
        await _syncService.addToSyncQueue(
          action: 'UPDATE',
          collection: 'receipts',
          documentId: receiptId,
          data: updatedModel.toJson(),
        );
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to update receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceipt(String receiptId) async {
    try {
      // Get receipt to access image paths
      final receipt = await _localDatasource.getReceiptById(receiptId);
      if (receipt == null) {
        return Left(DatabaseFailure('Receipt not found'));
      }

      // Delete local image cache
      if (receipt.localImagePath != null) {
        await _imageCacheManager.deleteImage(receipt.localImagePath!);
      }

      // Delete from local database
      await _localDatasource.deleteReceipt(receiptId);

      // Check connectivity and delete from remote if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.deleteReceipt(receiptId);

          // Delete remote image if exists
          if (receipt.imageUrl.isNotEmpty) {
            await _remoteDatasource.deleteReceiptImage(receipt.imageUrl);
          }
        } catch (e) {
          // Add to sync queue if remote delete fails
          await _syncService.addToSyncQueue(
            action: 'DELETE',
            collection: 'receipts',
            documentId: receiptId,
            data: {'id': receiptId},
          );
        }
      } else {
        // Add to sync queue for offline deletes
        await _syncService.addToSyncQueue(
          action: 'DELETE',
          collection: 'receipts',
          documentId: receiptId,
          data: {'id': receiptId},
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReceiptEntity?>> getReceiptById(
    String receiptId,
  ) async {
    try {
      // Try local first
      final localReceipt = await _localDatasource.getReceiptById(receiptId);
      if (localReceipt != null) {
        return Right(localReceipt.toEntity());
      }

      // Try remote if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteReceipt = await _remoteDatasource.getReceiptById(receiptId);
        if (remoteReceipt != null) {
          // Cache locally
          await _localDatasource.insertReceipt(remoteReceipt);
          return Right(remoteReceipt.toEntity());
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptEntity>>> getReceipts({
    required String userId,
    int? limit,
    String? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    ReceiptStatus? status,
    String? searchQuery,
  }) async {
    try {
      // Get from local database
      final localReceipts = await _localDatasource.getReceipts(
        userId: userId,
        limit: limit,
        startAfter: startAfter,
        startDate: startDate,
        endDate: endDate,
        category: category,
        status: status,
        searchQuery: searchQuery,
      );

      // Convert to entities
      final localEntities = localReceipts
          .map((model) => model.toEntity())
          .toList();

      // Try to fetch updates from remote if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          final remoteReceipts = await _remoteDatasource.getReceipts(
            userId: userId,
            limit: limit,
            startAfter: startAfter,
            startDate: startDate,
            endDate: endDate,
            category: category,
            status: status,
            searchQuery: searchQuery,
          );

          // Merge remote data with local
          final mergedReceipts = await _mergeReceiptData(
            localReceipts,
            remoteReceipts,
          );
          final mergedEntities = mergedReceipts
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
      return Left(DatabaseFailure('Failed to get receipts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptEntity>>> searchReceipts({
    required String userId,
    required String query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final receipts = await _localDatasource.searchReceipts(
        userId: userId,
        query: query,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );

      final entities = receipts.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to search receipts: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getReceiptStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statistics = await _localDatasource.getReceiptStatistics(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(statistics);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get receipt statistics: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, List<ReceiptEntity>>>>
  getReceiptsByCategory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final receiptsByCategory = await _localDatasource.getReceiptsByCategory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final result = <String, List<ReceiptEntity>>{};
      receiptsByCategory.forEach((category, receipts) {
        result[category] = receipts.map((model) => model.toEntity()).toList();
      });

      return Right(result);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get receipts by category: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> bulkUploadReceipts({
    required String userId,
    required List<File> imageFiles,
    Function(int, int)? onProgress,
  }) async {
    try {
      final results = <String>[];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];

        // Process each receipt
        final result = await createReceipt(userId: userId, imageFile: file);

        result.fold(
          (failure) => results.add('Failed: ${file.path}'),
          (receipt) => results.add('Success: ${receipt.id}'),
        );

        // Report progress
        onProgress?.call(i + 1, imageFiles.length);
      }

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to bulk upload receipts: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ReceiptEntity>>> getUnsynced({
    required String userId,
  }) async {
    try {
      final unsyncedReceipts = await _localDatasource.getUnsyncedReceipts(
        userId,
      );
      final entities = unsyncedReceipts
          .map((model) => model.toEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get unsynced receipts: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String receiptId) async {
    try {
      await _localDatasource.markReceiptAsSynced(receiptId);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to mark receipt as synced: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncReceipts(String userId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      // Get unsynced receipts
      final unsyncedReceipts = await _localDatasource.getUnsyncedReceipts(
        userId,
      );

      for (final receipt in unsyncedReceipts) {
        try {
          if (receipt.syncStatus == SyncStatus.pending) {
            // Upload image if needed
            String imageUrl = receipt.imageUrl;
            if (receipt.localImagePath != null && imageUrl.isEmpty) {
              final imageFile = File(receipt.localImagePath!);
              if (await imageFile.exists()) {
                imageUrl = await _remoteDatasource.uploadReceiptImage(
                  imageFile,
                  userId,
                  receipt.id,
                );
              }
            }

            // Update model with image URL
            final updatedReceipt = receipt.copyWith(
              imageUrl: imageUrl,
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now(),
            );

            // Save to remote
            await _remoteDatasource.createReceipt(updatedReceipt);

            // Update local
            await _localDatasource.updateReceipt(updatedReceipt);
          }
        } catch (e) {
          // Log error but continue with other receipts
          print('Failed to sync receipt ${receipt.id}: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to sync receipts: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ReceiptEntity>> watchReceipts({
    required String userId,
    String? category,
    ReceiptStatus? status,
  }) {
    return _localDatasource
        .watchReceipts(userId: userId, category: category, status: status)
        .map((receipts) => receipts.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Either<Failure, File?>> getReceiptImage(String receiptId) async {
    try {
      final receipt = await _localDatasource.getReceiptById(receiptId);
      if (receipt == null) {
        return Left(DatabaseFailure('Receipt not found'));
      }

      // Try local image first
      if (receipt.localImagePath != null) {
        final localFile = File(receipt.localImagePath!);
        if (await localFile.exists()) {
          return Right(localFile);
        }
      }

      // Download from remote if connected
      if (receipt.imageUrl.isNotEmpty) {
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          final downloadedFile = await _imageCacheManager.downloadAndCacheImage(
            receipt.imageUrl,
            'receipt_${receipt.id}',
          );

          if (downloadedFile != null) {
            // Update local path
            final updatedReceipt = receipt.copyWith(
              localImagePath: downloadedFile.path,
            );
            await _localDatasource.updateReceipt(updatedReceipt);

            return Right(downloadedFile);
          }
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get receipt image: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, ReceiptEntity>> reprocessOCR(String receiptId) async {
    try {
      final receipt = await _localDatasource.getReceiptById(receiptId);
      if (receipt == null) {
        return Left(DatabaseFailure('Receipt not found'));
      }

      // Get image file
      final imageResult = await getReceiptImage(receiptId);

      return imageResult.fold((failure) => Left(failure), (imageFile) async {
        if (imageFile == null) {
          return Left(DatabaseFailure('Receipt image not found'));
        }

        // Process OCR
        final ocrResult = await _ocrService.processReceiptImage(imageFile);
        if (!ocrResult.success || ocrResult.data == null) {
          return Left(ProcessingFailure('OCR processing failed'));
        }

        // Update receipt with new OCR data
        final updatedReceipt = receipt.copyWith(
          vendor: ocrResult.data!.vendor,
          amount: ocrResult.data!.amount,
          date: ocrResult.data!.date,
          category: ocrResult.data!.category,
          ocrData: OCRDataModel.fromOCRData(ocrResult.data!),
          ocrConfidence: ocrResult.confidence ?? 0.0,
          syncStatus: SyncStatus.pending,
          updatedAt: DateTime.now(),
        );

        // Save updated receipt
        await _localDatasource.updateReceipt(updatedReceipt);

        // Add to sync queue
        await _syncService.addToSyncQueue(
          action: 'UPDATE',
          collection: 'receipts',
          documentId: receiptId,
          data: updatedReceipt.toJson(),
        );

        return Right(updatedReceipt.toEntity());
      });
    } catch (e) {
      return Left(
        ProcessingFailure('Failed to reprocess OCR: ${e.toString()}'),
      );
    }
  }

  // Private helper methods
  String _generateReceiptId() {
    return 'receipt_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[random % chars.length],
    ).join();
  }

  Future<List<ReceiptModel>> _mergeReceiptData(
    List<ReceiptModel> localReceipts,
    List<ReceiptModel> remoteReceipts,
  ) async {
    final Map<String, ReceiptModel> merged = {};

    // Add local receipts
    for (final receipt in localReceipts) {
      merged[receipt.id] = receipt;
    }

    // Merge remote receipts
    for (final remoteReceipt in remoteReceipts) {
      final localReceipt = merged[remoteReceipt.id];

      if (localReceipt == null) {
        // New remote receipt - cache it locally
        merged[remoteReceipt.id] = remoteReceipt;
        await _localDatasource.insertReceipt(remoteReceipt);
      } else {
        // Check which is newer
        if (remoteReceipt.updatedAt.isAfter(localReceipt.updatedAt)) {
          // Remote is newer - update local
          merged[remoteReceipt.id] = remoteReceipt;
          await _localDatasource.updateReceipt(remoteReceipt);
        } else if (localReceipt.updatedAt.isAfter(remoteReceipt.updatedAt) &&
            localReceipt.syncStatus == SyncStatus.pending) {
          // Local is newer and unsynced - add to sync queue
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'receipts',
            documentId: localReceipt.id,
            data: localReceipt.toJson(),
          );
        }
      }
    }

    return merged.values.toList();
  }
}
