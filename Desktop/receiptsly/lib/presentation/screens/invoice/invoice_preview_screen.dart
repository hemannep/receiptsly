// lib/presentation/screens/invoice/invoice_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/layouts/app_scaffold.dart';
import 'widgets/payment_status_badge.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
  });

  @override
  ConsumerState<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  bool _isGeneratingPDF = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Invoice Preview',
      actions: [
        IconButton(
          onPressed: _isGeneratingPDF ? null : _downloadPDF,
          icon: _isGeneratingPDF 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          tooltip: 'Download PDF',
        ),
        IconButton(
          onPressed: _shareInvoice,
          icon: const Icon(Icons.share),
          tooltip: 'Share',
        ),
      ],
      body: Column(
        children: [
          // Preview Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildInvoicePreview(),
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildInvoiceHeader(),
        const SizedBox(height: 32),
        
        // Company and Client Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCompanyInfo()),
            const SizedBox(width: 32),
            Expanded(child: _buildClientInfo()),
          ],
        ),
        const SizedBox(height: 32),
        
        // Invoice Details
        _buildInvoiceDetails(),
        const SizedBox(height: 32),
        
        // Line Items Table
        _buildLineItemsTable(),
        const SizedBox(height: 24),
        
        // Totals
        _buildTotalsSection(),
        
        // Notes and Terms
        if (widget.invoice.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 32),
          _buildNotesSection(),
        ],
        
        if (widget.invoice.terms?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          _buildTermsSection(),
        ],
      ],
    );
  }

  Widget _buildInvoiceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INVOICE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.invoice.invoiceNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        PaymentStatusBadge(status: widget.invoice.status),
      ],
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FROM:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your Business Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'your.email@business.com',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        const Text(
          '+1 (555) 123-4567',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        const Text(
          '123 Business St\nCity, State 12345',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILL TO:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.invoice.clientName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.invoice.clientEmail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.invoice.clientEmail,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
        if (widget.invoice.clientAddress?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            widget.invoice.clientAddress!,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailItem(
              'Issue Date',
              DateFormat('MMM dd, yyyy').format(widget.invoice.issueDate),
            ),
          ),
          Expanded(
            child: _buildDetailItem(
              'Due Date',
              DateFormat('MMM dd, yyyy').format(widget.invoice.dueDate),
            ),
          ),
          Expanded(
            child: _buildDetailItem(
              'Amount Due',
              NumberFormat.currency(symbol: '\).format(widget.invoice.total),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'QTY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'RATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  'AMOUNT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        
        // Table Body
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.invoice.items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final item = widget.invoice.items[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        NumberFormat.currency(symbol: '\).format(item.rate),
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        NumberFormat.currency(symbol: '\).format(item.amount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            _buildTotalRow('Subtotal:', widget.invoice.subtotal),
            if (widget.invoice.discount > 0) ...[
              const SizedBox(height: 8),
              _buildTotalRow('Discount:', -widget.invoice.discount),
            ],
            if (widget.invoice.taxAmount > 0) ...[
              const SizedBox(height: 8),
              _buildTotalRow(
                'Tax (${widget.invoice.taxPercentage.toStringAsFixed(1)}%):',
                widget.invoice.taxAmount,
              ),
            ],
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            _buildTotalRow(
              'TOTAL:',
              widget.invoice.total,
              isTotal: true,
            ),
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
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\).format(amount),
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTES:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.invoice.notes!,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TERMS & CONDITIONS:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.invoice.terms!,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (widget.invoice.status == InvoiceStatus.draft) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendInvoice,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editInvoice,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
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
            child: ElevatedButton.icon(
              onPressed: _downloadPDF,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _downloadPDF() async {
    setState(() => _isGeneratingPDF = true);
    
    try {
      final pdfUrl = await ref.read(invoiceProvider.notifier)
          .generateInvoicePDF(widget.invoice.id);
      
      if (pdfUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
        // Handle PDF download/opening logic here
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  Future<void> _shareInvoice() async {
    try {
      final pdfUrl = await ref.read(invoiceProvider.notifier)
          .generateInvoicePDF(widget.invoice.id);
      
      if (pdfUrl != null) {
        await Share.share(
          'Invoice ${widget.invoice.invoiceNumber}\n\n'
          'Amount: ${NumberFormat.currency(symbol: '\).format(widget.invoice.total)}\n'
          'Due Date: ${DateFormat('MMM dd, yyyy').format(widget.invoice.dueDate)}\n\n'
          'View PDF: $pdfUrl',
          subject: 'Invoice ${widget.invoice.invoiceNumber}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    }
  }

  Future<void> _sendInvoice() async {
    setState(() => _isSending = true);
    
    try {
      final result = await ref.read(invoiceProvider.notifier)
          .sendInvoice(widget.invoice.id);
      
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice sent to ${widget.invoice.clientName}'),
          ),
        );
        context.pop(); // Go back to invoice list
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to send invoice')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending invoice: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    try {
      final result = await ref.read(invoiceProvider.notifier)
          .createInvoice(widget.invoice);
      
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved as draft')),
        );
        context.pop(); // Go back to invoice list
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to save invoice')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    }
  }

  void _editInvoice() {
    context.pop(); // Go back to edit screen
  }
}}