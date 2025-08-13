// lib/presentation/screens/invoice/widgets/payment_status_badge.dart
import 'package:flutter/material.dart';
import 'package:receiptsly/data/models/invoice/invoice_status.dart';

import '../../../../data/models/invoice/invoice_model.dart';

class PaymentStatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  final bool showIcon;
  final double fontSize;
  final EdgeInsets padding;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_getIcon(), size: fontSize + 2, color: _getTextColor()),
            const SizedBox(width: 4),
          ],
          Text(
            _getDisplayText(),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey.shade100;
      case InvoiceStatus.sent:
        return Colors.orange.shade100;
      case InvoiceStatus.paid:
        return Colors.green.shade100;
      case InvoiceStatus.cancelled:
        return Colors.red.shade100;
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey.shade300;
      case InvoiceStatus.sent:
        return Colors.orange.shade300;
      case InvoiceStatus.paid:
        return Colors.green.shade300;
      case InvoiceStatus.cancelled:
        return Colors.red.shade300;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey.shade700;
      case InvoiceStatus.sent:
        return Colors.orange.shade700;
      case InvoiceStatus.paid:
        return Colors.green.shade700;
      case InvoiceStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit_note;
      case InvoiceStatus.sent:
        return Icons.schedule;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getDisplayText() {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Extended version with additional status information
class ExtendedPaymentStatusBadge extends StatelessWidget {
  final InvoiceModel invoice;
  final bool showDueInfo;

  const ExtendedPaymentStatusBadge({
    super.key,
    required this.invoice,
    this.showDueInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PaymentStatusBadge(status: invoice.status),
        if (showDueInfo && invoice.status == InvoiceStatus.sent) ...[
          const SizedBox(height: 4),
          _buildDueInfo(),
        ],
      ],
    );
  }

  Widget _buildDueInfo() {
    final now = DateTime.now();
    final daysUntilDue = invoice.dueDate.difference(now).inDays;
    final isOverdue = daysUntilDue < 0;

    Color textColor;
    String text;
    IconData icon;

    if (isOverdue) {
      textColor = Colors.red.shade700;
      text = '${daysUntilDue.abs()} days overdue';
      icon = Icons.warning;
    } else if (daysUntilDue == 0) {
      textColor = Colors.orange.shade700;
      text = 'Due today';
      icon = Icons.today;
    } else if (daysUntilDue <= 3) {
      textColor = Colors.orange.shade700;
      text = 'Due in $daysUntilDue days';
      icon = Icons.schedule;
    } else if (daysUntilDue <= 7) {
      textColor = Colors.amber.shade700;
      text = 'Due in $daysUntilDue days';
      icon = Icons.schedule;
    } else {
      textColor = Colors.grey.shade600;
      text = 'Due in $daysUntilDue days';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.shade50
            : daysUntilDue <= 3
            ? Colors.orange.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade200
              : daysUntilDue <= 3
              ? Colors.orange.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Compact status badge for list items
class CompactStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const CompactStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }
}

// Status badge with count for dashboard
class StatusBadgeWithCount extends StatelessWidget {
  final InvoiceStatus status;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const StatusBadgeWithCount({
    super.key,
    required this.status,
    required this.count,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _getStatusColor()
              : _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 16,
              color: isSelected ? Colors.white : _getStatusColor(),
            ),
            const SizedBox(width: 6),
            Text(
              _getDisplayText(),
              style: TextStyle(
                color: isSelected ? Colors.white : _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : _getStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey.shade600;
      case InvoiceStatus.sent:
        return Colors.orange.shade600;
      case InvoiceStatus.paid:
        return Colors.green.shade600;
      case InvoiceStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit_note;
      case InvoiceStatus.sent:
        return Icons.schedule;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getDisplayText() {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}
