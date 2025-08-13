// lib/presentation/widgets/common/app_snackbar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production-ready snackbar utility for Receiptsly app
/// Provides consistent styling and functionality across the app
class AppSnackbar {
  AppSnackbar._();

  /// Shows a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    bool dismissible = true,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackbarType.success,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      dismissible: dismissible,
    );
  }

  /// Shows an error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 6),
    bool dismissible = true,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackbarType.error,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      dismissible: dismissible,
    );
  }

  /// Shows a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 5),
    bool dismissible = true,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackbarType.warning,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      dismissible: dismissible,
    );
  }

  /// Shows an info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    bool dismissible = true,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackbarType.info,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      dismissible: dismissible,
    );
  }

  /// Shows a loading snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context, {
    required String message,
    bool dismissible = false,
  }) {
    return _showCustom(
      context,
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.grey[800]!,
      duration: const Duration(days: 1), // Indefinite
      dismissible: dismissible,
    );
  }

  /// Shows a custom snackbar with full control
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showCustom(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool dismissible = true,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    return _showCustom(
      context,
      content: content,
      backgroundColor: backgroundColor,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      dismissible: dismissible,
      margin: margin,
      borderRadius: borderRadius,
      elevation: elevation,
    );
  }

  /// Internal method to show snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required AppSnackbarType type,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    bool dismissible = true,
  }) {
    final theme = Theme.of(context);
    final config = _getSnackbarConfig(type, theme);

    _showCustom(
      context,
      content: Row(
        children: [
          Icon(config.icon, color: config.iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: config.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: config.backgroundColor,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      dismissible: dismissible,
    );
  }

  /// Internal method to show custom snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showCustom(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool dismissible = true,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    final snackBar = SnackBar(
      content: content,
      backgroundColor: backgroundColor,
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onActionPressed ?? () {},
              textColor: Colors.white.withOpacity(0.9),
            )
          : null,
      behavior: SnackBarBehavior.floating,
      margin: margin ?? const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      elevation: elevation ?? 6,
      dismissDirection: dismissible
          ? DismissDirection.horizontal
          : DismissDirection.none,
      clipBehavior: Clip.antiAlias,
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Gets snackbar configuration based on type
  static _SnackbarConfig _getSnackbarConfig(
    AppSnackbarType type,
    ThemeData theme,
  ) {
    switch (type) {
      case AppSnackbarType.success:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFF4CAF50),
          textColor: Colors.white,
          iconColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
      case AppSnackbarType.error:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFFF44336),
          textColor: Colors.white,
          iconColor: Colors.white,
          icon: Icons.error_outline,
        );
      case AppSnackbarType.warning:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFFFF9800),
          textColor: Colors.white,
          iconColor: Colors.white,
          icon: Icons.warning_amber_outlined,
        );
      case AppSnackbarType.info:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFF2196F3),
          textColor: Colors.white,
          iconColor: Colors.white,
          icon: Icons.info_outline,
        );
    }
  }
}

/// Snackbar configuration class
class _SnackbarConfig {
  const _SnackbarConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;
}

/// Snackbar types
enum AppSnackbarType { success, error, warning, info }

/// Toast-style snackbar that appears at the top
class AppToast {
  AppToast._();

  /// Shows a toast at the top of the screen
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    bool dismissible = true,
  }) {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final config = AppSnackbar._getSnackbarConfig(type, theme);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        config: config,
        onDismiss: () => overlayEntry.remove(),
        dismissible: dismissible,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    if (duration != Duration.zero) {
      Future.delayed(duration, () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    }
  }
}

/// Toast widget that appears at the top
class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.config,
    required this.onDismiss,
    required this.dismissible,
  });

  final String message;
  final _SnackbarConfig config;
  final VoidCallback onDismiss;
  final bool dismissible;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: widget.config.backgroundColor,
            child: GestureDetector(
              onTap: widget.dismissible ? _dismiss : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.config.icon,
                      color: widget.config.iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.config.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.dismissible) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close,
                          color: widget.config.iconColor.withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Advanced snackbar with progress indicator
