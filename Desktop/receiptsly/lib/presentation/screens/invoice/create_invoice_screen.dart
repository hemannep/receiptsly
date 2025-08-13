// lib/presentation/screens/invoice/create_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/invoice/invoice_model.dart';
import '../../../data/models/invoice/invoice_item_model.dart';
import '../../../data/models/client/client_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/layouts/app_scaffold.dart';
import 'widgets/client_selector.dart';
import 'widgets/line_item_form.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String? invoiceId; // For editing existing invoice

  const CreateInvoiceScreen({
    super.key,
    this.invoiceId,
  });

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();
  final _taxPercentageController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  
  // Form data
  ClientModel? _selectedClient;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<InvoiceItemModel> _lineItems = [
    InvoiceItemModel(
      id: '',
      description: '',
      quantity: 1,
      rate: 0,
      amount: 0,
    ),
  ];
  
  bool _isLoading = false;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientProvider.notifier).loadClients();
      if (widget.invoiceId != null) {
        _loadExistingInvoice();
      }
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    _taxPercentageController.dispose();
    _discountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Generate invoice number
    final now = DateTime.now();
    _invoiceNumberController.text = 'INV-${DateFormat('yyyyMMdd').format(now)}-001';
    
    // Set default terms
    _termsController.text = 'Payment due within 30 days of invoice date.';
  }

  Future<void> _loadExistingInvoice() async {
    if (widget.invoiceId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final invoice = await ref.read(invoiceProvider.notifier)
          .getInvoiceById(widget.invoiceId!);
      
      if (invoice != null && mounted) {
        _populateFormWithInvoice(invoice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoice: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateFormWithInvoice(InvoiceModel invoice) {
    setState(() {
      _invoiceNumberController.text = invoice.invoiceNumber;
      _selectedClient = ClientModel(
        id: invoice.clientId,
        name: invoice.clientName,
        email: invoice.clientEmail,
        address: invoice.clientAddress ?? '',
        phone: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _issueDate = invoice.issueDate;
      _dueDate = invoice.dueDate;
      _lineItems = List.from(invoice.items);
      _notesController.text = invoice.notes ?? '';
      _termsController.text = invoice.terms ?? '';
      _taxPercentageController.text = invoice.taxPercentage.toString();
      _discountController.text = invoice.discount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    
    return AppScaffold(
      title: widget.invoiceId != null ? 'Edit Invoice' : 'Create Invoice',
      actions: [
        IconButton(
          icon: const Icon(Icons.preview),
          onPressed: _isLoading ? null : _previewInvoice,
          tooltip: 'Preview',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildBasicDetails(clientState),
                        const SizedBox(height: 24),
                        _buildLineItems(),
                        const SizedBox(height: 24),
                        _buildTotalsSection(),
                        const SizedBox(height: 24),
                        _buildAdvancedOptions(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                        const SizedBox(height: 100), // Bottom padding for FAB
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicDetails(ClientProviderState clientState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Invoice Number
            AppTextField(
              controller: _invoiceNumberController,
              label: 'Invoice Number',
              validator: Validators.required,
              prefixIcon: Icons.receipt,
            ),
            const SizedBox(height: 16),
            
            // Client Selector
            ClientSelector(
              selectedClient: _selectedClient,
              clients: clientState.clients,
              onClientSelected: (client) {
                setState(() {
                  _selectedClient = client;
                });
              },
              isLoading: clientState.isLoading,
            ),
            const SizedBox(height: 16),
            
            // Date Fields
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Issue Date',
                    date: _issueDate,
                    onDateSelected: (date) {
                      setState(() {
                        _issueDate = date;
                        // Auto-update due date to 30 days later
                        _dueDate = date.add(const Duration(days: 30));
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Due Date',
                    date: _dueDate,
                    onDateSelected: (date) {
                      setState(() {
                        _dueDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _addLineItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Line Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lineItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return LineItemForm(
                  item: _lineItems[index],
                  onChanged: (updatedItem) {
                    setState(() {
                      _lineItems[index] = updatedItem;
                    });
                  },
                  onRemove: _lineItems.length > 1 
                      ? () => _removeLineItem(index)
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    final subtotal = _calculateSubtotal();
    final taxPercentage = double.tryParse(_taxPercentageController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final taxAmount = (subtotal * taxPercentage) / 100;
    final total = subtotal + taxAmount - discount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal', subtotal),
            const SizedBox(height: 8),
            
            // Discount Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount:'),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tax Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax:'),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _taxPercentageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _buildTotalRow('Tax Amount', taxAmount),
            const Divider(thickness: 2),
            _buildTotalRow('Total', total, isTotal: true),
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

  Widget _buildAdvancedOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _showAdvancedOptions = !_showAdvancedOptions;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Additional Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Icon(
                    _showAdvancedOptions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
            
            if (_showAdvancedOptions) ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                label: 'Notes',
                maxLines: 3,
                hintText: 'Add any additional notes for this invoice...',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _termsController,
                label: 'Terms & Conditions',
                maxLines: 3,
                hintText: 'Payment terms and conditions...',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Save as Draft',
                onPressed: () => _saveInvoice(InvoiceStatus.draft),
                variant: AppButtonVariant.outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                text: widget.invoiceId != null ? 'Update Invoice' : 'Create & Send',
                onPressed: () => _saveInvoice(
                  widget.invoiceId != null ? InvoiceStatus.draft : InvoiceStatus.sent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(InvoiceItemModel(
        id: '',
        description: '',
        quantity: 1,
        rate: 0,
        amount: 0,
      ));
    });
    
    // Scroll to bottom to show new item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });}