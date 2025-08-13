// lib/presentation/screens/invoice/widgets/line_item_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/invoice/invoice_item_model.dart';

class LineItemForm extends StatefulWidget {
  final InvoiceItemModel item;
  final ValueChanged<InvoiceItemModel> onChanged;
  final VoidCallback? onRemove;
  final bool isReadOnly;

  const LineItemForm({
    super.key,
    required this.item,
    required this.onChanged,
    this.onRemove,
    this.isReadOnly = false,
  });

  @override
  State<LineItemForm> createState() => _LineItemFormState();
}

class _LineItemFormState extends State<LineItemForm> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _rateController = TextEditingController(
      text: widget.item.rate.toStringAsFixed(2),
    );

    // Add listeners to auto-calculate amount
    _quantityController.addListener(_calculateAmount);
    _rateController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LineItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controllers if item changed externally
    if (widget.item != oldWidget.item) {
      _descriptionController.text = widget.item.description;
      _quantityController.text = widget.item.quantity.toString();
      _rateController.text = widget.item.rate.toStringAsFixed(2);
    }
  }

  void _calculateAmount() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final amount = quantity * rate;

    final updatedItem = InvoiceItemModel(
      id: widget.item.id,
      description: _descriptionController.text,
      quantity: quantity,
      rate: rate,
      amount: amount,
    );

    widget.onChanged(updatedItem);
  }

  void _updateDescription() {
    final updatedItem = InvoiceItemModel(
      id: widget.item.id,
      description: _descriptionController.text,
      quantity: widget.item.quantity,
      rate: widget.item.rate,
      amount: widget.item.amount,
    );

    widget.onChanged(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remove button
          Row(
            children: [
              Expanded(
                child: Text(
                  'Line Item',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (widget.onRemove != null && !widget.isReadOnly)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  tooltip: 'Remove item',
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Enter item description',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            readOnly: widget.isReadOnly,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _updateDescription(),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Description is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Quantity, Rate, and Amount row
          Row(
            children: [
              // Quantity
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: widget.isReadOnly,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Required';
                    }
                    final qty = int.tryParse(value!);
                    if (qty == null || qty <= 0) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Rate
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _rateController,
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  readOnly: widget.isReadOnly,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Required';
                    }
                    final rate = double.tryParse(value!);
                    if (rate == null || rate < 0) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Amount (calculated, read-only)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(
                          symbol: '\$',
                        ).format(widget.item.amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Quick actions for common items (if not read-only)
          if (!widget.isReadOnly) ...[
            const SizedBox(height: 12),
            _buildQuickActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final commonItems = [
      {'name': 'Consultation', 'rate': 100.0},
      {'name': 'Development', 'rate': 150.0},
      {'name': 'Design', 'rate': 80.0},
      {'name': 'Project Management', 'rate': 120.0},
      {'name': 'Travel Expenses', 'rate': 0.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Fill:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: commonItems.map((item) {
            return ActionChip(
              label: Text(
                item['name'] as String,
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () => _fillCommonItem(item),
              backgroundColor: Colors.blue.shade50,
              labelStyle: TextStyle(color: Colors.blue.shade700),
              side: BorderSide(color: Colors.blue.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _fillCommonItem(Map<String, dynamic> item) {
    setState(() {
      _descriptionController.text = item['name'] as String;
      _quantityController.text = '1';
      _rateController.text = (item['rate'] as double).toStringAsFixed(2);
    });

    _updateDescription();
    _calculateAmount();
  }
}
