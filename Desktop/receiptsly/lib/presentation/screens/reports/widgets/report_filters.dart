// lib/presentation/screens/reports/widgets/report_filters.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ReportFilters extends StatefulWidget {
  final List<String> selectedCategories;
  final DateTimeRange selectedDateRange;
  final Function(List<String> categories, DateTimeRange dateRange) onFiltersChanged;

  const ReportFilters({
    super.key,
    required this.selectedCategories,
    required this.selectedDateRange,
    required this.onFiltersChanged,
  });

  @override
  State<ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends State<ReportFilters> {
  late List<String> _selectedCategories;
  late DateTimeRange _selectedDateRange;
  
  // Additional filter options
  double _minAmount = 0;
  double _maxAmount = 10000;
  List<String> _selectedClients = [];
  List<String> _selectedVendors = [];
  bool _includeRecurring = true;
  bool _includeTaxDeductible = false;
  String _sortBy = 'date';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
    _selectedDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Filters',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset All'),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Filter Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Section
                    _buildDateRangeSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Categories Section
                    _buildCategoriesSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Amount Range Section
                    _buildAmountRangeSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Clients Section
                    _buildClientsSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Vendors Section
                    _buildVendorsSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Additional Options Section
                    _buildAdditionalOptionsSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Sort Options Section
                    _buildSortOptionsSection(theme),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Date Range', Icons.date_range),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_selectedDateRange.start),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'To',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_selectedDateRange.end),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Change Date Range'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Categories', Icons.category),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.expenseCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategories = List.from(AppConstants.expenseCategories);
                });
              },
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategories.clear();
                });
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Amount Range', Icons.monetization_on),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: '\,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _minAmount.toString(),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0;
                        setState(() {
                          _minAmount = amount;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: '\,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _maxAmount.toString(),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 10000;
                        setState(() {
                          _maxAmount = amount;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              RangeSlider(
                values: RangeValues(_minAmount, _maxAmount),
                min: 0,
                max: 50000,
                divisions: 100,
                labels: RangeLabels(
                  '\${_minAmount.toInt()}',
                  '\${_maxAmount.toInt()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _minAmount = values.start;
                    _maxAmount = values.end;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientsSection(ThemeData theme) {
    // This would typically load clients from a provider
    final availableClients = [
      'John Doe',
      'ABC Corporation',
      'Smith Industries',
      'Tech Solutions Inc.',
      'Green Energy Co.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Clients', Icons.people),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by specific clients',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => _showClientSelector(availableClients),
                    child: Text('${_selectedClients.length} selected'),
                  ),
                ],
              ),
              
              if (_selectedClients.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedClients.map((client) {
                    return Chip(
                      label: Text(client),
                      onDeleted: () {
                        setState(() {
                          _selectedClients.remove(client);
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorsSection(ThemeData theme) {
    // This would typically load vendors from a provider
    final availableVendors = [
      'Office Depot',
      'Amazon',
      'Starbucks',
      'Shell Gas Station',
      'Microsoft',
      'Adobe',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Vendors', Icons.store),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by specific vendors',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => _showVendorSelector(availableVendors),
                    child: Text('${_selectedVendors.length} selected'),
                  ),
                ],
              ),
              
              if (_selectedVendors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedVendors.map((vendor) {
                    return Chip(
                      label: Text(vendor),
                      onDeleted: () {
                        setState(() {
                          _selectedVendors.remove(vendor);
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalOptionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Additional Options', Icons.settings),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Include Recurring Transactions'),
                subtitle: const Text('Show transactions that repeat regularly'),
                value: _includeRecurring,
                onChanged: (value) {
                  setState(() {
                    _includeRecurring = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const Divider(),
              
              SwitchListTile(
                title: const Text('Tax Deductible Only'),
                subtitle: const Text('Show only tax deductible expenses'),
                value: _includeTaxDeductible,
                onChanged: (value) {
                  setState(() {
                    _includeTaxDeductible = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Sort Options', Icons.sort),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                      ),
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'amount', child: Text('Amount')),
                        DropdownMenuItem(value: 'category', child: Text('Category')),
                        DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                        DropdownMenuItem(value: 'client', child: Text('Client')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        border: OutlineInputBorder(),
                      ),
                      value: _sortOrder,
                      items: const [
                        DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                        DropdownMenuItem(value: 'desc', child: Text('Descending')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortOrder = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showClientSelector(List<String> clients) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Clients'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final isSelected = _selectedClients.contains(client);
              
              return CheckboxListTile(
                title: Text(client),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedClients.add(client);
                    } else {
                      _selectedClients.remove(client);
                    }
                  });
                  Navigator.pop(context);
                  _showClientSelector(clients); // Refresh dialog
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showVendorSelector(List<String> vendors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Vendors'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              final isSelected = _selectedVendors.contains(vendor);
              
              return CheckboxListTile(
                title: Text(vendor),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedVendors.add(vendor);
                    } else {
                      _selectedVendors.remove(vendor);
                    }
                  });
                  Navigator.pop(context);
                  _showVendorSelector(vendors); // Refresh dialog
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
      _minAmount = 0;
      _maxAmount = 10000;
      _selectedClients.clear();
      _selectedVendors.clear();
      _includeRecurring = true;
      _includeTaxDeductible = false;
      _sortBy = 'date';
      _sortOrder = 'desc';
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_selectedCategories, _selectedDateRange);
    Navigator.pop(context);
  }
}