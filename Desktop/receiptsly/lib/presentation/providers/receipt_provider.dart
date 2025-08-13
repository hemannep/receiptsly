import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../data/models/receipt/receipt_model.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/firebase/storage_service.dart';
import '../../domain/usecases/receipt/capture_receipt_usecase.dart';
import '../../core/errors/failures.dart';

// Receipt Service Providers
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);
final captureReceiptUseCaseProvider = Provider<CaptureReceiptUseCase>((ref) {
  return CaptureReceiptUseCase(
    ocrService: ref.watch(ocrServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// Receipt State Notifier
class ReceiptStateNotifier
    extends StateNotifier<AsyncValue<List<ReceiptModel>>> {
  final String userId;

  ReceiptStateNotifier(this.userId) : super(const AsyncValue.loading()) {
    _loadReceipts();
  }

  void _loadReceipts() {
    FirebaseFirestore.instance
        .collection('receipts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final receipts = snapshot.docs
                .map(
                  (doc) => ReceiptModel.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList();
            state = AsyncValue.data(receipts);
          },
          onError: (error, stackTrace) =>
              state = AsyncValue.error(error, stackTrace),
        );
  }

  // Add Receipt
  Future<void> addReceipt(ReceiptModel receipt) async {
    try {
      await FirebaseFirestore.instance
          .collection('receipts')
          .add(receipt.toJson());
    } catch (error) {
      throw ReceiptFailure('Failed to add receipt');
    }
  }

  // Update Receipt
  Future<void> updateReceipt(
    String receiptId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(receiptId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (error) {
      throw ReceiptFailure('Failed to update receipt');
    }
  }

  // Delete Receipt
  Future<void> deleteReceipt(String receiptId) async {
    try {
      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(receiptId)
          .delete();
    } catch (error) {
      throw ReceiptFailure('Failed to delete receipt');
    }
  }
}

// Receipt Provider
final receiptProvider =
    StateNotifierProvider.family<
      ReceiptStateNotifier,
      AsyncValue<List<ReceiptModel>>,
      String
    >((ref, userId) {
      return ReceiptStateNotifier(userId);
    });

// Receipt Upload State
class ReceiptUploadState {
  final bool isUploading;
  final double? progress;
  final String? error;
  final ReceiptModel? uploadedReceipt;

  const ReceiptUploadState({
    this.isUploading = false,
    this.progress,
    this.error,
    this.uploadedReceipt,
  });

  ReceiptUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    ReceiptModel? uploadedReceipt,
  }) {
    return ReceiptUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      uploadedReceipt: uploadedReceipt ?? this.uploadedReceipt,
    );
  }
}

// Receipt Upload Notifier
class ReceiptUploadNotifier extends StateNotifier<ReceiptUploadState> {
  final CaptureReceiptUseCase _captureReceiptUseCase;

  ReceiptUploadNotifier(this._captureReceiptUseCase)
    : super(const ReceiptUploadState());

  // Upload Receipt from Image
  Future<void> uploadReceipt({
    required File imageFile,
    required String userId,
    String? category,
    String? description,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      // Progress callback
      void onProgress(double progress) {
        state = state.copyWith(progress: progress);
      }

      final result = await _captureReceiptUseCase.execute(
        imageFile: imageFile,
        userId: userId,
        category: category,
        description: description,
        onProgress: onProgress,
      );

      if (result.success) {
        state = state.copyWith(
          isUploading: false,
          uploadedReceipt: result.receipt,
          progress: 1.0,
        );
      } else {
        state = state.copyWith(isUploading: false, error: result.error);
      }
    } catch (error) {
      state = state.copyWith(isUploading: false, error: error.toString());
    }
  }

  // Reset Upload State
  void resetUploadState() {
    state = const ReceiptUploadState();
  }
}

// Receipt Upload Provider
final receiptUploadProvider =
    StateNotifierProvider<ReceiptUploadNotifier, ReceiptUploadState>((ref) {
      return ReceiptUploadNotifier(ref.watch(captureReceiptUseCaseProvider));
    });

// Receipt Filters
class ReceiptFilters {
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? vendor;
  final ReceiptStatus? status;

  const ReceiptFilters({
    this.category,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.vendor,
    this.status,
  });

  ReceiptFilters copyWith({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? vendor,
    ReceiptStatus? status,
  }) {
    return ReceiptFilters(
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      vendor: vendor ?? this.vendor,
      status: status ?? this.status,
    );
  }
}

// Receipt Filters Provider
final receiptFiltersProvider = StateProvider<ReceiptFilters>((ref) {
  return const ReceiptFilters();
});

// Filtered Receipts Provider
final filteredReceiptsProvider =
    Provider.family<AsyncValue<List<ReceiptModel>>, String>((ref, userId) {
      final receiptsAsync = ref.watch(receiptProvider(userId));
      final filters = ref.watch(receiptFiltersProvider);

      return receiptsAsync.when(
        data: (receipts) {
          var filteredReceipts = receipts;

          // Apply filters
          if (filters.category != null) {
            filteredReceipts = filteredReceipts
                .where((receipt) => receipt.category == filters.category)
                .toList();
          }

          if (filters.startDate != null) {
            filteredReceipts = filteredReceipts
                .where((receipt) => receipt.date.isAfter(filters.startDate!))
                .toList();
          }

          if (filters.endDate != null) {
            filteredReceipts = filteredReceipts
                .where((receipt) => receipt.date.isBefore(filters.endDate!))
                .toList();
          }

          if (filters.minAmount != null) {
            filteredReceipts = filteredReceipts
                .where((receipt) => receipt.amount >= filters.minAmount!)
                .toList();
          }

          if (filters.maxAmount != null) {
            filteredReceipts = filteredReceipts
                .where((receipt) => receipt.amount <= filters.maxAmount!)
                .toList();
          }

          if (filters.vendor != null && filters.vendor!.isNotEmpty) {
            filteredReceipts = filteredReceipts
                .where(
                  (receipt) => receipt.vendor.toLowerCase().contains(
                    filters.vendor!.toLowerCase(),
                  ),
                )
                .toList();
          }

          if (filters.status != null) {
            filteredReceipts = filteredReceipts
                .where((receipt) => receipt.status == filters.status)
                .toList();
          }

          return AsyncValue.data(filteredReceipts);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

// Receipt Statistics Provider
final receiptStatsProvider = Provider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) {
  final receiptsAsync = ref.watch(receiptProvider(userId));

  return receiptsAsync.when(
    data: (receipts) {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      final currentMonthReceipts = receipts
          .where((receipt) => receipt.date.isAfter(currentMonth))
          .toList();

      final lastMonthReceipts = receipts
          .where(
            (receipt) =>
                receipt.date.isAfter(lastMonth) &&
                receipt.date.isBefore(currentMonth),
          )
          .toList();

      final currentMonthTotal = currentMonthReceipts.fold(
        0.0,
        (sum, receipt) => sum + receipt.amount,
      );

      final lastMonthTotal = lastMonthReceipts.fold(
        0.0,
        (sum, receipt) => sum + receipt.amount,
      );

      final percentageChange = lastMonthTotal > 0
          ? ((currentMonthTotal - lastMonthTotal) / lastMonthTotal * 100)
          : 0.0;

      return {
        'totalReceipts': receipts.length,
        'currentMonthReceipts': currentMonthReceipts.length,
        'currentMonthTotal': currentMonthTotal,
        'lastMonthTotal': lastMonthTotal,
        'percentageChange': percentageChange,
        'categoryBreakdown': _getCategoryBreakdown(currentMonthReceipts),
      };
    },
    loading: () => <String, dynamic>{},
    error: (_, __) => <String, dynamic>{},
  );
});

Map<String, double> _getCategoryBreakdown(List<ReceiptModel> receipts) {
  final Map<String, double> breakdown = {};

  for (final receipt in receipts) {
    breakdown[receipt.category] =
        (breakdown[receipt.category] ?? 0.0) + receipt.amount;
  }

  return breakdown;
}
