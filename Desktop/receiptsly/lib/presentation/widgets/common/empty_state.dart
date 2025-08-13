// lib/presentation/widgets/common/empty_state.dart
import 'package:flutter/material.dart';

/// Production-ready empty state widget for Receiptsly app
/// Provides consistent empty state displays across the app
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.image,
    this.primaryAction,
    this.secondaryAction,
    this.size = EmptyStateSize.medium,
    this.alignment = Alignment.center,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  }) : assert(
         icon != null || image != null,
         'Either icon or image must be provided',
       );

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Icon to display (alternative to image)
  final IconData? icon;

  /// Image to display (alternative to icon)
  final Widget? image;

  /// Primary action button
  final EmptyStateAction? primaryAction;

  /// Secondary action button
  final EmptyStateAction? secondaryAction;

  /// Size variant of the empty state
  final EmptyStateSize size;

  /// Alignment of the content
  final Alignment alignment;

  /// Padding around the content
  final EdgeInsets? padding;

  /// Background color
  final Color? backgroundColor;

  /// Foreground color for text and icons
  final Color? foregroundColor;

  /// Semantic label for accessibility
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveForegroundColor =
        foregroundColor ?? theme.colorScheme.onSurface.withOpacity(0.6);

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon or Image
        _buildIconOrImage(theme, effectiveForegroundColor),

        SizedBox(height: _getSpacing()),

        // Title
        Text(
          title,
          style: _getTitleStyle(theme, effectiveForegroundColor),
          textAlign: TextAlign.center,
        ),

        // Subtitle
        if (subtitle != null) ...[
          SizedBox(height: _getSpacing() * 0.5),
          Text(
            subtitle!,
            style: _getSubtitleStyle(theme, effectiveForegroundColor),
            textAlign: TextAlign.center,
          ),
        ],

        // Actions
        if (primaryAction != null || secondaryAction != null) ...[
          SizedBox(height: _getSpacing() * 1.5),
          _buildActions(context),
        ],
      ],
    );

    // Wrap with semantics for accessibility
    content = Semantics(
      label: semanticLabel ?? '$title empty state',
      child: content,
    );

    // Apply padding
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    // Apply background color if specified
    if (backgroundColor != null) {
      content = Container(color: backgroundColor, child: content);
    }

    return Align(alignment: alignment, child: content);
  }

  /// Builds the icon or image widget
  Widget _buildIconOrImage(ThemeData theme, Color foregroundColor) {
    if (image != null) {
      return SizedBox(
        width: _getImageSize(),
        height: _getImageSize(),
        child: image!,
      );
    }

    return Icon(icon!, size: _getIconSize(), color: foregroundColor);
  }

  /// Builds the action buttons
  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (primaryAction != null) {
      actions.add(
        ElevatedButton(
          onPressed: primaryAction!.onPressed,
          style: primaryAction!.style,
          child: Text(primaryAction!.label),
        ),
      );
    }

    if (secondaryAction != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 12));
      }
      actions.add(
        OutlinedButton(
          onPressed: secondaryAction!.onPressed,
          style: secondaryAction!.style,
          child: Text(secondaryAction!.label),
        ),
      );
    }

    if (actions.length == 1) {
      return actions.first;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  /// Gets title text style based on size
  TextStyle _getTitleStyle(ThemeData theme, Color foregroundColor) {
    final baseStyle = switch (size) {
      EmptyStateSize.small => theme.textTheme.titleMedium,
      EmptyStateSize.medium => theme.textTheme.titleLarge,
      EmptyStateSize.large => theme.textTheme.headlineSmall,
    };

    return baseStyle?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(color: foregroundColor);
  }

  /// Gets subtitle text style based on size
  TextStyle _getSubtitleStyle(ThemeData theme, Color foregroundColor) {
    final baseStyle = switch (size) {
      EmptyStateSize.small => theme.textTheme.bodySmall,
      EmptyStateSize.medium => theme.textTheme.bodyMedium,
      EmptyStateSize.large => theme.textTheme.bodyLarge,
    };

    return baseStyle?.copyWith(
          color: foregroundColor.withOpacity(0.8),
          height: 1.4,
        ) ??
        TextStyle(color: foregroundColor);
  }

  /// Gets icon size based on size variant
  double _getIconSize() {
    return switch (size) {
      EmptyStateSize.small => 48.0,
      EmptyStateSize.medium => 64.0,
      EmptyStateSize.large => 80.0,
    };
  }

  /// Gets image size based on size variant
  double _getImageSize() {
    return switch (size) {
      EmptyStateSize.small => 80.0,
      EmptyStateSize.medium => 120.0,
      EmptyStateSize.large => 160.0,
    };
  }

  /// Gets spacing between elements
  double _getSpacing() {
    return switch (size) {
      EmptyStateSize.small => 12.0,
      EmptyStateSize.medium => 16.0,
      EmptyStateSize.large => 24.0,
    };
  }
}

