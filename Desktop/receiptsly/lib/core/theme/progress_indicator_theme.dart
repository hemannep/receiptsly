// lib/core/theme/progress_indicator_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Progress indicator theme configurations for light and dark themes
class AppProgressIndicatorTheme {
  AppProgressIndicatorTheme._();

  /// ==================== LIGHT PROGRESS INDICATOR THEME ====================

  static const ProgressIndicatorThemeData lightProgressIndicatorTheme =
      ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.gray200,
        linearMinHeight: 4.0,
        circularTrackColor: AppColors.gray200,
        refreshBackgroundColor: AppColors.lightSurface,
      );

  /// ==================== DARK PROGRESS INDICATOR THEME ====================

  static const ProgressIndicatorThemeData darkProgressIndicatorTheme =
      ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.slate600,
        linearMinHeight: 4.0,
        circularTrackColor: AppColors.slate600,
        refreshBackgroundColor: AppColors.darkSurface,
      );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate progress indicator theme
  static ProgressIndicatorThemeData getProgressIndicatorTheme(
    Brightness brightness,
  ) {
    return brightness == Brightness.dark
        ? darkProgressIndicatorTheme
        : lightProgressIndicatorTheme;
  }

  /// Create custom progress indicator theme
  static ProgressIndicatorThemeData createCustomProgressIndicatorTheme({
    required Color color,
    Color? trackColor,
    Color? backgroundColor,
    double? linearMinHeight,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getProgressIndicatorTheme(brightness);

    return ProgressIndicatorThemeData(
      color: color,
      linearTrackColor: trackColor ?? baseTheme.linearTrackColor,
      circularTrackColor: trackColor ?? baseTheme.circularTrackColor,
      linearMinHeight: linearMinHeight ?? baseTheme.linearMinHeight,
      refreshBackgroundColor:
          backgroundColor ?? baseTheme.refreshBackgroundColor,
    );
  }

  /// Create success progress indicator theme
  static ProgressIndicatorThemeData createSuccessProgressIndicatorTheme(
    Brightness brightness,
  ) {
    return createCustomProgressIndicatorTheme(
      color: AppColors.success,
      brightness: brightness,
    );
  }

  /// Create warning progress indicator theme
  static ProgressIndicatorThemeData createWarningProgressIndicatorTheme(
    Brightness brightness,
  ) {
    return createCustomProgressIndicatorTheme(
      color: AppColors.warning,
      brightness: brightness,
    );
  }

  /// Create error progress indicator theme
  static ProgressIndicatorThemeData createErrorProgressIndicatorTheme(
    Brightness brightness,
  ) {
    return createCustomProgressIndicatorTheme(
      color: AppColors.error,
      brightness: brightness,
    );
  }

  /// Create thick linear progress indicator theme
  static ProgressIndicatorThemeData createThickLinearProgressIndicatorTheme(
    Brightness brightness,
  ) {
    return createCustomProgressIndicatorTheme(
      color: brightness == Brightness.dark
          ? AppColors.primaryLight
          : AppColors.primary,
      linearMinHeight: 8.0,
      brightness: brightness,
    );
  }

  /// Create thin linear progress indicator theme
  static ProgressIndicatorThemeData createThinLinearProgressIndicatorTheme(
    Brightness brightness,
  ) {
    return createCustomProgressIndicatorTheme(
      color: brightness == Brightness.dark
          ? AppColors.primaryLight
          : AppColors.primary,
      linearMinHeight: 2.0,
      brightness: brightness,
    );
  }
}
