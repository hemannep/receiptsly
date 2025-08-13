import 'package:dartz/dartz.dart';
import '../../entities/receipt_entity.dart';
import '../../repositories/i_receipt_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/ai/categorization_service.dart';

class CategorizeReceiptUseCase {
  final IReceiptRepository _receiptRepository;
  final CategorizationService _categorizationService;

  CategorizeReceiptUseCase(
    this._receiptRepository,
    this._categorizationService,
  );

  Future<Either<Failure, ReceiptEntity>> call(
    CategorizeReceiptParams params,
  ) async {
    try {
      // Get receipt
      final receiptResult = await _receiptRepository.getById(params.receiptId);

      return receiptResult.fold((failure) => Left(failure), (receipt) async {
        // Skip if already categorized and not forcing
        if (!params.forceRecategorize &&
            receipt.category != null &&
            receipt.category != 'General') {
          return Right(receipt);
        }

        // Perform categorization
        final categoryResult = await _categorizeReceipt(receipt, params);

        return categoryResult.fold(
          (failure) => Left(failure),
          (updatedReceipt) => Right(updatedReceipt),
        );
      });
    } catch (e) {
      return Left(
        CategorizationFailure('Categorization failed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, ReceiptEntity>> _categorizeReceipt(
    ReceiptEntity receipt,
    CategorizeReceiptParams params,
  ) async {
    try {
      // Prepare categorization data
      final categorizationData = CategorizationData(
        vendor: receipt.vendor ?? receipt.ocrData?.vendor ?? 'Unknown',
        amount: receipt.amount ?? receipt.ocrData?.amount ?? 0.0,
        rawText: receipt.ocrData?.rawText ?? '',
        items: receipt.ocrData?.items ?? [],
        existingCategory: receipt.category,
        userHistory: await _getUserCategorizationHistory(receipt.userId),
      );

      // Get category suggestions
      final suggestions = await _categorizationService.categorizeReceipt(
        categorizationData,
      );

      if (suggestions.isEmpty) {
        return Left(CategorizationFailure('No category suggestions found'));
      }

      // Select best category
      final selectedCategory = _selectBestCategory(suggestions, params);

      // Update receipt
      final updatedReceipt = receipt.copyWith(
        category: selectedCategory.name,
        categoryConfidence: selectedCategory.confidence,
        suggestedCategories: suggestions.map((s) => s.name).toList(),
        updatedAt: DateTime.now(),
      );

      // Save updated receipt
      final saveResult = await _receiptRepository.update(updatedReceipt);

      return saveResult.fold((failure) => Left(failure), (savedReceipt) async {
        // Learn from categorization for future improvements
        await _categorizationService.learnFromCategorization(
          categorizationData,
          selectedCategory,
        );

        return Right(savedReceipt);
      });
    } catch (e) {
      return Left(
        CategorizationFailure('Category processing error: ${e.toString()}'),
      );
    }
  }

  CategorySuggestion _selectBestCategory(
    List<CategorySuggestion> suggestions,
    CategorizeReceiptParams params,
  ) {
    // Sort by confidence
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Apply user preferences
    if (params.preferredCategories != null) {
      for (final preferred in params.preferredCategories!) {
        final match = suggestions.firstWhere(
          (s) => s.name.toLowerCase() == preferred.toLowerCase(),
          orElse: () => suggestions.first,
        );
        if (match.confidence > 0.5) {
          return match;
        }
      }
    }

    // Apply business rules
    final topSuggestion = suggestions.first;

    // Override for high-confidence specific cases
    if (topSuggestion.confidence > 0.9) {
      return topSuggestion;
    }

    // Check for common patterns
    final businessRuleCategory = _applyBusinessRules(suggestions);
    if (businessRuleCategory != null) {
      return businessRuleCategory;
    }

    return topSuggestion;
  }

  CategorySuggestion? _applyBusinessRules(
    List<CategorySuggestion> suggestions,
  ) {
    // Rule: If multiple food-related categories, prefer "Food & Dining"
    final foodCategories = suggestions
        .where(
          (s) =>
              s.name.contains('Food') ||
              s.name.contains('Dining') ||
              s.name.contains('Restaurant'),
        )
        .toList();

    if (foodCategories.length > 1) {
      return foodCategories.firstWhere(
        (s) => s.name == 'Food & Dining',
        orElse: () => foodCategories.first,
      );
    }

    // Rule: Prefer specific categories over general ones
    final specificCategories = suggestions
        .where((s) => s.name != 'General')
        .toList();
    if (specificCategories.isNotEmpty &&
        specificCategories.first.confidence > 0.6) {
      return specificCategories.first;
    }

    return null;
  }

  Future<List<UserCategorizationHistory>> _getUserCategorizationHistory(
    String userId,
  ) async {
    try {
      final historyResult = await _receiptRepository
          .getUserCategorizationHistory(userId, limit: 100);

      return historyResult.fold((failure) => [], (history) => history);
    } catch (e) {
      return [];
    }
  }

  // Batch categorization for multiple receipts
  Future<Either<Failure, List<ReceiptEntity>>> categorizeBatch(
    List<String> receiptIds,
  ) async {
    try {
      final results = <ReceiptEntity>[];
      final failures = <String>[];

      for (final receiptId in receiptIds) {
        final result = await call(
          CategorizeReceiptParams(receiptId: receiptId),
        );

        result.fold(
          (failure) => failures.add(receiptId),
          (receipt) => results.add(receipt),
        );
      }

      if (failures.isNotEmpty && results.isEmpty) {
        return Left(CategorizationFailure('Failed to categorize any receipts'));
      }

      return Right(results);
    } catch (e) {
      return Left(
        CategorizationFailure('Batch categorization failed: ${e.toString()}'),
      );
    }
  }
}

class CategorizeReceiptParams {
  final String receiptId;
  final bool forceRecategorize;
  final List<String>? preferredCategories;
  final double minimumConfidence;

  CategorizeReceiptParams({
    required this.receiptId,
    this.forceRecategorize = false,
    this.preferredCategories,
    this.minimumConfidence = 0.5,
  });
}

class CategorizationData {
  final String vendor;
  final double amount;
  final String rawText;
  final List<ReceiptItemEntity> items;
  final String? existingCategory;
  final List<UserCategorizationHistory> userHistory;

  CategorizationData({
    required this.vendor,
    required this.amount,
    required this.rawText,
    required this.items,
    this.existingCategory,
    required this.userHistory,
  });
}

class CategorySuggestion {
  final String name;
  final double confidence;
  final String reason;
  final List<String> matchedKeywords;

  CategorySuggestion({
    required this.name,
    required this.confidence,
    required this.reason,
    required this.matchedKeywords,
  });
}

class UserCategorizationHistory {
  final String vendor;
  final String category;
  final int count;
  final DateTime lastUsed;

  UserCategorizationHistory({
    required this.vendor,
    required this.category,
    required this.count,
    required this.lastUsed,
  });
}