/// Action model for empty state buttons
class EmptyStateAction {
  const EmptyStateAction({
    required this.label,
    required this.onPressed,
    this.style,
    this.icon,
  });

  /// Button label
  final String label;

  /// Button callback
  final VoidCallback onPressed;

  /// Button style
  final ButtonStyle? style;

  /// Optional icon
  final IconData? icon;
}

/// Size variants for empty state
enum EmptyStateSize { small, medium, large }

/// Pre-built empty state widgets for common scenarios
class EmptyStateTemplates {
  EmptyStateTemplates._();

  /// No receipts uploaded yet
  static EmptyState noReceipts({
    VoidCallback? onUpload,
    VoidCallback? onTakePicture,
  }) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No receipts yet',
      subtitle: 'Start tracking your expenses by uploading your first receipt',
      primaryAction: onUpload != null
          ? EmptyStateAction(label: 'Upload Receipt', onPressed: onUpload)
          : null,
      secondaryAction: onTakePicture != null
          ? EmptyStateAction(label: 'Take Picture', onPressed: onTakePicture)
          : null,
    );
  }

  /// No invoices created yet
  static EmptyState noInvoices({VoidCallback? onCreate}) {
    return EmptyState(
      icon: Icons.description_outlined,
      title: 'No invoices yet',
      subtitle: 'Create your first invoice to start getting paid',
      primaryAction: onCreate != null
          ? EmptyStateAction(label: 'Create Invoice', onPressed: onCreate)
          : null,
    );
  }

  /// No clients added yet
  static EmptyState noClients({VoidCallback? onAdd}) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No clients yet',
      subtitle: 'Add your first client to start creating invoices',
      primaryAction: onAdd != null
          ? EmptyStateAction(label: 'Add Client', onPressed: onAdd)
          : null,
    );
  }

  /// Search returned no results
  static EmptyState searchNoResults({
    required String query,
    VoidCallback? onClear,
  }) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      subtitle: 'No items match your search for "$query"',
      size: EmptyStateSize.small,
      primaryAction: onClear != null
          ? EmptyStateAction(label: 'Clear Search', onPressed: onClear)
          : null,
    );
  }

  /// Network error state
  static EmptyState networkError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'Connection Error',
      subtitle: 'Please check your internet connection and try again',
      primaryAction: onRetry != null
          ? EmptyStateAction(label: 'Retry', onPressed: onRetry)
          : null,
    );
  }

  /// Server error state
  static EmptyState serverError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      subtitle: 'We\'re having trouble loading your data. Please try again',
      primaryAction: onRetry != null
          ? EmptyStateAction(label: 'Try Again', onPressed: onRetry)
          : null,
    );
  }

  /// Data sync in progress
  static EmptyState syncing() {
    return const EmptyState(
      icon: Icons.sync,
      title: 'Syncing data...',
      subtitle: 'Please wait while we sync your latest data',
      size: EmptyStateSize.small,
    );
  }

  /// Offline state
  static EmptyState offline({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: 'You\'re offline',
      subtitle: 'Some features may not be available while offline',
      size: EmptyStateSize.small,
      primaryAction: onRetry != null
          ? EmptyStateAction(label: 'Refresh', onPressed: onRetry)
          : null,
    );
  }

  /// Feature coming soon
  static EmptyState comingSoon({String? featureName}) {
    return EmptyState(
      icon: Icons.construction,
      title: 'Coming Soon',
      subtitle: featureName != null
          ? '$featureName is under development and will be available soon'
          : 'This feature is under development and will be available soon',
    );
  }

  /// Permission denied
  static EmptyState permissionDenied({
    required String permission,
    VoidCallback? onGrantPermission,
  }) {
    return EmptyState(
      icon: Icons.block,
      title: 'Permission Required',
      subtitle: 'We need $permission permission to use this feature',
      primaryAction: onGrantPermission != null
          ? EmptyStateAction(
              label: 'Grant Permission',
              onPressed: onGrantPermission,
            )
          : null,
    );
  }

  /// No data for date range
  static EmptyState noDataInRange({VoidCallback? onChangeRange}) {
    return EmptyState(
      icon: Icons.date_range,
      title: 'No data in this period',
      subtitle: 'Try selecting a different date range',
      size: EmptyStateSize.small,
      primaryAction: onChangeRange != null
          ? EmptyStateAction(label: 'Change Range', onPressed: onChangeRange)
          : null,
    );
  }

  /// Storage full
  static EmptyState storageFull({VoidCallback? onManageStorage}) {
    return EmptyState(
      icon: Icons.storage,
      title: 'Storage Full',
      subtitle: 'You\'ve reached your storage limit. Please free up some space',
      primaryAction: onManageStorage != null
          ? EmptyStateAction(
              label: 'Manage Storage',
              onPressed: onManageStorage,
            )
          : null,
    );
  }

  /// Subscription expired
  static EmptyState subscriptionExpired({VoidCallback? onUpgrade}) {
    return EmptyState(
      icon: Icons.card_membership,
      title: 'Subscription Expired',
      subtitle: 'Upgrade your plan to continue using all features',
      primaryAction: onUpgrade != null
          ? EmptyStateAction(label: 'Upgrade Now', onPressed: onUpgrade)
          : null,
    );
  }
}

