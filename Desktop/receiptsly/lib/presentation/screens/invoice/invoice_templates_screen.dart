// lib/presentation/screens/invoice/invoice_templates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice/invoice_template_model.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/layouts/app_scaffold.dart';

class InvoiceTemplatesScreen extends ConsumerStatefulWidget {
  const InvoiceTemplatesScreen({super.key});

  @override
  ConsumerState<InvoiceTemplatesScreen> createState() => _InvoiceTemplatesScreenState();
}

class _InvoiceTemplatesScreenState extends ConsumerState<InvoiceTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceProvider.notifier).loadInvoiceTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);
    
    return AppScaffold(
      title: 'Invoice Templates',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _createNewTemplate,
          tooltip: 'Create Template',
        ),
      ],
      body: invoiceState.isLoading
          ? const AppLoader()
          : invoiceState.templates.isEmpty
              ? EmptyState(
                  icon: Icons.description,
                  title: 'No templates found',
                  subtitle: 'Create your first invoice template to speed up invoicing',
                  actionText: 'Create Template',
                  onAction: _createNewTemplate,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(invoiceProvider.notifier).loadInvoiceTemplates();
                  },
                  child: _buildTemplatesList(invoiceState.templates),
                ),
    );
  }

  Widget _buildTemplatesList(List<InvoiceTemplateModel> templates) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(InvoiceTemplateModel template) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleTemplateAction(value, template),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'use',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text('Use Template'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
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
              ),
              const SizedBox(height: 16),
              
              // Template Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Items',
                            '${template.defaultItems.length}',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Tax Rate',
                            '${template.defaultTaxRate.toStringAsFixed(1)}%',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Payment Terms',
                            '${template.defaultPaymentTerms} days',
                          ),
                        ),
                      ],
                    ),
                    if (template.defaultItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Default Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...template.defaultItems.take(3).map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${item.rate.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (template.defaultItems.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${template.defaultItems.length - 3} more items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              
              // Usage Stats
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${_formatDate(template.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (template.usageCount > 0) ...[
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Used ${template.usageCount} times',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _handleTemplateAction(String action, InvoiceTemplateModel template) {
    switch (action) {
      case 'use':
        _useTemplate(template);
        break;
      case 'edit':
        _editTemplate(template);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  void _useTemplate(InvoiceTemplateModel template) {
    context.push('/invoices/create', extra: {'template': template});
  }

  void _editTemplate(InvoiceTemplateModel template) {
    _showTemplateDialog(template: template);
  }

  Future<void> _duplicateTemplate(InvoiceTemplateModel template) async {
    final result = await ref.read(invoiceProvider.notifier)
        .duplicateTemplate(template.id);
    
    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template duplicated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to duplicate template')),
      );
    }
  }

  Future<void> _deleteTemplate(InvoiceTemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
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
      final result = await ref.read(invoiceProvider.notifier)
          .deleteTemplate(template.id);
      
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to delete template')),
        );
      }
    }
  }

  void _createNewTemplate() {
    _showTemplateDialog();
  }

  void _showTemplateDialog({InvoiceTemplateModel? template}) {
    showDialog(
      context: context,
      builder: (context) => _TemplateDialog(template: template),
    ).then((result) {
      if (result == true) {
        ref.read(invoiceProvider.notifier).loadInvoiceTemplates();
      }
    });
  }
}

class _TemplateDialog extends ConsumerStatefulWidget {
  final InvoiceTemplateModel? template;

  const _TemplateDialog({this.template});

  @override
  ConsumerState<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<_TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  List<InvoiceItemModel> _defaultItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _populateFields();
    } else {
      _setDefaults();
    }
  }

  void _populateFields() {
    final template = widget.template!;
    _nameController.text = template.name;
    _descriptionController.text = template.description;
    _taxRateController.text = template.defaultTaxRate.toString();
    _paymentTermsController.text = template.defaultPaymentTerms.toString();
    _notesController.text = template.defaultNotes;
    _termsController.text = template.defaultTerms;
    _defaultItems = List.from(template.defaultItems);
  }

  void _setDefaults() {
    _taxRateController.text = '0';
    _paymentTermsController.text = '30';
    _termsController.text = 'Payment due within 30 days of invoice date.';
    _defaultItems = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _taxRateController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.template != null ? 'Edit Template' : 'Create Template',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Template Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return 'Please enter a template name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      
                      // Default Settings
                      Text(
                        'Default Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxRateController,
                              decoration: const InputDecoration(
                                labelText: 'Tax Rate (%)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _paymentTermsController,
                              decoration: const InputDecoration(
                                labelText: 'Payment Terms (days)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Default Items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Default Items',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: _addDefaultItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_defaultItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No default items added',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _defaultItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _defaultItems[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(item.description),
                                  ),
                                  Expanded(
                                    child: Text('Qty: ${item.quantity}'),
                                  ),
                                  Expanded(
                                    child: Text('\${item.rate.toStringAsFixed(2)}'),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeDefaultItem(index),
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      
                      // Default Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Default Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Default Terms
                      TextFormField(
                        controller: _termsController,
                        decoration: const InputDecoration(
                          labelText: 'Default Terms & Conditions',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTemplate,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.template != null ? 'Update' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addDefaultItem() {
    showDialog(
      context: context,
      builder: (context) => _ItemDialog(),
    ).then((item) {
      if (item != null) {
        setState(() {
          _defaultItems.add(item);
        });
      }
    });
  }

  void _removeDefaultItem(int index) {
    setState(() {
      _defaultItems.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final template = InvoiceTemplateModel(
        id: widget.template?.id ?? '',
        userId: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        defaultItems: _defaultItems,
        defaultTaxRate: double.tryParse(_taxRateController.text) ?? 0,
        defaultPaymentTerms: int.tryParse(_paymentTermsController.text) ?? 30,
        defaultNotes: _notesController.text.trim(),
        defaultTerms: _termsController.text.trim(),
        usageCount: widget.template?.usageCount ?? 0,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = widget.template != null
          ? await ref.read(invoiceProvider.notifier).updateTemplate(template)
          : await ref.read(invoiceProvider.notifier).createTemplate(template);

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.template != null
                  ? 'Template updated successfully'
                  : 'Template created successfully',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to save template')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _ItemDialog extends StatefulWidget {
  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty == true) {
                  return 'Please enter a description';
                }
                return null;
              },
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
                      if (value?.isEmpty == true) {
                        return 'Required';
                      }
                      final qty = int.tryParse(value!);
                      if (qty == null || qty <= 0) {
                        return 'Invalid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(),
                      prefixText: '\of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) {
                        return 'Required';
                      }
                      final rate = double.tryParse(value!);
                      if (rate == null || rate < 0) {
                        return 'Invalid rate';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    final rate = double.parse(_rateController.text);
    final item = InvoiceItemModel(
      id: '',
      description: _descriptionController.text.trim(),
      quantity: quantity,
      rate: rate,
      amount: quantity * rate,
    );

    Navigator.of(context).pop(item);
  }
}of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.