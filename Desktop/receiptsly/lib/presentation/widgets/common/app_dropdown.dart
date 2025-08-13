// lib/presentation/widgets/common/app_dropdown.dart
import 'package:flutter/material.dart';

/// Production-ready dropdown widget for Receiptsly app
/// Supports validation, search functionality, and accessibility features
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.isEnabled = true,
    this.isRequired = false,
    this.validator,
    this.isSearchable = false,
    this.searchHint = 'Search...',
    this.noItemsFoundText = 'No items found',
    this.maxHeight = 200.0,
    this.semanticLabel,
    this.testKey,
    this.borderType = AppDropdownBorderType.outline,
    this.density = AppDropdownDensity.standard,
    this.itemBuilder,
    this.displayStringForItem,
  }) : assert(items.isNotEmpty, 'Items list cannot be empty');

  /// List of dropdown items
  final List<AppDropdownItem<T>> items;

  /// Currently selected value
  final T? value;

  /// Callback when selection changes
  final ValueChanged<T?>? onChanged;

  /// Label text displayed above the dropdown
  final String? label;

  /// Hint text displayed when no item is selected
  final String? hint;

  /// Helper text displayed below the dropdown
  final String? helperText;

  /// Error text displayed below the dropdown
  final String? errorText;

  /// Icon displayed at the start of the dropdown
  final IconData? prefixIcon;

  /// Whether the dropdown is enabled
  final bool isEnabled;

  /// Whether the dropdown is required
  final bool isRequired;

  /// Validation function
  final String? Function(T?)? validator;

  /// Whether the dropdown is searchable
  final bool isSearchable;

  /// Hint text for search field
  final String searchHint;

  /// Text shown when no items match search
  final String noItemsFoundText;

  /// Maximum height of the dropdown overlay
  final double maxHeight;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Test key for widget testing
  final String? testKey;

  /// Border style type
  final AppDropdownBorderType borderType;

  /// Dropdown density for compact layouts
  final AppDropdownDensity density;

  /// Custom item builder for dropdown items
  final Widget Function(BuildContext, AppDropdownItem<T>, bool)? itemBuilder;

  /// Function to get display string for an item
  final String Function(T)? displayStringForItem;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  late List<AppDropdownItem<T>> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final displayText =
            widget.displayStringForItem?.call(item.value) ??
            item.label.toLowerCase();
        return displayText.contains(query);
      }).toList();
    });
  }

  void _resetSearch() {
    _searchController.clear();
    _filteredItems = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget dropdown = _buildDropdown(theme);

    // Add semantic label for accessibility
    if (widget.semanticLabel != null) {
      dropdown = Semantics(label: widget.semanticLabel, child: dropdown);
    }

    // Add test key if provided
    if (widget.testKey != null) {
      dropdown = Container(key: Key(widget.testKey!), child: dropdown);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) _buildLabel(theme),
        dropdown,
        if (_shouldShowHelperOrError()) _buildHelperText(theme),
      ],
    );
  }

  /// Builds the main dropdown widget
  Widget _buildDropdown(ThemeData theme) {
    return FormField<T>(
      initialValue: widget.value,
      validator: _getValidator(),
      enabled: widget.isEnabled,
      builder: (formFieldState) {
        return InputDecorator(
          decoration: _getInputDecoration(theme, formFieldState.hasError),
          isEmpty: widget.value == null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: widget.value,
              hint: widget.hint != null ? Text(widget.hint!) : null,
              isExpanded: true,
              isDense: widget.density == AppDropdownDensity.compact,
              focusNode: _focusNode,
              icon: _buildDropdownIcon(theme),
              onChanged: widget.isEnabled ? _onItemSelected : null,
              onTap: () {
                setState(() {
                  _isOpen = !_isOpen;
                });
                if (widget.isSearchable && _isOpen) {
                  _resetSearch();
                }
              },
              selectedItemBuilder: widget.items.isNotEmpty
                  ? _buildSelectedItem
                  : null,
              items: _buildDropdownItems(theme),
              dropdownColor: theme.colorScheme.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              menuMaxHeight: widget.maxHeight,
            ),
          ),
        );
      },
    );
  }

  /// Builds the label widget
  Widget _buildLabel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: widget.label),
            if (widget.isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds helper text or error text
  Widget _buildHelperText(ThemeData theme) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final text = hasError ? widget.errorText! : widget.helperText!;
    final color = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasError) ...[
            Icon(Icons.error_outline, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dropdown icon
  Widget _buildDropdownIcon(ThemeData theme) {
    return AnimatedRotation(
      turns: _isOpen ? 0.5 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.keyboard_arrow_down,
        color: widget.isEnabled
            ? theme.colorScheme.onSurface.withOpacity(0.6)
            : theme.colorScheme.onSurface.withOpacity(0.38),
      ),
    );
  }

  /// Builds selected item display
  List<Widget> _buildSelectedItem(BuildContext context) {
    return widget.items.map((item) {
      return Text(
        widget.displayStringForItem?.call(item.value) ?? item.label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.isEnabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
        ),
      );
    }).toList();
  }

  /// Builds dropdown menu items
  List<DropdownMenuItem<T>> _buildDropdownItems(ThemeData theme) {
    final items = <DropdownMenuItem<T>>[];

    // Add search field if searchable
    if (widget.isSearchable) {
      items.add(
        DropdownMenuItem<T>(
          enabled: false,
          value: null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      );

      // Add divider after search
      if (_filteredItems.isNotEmpty) {
        items.add(
          DropdownMenuItem<T>(
            enabled: false,
            value: null,
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
        );
      }
    }

    // Add filtered items
    if (_filteredItems.isEmpty && widget.isSearchable) {
      items.add(
        DropdownMenuItem<T>(
          enabled: false,
          value: null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.noItemsFoundText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    } else {
      items.addAll(
        _filteredItems.map((item) {
          return DropdownMenuItem<T>(
            value: item.value,
            enabled: item.isEnabled,
            child:
                widget.itemBuilder?.call(
                  context,
                  item,
                  widget.value == item.value,
                ) ??
                _buildDefaultItem(theme, item),
          );
        }),
      );
    }

    return items;
  }

  /// Builds default item widget
  Widget _buildDefaultItem(ThemeData theme, AppDropdownItem<T> item) {
    final isSelected = widget.value == item.value;

    return Row(
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 20,
            color: item.isEnabled
                ? (isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6))
                : theme.colorScheme.onSurface.withOpacity(0.38),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.displayStringForItem?.call(item.value) ?? item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: item.isEnabled
                      ? (isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface)
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.isEnabled
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : theme.colorScheme.onSurface.withOpacity(0.38),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check, size: 20, color: theme.colorScheme.primary),
        ],
      ],
    );
  }

  /// Gets input decoration based on theme and state
  InputDecoration _getInputDecoration(ThemeData theme, bool hasError) {
    return InputDecoration(
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      border: _getBorder(theme, hasError),
      enabledBorder: _getBorder(theme, hasError),
      focusedBorder: _getBorder(theme, hasError),
      errorBorder: _getBorder(theme, true),
      focusedErrorBorder: _getBorder(theme, true),
      disabledBorder: _getBorder(theme, hasError),
      filled: widget.borderType == AppDropdownBorderType.filled,
      fillColor: widget.borderType == AppDropdownBorderType.filled
          ? theme.colorScheme.surfaceVariant.withOpacity(0.1)
          : null,
      contentPadding: _getContentPadding(),
      isDense: widget.density == AppDropdownDensity.compact,
      errorText: null, // We handle error text separately
    );
  }

  /// Gets border based on type and error state
  InputBorder _getBorder(ThemeData theme, bool hasError) {
    final borderRadius = BorderRadius.circular(8.0);
    final borderColor = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.outline;

    switch (widget.borderType) {
      case AppDropdownBorderType.outline:
        return OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: borderColor),
        );
      case AppDropdownBorderType.underline:
        return UnderlineInputBorder(borderSide: BorderSide(color: borderColor));
      case AppDropdownBorderType.filled:
        return OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        );
    }
  }

  /// Gets content padding based on density
  EdgeInsets _getContentPadding() {
    switch (widget.density) {
      case AppDropdownDensity.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppDropdownDensity.standard:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppDropdownDensity.comfortable:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }

  /// Gets effective validator function
  String? Function(T?)? _getValidator() {
    if (widget.validator == null && !widget.isRequired) return null;

    return (value) {
      // Check required validation first
      if (widget.isRequired && value == null) {
        return '${widget.label ?? 'This field'} is required';
      }

      // Then apply custom validator
      return widget.validator?.call(value);
    };
  }

  /// Handles item selection
  void _onItemSelected(T? value) {
    setState(() {
      _isOpen = false;
    });
    widget.onChanged?.call(value);
  }

  /// Whether to show helper text or error text
  bool _shouldShowHelperOrError() {
    return (widget.helperText != null && widget.helperText!.isNotEmpty) ||
        (widget.errorText != null && widget.errorText!.isNotEmpty);
  }
}

