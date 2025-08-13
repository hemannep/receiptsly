import 'package:dartz/dartz.dart';
import '../../entities/receipt_entity.dart';
import '../../entities/invoice_entity.dart';
import '../../repositories/i_sync_repository.dart';
import '../../repositories/i_receipt_repository.dart';
import '../../repositories/i_invoice_repository.dart';
import '../../../core/errors/failures.dart';

class ResolveConflictsUseCase {
  final ISyncRepository _syncRepository;
  final IReceiptRepository _receiptRepository;
  final IInvoiceRepository _invoiceRepository;

  ResolveConflictsUseCase(
    this._syncRepository,
    this._receiptRepository,
    this._invoiceRepository,
  );

  Future<Either<Failure, ConflictResolutionResult>> call(
    ResolveConflictsParams params,
  ) async {
    try {
      // Get all unresolved conflicts for user
      final conflictsResult = await _syncRepository.getUnresolvedConflicts(
        params.userId,
      );

      return conflictsResult.fold((failure) => Left(failure), (
        conflicts,
      ) async {
        final result = ConflictResolutionResult();

        for (final conflict in conflicts) {
          try {
            final resolutionResult = await _resolveConflict(conflict, params);
            resolutionResult.fold(
              (failure) => result.failed.add(
                ConflictResolutionFailure(
                  conflictId: conflict.id,
                  error: failure.message,
                ),
              ),
              (resolvedConflict) => result.resolved.add(resolvedConflict),
            );
          } catch (e) {
            result.failed.add(
              ConflictResolutionFailure(
                conflictId: conflict.id,
                error: e.toString(),
              ),
            );
          }
        }

        result.totalConflicts = conflicts.length;
        result.resolvedCount = result.resolved.length;
        result.failedCount = result.failed.length;
        result.success = result.failedCount == 0;

        return Right(result);
      });
    } catch (e) {
      return Left(
        ConflictResolutionFailure(
          'Conflict resolution failed: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<Failure, ResolvedConflict>> _resolveConflict(
    DataConflict conflict,
    ResolveConflictsParams params,
  ) async {
    try {
      // Determine resolution strategy
      final strategy = _determineResolutionStrategy(conflict, params);

      // Apply resolution based on entity type
      switch (conflict.entityType) {
        case 'receipt':
          return await _resolveReceiptConflict(conflict, strategy);
        case 'invoice':
          return await _resolveInvoiceConflict(conflict, strategy);
        default:
          return Left(
            ConflictResolutionFailure(
              'Unknown entity type: ${conflict.entityType}',
            ),
          );
      }
    } catch (e) {
      return Left(
        ConflictResolutionFailure('Conflict resolution error: ${e.toString()}'),
      );
    }
  }

  ConflictResolutionStrategy _determineResolutionStrategy(
    DataConflict conflict,
    ResolveConflictsParams params,
  ) {
    // Use user-specified strategy if provided
    if (params.strategy != null) {
      return params.strategy!;
    }

    // Auto-determine strategy based on conflict analysis
    return _analyzeConflictAndDetermineStrategy(conflict);
  }

  ConflictResolutionStrategy _analyzeConflictAndDetermineStrategy(
    DataConflict conflict,
  ) {
    final local = conflict.localVersion;
    final remote = conflict.remoteVersion;

    // Strategy 1: Last Write Wins
    if (remote['updatedAt'] != null && local['updatedAt'] != null) {
      final remoteTime = DateTime.parse(remote['updatedAt']);
      final localTime = DateTime.parse(local['updatedAt']);

      // If one is significantly newer (>1 hour), prefer the newer one
      if (remoteTime.difference(localTime).inHours.abs() > 1) {
        return remoteTime.isAfter(localTime)
            ? ConflictResolutionStrategy.preferRemote
            : ConflictResolutionStrategy.preferLocal;
      }
    }

    // Strategy 2: Completeness-based resolution
    final localCompleteness = _calculateDataCompleteness(local);
    final remoteCompleteness = _calculateDataCompleteness(remote);

    if ((localCompleteness - remoteCompleteness).abs() > 0.2) {
      return localCompleteness > remoteCompleteness
          ? ConflictResolutionStrategy.preferLocal
          : ConflictResolutionStrategy.preferRemote;
    }

    // Strategy 3: Field-level merge for compatible changes
    if (_areChangesCompatible(local, remote)) {
      return ConflictResolutionStrategy.merge;
    }

    // Default: Manual review required
    return ConflictResolutionStrategy.manualReview;
  }

  double _calculateDataCompleteness(Map<String, dynamic> data) {
    int totalFields = 0;
    int populatedFields = 0;

    // Check common fields
    final fieldsToCheck = ['vendor', 'amount', 'date', 'category', 'notes'];

    for (final field in fieldsToCheck) {
      totalFields++;
      if (data[field] != null && data[field].toString().trim().isNotEmpty) {
        populatedFields++;
      }
    }

    // Check OCR data completeness for receipts
    if (data.containsKey('ocrData') && data['ocrData'] != null) {
      totalFields += 3;
      final ocrData = data['ocrData'] as Map<String, dynamic>;
      if (ocrData['confidence'] != null && ocrData['confidence'] > 0.7)
        populatedFields++;
      if (ocrData['items'] != null && (ocrData['items'] as List).isNotEmpty)
        populatedFields++;
      if (ocrData['rawText'] != null &&
          ocrData['rawText'].toString().length > 50)
        populatedFields++;
    }

    return totalFields > 0 ? populatedFields / totalFields : 0.0;
  }

  bool _areChangesCompatible(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Check if changes are in non-conflicting fields
    final conflictingFields = ['amount', 'vendor', 'category'];

    for (final field in conflictingFields) {
      if (local[field] != null &&
          remote[field] != null &&
          local[field] != remote[field]) {
        return false;
      }
    }

    return true;
  }

  Future<Either<Failure, ResolvedConflict>> _resolveReceiptConflict(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    try {
      late ReceiptEntity resolvedReceipt;

      switch (strategy) {
        case ConflictResolutionStrategy.preferLocal:
          resolvedReceipt = ReceiptEntity.fromJson(conflict.localVersion);
          break;

        case ConflictResolutionStrategy.preferRemote:
          resolvedReceipt = ReceiptEntity.fromJson(conflict.remoteVersion);
          break;

        case ConflictResolutionStrategy.merge:
          resolvedReceipt = _mergeReceiptData(
            conflict.localVersion,
            conflict.remoteVersion,
          );
          break;

        case ConflictResolutionStrategy.manualReview:
          // Mark for manual review
          await _syncRepository.markConflictForManualReview(conflict.id);
          return Right(
            ResolvedConflict(
              conflictId: conflict.id,
              strategy: strategy,
              requiresManualReview: true,
            ),
          );
      }

      // Save resolved receipt
      final saveResult = await _receiptRepository.update(resolvedReceipt);

      return saveResult.fold((failure) => Left(failure), (savedReceipt) async {
        // Mark conflict as resolved
        await _syncRepository.markConflictResolved(
          conflict.id,
          strategy,
          savedReceipt.toJson(),
        );

        return Right(
          ResolvedConflict(
            conflictId: conflict.id,
            strategy: strategy,
            resolvedEntity: savedReceipt,
            requiresManualReview: false,
          ),
        );
      });
    } catch (e) {
      return Left(
        ConflictResolutionFailure(
          'Receipt conflict resolution failed: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<Failure, ResolvedConflict>> _resolveInvoiceConflict(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    try {
      late InvoiceEntity resolvedInvoice;

      switch (strategy) {
        case ConflictResolutionStrategy.preferLocal:
          resolvedInvoice = InvoiceEntity.fromJson(conflict.localVersion);
          break;

        case ConflictResolutionStrategy.preferRemote:
          resolvedInvoice = InvoiceEntity.fromJson(conflict.remoteVersion);
          break;

        case ConflictResolutionStrategy.merge:
          resolvedInvoice = _mergeInvoiceData(
            conflict.localVersion,
            conflict.remoteVersion,
          );
          break;

        case ConflictResolutionStrategy.manualReview:
          await _syncRepository.markConflictForManualReview(conflict.id);
          return Right(
            ResolvedConflict(
              conflictId: conflict.id,
              strategy: strategy,
              requiresManualReview: true,
            ),
          );
      }

      // Save resolved invoice
      final saveResult = await _invoiceRepository.update(resolvedInvoice);

      return saveResult.fold((failure) => Left(failure), (savedInvoice) async {
        await _syncRepository.markConflictResolved(
          conflict.id,
          strategy,
          savedInvoice.toJson(),
        );

        return Right(
          ResolvedConflict(
            conflictId: conflict.id,
            strategy: strategy,
            resolvedEntity: savedInvoice,
            requiresManualReview: false,
          ),
        );
      });
    } catch (e) {
      return Left(
        ConflictResolutionFailure(
          'Invoice conflict resolution failed: ${e.toString()}',
        ),
      );
    }
  }

  ReceiptEntity _mergeReceiptData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Create a merged version by combining compatible fields
    final merged = Map<String, dynamic>.from(local);

    // Use remote timestamp
    merged['updatedAt'] = remote['updatedAt'];

    // Merge fields where local is incomplete
    if (_isFieldEmpty(local['vendor']) && !_isFieldEmpty(remote['vendor'])) {
      merged['vendor'] = remote['vendor'];
    }

    if (_isFieldEmpty(local['category']) &&
        !_isFieldEmpty(remote['category'])) {
      merged['category'] = remote['category'];
    }

    if ((local['amount'] == null || local['amount'] == 0) &&
        remote['amount'] != null) {
      merged['amount'] = remote['amount'];
    }

    // Merge OCR data if local has lower confidence
    if (local['ocrData'] != null && remote['ocrData'] != null) {
      final localConfidence = local['ocrData']['confidence'] ?? 0.0;
      final remoteConfidence = remote['ocrData']['confidence'] ?? 0.0;

      if (remoteConfidence > localConfidence) {
        merged['ocrData'] = remote['ocrData'];
      }
    } else if (local['ocrData'] == null && remote['ocrData'] != null) {
      merged['ocrData'] = remote['ocrData'];
    }

    // Mark as merged
    merged['conflictResolution'] = 'merged';
    merged['syncStatus'] = 'synced';

    return ReceiptEntity.fromJson(merged);
  }

  InvoiceEntity _mergeInvoiceData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);

    // Use remote timestamp
    merged['updatedAt'] = remote['updatedAt'];

    // For invoices, be more conservative with merging
    // Only merge non-critical fields
    if (_isFieldEmpty(local['notes']) && !_isFieldEmpty(remote['notes'])) {
      merged['notes'] = remote['notes'];
    }

    if (_isFieldEmpty(local['terms']) && !_isFieldEmpty(remote['terms'])) {
      merged['terms'] = remote['terms'];
    }

    // Update payment status if remote has newer payment information
    if (remote['paidAmount'] != null &&
        (local['paidAmount'] == null ||
            remote['paidAmount'] > local['paidAmount'])) {
      merged['paidAmount'] = remote['paidAmount'];
      merged['status'] = remote['status'];
      if (remote['paidAt'] != null) {
        merged['paidAt'] = remote['paidAt'];
      }
    }

    merged['conflictResolution'] = 'merged';
    merged['syncStatus'] = 'synced';

    return InvoiceEntity.fromJson(merged);
  }

  bool _isFieldEmpty(dynamic field) {
    if (field == null) return true;
    if (field is String) return field.trim().isEmpty;
    if (field is num) return field == 0;
    return false;
  }

  // Manual conflict resolution
  Future<Either<Failure, ResolvedConflict>> resolveManually(
    ResolveManuallyParams params,
  ) async {
    try {
      // Get the conflict
      final conflictResult = await _syncRepository.getConflictById(
        params.conflictId,
      );

      return conflictResult.fold((failure) => Left(failure), (conflict) async {
        // Validate the manual resolution
        final validationResult = _validateManualResolution(conflict, params);
        if (validationResult != null) {
          return Left(ValidationFailure(validationResult));
        }

        // Apply manual resolution
        final resolutionResult = await _applyManualResolution(conflict, params);

        return resolutionResult.fold(
          (failure) => Left(failure),
          (resolvedConflict) => Right(resolvedConflict),
        );
      });
    } catch (e) {
      return Left(
        ConflictResolutionFailure('Manual resolution failed: ${e.toString()}'),
      );
    }
  }

  String? _validateManualResolution(
    DataConflict conflict,
    ResolveManuallyParams params,
  ) {
    // Validate that the resolution data is complete
    if (params.resolutionData.isEmpty) {
      return 'Resolution data cannot be empty';
    }

    // Validate required fields based on entity type
    switch (conflict.entityType) {
      case 'receipt':
        final requiredFields = ['vendor', 'amount', 'date'];
        for (final field in requiredFields) {
          if (params.resolutionData[field] == null) {
            return 'Required field missing: $field';
          }
        }
        break;
      case 'invoice':
        final requiredFields = ['invoiceNumber', 'clientId', 'total', 'status'];
        for (final field in requiredFields) {
          if (params.resolutionData[field] == null) {
            return 'Required field missing: $field';
          }
        }
        break;
    }

    return null;
  }

  Future<Either<Failure, ResolvedConflict>> _applyManualResolution(
    DataConflict conflict,
    ResolveManuallyParams params,
  ) async {
    try {
      // Apply the manual resolution based on entity type
      switch (conflict.entityType) {
        case 'receipt':
          final receipt = ReceiptEntity.fromJson(params.resolutionData);
          final saveResult = await _receiptRepository.update(receipt);

          return saveResult.fold((failure) => Left(failure), (
            savedReceipt,
          ) async {
            await _syncRepository.markConflictResolved(
              conflict.id,
              ConflictResolutionStrategy.manual,
              savedReceipt.toJson(),
            );

            return Right(
              ResolvedConflict(
                conflictId: conflict.id,
                strategy: ConflictResolutionStrategy.manual,
                resolvedEntity: savedReceipt,
                requiresManualReview: false,
                resolutionNotes: params.resolutionNotes,
              ),
            );
          });

        case 'invoice':
          final invoice = InvoiceEntity.fromJson(params.resolutionData);
          final saveResult = await _invoiceRepository.update(invoice);

          return saveResult.fold((failure) => Left(failure), (
            savedInvoice,
          ) async {
            await _syncRepository.markConflictResolved(
              conflict.id,
              ConflictResolutionStrategy.manual,
              savedInvoice.toJson(),
            );

            return Right(
              ResolvedConflict(
                conflictId: conflict.id,
                strategy: ConflictResolutionStrategy.manual,
                resolvedEntity: savedInvoice,
                requiresManualReview: false,
                resolutionNotes: params.resolutionNotes,
              ),
            );
          });

        default:
          return Left(
            ConflictResolutionFailure(
              'Unknown entity type: ${conflict.entityType}',
            ),
          );
      }
    } catch (e) {
      return Left(
        ConflictResolutionFailure(
          'Manual resolution application failed: ${e.toString()}',
        ),
      );
    }
  }

  // Batch conflict resolution
  Future<Either<Failure, ConflictResolutionResult>> resolveBatch(
    ResolveBatchParams params,
  ) async {
    try {
      final result = ConflictResolutionResult();

      for (final conflictId in params.conflictIds) {
        final individualParams = ResolveConflictsParams(
          userId: params.userId,
          strategy: params.strategy,
        );

        // Get specific conflict
        final conflictResult = await _syncRepository.getConflictById(
          conflictId,
        );

        await conflictResult.fold(
          (failure) async {
            result.failed.add(
              ConflictResolutionFailure(
                conflictId: conflictId,
                error: failure.message,
              ),
            );
          },
          (conflict) async {
            final resolutionResult = await _resolveConflict(
              conflict,
              individualParams,
            );
            resolutionResult.fold(
              (failure) => result.failed.add(
                ConflictResolutionFailure(
                  conflictId: conflictId,
                  error: failure.message,
                ),
              ),
              (resolvedConflict) => result.resolved.add(resolvedConflict),
            );
          },
        );
      }

      result.totalConflicts = params.conflictIds.length;
      result.resolvedCount = result.resolved.length;
      result.failedCount = result.failed.length;
      result.success = result.failedCount == 0;

      return Right(result);
    } catch (e) {
      return Left(
        ConflictResolutionFailure('Batch resolution failed: ${e.toString()}'),
      );
    }
  }
}

class ResolveConflictsParams {
  final String userId;
  final ConflictResolutionStrategy? strategy;
  final int maxConflictsToResolve;
  final bool resolveManualReviewItems;

  ResolveConflictsParams({
    required this.userId,
    this.strategy,
    this.maxConflictsToResolve = 50,
    this.resolveManualReviewItems = false,
  });
}

class ResolveManuallyParams {
  final String conflictId;
  final Map<String, dynamic> resolutionData;
  final String? resolutionNotes;
  final String resolvedBy;

  ResolveManuallyParams({
    required this.conflictId,
    required this.resolutionData,
    this.resolutionNotes,
    required this.resolvedBy,
  });
}

class ResolveBatchParams {
  final String userId;
  final List<String> conflictIds;
  final ConflictResolutionStrategy strategy;

  ResolveBatchParams({
    required this.userId,
    required this.conflictIds,
    required this.strategy,
  });
}

enum ConflictResolutionStrategy {
  preferLocal,
  preferRemote,
  merge,
  manualReview,
  manual,
  lastWriteWins,
  mostComplete,
}

class DataConflict {
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> remoteVersion;
  final DateTime conflictDetectedAt;
  final bool requiresManualReview;
  final ConflictResolutionStrategy? suggestedStrategy;

  DataConflict({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.remoteVersion,
    required this.conflictDetectedAt,
    this.requiresManualReview = false,
    this.suggestedStrategy,
  });
}

class ResolvedConflict {
  final String conflictId;
  final ConflictResolutionStrategy strategy;
  final dynamic resolvedEntity;
  final bool requiresManualReview;
  final String? resolutionNotes;
  final DateTime resolvedAt;

  ResolvedConflict({
    required this.conflictId,
    required this.strategy,
    this.resolvedEntity,
    this.requiresManualReview = false,
    this.resolutionNotes,
  }) : resolvedAt = DateTime.now();
}

class ConflictResolutionResult {
  int totalConflicts = 0;
  int resolvedCount = 0;
  int failedCount = 0;
  bool success = false;
  List<ResolvedConflict> resolved = [];
  List<ConflictResolutionFailure> failed = [];

  double get successRate =>
      totalConflicts > 0 ? resolvedCount / totalConflicts : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalConflicts': totalConflicts,
      'resolvedCount': resolvedCount,
      'failedCount': failedCount,
      'success': success,
      'successRate': successRate,
      'resolved': resolved
          .map(
            (r) => {
              'conflictId': r.conflictId,
              'strategy': r.strategy.toString(),
              'requiresManualReview': r.requiresManualReview,
              'resolvedAt': r.resolvedAt.toIso8601String(),
            },
          )
          .toList(),
      'failed': failed
          .map((f) => {'conflictId': f.conflictId, 'error': f.error})
          .toList(),
    };
  }
}

class ConflictResolutionFailure extends Failure {
  final String conflictId;
  final String error;

  ConflictResolutionFailure({required this.conflictId, required this.error})
    : super(error);
}
