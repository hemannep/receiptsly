// lib/core/theme/tooltip_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Tooltip theme configurations for light and dark themes
class AppTooltipTheme {
  AppTooltipTheme._();

  /// ==================== LIGHT TOOLTIP THEME ====================

  static TooltipThemeData get lightTooltipTheme => TooltipThemeData(
    height: null,
    padding: AppDimensions.paddingMD,
    margin: AppDimensions.paddingSM,
    verticalOffset: AppDimensions.spaceLG,
    preferBelow: true,
    excludeFromSemantics: false,
    enableFeedback: true,
    decoration: BoxDecoration(
      color: AppColors.gray800,
      borderRadius: AppDimensions.borderRadiusLG,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 4.0,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    textStyle: AppTypography.withColor(AppTypography.tooltip, AppColors.white),
    textAlign: TextAlign.center,
    triggerMode: TooltipTriggerMode.longPress,
    showDuration: const Duration(milliseconds: 1500),
    waitDuration: const Duration(milliseconds: 500),
    exitDuration: const Duration(milliseconds: 200),
  );

  /// ==================== DARK TOOLTIP THEME ====================

  static TooltipThemeData get darkTooltipTheme => TooltipThemeData(
    height: null,
    padding: AppDimensions.paddingMD,
    margin: AppDimensions.paddingSM,
    verticalOffset: AppDimensions.spaceLG,
    preferBelow: true,
    excludeFromSemantics: false,
    enableFeedback: true,
    decoration: BoxDecoration(
      color: AppColors.gray200,
      borderRadius: AppDimensions.borderRadiusLG,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDarkLight,
          blurRadius: 4.0,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    textStyle: AppTypography.withColor(AppTypography.tooltip, AppColors.black),
    textAlign: TextAlign.center,
    triggerMode: TooltipTriggerMode.longPress,
    showDuration: const Duration(milliseconds: 1500),
    waitDuration: const Duration(milliseconds: 500),
    exitDuration: const Duration(milliseconds: 200),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate tooltip theme
  static TooltipThemeData getTooltipTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTooltipTheme : lightTooltipTheme;
  }

  /// Create custom tooltip theme
  static TooltipThemeData createCustomTooltipTheme({
    required Color backgroundColor,
    required Color textColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Duration? showDuration,
    TooltipTriggerMode? triggerMode,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getTooltipTheme(brightness);

    return baseTheme.copyWith(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? AppDimensions.borderRadiusLG,
        boxShadow: [
          BoxShadow(
            color: brightness == Brightness.dark
                ? AppColors.shadowDarkLight
                : AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: AppTypography.withColor(AppTypography.tooltip, textColor),
      padding: padding ?? baseTheme.padding,
      showDuration: showDuration ?? baseTheme.showDuration,
      triggerMode: triggerMode ?? baseTheme.triggerMode,
    );
  }

  /// Create error tooltip theme
  static TooltipThemeData createErrorTooltipTheme(Brightness brightness) {
    return createCustomTooltipTheme(
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      brightness: brightness,
    );
  }

  /// Create success tooltip theme
  static TooltipThemeData createSuccessTooltipTheme(Brightness brightness) {
    return createCustomTooltipTheme(
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
      brightness: brightness,
    );
  }

  /// Create warning tooltip theme
  static TooltipThemeData createWarningTooltipTheme(Brightness brightness) {
    return createCustomTooltipTheme(
      backgroundColor: AppColors.warning,
      textColor: AppColors.black,
      brightness: brightness,
    );
  }

  /// Create info tooltip theme
  static TooltipThemeData createInfoTooltipTheme(Brightness brightness) {
    return createCustomTooltipTheme(
      backgroundColor: AppColors.info,
      textColor: AppColors.white,
      brightness: brightness,
    );
  }

  /// Create instant tooltip theme (shows immediately)
  static TooltipThemeData createInstantTooltipTheme(Brightness brightness) {
    final baseTheme = getTooltipTheme(brightness);

    return baseTheme.copyWith(
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: const Duration(milliseconds: 2000),
    );
  }

  /// Create persistent tooltip theme (stays visible longer)
  static TooltipThemeData createPersistentTooltipTheme(Brightness brightness) {
    final baseTheme = getTooltipTheme(brightness);

    return baseTheme.copyWith(
      showDuration: const Duration(milliseconds: 5000),
      triggerMode: TooltipTriggerMode.manual,
    );
  }
}