/// Animated empty state with custom animations
class AnimatedEmptyState extends StatefulWidget {
  const AnimatedEmptyState({
    super.key,
    required this.emptyState,
    this.animationType = EmptyStateAnimation.fadeIn,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  /// The empty state widget to animate
  final EmptyState emptyState;

  /// Type of animation
  final EmptyStateAnimation animationType;

  /// Animation duration
  final Duration duration;

  /// Delay before animation starts
  final Duration delay;

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.emptyState;

    switch (widget.animationType) {
      case EmptyStateAnimation.fadeIn:
        child = FadeTransition(opacity: _fadeAnimation, child: child);
        break;
      case EmptyStateAnimation.slideUp:
        child = SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: child),
        );
        break;
      case EmptyStateAnimation.scale:
        child = ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: child),
        );
        break;
    }

    return child;
  }
}

/// Animation types for empty state
enum EmptyStateAnimation { fadeIn, slideUp, scale }

/// Extension for easier empty state usage
extension EmptyStateExtension on Widget {
  /// Wraps widget with empty state animation
  Widget animateEmptyState({
    EmptyStateAnimation animationType = EmptyStateAnimation.fadeIn,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
  }) {
    if (this is EmptyState) {
      return AnimatedEmptyState(
        emptyState: this as EmptyState,
        animationType: animationType,
        duration: duration,
        delay: delay,
      );
    }
    return this;
  }
}