class AppProgressSnackbar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _currentController;

  /// Shows a progress snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    double? progress,
    Color? backgroundColor,
    Color? progressColor,
    bool dismissible = false,
  }) {
    // Clear existing progress snackbar
    hide();

    final snackBar = SnackBar(
      content: _ProgressSnackbarContent(
        message: message,
        progress: progress,
        progressColor: progressColor,
      ),
      backgroundColor: backgroundColor ?? Colors.grey[800],
      duration: const Duration(days: 1), // Indefinite
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dismissDirection: dismissible
          ? DismissDirection.horizontal
          : DismissDirection.none,
    );

    _currentController = ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return _currentController!;
  }

  /// Updates the progress
  static void updateProgress(double progress) {
    // Progress updates would be handled through state management
    // This is a placeholder for the concept
  }

  /// Hides the progress snackbar
  static void hide() {
    _currentController?.close(SnackBarClosedReason.action);
    _currentController = null;
  }
}

/// Progress snackbar content widget
class _ProgressSnackbarContent extends StatelessWidget {
  const _ProgressSnackbarContent({
    required this.message,
    this.progress,
    this.progressColor,
  });

  final String message;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (progress == null) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: 8),
              Text(
                '${(progress! * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

/// Extension for easier context-based snackbar usage
extension AppSnackbarExtension on BuildContext {
  /// Shows success snackbar
  void showSuccess(String message, {String? action, VoidCallback? onAction}) {
    AppSnackbar.showSuccess(
      this,
      message: message,
      actionLabel: action,
      onActionPressed: onAction,
    );
  }

  /// Shows error snackbar
  void showError(String message, {String? action, VoidCallback? onAction}) {
    AppSnackbar.showError(
      this,
      message: message,
      actionLabel: action,
      onActionPressed: onAction,
    );
  }

  /// Shows warning snackbar
  void showWarning(String message, {String? action, VoidCallback? onAction}) {
    AppSnackbar.showWarning(
      this,
      message: message,
      actionLabel: action,
      onActionPressed: onAction,
    );
  }

  /// Shows info snackbar
  void showInfo(String message, {String? action, VoidCallback? onAction}) {
    AppSnackbar.showInfo(
      this,
      message: message,
      actionLabel: action,
      onActionPressed: onAction,
    );
  }

  /// Shows loading snackbar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    String message,
  ) {
    return AppSnackbar.showLoading(this, message: message);
  }

  /// Shows toast
  void showToast(
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
  }) {
    AppToast.show(this, message: message, type: type);
  }
}

/// Utility class for common snackbar messages
class AppSnackbarMessages {
  AppSnackbarMessages._();

  // Success messages
  static const String receiptUploaded = 'Receipt uploaded successfully';
  static const String receiptSaved = 'Receipt saved';
  static const String invoiceSent = 'Invoice sent successfully';
  static const String dataSync = 'Data synchronized';
  static const String settingsSaved = 'Settings saved';
  static const String accountCreated = 'Account created successfully';
  static const String passwordChanged = 'Password changed successfully';

  // Error messages
  static const String uploadFailed = 'Upload failed. Please try again';
  static const String networkError = 'Network error. Check your connection';
  static const String syncFailed = 'Sync failed. Will retry automatically';
  static const String invalidInput = 'Please check your input and try again';
  static const String authError = 'Authentication failed';
  static const String serverError = 'Server error. Please try again later';
  static const String storageError = 'Not enough storage space';

  // Warning messages
  static const String unsavedChanges = 'You have unsaved changes';
  static const String lowStorage = 'Storage space is running low';
  static const String offlineMode = 'You are offline. Changes will sync later';
  static const String subscription = 'Subscription expires soon';
  static const String largeFile = 'File size is large. Upload may take time';

  // Info messages
  static const String processing = 'Processing your request...';
  static const String uploading = 'Uploading receipt...';
  static const String syncing = 'Syncing data...';
  static const String loading = 'Loading...';
  static const String comingSoon = 'This feature is coming soon';
}
