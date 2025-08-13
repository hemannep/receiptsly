// lib/presentation/screens/receipt/receipt_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../domain/entities/receipt_entity.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/category_selector.dart';

class ReceiptEditScreen extends ConsumerStatefulWidget {
  final String receiptId;
  final bool isNew;

  const ReceiptEditScreen({
    super.key,
    required this.receiptId,
    this.isNew = false,
  });

  @override
  ConsumerState<ReceiptEditScreen> createState() => _ReceiptEditScreenState();
}

class _ReceiptEditScreenState extends ConsumerState<ReceiptEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _tipAmountController = TextEditingController();
  final _paymentMethodController = TextEditingController();

  // Form state
  DateTime _selectedDate = DateTime.now();
  CategoryEntity? _selectedCategory;
  String _selectedCurrency = 'USD';
  ReceiptStatus _selectedStatus = ReceiptStatus.processed;
  List<ReceiptItem> _items = [];
  File? _newImageFile;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReceiptData();
    _setupFormListeners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _vendorController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _taxAmountController.dispose();
    _tipAmountController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _setupFormListeners() {
    _vendorController.addListener(_onFormChanged);
    _amountController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _taxAmountController.addListener(_onFormChanged);
    _tipAmountController.addListener(_onFormChanged);
    _paymentMethodController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _loadReceiptData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isNew) {
        ref
            .read(receiptDetailProvider(widget.receiptId).notifier)
            .loadReceipt();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptDetailProvider(widget.receiptId));

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(context),
        body: receiptState.when(
          loading: () => _buildLoadingState(),
          error: (error, _) => _buildErrorState(error.toString()),
          data: (receipt) {
            _populateForm(receipt);
            return _buildForm(context, receipt);
          },
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.isNew ? 'New Receipt' : 'Edit Receipt'),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        if (_hasUnsavedChanges)
          TextButton(
            onPressed: _saveReceipt,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoader(),
          SizedBox(height: 16),
          Text('Loading receipt...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load receipt',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReceiptData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, ReceiptEntity? receipt) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(receipt),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildAmountSection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildDateSection(),
              const SizedBox(height: 24),
              _buildOptionalInfoSection(),
              const SizedBox(height: 24),
              _buildItemsSection(),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ReceiptEntity? receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Receipt Image'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _changeImage,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreview(receipt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ReceiptEntity? receipt) {
    if (_newImageFile != null) {
      return Image.file(_newImageFile!, fit: BoxFit.cover);
    } else if (receipt?.imageUrl != null) {
      return Image.network(
        receipt!.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: AppLoader());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Failed to load image'),
              ],
            ),
          );
        },
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image selected'),
          ],
        ),
      );
    }
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Basic Information'),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _vendorController,
              label: 'Vendor/Store Name',
              hintText: 'Enter vendor name',
              prefixIcon: Icons.business,
              validator: Validators.required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hintText: 'Add description or notes',
              prefixIcon: Icons.description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Amount Details'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _amountController,
                    label: 'Total Amount',
                    hintText: '0.00',
                    prefixIcon: Icons.payment,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.amount,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency['code'],
                        child: Text(
                          '${currency['code']} ${currency['symbol']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                        _onFormChanged();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _taxAmountController,
                    label: 'Tax Amount',
                    hintText: '0.00',
                    prefixIcon: Icons.receipt,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _tipAmountController,
                    label: 'Tip Amount',
                    hintText: '0.00',
                    prefixIcon: Icons.thumb_up,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Category'),
              ],
            ),
            const SizedBox(height: 16),
            CategorySelector(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                  _onFormChanged();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Date'),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Additional Information'),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _paymentMethodController,
              label: 'Payment Method',
              hintText: 'Cash, Credit Card, etc.',
              prefixIcon: Icons.payment,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Items'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text(
                    'No items added\nTap "Add Item" to add receipt items',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildItemRow(index, item);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, ReceiptItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                CurrencyFormatter.format(item.amount),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          if (item.quantity > 1)
            Row(
              children: [
                Text(
                  'Quantity: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Status'),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReceiptStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Receipt Status',
              ),
              items: ReceiptStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                  _onFormChanged();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!widget.isNew) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleteReceipt,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: AppButton(
                onPressed: _isSaving ? null : _saveReceipt,
                isLoading: _isSaving,
                child: Text(widget.isNew ? 'Create Receipt' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _populateForm(ReceiptEntity receipt) {
    if (_vendorController.text.isEmpty) {
      _vendorController.text = receipt.vendor;
      _amountController.text = receipt.amount.toString();
      _descriptionController.text = receipt.description ?? '';
      _taxAmountController.text = receipt.taxAmount.toString();
      _tipAmountController.text = receipt.tipAmount.toString();
      _paymentMethodController.text = receipt.paymentMethod ?? '';
      _selectedDate = receipt.date;
      _selectedCategory = receipt.category;
      _selectedCurrency = receipt.currency;
      _selectedStatus = receipt.status;
      _items = List.from(receipt.items);
    }
  }

  Color _getStatusColor(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.processed:
        return AppColors.success;
      case ReceiptStatus.pendingReview:
        return AppColors.warning;
      case ReceiptStatus.rejected:
        return AppColors.error;
      case ReceiptStatus.draft:
        return AppColors.secondary;
    }
  }

  Future<void> _changeImage() async {
    final ImagePicker picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image != null) {
        setState(() {
          _newImageFile = File(image.path);
          _onFormChanged();
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _onFormChanged();
      });
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _ItemDialog(
        onSave: (item) {
          setState(() {
            _items.add(item);
            _onFormChanged();
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _onFormChanged();
    });
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate()) {
      AppSnackbar.showError(context, 'Please fix the errors in the form');
      return;
    }

    if (_selectedCategory == null) {
      AppSnackbar.showError(context, 'Please select a category');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final receiptData = ReceiptEntity(
        id: widget.receiptId,
        vendor: _vendorController.text.trim(),
        amount: double.parse(
          _amountController.text.isNotEmpty ? _amountController.text : '0',
        ),
        date: _selectedDate,
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        taxAmount: double.parse(
          _taxAmountController.text.isNotEmpty
              ? _taxAmountController.text
              : '0',
        ),
        tipAmount: double.parse(
          _tipAmountController.text.isNotEmpty
              ? _tipAmountController.text
              : '0',
        ),
        currency: _selectedCurrency,
        paymentMethod: _paymentMethodController.text.trim().isNotEmpty
            ? _paymentMethodController.text.trim()
            : null,
        status: _selectedStatus,
        items: _items,
        imageUrl: null, // Will be set by the provider
        userId: '',
        source: 'manual',
        ocrConfidence: 0.0,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.isNew) {
        await ref
            .read(receiptProviderProvider.notifier)
            .createReceipt(receiptData, imageFile: _newImageFile);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Receipt created successfully');
          context.pop();
        }
      } else {
        await ref
            .read(receiptProviderProvider.notifier)
            .updateReceipt(receiptData, imageFile: _newImageFile);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Receipt updated successfully');
          setState(() => _hasUnsavedChanges = false);
        }
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to save receipt: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text(
          'Are you sure you want to delete this receipt? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(receiptProviderProvider.notifier)
            .deleteReceipt(widget.receiptId);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Receipt deleted successfully');
          context.pop();
        }
      } catch (e) {
        AppSnackbar.showError(context, 'Failed to delete receipt');
      }
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _hasUnsavedChanges = false);
              context.pop();
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveReceipt();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ItemDialog extends StatefulWidget {
  final Function(ReceiptItem) onSave;
  final ReceiptItem? initialItem;

  const _ItemDialog({required this.onSave, this.initialItem});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _descriptionController.text = widget.initialItem!.description;
      _quantityController.text = widget.initialItem!.quantity.toString();
      _amountController.text = widget.initialItem!.amount.toString();
    } else {
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem != null ? 'Edit Item' : 'Add Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Invalid quantity';
                      }
                      return null;
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveItem, child: const Text('Save')),
      ],
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = ReceiptItem(
      description: _descriptionController.text.trim(),
      quantity: int.parse(_quantityController.text),
      amount: double.parse(_amountController.text),
    );

    widget.onSave(item);
    Navigator.pop(context);
  }
}
