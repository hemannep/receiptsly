import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../animations/scale_animation.dart';
import '../animations/fade_animation.dart';

// Floating Action Item Model
class FloatingActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool enabled;

  const FloatingActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.enabled = true,
  });
}

class FloatingActionMenu extends StatefulWidget {
  final List<FloatingActionItem> items;
  final Widget? mainButton;
  final IconData? mainIcon;
  final Color? mainButtonColor;
  final Color? overlayColor;
  final double? spacing;
  final AnimationDirection? direction;
  final String? tooltip;
  final bool? mini;

  const FloatingActionMenu({
    Key? key,
    required this.items,
    this.mainButton,
    this.mainIcon,
    this.mainButtonColor,
    this.overlayColor,
    this.spacing,
    this.direction,
    this.tooltip,
    this.mini,
  }) : super(key: key);

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _overlayController;
  late List<AnimationController> _itemControllers;
  late Animation<double> _mainRotation;
  late Animation<double> _overlayOpacity;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _mainRotation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _overlayOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeInOut),
    );

    _itemControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200 + (index * 50)),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _overlayController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();

    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() async {
    setState(() {
      _isOpen = true;
    });

    _overlayController.forward();
    _mainController.forward();

    // Stagger item animations
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && _isOpen) {
        _itemControllers[i].forward();
      }
    }
  }

  void _close() async {
    setState(() {
      _isOpen = false;
    });

    // Reverse item animations
    for (int i = _itemControllers.length - 1; i >= 0; i--) {
      _itemControllers[i].reverse();
      await Future.delayed(const Duration(milliseconds: 30));
    }

    _mainController.reverse();
    await Future.delayed(const Duration(milliseconds: 100));
    _overlayController.reverse();
  }

  Widget _buildMainButton() {
    if (widget.mainButton != null) {
      return GestureDetector(onTap: _toggle, child: widget.mainButton!);
    }

    return FloatingActionButton(
      onPressed: _toggle,
      backgroundColor: widget.mainButtonColor ?? AppColors.primary,
      mini: widget.mini ?? false,
      tooltip: widget.tooltip ?? 'Menu',
      child: AnimatedBuilder(
        animation: _mainRotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _mainRotation.value * 2 * 3.14159,
            child: Icon(
              _isOpen ? Icons.close : (widget.mainIcon ?? Icons.add),
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(FloatingActionItem item, int index) {
    final direction = widget.direction ?? AnimationDirection.up;
    double offset = (widget.spacing ?? 70.0) * (index + 1);

    return ScaleAnimation(
      controller: _itemControllers[index],
      child: Container(
        margin: EdgeInsets.only(
          bottom: direction == AnimationDirection.up ? offset : 0,
          top: direction == AnimationDirection.down ? offset : 0,
          right: direction == AnimationDirection.left ? offset : 0,
          left: direction == AnimationDirection.right ? offset : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            if (direction == AnimationDirection.up ||
                direction == AnimationDirection.down) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
                margin: EdgeInsets.only(right: AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],

            // Button
            FloatingActionButton(
              onPressed: item.enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      item.onTap();
                      _close();
                    }
                  : null,
              backgroundColor: item.backgroundColor ?? AppColors.surface,
              mini: true,
              tooltip: item.tooltip ?? item.label,
              heroTag: 'fab_${item.label}_$index',
              child: Icon(
                item.icon,
                color: item.iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),

            // Label for horizontal directions
            if (direction == AnimationDirection.left ||
                direction == AnimationDirection.right) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
                margin: EdgeInsets.only(left: AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Overlay
        AnimatedBuilder(
          animation: _overlayOpacity,
          builder: (context, child) {
            if (_overlayOpacity.value == 0) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  color: (widget.overlayColor ?? Colors.black).withOpacity(
                    0.3 * _overlayOpacity.value,
                  ),
                ),
              ),
            );
          },
        ),

        // Menu Items
        if (_isOpen)
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildMenuItem(item, index);
          }).toList(),

        // Main Button
        _buildMainButton(),
      ],
    );
  }
}

// Quick Action FAB for common actions
class QuickActionFAB extends StatelessWidget {
  final VoidCallback? onReceiptCapture;
  final VoidCallback? onQuickInvoice;
  final VoidCallback? onExpenseEntry;
  final VoidCallback? onClientAdd;

  const QuickActionFAB({
    Key? key,
    this.onReceiptCapture,
    this.onQuickInvoice,
    this.onExpenseEntry,
    this.onClientAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <FloatingActionItem>[
      if (onReceiptCapture != null)
        FloatingActionItem(
          label: 'Capture Receipt',
          icon: Icons.camera_alt,
          onTap: onReceiptCapture!,
          backgroundColor: AppColors.success,
          iconColor: Colors.white,
          tooltip: 'Take a photo of your receipt',
        ),
      if (onQuickInvoice != null)
        FloatingActionItem(
          label: 'Quick Invoice',
          icon: Icons.description,
          onTap: onQuickInvoice!,
          backgroundColor: AppColors.info,
          iconColor: Colors.white,
          tooltip: 'Create a new invoice',
        ),
      if (onExpenseEntry != null)
        FloatingActionItem(
          label: 'Add Expense',
          icon: Icons.receipt_long,
          onTap: onExpenseEntry!,
          backgroundColor: AppColors.warning,
          iconColor: Colors.white,
          tooltip: 'Manually add an expense',
        ),
      if (onClientAdd != null)
        FloatingActionItem(
          label: 'Add Client',
          icon: Icons.person_add,
          onTap: onClientAdd!,
          backgroundColor: AppColors.secondary,
          iconColor: Colors.white,
          tooltip: 'Add a new client',
        ),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionMenu(
      items: items,
      mainIcon: Icons.add,
      tooltip: 'Quick Actions',
    );
  }
}

enum AnimationDirection { up, down, left, right }
