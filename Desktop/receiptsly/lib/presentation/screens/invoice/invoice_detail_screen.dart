// lib/presentation/screens/invoice/invoice_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/layouts/app_scaffold.dart';
import 'widgets/payment_status_badge.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  InvoiceModel? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final invoice = await ref
          .read(invoiceProvider.notifier)
          .getInvoiceById(widget.invoiceId);

      if (mounted) {
        setState(() {
          _invoice = invoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading invoice: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(title: 'Invoice Details', body: AppLoader());
    }

    if (_invoice == null) {
      return AppScaffold(
        title: 'Invoice Details',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Invoice not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: _invoice!.invoiceNumber,
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            if (_invoice!.status == InvoiceStatus.draft)
              const PopupMenuItem(
                value: 'send',
                child: Row(
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 8),
                    Text('Send'),
                  ],
                ),
              ),
            if (_invoice!.status == InvoiceStatus.sent)
              const PopupMenuItem(
                value: 'mark_paid',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Mark as Paid'),
                  ],
                ),
              ),
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
          ],
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildClientInfo(),
            const SizedBox(height: 24),
            _buildInvoiceDetails(),
            const SizedBox(height: 24),
            _buildLineItems(),
            const SizedBox(height: 24),
            _buildTotals(),
            if (_invoice!.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              _buildNotes(),
            ],
            if (_invoice!.terms?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              _buildTerms(),
            ],
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice ${_invoice!.invoiceNumber}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${NumberFormat.currency(symbol: '\$').format(_invoice!.total)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            PaymentStatusBadge(status: _invoice!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill To',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _invoice!.clientName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (_invoice!.clientEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _invoice!.clientEmail,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
            if (_invoice!.clientAddress?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _invoice!.clientAddress!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              'Issue Date',
              DateFormat('MMM dd, yyyy').format(_invoice!.issueDate),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Due Date',
              DateFormat('MMM dd, yyyy').format(_invoice!.dueDate),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Days Until Due',
              _invoice!.dueDate.difference(DateTime.now()).inDays.toString(),
              valueColor: _invoice!.dueDate.isBefore(DateTime.now())
                  ? Colors.red
                  : _invoice!.dueDate.difference(DateTime.now()).inDays <= 7
                  ? Colors.orange
                  : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildLineItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Line Items',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoice!.items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _invoice!.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(item.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Rate: ${NumberFormat.currency(symbol: '\$').format(item.rate)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', _invoice!.subtotal),
            if (_invoice!.discount > 0) ...[
              const SizedBox(height: 8),
              _buildTotalRow('Discount', -_invoice!.discount),
            ],
            if (_invoice!.taxAmount > 0) ...[
              const SizedBox(height: 8),
              _buildTotalRow(
                'Tax (${_invoice!.taxPercentage.toStringAsFixed(1)}%)',
                _invoice!.taxAmount,
              ),
            ],
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            _buildTotalRow('Total', _invoice!.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$').format(amount),
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_invoice!.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_invoice!.terms!),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_invoice!.status == InvoiceStatus.draft) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendInvoice,
              icon: const Icon(Icons.send),
              label: const Text('Send Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_invoice!.status == InvoiceStatus.sent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markAsPaid,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editInvoice,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareInvoice,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editInvoice();
        break;
      case 'duplicate':
        _duplicateInvoice();
        break;
      case 'share':
        _shareInvoice();
        break;
      case 'send':
        _sendInvoice();
        break;
      case 'mark_paid':
        _markAsPaid();
        break;
      case 'delete':
        _deleteInvoice();
        break;
    }
  }

  void _editInvoice() {
    context.push('/invoices/${widget.invoiceId}/edit');
  }

  Future<void> _duplicateInvoice() async {
    final result = await ref
        .read(invoiceProvider.notifier)
        .duplicateInvoice(widget.invoiceId);

    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice duplicated successfully')),
      );
    }
  }

  Future<void> _shareInvoice() async {
    try {
      // Generate PDF and share
      final pdfUrl = await ref
          .read(invoiceProvider.notifier)
          .generateInvoicePDF(widget.invoiceId);

      if (pdfUrl != null) {
        await Share.share(
          'Invoice ${_invoice!.invoiceNumber}\n\nTotal: ${NumberFormat.currency(symbol: '\$').format(_invoice!.total)}\n\nView PDF: $pdfUrl',
          subject: 'Invoice ${_invoice!.invoiceNumber}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing invoice: $e')));
      }
    }
  }

  Future<void> _sendInvoice() async {
    final result = await ref
        .read(invoiceProvider.notifier)
        .sendInvoice(widget.invoiceId);

    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice sent to ${_invoice!.clientName}')),
      );
      await _loadInvoice(); // Reload to update status
    }
  }

  Future<void> _markAsPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark invoice ${_invoice!.invoiceNumber} as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref
          .read(invoiceProvider.notifier)
          .markInvoiceAsPaid(widget.invoiceId);

      if (result.success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice marked as paid')));
        await _loadInvoice(); // Reload to update status
      }
    }
  }

  Future<void> _deleteInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete invoice ${_invoice!.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref
          .read(invoiceProvider.notifier)
          .deleteInvoice(widget.invoiceId);

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully')),
        );
        context.pop();
      }
    }
  }
}
