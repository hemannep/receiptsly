import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/user/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../common/app_button.dart';

// Drawer Item Model
class DrawerItem {
  final String title;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;
  final Color? iconColor;
  final Color? textColor;
  final bool showDivider;

  const DrawerItem({
    required this.title,
    required this.icon,
    this.route,
    this.onTap,
    this.trailing,
    this.enabled = true,
    this.iconColor,
    this.textColor,
    this.showDivider = false,
  });
}

class AppDrawer extends ConsumerStatefulWidget {
  final List<DrawerItem>? customItems;
  final Widget? header;
  final Widget? footer;
  final double? width;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const AppDrawer({
    Key? key,
    this.customItems,
    this.header,
    this.footer,
    this.width,
    this.backgroundColor,
    this.padding,
  }) : super(key: key);

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late List<AnimationController> _itemControllers;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final items = _getDrawerItems();
    _itemControllers = List.generate(
      items.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200 + (index * 50)),
        vsync: this,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();

    // Stagger item animations
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _itemControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<DrawerItem> _getDrawerItems() {
    if (widget.customItems != null) {
      return widget.customItems!;
    }

    return [
      const DrawerItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      const DrawerItem(
        title: 'Receipts',
        icon: Icons.receipt_long_outlined,
        route: '/receipts',
      ),
      const DrawerItem(
        title: 'Invoices',
        icon: Icons.description_outlined,
        route: '/invoices',
      ),
      const DrawerItem(
        title: 'Clients',
        icon: Icons.people_outline,
        route: '/clients',
      ),
      const DrawerItem(
        title: 'Reports',
        icon: Icons.analytics_outlined,
        route: '/reports',
        showDivider: true,
      ),
      const DrawerItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        route: '/settings',
      ),
      const DrawerItem(
        title: 'Help & Support',
        icon: Icons.help_outline,
        route: '/support',
      ),
      const DrawerItem(
        title: 'Sync Status',
        icon: Icons.sync,
        route: '/sync-status',
        trailing: Icon(Icons.circle, size: 12, color: AppColors.success),
      ),
    ];
  }

  Widget _buildHeader() {
    if (widget.header != null) {
      return widget.header!;
    }

    final user = ref.watch(currentUserProvider);

    return FadeAnimation(
      controller: _fadeController,
      child: Container(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white.withOpacity(0.8),
                      )
                    : null,
              ),
            ),

            SizedBox(height: AppDimensions.paddingMedium),

            // User Name
            Text(
              user?.displayName ?? 'Guest User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: AppDimensions.paddingXSmall),

            // User Email
            Text(
              user?.email ?? 'guest@receiptsly.app',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),

            SizedBox(height: AppDimensions.paddingMedium),

            // Subscription Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: AppDimensions.paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Text(
                'Free Plan',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(DrawerItem item, int index) {
    return SlideAnimation(
      controller: _itemControllers[index],
      direction: SlideDirection.left,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              item.icon,
              color: item.iconColor ?? AppColors.textSecondary,
            ),
            title: Text(
              item.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: item.textColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: item.trailing,
            enabled: item.enabled,
            onTap: item.enabled
                ? () {
                    if (item.onTap != null) {
                      item.onTap!();
                    } else if (item.route != null) {
                      Navigator.of(context).pop();
                      context.go(item.route!);
                    }
                  }
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingXSmall,
            ),
          ),
          if (item.showDivider)
            Divider(
              thickness: 1,
              color: AppColors.border,
              indent: AppDimensions.paddingLarge,
              endIndent: AppDimensions.paddingLarge,
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (widget.footer != null) {
      return widget.footer!;
    }

    return FadeAnimation(
      controller: _fadeController,
      child: Container(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            Divider(thickness: 1, color: AppColors.border),

            SizedBox(height: AppDimensions.paddingMedium),

            // App Version
            Text(
              'Receiptsly v1.0.0',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),

            SizedBox(height: AppDimensions.paddingMedium),

            // Logout Button
            AppButton(
              text: 'Sign Out',
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authServiceProvider).signOut();
                if (mounted) {
                  context.go('/login');
                }
              },
              variant: ButtonVariant.outlined,
              size: ButtonSize.small,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _getDrawerItems();

    return SlideAnimation(
      controller: _slideController,
      direction: SlideDirection.left,
      child: Drawer(
        width: widget.width,
        backgroundColor: widget.backgroundColor ?? AppColors.surface,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Menu Items
              Expanded(
                child: ListView.builder(
                  padding:
                      widget.padding ??
                      EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMedium,
                      ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildDrawerItem(items[index], index);
                  },
                ),
              ),

              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for custom drawer usage
class CustomAppDrawer extends StatelessWidget {
  final List<DrawerItem> items;
  final Widget? header;
  final Widget? footer;

  const CustomAppDrawer({
    Key? key,
    required this.items,
    this.header,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppDrawer(customItems: items, header: header, footer: footer);
  }
}