/// Dropdown item model
class AppDropdownItem<T> {
  const AppDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.isEnabled = true,
  });

  /// The value of the item
  final T value;

  /// Display label for the item
  final String label;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional icon
  final IconData? icon;

  /// Whether the item is enabled
  final bool isEnabled;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppDropdownItem<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Border type variants for dropdown
enum AppDropdownBorderType {
  outline, // Outlined border
  underline, // Underline border
  filled, // Filled background
}

/// Density variants for dropdown
enum AppDropdownDensity {
  compact, // Smaller padding
  standard, // Default padding
  comfortable, // Larger padding
}

/// Extension methods for common dropdown types
extension AppDropdownExtension on AppDropdown {
  /// Creates a category dropdown
  static AppDropdown<String> category({
    Key? key,
    required List<String> categories,
    String? value,
    ValueChanged<String?>? onChanged,
    String? label,
    String? hint,
    bool isRequired = false,
    bool isEnabled = true,
  }) {
    return AppDropdown<String>(
      key: key,
      items: categories
          .map(
            (category) => AppDropdownItem(
              value: category,
              label: category,
              icon: _getCategoryIcon(category),
            ),
          )
          .toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? 'Category',
      hint: hint ?? 'Select a category',
      prefixIcon: Icons.category_outlined,
      isRequired: isRequired,
      isEnabled: isEnabled,
      isSearchable: categories.length > 5,
    );
  }

