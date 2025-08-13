// lib/presentation/widgets/common/app_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production-ready customizable button widget for Receiptsly app
/// Supports multiple variants, loading states, icons, and accessibility features
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.fullWidth = false,
    this.borderRadius,
    this.elevation,
    this.semanticLabel,
    this.tooltip,
    this.testKey,
  });

  /// Button text content
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Visual variant of the button
  final AppButtonVariant variant;

  /// Size variant of the button
  final AppButtonSize size;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button is enabled
  final bool isEnabled;

  /// Optional icon to display
  final IconData? icon;

  /// Position of icon relative to text
  final IconPosition iconPosition;

  /// Whether button should take full width
  final bool fullWidth;

  /// Custom border radius override
  final BorderRadius? borderRadius;

  /// Custom elevation override
  final double? elevation;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Tooltip text
  final String? tooltip;

  /// Test key for widget testing
  final String? testKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = _getButtonStyle(theme);
    final textStyle = _getTextStyle(theme);
    final buttonHeight = _getButtonHeight();
    final isInteractive = isEnabled && !isLoading && onPressed != null;

    Widget child = _buildButtonContent(context, textStyle);

    // Wrap with SizedBox for consistent height
    child = SizedBox(
      height: buttonHeight,
      width: fullWidth ? double.infinity : null,
      child: child,
    );

    // Add tooltip if provided
    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }

    // Add semantics for accessibility
    child = Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: isInteractive,
      child: child,
    );

    // Add test key if provided
    if (testKey != null) {
      child = Key(testKey!) != null ? child : child;
    }

    return child;
  }

  /// Builds the main button widget based on variant
  Widget _buildButtonContent(BuildContext context, TextStyle textStyle) {
    final content = _buildContentRow(context, textStyle);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: _getOnPressed(),
          style: _getButtonStyle(Theme.of(context)),
          child: content,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: _getOnPressed(),
          style: _getButtonStyle(Theme.of(context)),
          child: content,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: _getOnPressed(),
          style: _getButtonStyle(Theme.of(context)),
          child: content,
        );
      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: _getOnPressed(),
          style: _getButtonStyle(Theme.of(context)),
          child: content,
        );
    }
  }

  /// Builds the content row with text and optional icon/loading indicator
  Widget _buildContentRow(BuildContext context, TextStyle textStyle) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _getLoadingIndicatorSize(),
            height: _getLoadingIndicatorSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingIndicatorColor(theme),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    if (icon == null) {
      return Text(
        text,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    }

    final iconWidget = Icon(icon, size: _getIconSize(), color: textStyle.color);

    final textWidget = Text(
      text,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (iconPosition == IconPosition.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Flexible(child: textWidget),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: textWidget),
          const SizedBox(width: 8),
          iconWidget,
        ],
      );
    }
  }

  /// Gets the effective onPressed callback
  VoidCallback? _getOnPressed() {
    if (!isEnabled || isLoading) return null;

    return () {
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();
      onPressed?.call();
    };
  }

  /// Gets button style based on variant and theme
  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseStyle = _getBaseButtonStyle(theme);

    switch (variant) {
      case AppButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.disabledColor;
            }
            return theme.colorScheme.primary;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.38);
            }
            return theme.colorScheme.onPrimary;
          }),
        );

      case AppButtonVariant.secondary:
        return baseStyle.copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.38);
            }
            return theme.colorScheme.primary;
          }),
          side: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.12),
                width: 1,
              );
            }
            return BorderSide(color: theme.colorScheme.primary, width: 1);
          }),
        );

      case AppButtonVariant.text:
        return baseStyle.copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.38);
            }
            return theme.colorScheme.primary;
          }),
          elevation: MaterialStateProperty.all(0),
        );

      case AppButtonVariant.danger:
        return baseStyle.copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.disabledColor;
            }
            return theme.colorScheme.error;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.38);
            }
            return theme.colorScheme.onError;
          }),
        );
    }
  }

  /// Gets base button style with common properties
  ButtonStyle _getBaseButtonStyle(ThemeData theme) {
    return ButtonStyle(
      padding: MaterialStateProperty.all(_getPadding()),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius:
              borderRadius ?? BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      elevation: MaterialStateProperty.all(elevation ?? _getElevation()),
      animationDuration: const Duration(milliseconds: 200),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.comfortable,
    );
  }

  /// Gets text style based on size and theme
  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = switch (size) {
      AppButtonSize.small => theme.textTheme.labelSmall,
      AppButtonSize.medium => theme.textTheme.labelMedium,
      AppButtonSize.large => theme.textTheme.labelLarge,
    };

    return baseStyle?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ) ??
        const TextStyle();
  }

  /// Gets button height based on size
  double _getButtonHeight() {
    return switch (size) {
      AppButtonSize.small => 32.0,
      AppButtonSize.medium => 40.0,
      AppButtonSize.large => 48.0,
    };
  }

  /// Gets padding based on size
  EdgeInsets _getPadding() {
    return switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      AppButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      AppButtonSize.large => const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
    };
  }

  /// Gets border radius based on size
  double _getBorderRadius() {
    return switch (size) {
      AppButtonSize.small => 6.0,
      AppButtonSize.medium => 8.0,
      AppButtonSize.large => 10.0,
    };
  }

  /// Gets elevation based on variant
  double _getElevation() {
    return switch (variant) {
      AppButtonVariant.primary => 2.0,
      AppButtonVariant.secondary => 0.0,
      AppButtonVariant.text => 0.0,
      AppButtonVariant.danger => 2.0,
    };
  }

  /// Gets icon size based on button size
  double _getIconSize() {
    return switch (size) {
      AppButtonSize.small => 16.0,
      AppButtonSize.medium => 18.0,
      AppButtonSize.large => 20.0,
    };
  }

  /// Gets loading indicator size
  double _getLoadingIndicatorSize() {
    return switch (size) {
      AppButtonSize.small => 14.0,
      AppButtonSize.medium => 16.0,
      AppButtonSize.large => 18.0,
    };
  }

  /// Gets loading indicator color based on variant and theme
  Color _getLoadingIndicatorColor(ThemeData theme) {
    return switch (variant) {
      AppButtonVariant.primary => theme.colorScheme.onPrimary,
      AppButtonVariant.secondary => theme.colorScheme.primary,
      AppButtonVariant.text => theme.colorScheme.primary,
      AppButtonVariant.danger => theme.colorScheme.onError,
    };
  }
}

