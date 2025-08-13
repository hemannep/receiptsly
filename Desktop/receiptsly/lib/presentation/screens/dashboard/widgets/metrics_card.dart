// lib/presentation/screens/dashboard/widgets/metrics_card.dart
import 'package:flutter/material.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/presentation/widgets/animations/fade_animation.dart';

class MetricsCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final String? trend;
  final double? trendPercentage;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool showAnimation;

  const MetricsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.trend,
    this.trendPercentage,
    this.onTap,
    this.isLoading = false,
    this.showAnimation = true,
  });

  @override
  State<MetricsCard> createState() => _MetricsCardState();
}

class _MetricsCardState extends State<MetricsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: _buildCard()),
        );
      },
    );
  }

  Widget _buildCard() {
    final cardColor = widget.color ?? AppColors.primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: cardColor.withOpacity(0.1), width: 1),
        ),
        child: widget.isLoading
            ? _buildLoadingState()
            : _buildContent(cardColor),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Spacer(),
            Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon and trend
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: cardColor, size: 24),
            ),
            const Spacer(),
            if (widget.trendPercentage != null) _buildTrendIndicator(cardColor),
          ],
        ),

        const SizedBox(height: 16),

        // Title
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 8),

        // Value
        Text(
          widget.value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // Subtitle or trend text
        if (widget.subtitle != null || widget.trend != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle ?? widget.trend ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getTrendColor(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendIndicator(Color cardColor) {
    if (widget.trendPercentage == null) return const SizedBox.shrink();

    final isPositive = widget.trendPercentage! > 0;
    final trendColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: trendColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.trendPercentage!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    if (widget.trendPercentage != null) {
      return widget.trendPercentage! > 0 ? AppColors.success : AppColors.error;
    }
    return AppColors.textSecondary;
  }
}

// Specialized metric cards for different data types
class RevenueMetricsCard extends StatelessWidget {
  final double amount;
  final double? previousAmount;
  final bool isLoading;
  final VoidCallback? onTap;

  const RevenueMetricsCard({
    super.key,
    required this.amount,
    this.previousAmount,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double? trendPercentage;
    String? trend;

    if (previousAmount != null && previousAmount! > 0) {
      trendPercentage = ((amount - previousAmount!) / previousAmount!) * 100;
      trend = trendPercentage > 0 ? 'vs last month' : 'vs last month';
    }

    return MetricsCard(
      title: 'Monthly Revenue',
      value: CurrencyUtils.format(amount),
      icon: Icons.trending_up,
      color: AppColors.success,
      trendPercentage: trendPercentage,
      trend: trend,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}

class ExpenseMetricsCard extends StatelessWidget {
  final double amount;
  final double? previousAmount;
  final bool isLoading;
  final VoidCallback? onTap;

  const ExpenseMetricsCard({
    super.key,
    required this.amount,
    this.previousAmount,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double? trendPercentage;
    String? trend;

    if (previousAmount != null && previousAmount! > 0) {
      trendPercentage = ((amount - previousAmount!) / previousAmount!) * 100;
      trend = trendPercentage > 0 ? 'vs last month' : 'vs last month';
    }

    return MetricsCard(
      title: 'Monthly Expenses',
      value: CurrencyUtils.format(amount),
      icon: Icons.trending_down,
      color: AppColors.warning,
      trendPercentage: trendPercentage,
      trend: trend,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}

class ProfitMetricsCard extends StatelessWidget {
  final double revenue;
  final double expenses;
  final bool isLoading;
  final VoidCallback? onTap;

  const ProfitMetricsCard({
    super.key,
    required this.revenue,
    required this.expenses,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profit = revenue - expenses;
    final profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

    return MetricsCard(
      title: 'Net Profit',
      value: CurrencyUtils.format(profit),
      subtitle: '${profitMargin.toStringAsFixed(1)}% margin',
      icon: Icons.account_balance_wallet,
      color: profit >= 0 ? AppColors.success : AppColors.error,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}

class InvoiceMetricsCard extends StatelessWidget {
  final int totalInvoices;
  final int paidInvoices;
  final int pendingInvoices;
  final double pendingAmount;
  final bool isLoading;
  final VoidCallback? onTap;

  const InvoiceMetricsCard({
    super.key,
    required this.totalInvoices,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.pendingAmount,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MetricsCard(
      title: 'Pending Invoices',
      value: pendingInvoices.toString(),
      subtitle: '${CurrencyUtils.format(pendingAmount)} outstanding',
      icon: Icons.receipt_long,
      color: pendingInvoices > 0 ? AppColors.warning : AppColors.success,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}

class ReceiptMetricsCard extends StatelessWidget {
  final int monthlyReceipts;
  final int totalReceipts;
  final bool isLoading;
  final VoidCallback? onTap;

  const ReceiptMetricsCard({
    super.key,
    required this.monthlyReceipts,
    required this.totalReceipts,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MetricsCard(
      title: 'Receipts This Month',
      value: monthlyReceipts.toString(),
      subtitle: '$totalReceipts total receipts',
      icon: Icons.camera_alt,
      color: AppColors.primary,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}
