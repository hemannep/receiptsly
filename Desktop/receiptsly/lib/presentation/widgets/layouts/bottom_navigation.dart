import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../animations/scale_animation.dart';

// Navigation Items Model
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;
  final Widget? badge;
  final bool enabled;

  const NavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
    this.badge,
    this.enabled = true,
  });
}

// Current Index Provider
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Badge Provider for notifications
final notificationBadgeProvider = StateProvider<int>((ref) => 0);
final syncBadgeProvider = StateProvider<bool>((ref) => false);

class BottomNavigation extends ConsumerStatefulWidget {
  final List<NavigationItem>? customItems;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? iconSize;
  final TextStyle? labelStyle;
  final bool showLabels;
  final double? elevation;

  const BottomNavigation({
    Key? key,
    this.customItems,
    this.height,
    this.padding,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.iconSize,
    this.labelStyle,
    this.showLabels = true,
    this.elevation,
  }) : super(key: key);

  @override
  ConsumerState<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends ConsumerState<BottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize item controllers for individual animations
    _itemControllers = List.generate(
      _getNavigationItems().length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<NavigationItem> _getNavigationItems() {
    if (widget.customItems != null) {
      return widget.customItems!;
    }

    final notificationCount = ref.watch(notificationBadgeProvider);
    final hasSyncIssues = ref.watch(syncBadgeProvider);

    return [
      const NavigationItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        route: '/dashboard',
      ),
      NavigationItem(
        label: 'Receipts',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        route: '/receipts',
        badge: hasSyncIssues
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
      const NavigationItem(
        label: 'Camera',
        icon: Icons.camera_alt_outlined,
        activeIcon: Icons.camera_alt,
        route: '/camera',
      ),
      const NavigationItem(
        label: 'Invoices',
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        route: '/invoices',
      ),
      NavigationItem(
        label: 'Reports',
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        route: '/reports',
        badge: notificationCount > 0
            ? Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  notificationCount > 99 ? '99+' : '$notificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : null,
      ),
    ];
  }

  void _onItemTapped(int index, NavigationItem item) {
    if (!item.enabled) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate the tapped item
    _itemControllers[index].forward().then((_) {
      _itemControllers[index].reverse();
    });

    // Update current index
    ref.read(bottomNavIndexProvider.notifier).state = index;

    // Navigate to route
    context.go(item.route);
  }

  Widget _buildNavigationItem(NavigationItem item, int index, bool isSelected) {
    final theme = Theme.of(context);
    final selectedColor = widget.selectedItemColor ?? AppColors.primary;
    final unselectedColor =
        widget.unselectedItemColor ?? AppColors.textSecondary;

    return Expanded(
      child: ScaleAnimation(
        controller: _itemControllers[index],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.enabled ? () => _onItemTapped(index, item) : null,
            splashColor: selectedColor.withOpacity(0.1),
            highlightColor: selectedColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: AppDimensions.paddingSmall,
                horizontal: AppDimensions.paddingXSmall,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected
                              ? (item.activeIcon ?? item.icon)
                              : item.icon,
                          key: ValueKey(isSelected),
                          size: widget.iconSize ?? 24,
                          color: isSelected
                              ? selectedColor
                              : (item.enabled
                                    ? unselectedColor
                                    : unselectedColor.withOpacity(0.5)),
                        ),
                      ),
                      if (item.badge != null)
                        Positioned(right: -4, top: -4, child: item.badge!),
                    ],
                  ),

                  if (widget.showLabels) ...[
                    SizedBox(height: AppDimensions.paddingXSmall),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: (widget.labelStyle ?? theme.textTheme.labelSmall!)
                          .copyWith(
                            color: isSelected
                                ? selectedColor
                                : (item.enabled
                                      ? unselectedColor
                                      : unselectedColor.withOpacity(0.5)),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final items = _getNavigationItems();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * _slideAnimation.value),
          child: Container(
            height:
                widget.height ?? (56 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppColors.surface,
              boxShadow: [
                if ((widget.elevation ?? 8) > 0)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: widget.elevation ?? 8,
                    offset: const Offset(0, -2),
                  ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    widget.padding ??
                    EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingSmall,
                    ),
                child: Row(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = currentIndex == index;

                    return _buildNavigationItem(item, index, isSelected);
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper widget for custom bottom navigation usage
class CustomBottomNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [bottomNavIndexProvider.overrideWith((ref) => currentIndex)],
      child: BottomNavigation(customItems: items),
    );
  }
}