  /// Creates a currency dropdown
  static AppDropdown<String> currency({
    Key? key,
    String? value,
    ValueChanged<String?>? onChanged,
    String? label,
    bool isRequired = false,
    bool isEnabled = true,
  }) {
    const currencies = [
      AppDropdownItem(value: 'USD', label: 'US Dollar', subtitle: 'USD'),
      AppDropdownItem(value: 'EUR', label: 'Euro', subtitle: 'EUR'),
      AppDropdownItem(value: 'GBP', label: 'British Pound', subtitle: 'GBP'),
      AppDropdownItem(value: 'JPY', label: 'Japanese Yen', subtitle: 'JPY'),
      AppDropdownItem(value: 'CAD', label: 'Canadian Dollar', subtitle: 'CAD'),
      AppDropdownItem(
        value: 'AUD',
        label: 'Australian Dollar',
        subtitle: 'AUD',
      ),
    ];

    return AppDropdown<String>(
      key: key,
      items: currencies,
      value: value,
      onChanged: onChanged,
      label: label ?? 'Currency',
      hint: 'Select currency',
      prefixIcon: Icons.monetization_on_outlined,
      isRequired: isRequired,
      isEnabled: isEnabled,
      isSearchable: true,
    );
  }

  /// Creates a business type dropdown
  static AppDropdown<String> businessType({
    Key? key,
    String? value,
    ValueChanged<String?>? onChanged,
    String? label,
    bool isRequired = false,
    bool isEnabled = true,
  }) {
    const businessTypes = [
      AppDropdownItem(
        value: 'freelancer',
        label: 'Freelancer',
        icon: Icons.person,
      ),
      AppDropdownItem(
        value: 'consultant',
        label: 'Consultant',
        icon: Icons.business_center,
      ),
      AppDropdownItem(
        value: 'contractor',
        label: 'Contractor',
        icon: Icons.construction,
      ),
      AppDropdownItem(
        value: 'small_business',
        label: 'Small Business',
        icon: Icons.store,
      ),
      AppDropdownItem(
        value: 'startup',
        label: 'Startup',
        icon: Icons.rocket_launch,
      ),
      AppDropdownItem(value: 'other', label: 'Other', icon: Icons.more_horiz),
    ];

    return AppDropdown<String>(
      key: key,
      items: businessTypes,
      value: value,
      onChanged: onChanged,
      label: label ?? 'Business Type',
      hint: 'Select business type',
      prefixIcon: Icons.business,
      isRequired: isRequired,
      isEnabled: isEnabled,
    );
  }

  /// Gets category icon based on category name
  static IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'office supplies':
        return Icons.work;
      case 'software & technology':
        return Icons.computer;
      case 'marketing':
        return Icons.campaign;
      case 'travel':
        return Icons.flight;
      case 'utilities':
        return Icons.electrical_services;
      case 'healthcare':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }
}
