import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    required String userId,
    required String name,
    required String description,
    required String colorHex,
    required String iconName,
    String? parentCategoryId,
    @Default([]) List<String> subcategoryIds,
    @Default('expense') String type,
    @Default(true) bool isActive,
    @Default(false) bool isDefault,
    @Default(false) bool isSystemCategory,
    @Default(true) bool isTaxDeductible,
    @Default(0) int sortOrder,
    @Default(0.0) double budgetAmount,
    @Default('monthly') String budgetPeriod,
    @Default(0.0) double currentSpent,
    @Default([]) List<String> keywords,
    @Default([]) List<String> vendorPatterns,
    required CategoryRulesModel rules,
    required CategoryStatsModel stats,
    @Default([]) List<String> tags,
    Map<String, dynamic>? metadata,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @Default(1) int version,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}

@freezed
class CategoryRulesModel with _$CategoryRulesModel {
  const factory CategoryRulesModel({
    @Default(true) bool enableAutoMatch,
    @Default(0.8) double matchConfidenceThreshold,
    @Default(true) bool matchByVendor,
    @Default(true) bool matchByDescription,
    @Default(false) bool matchByAmount,
    double? minAmount,
    double? maxAmount,
    @Default([]) List<String> excludeVendors,
    @Default([]) List<String> includeVendors,
    @Default([]) List<String> excludeKeywords,
    @Default([]) List<String> includeKeywords,
    @Default(false) bool requireApproval,
    Map<String, dynamic>? customRules,
  }) = _CategoryRulesModel;

  factory CategoryRulesModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryRulesModelFromJson(json);
}

@freezed
class CategoryStatsModel with _$CategoryStatsModel {
  const factory CategoryStatsModel({
    @Default(0) int totalTransactions,
    @Default(0.0) double totalAmount,
    @Default(0.0) double averageAmount,
    @Default(0.0) double monthlyAverage,
    @Default(0.0) double yearlyTotal,
    @Default(0.0) double percentageOfTotal,
    @TimestampConverter() DateTime? lastUsedAt,
    @TimestampConverter() DateTime? firstUsedAt,
    @Default(0) int thisMonthCount,
    @Default(0.0) double thisMonthAmount,
    @Default(0) int lastMonthCount,
    @Default(0.0) double lastMonthAmount,
    @Default(0.0) double growthRate,
    Map<String, double>? monthlyTrends,
  }) = _CategoryStatsModel;

  factory CategoryStatsModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryStatsModelFromJson(json);
}

extension CategoryModelExtension on CategoryModel {
  bool get isParentCategory => subcategoryIds.isNotEmpty;
  bool get isSubcategory => parentCategoryId != null;
  bool get isRootCategory => parentCategoryId == null;
  int get hierarchyLevel => isRootCategory ? 0 : 1;
  bool get hasBudget => budgetAmount > 0;
  bool get isBudgetExceeded => hasBudget && currentSpent > budgetAmount;

  double get budgetUtilization =>
      !hasBudget ? 0.0 : (currentSpent / budgetAmount) * 100;

  double get remainingBudget => !hasBudget
      ? 0.0
      : (budgetAmount - currentSpent).clamp(0.0, double.infinity);

  String get budgetStatusColor {
    if (!hasBudget) return '#9E9E9E';
    final utilization = budgetUtilization;
    if (utilization >= 100) return '#F44336';
    if (utilization >= 80) return '#FF9800';
    if (utilization >= 60) return '#FFC107';
    return '#4CAF50';
  }

  String get budgetStatusLabel {
    if (!hasBudget) return 'No Budget';
    final utilization = budgetUtilization;
    if (utilization >= 100) return 'Over Budget';
    if (utilization >= 80) return 'Near Limit';
    if (utilization >= 60) return 'On Track';
    return 'Under Budget';
  }

  bool get isFrequentlyUsed {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return stats.lastUsedAt != null &&
        stats.lastUsedAt!.isAfter(thirtyDaysAgo) &&
        stats.thisMonthCount >= 3;
  }

  String get growthTrend {
    if (stats.growthRate > 10) return 'increasing';
    if (stats.growthRate < -10) return 'decreasing';
    return 'stable';
  }

  String get growthTrendIcon {
    switch (growthTrend) {
      case 'increasing':
        return 'trending_up';
      case 'decreasing':
        return 'trending_down';
      default:
        return 'trending_flat';
    }
  }

  String get growthTrendColor {
    switch (growthTrend) {
      case 'increasing':
        return '#F44336';
      case 'decreasing':
        return '#4CAF50';
      default:
        return '#9E9E9E';
    }
  }

  bool matchesVendor(String vendorName) {
    if (!rules.enableAutoMatch || !rules.matchByVendor) return false;
    final lowerVendor = vendorName.toLowerCase();
    if (rules.includeVendors.any(
      (v) => lowerVendor.contains(v.toLowerCase()),
    )) {
      return true;
    }
    if (rules.excludeVendors.any(
      (v) => lowerVendor.contains(v.toLowerCase()),
    )) {
      return false;
    }
    return keywords.any((k) => lowerVendor.contains(k.toLowerCase()));
  }

  bool matchesDescription(String description) {
    if (!rules.enableAutoMatch || !rules.matchByDescription) return false;
    final lowerDesc = description.toLowerCase();
    if (rules.excludeKeywords.any((k) => lowerDesc.contains(k.toLowerCase()))) {
      return false;
    }
    if (rules.includeKeywords.any((k) => lowerDesc.contains(k.toLowerCase()))) {
      return true;
    }
    return keywords.any((k) => lowerDesc.contains(k.toLowerCase()));
  }

