// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../common/app_loader.dart';
import 'bottom_navigation.dart';
import 'app_drawer.dart';
import 'floating_action_menu.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBottomNavigation;
  final bool showDrawer;
  final bool showAppBar;
  final PreferredSizeWidget? appBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomNavigationBar;
  final bool showFloatingActionMenu;
  final List<FloatingActionItem>? floatingActions;
  final bool isLoading;
  final String? loadingMessage;
  final VoidCallback? onRefresh;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final double? elevation;
  final bool centerTitle;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBottomNavigation = false,
    this.showDrawer = false,
    this.showAppBar = true,
    this.appBar,
    this.bottomSheet,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.bottomNavigationBar,
    this.showFloatingActionMenu = false,
    this.floatingActions,
    this.isLoading = false,
    this.loadingMessage,
    this.onRefresh,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.elevation,
    this.centerTitle = true,
    this.systemOverlayStyle,
  }) : super(key: key);

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _loadingController.forward();
    }
  }

  @override
  void didUpdateWidget(AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.forward();
      } else {
        _loadingController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!widget.showAppBar) return null;

    if (widget.appBar != null) return widget.appBar;

    return AppBar(
      title: widget.title != null
          ? Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            )
          : null,
      centerTitle: widget.centerTitle,
      elevation: widget.elevation ?? 0,
      backgroundColor: widget.backgroundColor ?? AppColors.surface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle:
          widget.systemOverlayStyle ?? SystemUiOverlayStyle.dark,
      leading:
          widget.leading ??
          (widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed:
                      widget.onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null),
      actions: [
        ...?widget.actions,
        if (widget.onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
            tooltip: 'Refresh',
          ),
      ],
    );
  }

  Widget _buildBody() {
    Widget body = widget.body;

    if (widget.onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh?.call();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: body,
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: body,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (widget.showFloatingActionMenu && widget.floatingActions != null) {
      return FloatingActionMenu(items: widget.floatingActions!);
    }
    return widget.floatingActionButton ?? const SizedBox.shrink();
  }

  Widget _buildBottomNavigationBar() {
    if (widget.bottomNavigationBar != null) {
      return widget.bottomNavigationBar!;
    }

    if (widget.showBottomNavigation) {
      return const BottomNavigation();
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? AppColors.background,
      appBar: _buildAppBar(),
      drawer: widget.showDrawer ? const AppDrawer() : null,
      body: Stack(
        children: [
          _buildBody(),
          // Loading Overlay
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              if (_loadingAnimation.value == 0) {
                return const SizedBox.shrink();
              }

              return Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(
                    0.3 * _loadingAnimation.value,
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: _loadingAnimation.value,
                      child: AppLoader(message: widget.loadingMessage),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: _buildBottomNavigationBar(),
      bottomSheet: widget.bottomSheet,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
    );
  }
}
