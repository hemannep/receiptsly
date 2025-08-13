// lib/presentation/screens/invoice/payment_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../../data/models/payment/payment_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/layouts/app_scaffold.dart';
import 'widgets/payment_status_badge.dart';

class PaymentTrackingScreen extends ConsumerStatefulWidget {
  const PaymentTrackingScreen({super.key});

  @override
  ConsumerState<PaymentTrackingScreen> createState() => _PaymentTrackingScreenState();
}

class _PaymentTrackingScreenState extends ConsumerState<PaymentTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceProvider.notifier).loadInvoices();
      ref.read(paymentProvider.notifier).loadPayments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);
    final paymentState = ref.watch(paymentProvider);
    
    return AppScaffold(
      title: 'Payment Tracking',
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              _selectedPeriod = value;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'all', child: Text('All Time')),
            const PopupMenuItem(value: 'month', child: Text('This Month')),
            const PopupMenuItem(value: 'quarter', child: Text('This Quarter')),
            const PopupMenuItem(value: 'year', child: Text('This Year')),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getPeriodDisplayName()),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(invoiceState.invoices, paymentState.payments),
          
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Outstanding'),
                Tab(text: 'Overdue'),
                Tab(text: 'Paid'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: invoiceState.isLoading || paymentState.isLoading
                ? const AppLoader()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOutstandingInvoices(invoiceState.invoices),
                      _buildOverdueInvoices(invoiceState.invoices),
                      _buildPaidInvoices(invoiceState.invoices, paymentState.payments),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<InvoiceModel> invoices, List<PaymentModel> payments) {
    final filteredInvoices = _filterInvoicesByPeriod(invoices);
    final filteredPayments = _filterPaymentsByPeriod(payments);
    
    final totalOutstanding = filteredInvoices
        .where((i) => i.status == InvoiceStatus.sent)
        .fold(0.0, (sum, i) => sum + i.total);
    
    final totalOverdue = filteredInvoices
        .where((i) => i.status == InvoiceStatus.sent && i.dueDate.isBefore(DateTime.now()))
        .fold(0.0, (sum, i) => sum + i.total);
    
    final totalPaid = filteredPayments
        .fold(0.0, (sum, p) => sum + p.amount);
    
    final overdueCount = filteredInvoices
        .where((i) => i.status == InvoiceStatus.sent && i.dueDate.isBefore(DateTime.now()))
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Outstanding',
              NumberFormat.currency(symbol: '\$').format(totalOutstanding),
              Icons.schedule,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Overdue',
              NumberFormat.currency(symbol: '\$').format(totalOverdue),
              Icons.warning,
              Colors.red,
              subtitle: '$overdueCount invoices',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Paid',
              NumberFormat.currency(symbol: '\$').format(totalPaid),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingInvoices(List<InvoiceModel> invoices) {
    final outstanding = _filterInvoicesByPeriod(invoices)
        .where((i) => i.status == InvoiceStatus.sent)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (outstanding.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No outstanding invoices',
        subtitle: 'All invoices have been paid',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(invoiceProvider.notifier).loadInvoices();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: outstanding.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invoice = outstanding[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildOverdueInvoices(List<InvoiceModel> invoices) {
    final overdue = _filterInvoicesByPeriod(invoices)
        .where((i) => i.status == InvoiceStatus.sent && i.dueDate.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (overdue.isEmpty) {
      return const EmptyState(
        icon: Icons.thumb_up_outlined,
        title: 'No overdue invoices',
        subtitle: 'Great job staying on top of payments!',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(invoiceProvider.notifier).loadInvoices();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: overdue.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invoice = overdue[index];
          return _buildInvoiceCard(invoice, isOverdue: true);
        },
      ),
    );
  }

  Widget _buildPaidInvoices(List<InvoiceModel> invoices, List<PaymentModel> payments) {
    final paid = _filterInvoicesByPeriod(invoices)
        .where((i) => i.status == InvoiceStatus.paid)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (paid.isEmpty) {
      return const EmptyState(
        icon: Icons.payment,
        title: 'No paid invoices',
        subtitle: 'Paid invoices will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(invoiceProvider.notifier).loadInvoices();
        await ref.read(paymentProvider.notifier).loadPayments();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: paid.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invoice = paid[index];
          final payment = payments
              .where((p) => p.invoiceId == invoice.id)
              .firstOrNull;
          return _buildPaidInvoiceCard(invoice, payment);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, {bool isOverdue = false}) {
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;
    
    return Card(
      elevation: isOverdue ? 4 : 2,
      color: isOverdue ? Colors.red.shade50 : null,
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                        const SizedBox(height: 4),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: '\$').format(invoice.total),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PaymentStatusBadge(status: invoice.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (isOverdue)
                    Text(
                      '${daysUntilDue.abs()} days overdue',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (daysUntilDue <= 7)
                    Text(
                      daysUntilDue == 0
                          ? 'Due today'
                          : 'Due in $daysUntilDue days',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysUntilDue <= 3 ? Colors.orange : Colors.grey[600],
                        fontWeight: daysUntilDue <= 3 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              
              if (isOverdue) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendReminder(invoice),
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('Send Reminder'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsPaid(invoice),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaidInvoiceCard(InvoiceModel invoice, PaymentModel? payment) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                        const SizedBox(height: 4),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: '\).format(invoice.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PaymentStatusBadge(status: invoice.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    payment != null
                        ? 'Paid on ${DateFormat('MMM dd, yyyy').format(payment.paidAt)}'
                        : 'Marked as paid',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (payment?.method != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment!.method,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (payment?.reference?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ref: ${payment!.reference}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<InvoiceModel> _filterInvoicesByPeriod(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return invoices.where((i) => 
          i.issueDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          i.issueDate.isBefore(endOfMonth.add(const Duration(days: 1)))
        ).toList();
        
      case 'quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startOfQuarter = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        final endOfQuarter = DateTime(now.year, quarter * 3 + 1, 0);
        return invoices.where((i) => 
          i.issueDate.isAfter(startOfQuarter.subtract(const Duration(days: 1))) &&
          i.issueDate.isBefore(endOfQuarter.add(const Duration(days: 1)))
        ).toList();
        
      case 'year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return invoices.where((i) => 
          i.issueDate.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
          i.issueDate.isBefore(endOfYear.add(const Duration(days: 1)))
        ).toList();
        
      default:
        return invoices;
    }
  }

  List<PaymentModel> _filterPaymentsByPeriod(List<PaymentModel> payments) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return payments.where((p) => 
          p.paidAt.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          p.paidAt.isBefore(endOfMonth.add(const Duration(days: 1)))
        ).toList();
        
      case 'quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startOfQuarter = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        final endOfQuarter = DateTime(now.year, quarter * 3 + 1, 0);
        return payments.where((p) => 
          p.paidAt.isAfter(startOfQuarter.subtract(const Duration(days: 1))) &&
          p.paidAt.isBefore(endOfQuarter.add(const Duration(days: 1)))
        ).toList();
        
      case 'year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return payments.where((p) => 
          p.paidAt.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
          p.paidAt.isBefore(endOfYear.add(const Duration(days: 1)))
        ).toList();
        
      default:
        return payments;
    }
  }

  String _getPeriodDisplayName() {
    switch (_selectedPeriod) {
      case 'month':
        return 'This Month';
      case 'quarter':
        return 'This Quarter';
      case 'year':
        return 'This Year';
      default:
        return 'All Time';
    }
  }

  Future<void> _sendReminder(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Payment Reminder'),
        content: Text(
          'Send a payment reminder for invoice ${invoice.invoiceNumber} to ${invoice.clientName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await ref.read(invoiceProvider.notifier)
            .sendPaymentReminder(invoice.id);
        
        if (result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment reminder sent to ${invoice.clientName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to send reminder'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsPaid(InvoiceModel invoice) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _PaymentDialog(invoice: invoice),
    );

    if (result != null) {
      try {
        final paymentResult = await ref.read(invoiceProvider.notifier)
            .markInvoiceAsPaid(invoice.id, result);
        
        if (paymentResult.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice marked as paid'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          ref.read(invoiceProvider.notifier).loadInvoices();
          ref.read(paymentProvider.notifier).loadPayments();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.error ?? 'Failed to mark as paid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _PaymentDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const _PaymentDialog({required this.invoice});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  
  DateTime _paidDate = DateTime.now();
  String _paymentMethod = 'Bank Transfer';
  
  final List<String> _paymentMethods = [
    'Bank Transfer',
    'Credit Card',
    'PayPal',
    'Stripe',
    'Cash',
    'Check',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invoice: ${widget.invoice.invoiceNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  prefixText: '\,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _paidDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _paidDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Date',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_paidDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference/Transaction ID',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _recordPayment,
          child: const Text('Record Payment'),
        ),
      ],
    );
  }

  void _recordPayment() {
    if (!_formKey.currentState!.validate()) return;

    final paymentData = {
      'amount': double.parse(_amountController.text),
      'method': _paymentMethod,
      'paidAt': _paidDate,
      'reference': _referenceController.text.trim(),
    };

    Navigator.of(context).pop(paymentData);
  }
}