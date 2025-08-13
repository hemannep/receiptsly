// lib/presentation/screens/receipt/widgets/category_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/category_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/category_provider.dart';
import '../../../widgets/common/app_loader.dart';
import '../../../widgets/common/app_snackbar.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final CategoryEntity? selectedCategory;
  final Function(CategoryEntity) onCategorySelected;
  final bool allowCustomCategory;
  final String? errorText;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.allowCustomCategory = true,
    this.errorText,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _customCategoryController =
      TextEditingController();
  bool _showCustomInput = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCategories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _loadCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryListProvider);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectedCategory(theme),
              const SizedBox(height: 12),
              _buildCategoryGrid(categoryState, theme),
              if (widget.allowCustomCategory) ...[
                const SizedBox(height: 12),
                _buildCustomCategorySection(theme),
              ],
              if (widget.errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedCategory(ThemeData theme) {
    if (widget.selectedCategory == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.errorText != null
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              'Select a category',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.selectedCategory!.color.withOpacity(0.1),
        border: Border.all(color: widget.selectedCategory!.color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.selectedCategory!.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.selectedCategory!.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedCategory!.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.selectedCategory!.color,
                  ),
                ),
                if (widget.selectedCategory!.description?.isNotEmpty == true)
                  Text(
                    widget.selectedCategory!.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showCategoryPicker,
            icon: const Icon(Icons.edit),
            color: widget.selectedCategory!.color,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
    AsyncValue<List<CategoryEntity>> categoryState,
    ThemeData theme,
  ) {
    return categoryState.when(
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(32), child: AppLoader()),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load categories',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadCategories,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState(theme);
        }

        final filteredCategories = _searchQuery.isEmpty
            ? categories
            : categories
                  .where(
                    (category) => category.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        return Column(
          children: [
            if (categories.length > 6) _buildSearchField(theme),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: filteredCategories.length > 6
                  ? 6
                  : filteredCategories.length,
              itemBuilder: (context, index) {
                if (index == 5 && filteredCategories.length > 6) {
                  return _buildMoreButton(theme, filteredCategories.length - 5);
                }
                return _buildCategoryItem(filteredCategories[index], theme);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search categories...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildCategoryItem(CategoryEntity category, ThemeData theme) {
    final isSelected = widget.selectedCategory?.id == category.id;

    return GestureDetector(
      onTap: () => widget.onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withOpacity(0.2)
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color
                    : category.color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? category.color : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton(ThemeData theme, int remainingCount) {
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 4),
            Text(
              '+$remainingCount more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showCustomInput)
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _showCustomInput = true);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Custom Category'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        else
          _buildCustomCategoryInput(theme),
      ],
    );
  }

  Widget _buildCustomCategoryInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Custom Category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customCategoryController,
            decoration: const InputDecoration(
              hintText: 'Enter category name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showCustomInput = false;
                      _customCategoryController.clear();
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createCustomCategory,
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No categories available',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(
        selectedCategory: widget.selectedCategory,
        onCategorySelected: widget.onCategorySelected,
        allowCustomCategory: widget.allowCustomCategory,
      ),
    );
  }

  void _createCustomCategory() async {
    final name = _customCategoryController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.showError(context, 'Please enter a category name');
      return;
    }

    try {
      final newCategory = await ref
          .read(categoryListProvider.notifier)
          .createCategory(name);

      widget.onCategorySelected(newCategory);

      setState(() {
        _showCustomInput = false;
        _customCategoryController.clear();
      });

      AppSnackbar.showSuccess(context, 'Category created successfully');
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to create category');
    }
  }
}

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final CategoryEntity? selectedCategory;
  final Function(CategoryEntity) onCategorySelected;
  final bool allowCustomCategory;

  const _CategoryPickerSheet({
    this.selectedCategory,
    required this.onCategorySelected,
    this.allowCustomCategory = true,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryListProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildSearchField(theme),
          Expanded(child: _buildCategoryList(categoryState, theme)),
          if (widget.allowCustomCategory) _buildCreateButton(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Select Category',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildCategoryList(
    AsyncValue<List<CategoryEntity>> categoryState,
    ThemeData theme,
  ) {
    return categoryState.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Text('Failed to load categories'),
            TextButton(
              onPressed: () {
                ref.read(categoryListProvider.notifier).loadCategories();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (categories) {
        final filteredCategories = _searchQuery.isEmpty
            ? categories
            : categories
                  .where(
                    (category) => category.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        if (filteredCategories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text('No categories found', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];
            final isSelected = widget.selectedCategory?.id == category.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? category.color.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: category.color, width: 2)
                    : null,
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 20),
                ),
                title: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? category.color : null,
                  ),
                ),
                subtitle: category.description?.isNotEmpty == true
                    ? Text(category.description!)
                    : null,
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: category.color)
                    : null,
                onTap: () {
                  widget.onCategorySelected(category);
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _showCreateCategoryDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text('Create New Category'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateCategoryDialog(
        onCategoryCreated: (category) {
          widget.onCategorySelected(category);
        },
      ),
    );
  }
}

class _CreateCategoryDialog extends ConsumerStatefulWidget {
  final Function(CategoryEntity) onCategoryCreated;

  const _CreateCategoryDialog({required this.onCategoryCreated});

  @override
  ConsumerState<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<_CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  IconData _selectedIcon = Icons.category;
  Color _selectedColor = AppColors.primary;
  bool _isCreating = false;

  final List<IconData> _availableIcons = [
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.shopping_cart,
    Icons.medical_services,
    Icons.school,
    Icons.home,
    Icons.directions_car,
    Icons.flight,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.pets,
    Icons.business,
    Icons.computer,
    Icons.phone,
    Icons.music_note,
    Icons.movie,
    Icons.book,
    Icons.kitchen,
    Icons.local_laundry_service,
    Icons.build,
  ];

  final List<Color> _availableColors = [
    AppColors.primary,
    AppColors.secondary,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Create Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Text(
                'Icon',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIcon = icon);
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.2)
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: _selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? _selectedColor : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createCategory,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  void _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final category = await ref
          .read(categoryListProvider.notifier)
          .createCategory(
            _nameController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            icon: _selectedIcon,
            color: _selectedColor,
          );

      widget.onCategoryCreated(category);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, 'Category created successfully');
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to create category');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
