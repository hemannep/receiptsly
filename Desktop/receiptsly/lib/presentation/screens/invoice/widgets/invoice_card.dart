// lib/presentation/screens/invoice/widgets/invoice_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/invoice/invoice_model.dart';
import 'payment_status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onSend;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        invoice.status == InvoiceStatus.sent &&
        invoice.dueDate.isBefore(DateTime.now());
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: isOverdue ? 4 : 2,
      color: isOverdue ? Colors.red.shade50 : null,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Invoice Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Invoice Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.clientName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(
                          symbol: '\$',
                        ).format(invoice.total),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      PaymentStatusBadge(status: invoice.status),
                    ],
                  ),

                  // Menu Button
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => _buildMenuItems(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dates Row
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Issued: ${DateFormat('MMM dd, yyyy').format(invoice.issueDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(
                    isOverdue ? Icons.warning : Icons.schedule,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              // Due Status
              if (invoice.status == InvoiceStatus.sent) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDueStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getDueStatusColor().withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getDueStatusIcon(),
                            size: 12,
                            color: _getDueStatusColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDueStatusText(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getDueStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Quick Actions for Overdue
                    if (isOverdue)
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _sendReminder(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Remind',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],

              // Line Items Preview
              if (invoice.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${invoice.items.length} item${invoice.items.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...invoice.items
                          .take(2)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      symbol: '\$',
                                    ).format(item.amount),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (invoice.items.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${invoice.items.length - 2} more',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Quick Send Button for Drafts
              if (invoice.status == InvoiceStatus.draft && onSend != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSend,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send Invoice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return invoice.dueDate.isBefore(DateTime.now())
            ? Colors.red
            : Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Icons.edit_note;
      case InvoiceStatus.sent:
        return invoice.dueDate.isBefore(DateTime.now())
            ? Icons.warning
            : Icons.schedule;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getAmountColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey[700]!;
      case InvoiceStatus.sent:
        return invoice.dueDate.isBefore(DateTime.now())
            ? Colors.red
            : AppColors.primary;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getDueStatusColor() {
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) {
      return Colors.red;
    } else if (daysUntilDue == 0) {
      return Colors.orange;
    } else if (daysUntilDue <= 3) {
      return Colors.orange;
    } else if (daysUntilDue <= 7) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  IconData _getDueStatusIcon() {
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) {
      return Icons.warning;
    } else if (daysUntilDue == 0) {
      return Icons.today;
    } else {
      return Icons.schedule;
    }
  }

  String _getDueStatusText() {
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) {
      return '${daysUntilDue.abs()} days overdue';
    } else if (daysUntilDue == 0) {
      return 'Due today';
    } else if (daysUntilDue == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }

  List<PopupMenuItem<String>> _buildMenuItems() {
    final items = <PopupMenuItem<String>>[];

    items.add(
      const PopupMenuItem(
        value: 'view',
        child: Row(
          children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View')],
        ),
      ),
    );

    if (onEdit != null) {
      items.add(
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
          ),
        ),
      );
    }

    if (invoice.status == InvoiceStatus.draft && onSend != null) {
      items.add(
        const PopupMenuItem(
          value: 'send',
          child: Row(
            children: [Icon(Icons.send), SizedBox(width: 8), Text('Send')],
          ),
        ),
      );
    }

    if (invoice.status == InvoiceStatus.sent) {
      items.add(
        const PopupMenuItem(
          value: 'reminder',
          child: Row(
            children: [
              Icon(Icons.email_outlined),
              SizedBox(width: 8),
              Text('Send Reminder'),
            ],
          ),
        ),
      );

      items.add(
        const PopupMenuItem(
          value: 'mark_paid',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Mark as Paid'),
            ],
          ),
        ),
      );
    }

    items.add(
      const PopupMenuItem(
        value: 'share',
        child: Row(
          children: [Icon(Icons.share), SizedBox(width: 8), Text('Share')],
        ),
      ),
    );

    if (onDuplicate != null) {
      items.add(
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [Icon(Icons.copy), SizedBox(width: 8), Text('Duplicate')],
          ),
        ),
      );
    }

    items.add(
      const PopupMenuItem(
        value: 'download',
        child: Row(
          children: [
            Icon(Icons.download),
            SizedBox(width: 8),
            Text('Download PDF'),
          ],
        ),
      ),
    );

    if (onDelete != null) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view':
        onTap?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'send':
        onSend?.call();
        break;
      case 'reminder':
        // Handle send reminder
        break;
      case 'mark_paid':
        // Handle mark as paid
        break;
      case 'share':
        // Handle share
        break;
      case 'duplicate':
        onDuplicate?.call();
        break;
      case 'download':
        // Handle download PDF
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  void _sendReminder(BuildContext context) {
    // Show reminder dialog or trigger send reminder action
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reminder'),
        content: Text(
          'Send a payment reminder for invoice ${invoice.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger send reminder action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder sent successfully')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