/// Button variant types
enum AppButtonVariant {
  primary, // Filled button with primary color
  secondary, // Outlined button
  text, // Text-only button
  danger, // Danger/error button
}

/// Button size variants
enum AppButtonSize { small, medium, large }

/// Icon position relative to text
enum IconPosition { left, right }

/// Extension methods for easier button creation
extension AppButtonExtension on AppButton {
  /// Creates a primary button
  static AppButton primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
    bool fullWidth = false,
    String? tooltip,
    AppButtonSize size = AppButtonSize.medium,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      fullWidth: fullWidth,
      tooltip: tooltip,
    );
  }

  /// Creates a secondary button
  static AppButton secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
    bool fullWidth = false,
    String? tooltip,
    AppButtonSize size = AppButtonSize.medium,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      fullWidth: fullWidth,
      tooltip: tooltip,
    );
  }

  /// Creates a text button
  static AppButton text({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
    String? tooltip,
    AppButtonSize size = AppButtonSize.medium,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.text,
      size: size,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      tooltip: tooltip,
    );
  }

  /// Creates a danger button
  static AppButton danger({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
    bool fullWidth = false,
    String? tooltip,
    AppButtonSize size = AppButtonSize.medium,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      size: size,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      fullWidth: fullWidth,
      tooltip: tooltip,
    );
  }
}
