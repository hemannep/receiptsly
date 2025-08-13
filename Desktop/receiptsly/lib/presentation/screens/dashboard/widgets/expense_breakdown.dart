// lib/presentation/screens/dashboard/widgets/expense_breakdown.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/data/models/category/category_model.dart';
import 'package:receiptsly/presentation/widgets/animations/scale_animation.dart';

class ExpenseBreakdown extends StatefulWidget {
  final List<CategoryExpense> expenses;
  final double totalAmount;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const ExpenseBreakdown({
    super.key,
    required this.expenses,
    required this.totalAmount,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  State<ExpenseBreakdown> createState() => _ExpenseBreakdownState();
}

class _ExpenseBreakdownState extends State<ExpenseBreakdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _touchedIndex;
  bool _showPercentages = true;

  // Color palette for categories
  final List<Color> _categoryColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.warning,
    AppColors.success,
    AppColors.error,
    const Color(0xFF8E24AA),
    const Color(0xFF00ACC1),
    const Color(0xFF039BE5),
    const Color(0xFF43A047),
    const Color(0xFFFB8C00),
    const Color(0xFFE53935),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (widget.isLoading)
            _buildLoadingState()
          else if (widget.expenses.isEmpty)
            _buildEmptyState()
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${CurrencyUtils.format(widget.totalAmount)}',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _buildToggleButton(),
        if (widget.onViewAll != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onViewAll,
            child: const Text('View All'),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            icon: Icons.pie_chart,
            isSelected: _showPercentages,
            onTap: () => setState(() => _showPercentages = true),
          ),
          _buildModeButton(
            icon: Icons.format_list_bulleted,
            isSelected: !_showPercentages,
            onTap: () => setState(() => _showPercentages = false),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: _showPercentages ? _buildChartView() : _buildListView(),
        );
      },
    );
  }

  Widget _buildChartView() {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildPieChart()),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildLegend()),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _getPieChartSections(),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: widget.expenses.length,
            itemBuilder: (context, index) {
              final expense = widget.expenses[index];
              final percentage = (expense.amount / widget.totalAmount) * 100;
              final color = _getCategoryColor(index);

              return ScaleAnimation(
                delay: Duration(milliseconds: index * 100),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      children: widget.expenses.asMap().entries.map((entry) {
        final index = entry.key;
        final expense = entry.value;
        final percentage = (expense.amount / widget.totalAmount) * 100;
        final color = _getCategoryColor(index);

        return ScaleAnimation(
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.categoryName),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${expense.count} transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.format(expense.amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: Column(
        children: List.generate(
          5,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(12),
            ),
            height: 60,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses this month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding receipts to see your expense breakdown',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    return widget.expenses.asMap().entries.map((entry) {
      final index = entry.key;
      final expense = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage = (expense.amount / widget.totalAmount) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: expense.amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched ? _buildBadge(expense) : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildBadge(CategoryExpense expense) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            expense.categoryName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            CurrencyUtils.format(expense.amount),
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  IconData _getCategoryIcon(String categoryName) {
    final category = categoryName.toLowerCase();

    if (category.contains('food') ||
        category.contains('dining') ||
        category.contains('restaurant')) {
      return Icons.restaurant;
    } else if (category.contains('transport') ||
        category.contains('travel') ||
        category.contains('gas')) {
      return Icons.directions_car;
    } else if (category.contains('office') || category.contains('supplies')) {
      return Icons.business_center;
    } else if (category.contains('software') ||
        category.contains('technology') ||
        category.contains('tech')) {
      return Icons.computer;
    } else if (category.contains('health') || category.contains('medical')) {
      return Icons.local_hospital;
    } else if (category.contains('entertainment') || category.contains('fun')) {
      return Icons.movie;
    } else if (category.contains('education') ||
        category.contains('training')) {
      return Icons.school;
    } else if (category.contains('marketing') ||
        category.contains('advertising')) {
      return Icons.campaign;
    } else if (category.contains('utilities') || category.contains('bills')) {
      return Icons.electrical_services;
    } else if (category.contains('rent') || category.contains('housing')) {
      return Icons.home;
    }

    return Icons.category;
  }
}

// Model for category expenses
class CategoryExpense {
  final String categoryId;
  final String categoryName;
  final double amount;
  final int count;
  final Color? color;

  const CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.count,
    this.color,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) {
    return CategoryExpense(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? 'Unknown',
      amount: (json['amount'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'count': count,
    };
  }
}

// Enhanced breakdown with trends
class ExpenseBreakdownWithTrends extends StatelessWidget {
  final List<CategoryExpense> currentExpenses;
  final List<CategoryExpense> previousExpenses;
  final double totalAmount;
  final bool isLoading;

  const ExpenseBreakdownWithTrends({
    super.key,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.totalAmount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (isLoading) _buildLoadingState() else _buildTrendsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Category Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'vs Last Month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsList() {
    final trends = _calculateTrends();

    return Column(
      children: trends.map((trend) => _buildTrendItem(trend)).toList(),
    );
  }

  Widget _buildTrendItem(CategoryTrend trend) {
    final isIncrease = trend.changeAmount > 0;
    final trendColor = isIncrease ? AppColors.error : AppColors.success;
    final trendIcon = isIncrease ? Icons.trending_up : Icons.trending_down;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(trend.categoryName),
              color: trendColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.categoryName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyUtils.format(trend.currentAmount),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 16),
              const SizedBox(width: 4),
              Text(
                '${trend.changePercentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        5,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  List<CategoryTrend> _calculateTrends() {
    final trends = <CategoryTrend>[];

    for (final current in currentExpenses) {
      final previous = previousExpenses.firstWhere(
        (p) => p.categoryId == current.categoryId,
        orElse: () => CategoryExpense(
          categoryId: current.categoryId,
          categoryName: current.categoryName,
          amount: 0,
          count: 0,
        ),
      );

      final changeAmount = current.amount - previous.amount;
      final changePercentage = previous.amount > 0
          ? (changeAmount / previous.amount) * 100
          : 100.0;

      trends.add(
        CategoryTrend(
          categoryName: current.categoryName,
          currentAmount: current.amount,
          previousAmount: previous.amount,
          changeAmount: changeAmount,
          changePercentage: changePercentage,
        ),
      );
    }

    // Sort by absolute change amount (biggest changes first)
    trends.sort((a, b) => b.changeAmount.abs().compareTo(a.changeAmount.abs()));

    return trends.take(5).toList(); // Show top 5 changes
  }

  IconData _getCategoryIcon(String categoryName) {
    final category = categoryName.toLowerCase();

    if (category.contains('food') || category.contains('dining')) {
      return Icons.restaurant;
    } else if (category.contains('transport') || category.contains('travel')) {
      return Icons.directions_car;
    } else if (category.contains('office') || category.contains('supplies')) {
      return Icons.business_center;
    } else if (category.contains('software') ||
        category.contains('technology')) {
      return Icons.computer;
    } else if (category.contains('health') || category.contains('medical')) {
      return Icons.local_hospital;
    } else if (category.contains('entertainment')) {
      return Icons.movie;
    } else if (category.contains('education')) {
      return Icons.school;
    } else if (category.contains('marketing')) {
      return Icons.campaign;
    }

    return Icons.category;
  }
}

class CategoryTrend {
  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double changeAmount;
  final double changePercentage;

  const CategoryTrend({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.changeAmount,
    required this.changePercentage,
  });
}
