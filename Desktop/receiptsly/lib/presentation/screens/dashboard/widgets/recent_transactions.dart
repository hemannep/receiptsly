// lib/presentation/screens/dashboard/widgets/recent_transactions.dart
import 'package:flutter/material.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/core/utils/date_utils.dart';
import 'package:receiptsly/data/models/transaction/transaction_model.dart';
import 'package:receiptsly/presentation/widgets/animations/slide_animation.dart';
import 'package:receiptsly/presentation/widgets/common/app_button.dart';

class RecentTransactions extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final Function(TransactionModel)? onTransactionTap;
  final int maxItems;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.onViewAll,
    this.onTransactionTap,
    this.maxItems = 5,
  });

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  TransactionFilter _filter = TransactionFilter.all;

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
          const SizedBox(height: 16),
          _buildFilterTabs(),
          const SizedBox(height: 20),
          if (widget.isLoading)
            _buildLoadingState()
          else if (_getFilteredTransactions().isEmpty)
            _buildEmptyState()
          else
            _buildTransactionsList(),
          if (!widget.isLoading && _getFilteredTransactions().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildViewAllButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Recent Activity',
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
            '${_getFilteredTransactions().length} items',
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

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TransactionFilter.values.map((filter) {
          final isSelected = _filter == filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                _getFilterLabel(filter),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final transactions = _getFilteredTransactions();
    final displayTransactions = transactions.take(widget.maxItems).toList();

    return Column(
      children: displayTransactions.asMap().entries.map((entry) {
        final index = entry.key;
        final transaction = entry.value;

        return SlideAnimation(
          delay: Duration(milliseconds: index * 100),
          direction: SlideDirection.left,
          child: _buildTransactionItem(transaction, index),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction, int index) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.error : AppColors.success;
    final icon = _getTransactionIcon(transaction);

    return GestureDetector(
      onTap: () => widget.onTransactionTap?.call(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Transaction Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${CurrencyUtils.format(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (transaction.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            transaction.category!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        DateUtils.formatRelative(transaction.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (transaction.hasAttachment) ...[
                        Icon(
                          Icons.attach_file,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (transaction.isRecurring) ...[
                        Icon(Icons.repeat, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                      ],
                      _buildStatusIndicator(transaction.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(TransactionStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case TransactionStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case TransactionStatus.processed:
        statusColor = AppColors.success;
        statusText = 'Processed';
        break;
      case TransactionStatus.failed:
        statusColor = AppColors.error;
        statusText = 'Failed';
        break;
      case TransactionStatus.cancelled:
        statusColor = AppColors.textSecondary;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        widget.maxItems,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
          height: 80,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: AppButton(
        text: 'View All Transactions',
        onPressed: widget.onViewAll,
        variant: AppButtonVariant.outline,
        size: AppButtonSize.small,
      ),
    );
  }

  List<TransactionModel> _getFilteredTransactions() {
    switch (_filter) {
      case TransactionFilter.all:
        return widget.transactions;
      case TransactionFilter.income:
        return widget.transactions
            .where((t) => t.type == TransactionType.income)
            .toList();
      case TransactionFilter.expenses:
        return widget.transactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
      case TransactionFilter.pending:
        return widget.transactions
            .where((t) => t.status == TransactionStatus.pending)
            .toList();
    }
  }

  String _getFilterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.income:
        return 'Income';
      case TransactionFilter.expenses:
        return 'Expenses';
      case TransactionFilter.pending:
        return 'Pending';
    }
  }

  IconData _getTransactionIcon(TransactionModel transaction) {
    if (transaction.type == TransactionType.income) {
      return Icons.arrow_downward;
    }

    // Expense icons based on category
    final category = transaction.category?.toLowerCase() ?? '';

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
    } else if (category.contains('utilities')) {
      return Icons.electrical_services;
    } else if (category.contains('rent') || category.contains('housing')) {
      return Icons.home;
    }

    return Icons.arrow_upward;
  }

  String _getEmptyStateTitle() {
    switch (_filter) {
      case TransactionFilter.all:
        return 'No transactions yet';
      case TransactionFilter.income:
        return 'No income recorded';
      case TransactionFilter.expenses:
        return 'No expenses recorded';
      case TransactionFilter.pending:
        return 'No pending transactions';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_filter) {
      case TransactionFilter.all:
        return 'Start by adding your first receipt or creating an invoice';
      case TransactionFilter.income:
        return 'Create invoices to track your income';
      case TransactionFilter.expenses:
        return 'Upload receipts to track your expenses';
      case TransactionFilter.pending:
        return 'All transactions have been processed';
    }
  }
}

// Enhanced version with quick actions
class RecentTransactionsWithActions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final Function(TransactionModel)? onTransactionTap;
  final Function(TransactionModel)? onEdit;
  final Function(TransactionModel)? onDelete;
  final Function(TransactionModel)? onDuplicate;

  const RecentTransactionsWithActions({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.onViewAll,
    this.onTransactionTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
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
          if (isLoading)
            _buildLoadingState()
          else if (transactions.isEmpty)
            _buildEmptyState()
          else
            _buildTransactionsWithActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }

  Widget _buildTransactionsWithActions() {
    return Column(
      children: transactions.take(5).map((transaction) {
        return _buildTransactionItemWithActions(transaction);
      }).toList(),
    );
  }

  Widget _buildTransactionItemWithActions(TransactionModel transaction) {
    return Dismissible(
      key: Key(transaction.id),
      background: _buildSwipeBackground(isLeft: true),
      secondaryBackground: _buildSwipeBackground(isLeft: false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call(transaction);
        } else {
          onDelete?.call(transaction);
        }
      },
      child: GestureDetector(
        onTap: () => onTransactionTap?.call(transaction),
        onLongPress: () => _showActionSheet(transaction),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildTransactionIcon(transaction),
              const SizedBox(width: 12),
              Expanded(child: _buildTransactionDetails(transaction)),
              _buildTransactionAmount(transaction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLeft ? AppColors.primary : AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isLeft ? Icons.edit : Icons.delete,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTransactionIcon(TransactionModel transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.error : AppColors.success;
    final icon = _getTransactionIcon(transaction);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildTransactionDetails(TransactionModel transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.description,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (transaction.category != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  transaction.category!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              DateUtils.formatRelative(transaction.date),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionAmount(TransactionModel transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.error : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${isExpense ? '-' : '+'}${CurrencyUtils.format(transaction.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        _buildStatusIndicator(transaction.status),
      ],
    );
  }

  Widget _buildStatusIndicator(TransactionStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case TransactionStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case TransactionStatus.processed:
        statusColor = AppColors.success;
        statusText = 'Done';
        break;
      case TransactionStatus.failed:
        statusColor = AppColors.error;
        statusText = 'Failed';
        break;
      case TransactionStatus.cancelled:
        statusColor = AppColors.textSecondary;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        5,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
          height: 80,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first receipt or creating an invoice',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(TransactionModel transaction) {
    // Implementation would show a bottom sheet with action options
    // This is a placeholder for the actual implementation
  }

  IconData _getTransactionIcon(TransactionModel transaction) {
    if (transaction.type == TransactionType.income) {
      return Icons.arrow_downward;
    }

    final category = transaction.category?.toLowerCase() ?? '';

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

    return Icons.arrow_upward;
  }
}

// Enums and models
enum TransactionFilter { all, income, expenses, pending }

enum TransactionType { income, expense }

enum TransactionStatus { pending, processed, failed, cancelled }

// Transaction model (simplified version)
class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionStatus status;
  final String? category;
  final bool hasAttachment;
  final bool isRecurring;
  final String? receiptId;
  final String? invoiceId;

  const TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.status = TransactionStatus.processed,
    this.category,
    this.hasAttachment = false,
    this.isRecurring = false,
    this.receiptId,
    this.invoiceId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.expense,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.processed,
      ),
      category: json['category'],
      hasAttachment: json['hasAttachment'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      receiptId: json['receiptId'],
      invoiceId: json['invoiceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'category': category,
      'hasAttachment': hasAttachment,
      'isRecurring': isRecurring,
      'receiptId': receiptId,
      'invoiceId': invoiceId,
    };
  }
}
