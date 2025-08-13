// lib/presentation/screens/invoice/invoice_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/layouts/app_scaffold.dart';
import 'widgets/invoice_card.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  InvoiceStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);

    return AppScaffold(
      title: 'Invoices',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
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
              tabs: [
                Tab(
                  child: _buildTabWithCount(
                    'All',
                    invoiceState.invoices.length,
                  ),
                ),
                Tab(
                  child: _buildTabWithCount(
                    'Draft',
                    _getInvoicesByStatus(
                      invoiceState.invoices,
                      InvoiceStatus.draft,
                    ).length,
                  ),
                ),
                Tab(
                  child: _buildTabWithCount(
                    'Sent',
                    _getInvoicesByStatus(
                      invoiceState.invoices,
                      InvoiceStatus.sent,
                    ).length,
                  ),
                ),
                Tab(
                  child: _buildTabWithCount(
                    'Paid',
                    _getInvoicesByStatus(
                      invoiceState.invoices,
                      InvoiceStatus.paid,
                    ).length,
                  ),
                ),
              ],
            ),
          ),

          // Search bar (if active)
          if (_searchQuery.isNotEmpty) _buildSearchBar(),

          // Content
          Expanded(
            child: invoiceState.isLoading
                ? const AppLoader()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInvoiceList(_filterInvoices(invoiceState.invoices)),
                      _buildInvoiceList(
                        _filterInvoices(
                          _getInvoicesByStatus(
                            invoiceState.invoices,
                            InvoiceStatus.draft,
                          ),
                        ),
                      ),
                      _buildInvoiceList(
                        _filterInvoices(
                          _getInvoicesByStatus(
                            invoiceState.invoices,
                            InvoiceStatus.sent,
                          ),
                        ),
                      ),
                      _buildInvoiceList(
                        _filterInvoices(
                          _getInvoicesByStatus(
                            invoiceState.invoices,
                            InvoiceStatus.paid,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithCount(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.lightGrey,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search invoices...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildInvoiceList(List<InvoiceModel> invoices) {
    if (invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: 'No invoices found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try adjusting your search criteria'
            : 'Create your first invoice to get started',
        actionText: _searchQuery.isEmpty ? 'Create Invoice' : null,
        onAction: _searchQuery.isEmpty
            ? () => context.push('/invoices/create')
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(invoiceProvider.notifier).loadInvoices();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return InvoiceCard(
            invoice: invoice,
            onTap: () => context.push('/invoices/${invoice.id}'),
            onEdit: () => context.push('/invoices/${invoice.id}/edit'),
            onDuplicate: () => _duplicateInvoice(invoice),
            onDelete: () => _deleteInvoice(invoice),
            onSend: invoice.status == InvoiceStatus.draft
                ? () => _sendInvoice(invoice)
                : null,
          );
        },
      ),
    );
  }

  List<InvoiceModel> _getInvoicesByStatus(
    List<InvoiceModel> invoices,
    InvoiceStatus status,
  ) {
    return invoices.where((invoice) => invoice.status == status).toList();
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> invoices) {
    if (_searchQuery.isEmpty && _selectedStatus == null) {
      return invoices;
    }

    return invoices.where((invoice) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.clientName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatus == null || invoice.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Invoices'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter invoice number or client name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Invoices'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Status:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<InvoiceStatus?>(
              value: _selectedStatus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...InvoiceStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateInvoice(InvoiceModel invoice) async {
    final result = await ref
        .read(invoiceProvider.notifier)
        .duplicateInvoice(invoice.id);
    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice duplicated successfully')),
      );
    }
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
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
          .deleteInvoice(invoice.id);
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully')),
        );
      }
    }
  }

  Future<void> _sendInvoice(InvoiceModel invoice) async {
    final result = await ref
        .read(invoiceProvider.notifier)
        .sendInvoice(invoice.id);
    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice sent to ${invoice.clientName}')),
      );
    }
  }
}
