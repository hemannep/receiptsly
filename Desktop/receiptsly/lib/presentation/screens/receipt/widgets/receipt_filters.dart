// lib/presentation/screens/receipt/widgets/receipt_filters.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/receipt_entity.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/category_provider.dart';
import '../../../widgets/common/app_button.dart';

class ReceiptFilters extends ConsumerStatefulWidget {
  const ReceiptFilters({super.key});

  @override
  ConsumerState<ReceiptFilters> createState() => _ReceiptFiltersState();
}

class _ReceiptFiltersState extends ConsumerState<ReceiptFilters>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Filter state
  DateTimeRange? _dateRange;
  RangeValues? _amountRange;
  List<CategoryEntity> _selectedCategories = [];
  List<ReceiptStatus> _selectedStatuses = [];
  List<String> _selectedSources = [];
  double _minConfidence = 0.0;

  // UI state
  bool _isExpanded = false;
  final double _maxAmount = 10000.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialFilters();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _loadInitialFilters() {
    final currentFilters = ref.read(receiptFiltersProvider);
    setState(() {
      _dateRange = currentFilters.dateRange;
      _amountRange = currentFilters.amountRange;
      _selectedCategories = currentFilters.categories;
      _selectedStatuses = currentFilters.statuses;
      _selectedSources = currentFilters.sources;
      _minConfidence = currentFilters.minConfidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                _buildQuickFilters(theme),
                if (_isExpanded) _buildAdvancedFilters(theme),
                _buildActionButtons(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_isExpanded ? 'Less' : 'More'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateRangeChip(theme),
                const SizedBox(width: 8),
                _buildAmountRangeChip(theme),
                const SizedBox(width: 8),
                _buildCategoryChip(theme),
                const SizedBox(width: 8),
                _buildStatusChip(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          _buildSourceFilter(theme),
          const SizedBox(height: 20),
          _buildConfidenceFilter(theme),
          const SizedBox(height: 20),
          _buildDetailedCategoryFilter(theme),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(ThemeData theme) {
    return FilterChip(
      label: Text(
        _dateRange == null
            ? 'Date Range'
            : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
      ),
      selected: _dateRange != null,
      onSelected: (_) => _showDateRangePicker(),
      avatar: const Icon(Icons.calendar_today, size: 16),
      deleteIcon: _dateRange != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: _dateRange != null
          ? () => setState(() => _dateRange = null)
          : null,
    );
  }

  Widget _buildAmountRangeChip(ThemeData theme) {
    return FilterChip(
      label: Text(
        _amountRange == null
            ? 'Amount Range'
            : '${CurrencyFormatter.format(_amountRange!.start)} - ${CurrencyFormatter.format(_amountRange!.end)}',
      ),
      selected: _amountRange != null,
      onSelected: (_) => _showAmountRangePicker(),
      avatar: const Icon(Icons.attach_money, size: 16),
      deleteIcon: _amountRange != null
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: _amountRange != null
          ? () => setState(() => _amountRange = null)
          : null,
    );
  }

  Widget _buildCategoryChip(ThemeData theme) {
    return FilterChip(
      label: Text(
        _selectedCategories.isEmpty
            ? 'Categories'
            : '${_selectedCategories.length} selected',
      ),
      selected: _selectedCategories.isNotEmpty,
      onSelected: (_) => _showCategoryPicker(),
      avatar: const Icon(Icons.category, size: 16),
      deleteIcon: _selectedCategories.isNotEmpty
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: _selectedCategories.isNotEmpty
          ? () => setState(() => _selectedCategories.clear())
          : null,
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    return FilterChip(
      label: Text(
        _selectedStatuses.isEmpty
            ? 'Status'
            : '${_selectedStatuses.length} selected',
      ),
      selected: _selectedStatuses.isNotEmpty,
      onSelected: (_) => _showStatusPicker(),
      avatar: const Icon(Icons.flag, size: 16),
      deleteIcon: _selectedStatuses.isNotEmpty
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: _selectedStatuses.isNotEmpty
          ? () => setState(() => _selectedStatuses.clear())
          : null,
    );
  }

  Widget _buildSourceFilter(ThemeData theme) {
    final availableSources = [
      'manual',
      'camera',
      'whatsapp',
      'telegram',
      'email',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: availableSources.map((source) {
            final isSelected = _selectedSources.contains(source);
            return FilterChip(
              label: Text(_getSourceDisplayName(source)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSources.add(source);
                  } else {
                    _selectedSources.remove(source);
                  }
                });
              },
              avatar: Icon(_getSourceIcon(source), size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfidenceFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Minimum OCR Confidence',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(_minConfidence * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.3),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: _minConfidence,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() => _minConfidence = value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: theme.textTheme.bodySmall),
            Text('50%', style: theme.textTheme.bodySmall),
            Text('100%', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedCategoryFilter(ThemeData theme) {
    final categoryState = ref.watch(categoryListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        categoryState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error loading categories'),
          data: (categories) {
            if (categories.isEmpty) {
              return const Text('No categories available');
            }

            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: categories.map((category) {
                final isSelected = _selectedCategories.any(
                  (c) => c.id == category.id,
                );
                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.removeWhere(
                          (c) => c.id == category.id,
                        );
                      }
                    });
                  },
                  avatar: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, size: 10, color: Colors.white),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final hasActiveFilters =
        _dateRange != null ||
        _amountRange != null ||
        _selectedCategories.isNotEmpty ||
        _selectedStatuses.isNotEmpty ||
        _selectedSources.isNotEmpty ||
        _minConfidence > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          if (hasActiveFilters)
            Expanded(
              child: OutlinedButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear All'),
              ),
            ),
          if (hasActiveFilters) const SizedBox(width: 12),
          Expanded(
            flex: hasActiveFilters ? 2 : 1,
            child: AppButton(
              onPressed: _applyFilters,
              child: Text(hasActiveFilters ? 'Apply Filters' : 'Close'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showAmountRangePicker() {
    showDialog(
      context: context,
      builder: (context) => _AmountRangeDialog(
        initialRange: _amountRange,
        maxAmount: _maxAmount,
        onRangeSelected: (range) {
          setState(() => _amountRange = range);
        },
      ),
    );
  }

  void _showCategoryPicker() {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog<CategoryEntity>(
        title: 'Select Categories',
        items: ref.read(categoryListProvider).value ?? [],
        selectedItems: _selectedCategories,
        itemBuilder: (category) => ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: Colors.white, size: 16),
          ),
          title: Text(category.name),
        ),
        onSelectionChanged: (selected) {
          setState(() => _selectedCategories = selected);
        },
      ),
    );
  }

  void _showStatusPicker() {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog<ReceiptStatus>(
        title: 'Select Status',
        items: ReceiptStatus.values,
        selectedItems: _selectedStatuses,
        itemBuilder: (status) => ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getStatusIcon(status), color: Colors.white, size: 16),
          ),
          title: Text(status.displayName),
        ),
        onSelectionChanged: (selected) {
          setState(() => _selectedStatuses = selected);
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _dateRange = null;
      _amountRange = null;
      _selectedCategories.clear();
      _selectedStatuses.clear();
      _selectedSources.clear();
      _minConfidence = 0.0;
    });
  }

  void _applyFilters() {
    final filters = ReceiptFilters(
      dateRange: _dateRange,
      amountRange: _amountRange,
      categories: _selectedCategories,
      statuses: _selectedStatuses,
      sources: _selectedSources,
      minConfidence: _minConfidence,
    );

    ref.read(receiptFiltersProvider.notifier).updateFilters(filters);
    ref.read(receiptListProvider.notifier).applyFilters(filters);
  }

  String _getSourceDisplayName(String source) {
    switch (source) {
      case 'manual':
        return 'Manual';
      case 'camera':
        return 'Camera';
      case 'whatsapp':
        return 'WhatsApp';
      case 'telegram':
        return 'Telegram';
      case 'email':
        return 'Email';
      default:
        return source.toUpperCase();
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'manual':
        return Icons.edit;
      case 'camera':
        return Icons.camera_alt;
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.send;
      case 'email':
        return Icons.email;
      default:
        return Icons.source;
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

  IconData _getStatusIcon(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.processed:
        return Icons.check_circle;
      case ReceiptStatus.pendingReview:
        return Icons.pending;
      case ReceiptStatus.rejected:
        return Icons.cancel;
      case ReceiptStatus.draft:
        return Icons.draft;
    }
  }
}

class _AmountRangeDialog extends StatefulWidget {
  final RangeValues? initialRange;
  final double maxAmount;
  final Function(RangeValues) onRangeSelected;

  const _AmountRangeDialog({
    this.initialRange,
    required this.maxAmount,
    required this.onRangeSelected,
  });

  @override
  State<_AmountRangeDialog> createState() => _AmountRangeDialogState();
}

class _AmountRangeDialogState extends State<_AmountRangeDialog> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange ?? RangeValues(0, widget.maxAmount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Amount Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CurrencyFormatter.format(_currentRange.start)),
              Text(CurrencyFormatter.format(_currentRange.end)),
            ],
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: _currentRange,
            min: 0,
            max: widget.maxAmount,
            divisions: 100,
            labels: RangeLabels(
              CurrencyFormatter.format(_currentRange.start),
              CurrencyFormatter.format(_currentRange.end),
            ),
            onChanged: (values) {
              setState(() => _currentRange = values);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onRangeSelected(_currentRange);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  final Widget Function(T) itemBuilder;
  final Function(List<T>) onSelectionChanged;

  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.itemBuilder,
    required this.onSelectionChanged,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = _selectedItems.contains(item);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
              title: widget.itemBuilder(item),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelectionChanged(_selectedItems);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// Filter model class
class ReceiptFilters {
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;
  final List<CategoryEntity> categories;
  final List<ReceiptStatus> statuses;
  final List<String> sources;
  final double minConfidence;

  const ReceiptFilters({
    this.dateRange,
    this.amountRange,
    this.categories = const [],
    this.statuses = const [],
    this.sources = const [],
    this.minConfidence = 0.0,
  });

  bool get hasActiveFilters =>
      dateRange != null ||
      amountRange != null ||
      categories.isNotEmpty ||
      statuses.isNotEmpty ||
      sources.isNotEmpty ||
      minConfidence > 0;

  ReceiptFilters copyWith({
    DateTimeRange? dateRange,
    RangeValues? amountRange,
    List<CategoryEntity>? categories,
    List<ReceiptStatus>? statuses,
    List<String>? sources,
    double? minConfidence,
  }) {
    return ReceiptFilters(
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      sources: sources ?? this.sources,
      minConfidence: minConfidence ?? this.minConfidence,
    );
  }
}