  bool matchesAmount(double amount) {
    if (!rules.enableAutoMatch || !rules.matchByAmount) return true;
    if (rules.minAmount != null && amount < rules.minAmount!) return false;
    if (rules.maxAmount != null && amount > rules.maxAmount!) return false;
    return true;
  }

  double calculateMatchConfidence({
    required String vendor,
    required String description,
    required double amount,
  }) {
    if (!rules.enableAutoMatch) return 0.0;

    double confidence = 0.0;
    int factors = 0;

    if (rules.matchByVendor && matchesVendor(vendor)) {
      confidence += 0.4;
      factors++;
    }

    if (rules.matchByDescription && matchesDescription(description)) {
      confidence += 0.3;
      factors++;
    }

    if (rules.matchByAmount && matchesAmount(amount)) {
      confidence += 0.3;
      factors++;
    }

    return factors > 0 ? confidence * (factors / 3.0) : 0.0;
  }

  bool shouldAutoMatch({
    required String vendor,
    required String description,
    required double amount,
  }) {
    return calculateMatchConfidence(
          vendor: vendor,
          description: description,
          amount: amount,
        ) >=
        rules.matchConfidenceThreshold;
  }

  String get budgetPeriodLabel {
    switch (budgetPeriod) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Monthly';
    }
  }

  DateTime getNextBudgetReset() {
    final now = DateTime.now();
    switch (budgetPeriod) {
      case 'weekly':
        final daysUntilMonday = (8 - now.weekday) % 7;
        return now.add(
          Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
        );
      case 'monthly':
        return now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
      case 'quarterly':
        final nextQuarterMonth = ((now.month - 1) ~/ 3 + 1) * 3 + 1;
        return nextQuarterMonth > 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, nextQuarterMonth, 1);
      case 'yearly':
        return DateTime(now.year + 1, 1, 1);
      default:
        return DateTime(now.year, now.month + 1, 1);
    }
  }

  CategoryModel updateStats({
    required double amount,
    required DateTime transactionDate,
  }) {
    final newStats = stats.copyWith(
      totalTransactions: stats.totalTransactions + 1,
      totalAmount: stats.totalAmount + amount,
      lastUsedAt: transactionDate,
      firstUsedAt: stats.firstUsedAt ?? transactionDate,
    );

    final now = DateTime.now();
    if (transactionDate.year == now.year &&
        transactionDate.month == now.month) {
      newStats.copyWith(
        thisMonthCount: stats.thisMonthCount + 1,
        thisMonthAmount: stats.thisMonthAmount + amount,
      );
    }

    return copyWith(
      stats: newStats.copyWith(
        averageAmount: newStats.totalAmount / newStats.totalTransactions,
        currentSpent: currentSpent + amount,
      ),
      updatedAt: DateTime.now(),
    );
  }

  CategoryModel updateBudget({
    required double budgetAmount,
    required String budgetPeriod,
  }) {
    return copyWith(
      budgetAmount: budgetAmount,
      budgetPeriod: budgetPeriod,
      updatedAt: DateTime.now(),
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (name.trim().isEmpty) errors.add('Category name is required');
    if (colorHex.isEmpty || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(colorHex)) {
      errors.add('Valid color hex code is required');
    }
    if (iconName.isEmpty) errors.add('Icon name is required');
    if (!['expense', 'income', 'both'].contains(type)) {
      errors.add('Type must be expense, income, or both');
    }
    if (budgetAmount < 0) errors.add('Budget amount cannot be negative');
    if (!['weekly', 'monthly', 'quarterly', 'yearly'].contains(budgetPeriod)) {
      errors.add('Invalid budget period');
    }
    if (rules.matchConfidenceThreshold < 0 ||
        rules.matchConfidenceThreshold > 1) {
      errors.add('Match confidence threshold must be between 0 and 1');
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['createdAt'] = TimestampConverter().toJson(createdAt);
    json['updatedAt'] = TimestampConverter().toJson(updatedAt);
    if (stats.lastUsedAt != null) {
      json['stats']['lastUsedAt'] = TimestampConverter().toJson(
        stats.lastUsedAt!,
      );
    }
    if (stats.firstUsedAt != null) {
      json['stats']['firstUsedAt'] = TimestampConverter().toJson(
        stats.firstUsedAt!,
      );
    }
    return json;
  }

  static CategoryModel fromFirestore(Map<String, dynamic> data) {
    return CategoryModel.fromJson(data);
  }
}

class DefaultCategories {
  static List<CategoryModel> getDefaults(String userId) {
    final now = DateTime.now();
    return [
      _createDefault(
        id: 'food_dining',
        name: 'Food & Dining',
        description: 'Restaurants, cafes, groceries, and food expenses',
        colorHex: '#FF5722',
        iconName: 'restaurant',
        keywords: ['restaurant', 'cafe', 'food', 'dining', 'grocery'],
        userId: userId,
        now: now,
      ),
      // Add other default categories similarly
    ];
  }

  static CategoryModel _createDefault({
    required String id,
    required String name,
    required String description,
    required String colorHex,
    required String iconName,
    required List<String> keywords,
    required String userId,
    required DateTime now,
  }) {
    return CategoryModel(
      id: id,
      userId: userId,
      name: name,
      description: description,
      colorHex: colorHex,
      iconName: iconName,
      isDefault: true,
      isSystemCategory: true,
      keywords: keywords,
      rules: const CategoryRulesModel(),
      stats: const CategoryStatsModel(),
      createdAt: now,
      updatedAt: now,
    );
  }
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
