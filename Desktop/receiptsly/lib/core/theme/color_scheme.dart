// lib/core/theme/color_scheme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Color scheme configurations for light and dark themes
class AppColorScheme {
  AppColorScheme._();

  /// ==================== LIGHT COLOR SCHEME ====================

  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryExtraLight,
    onPrimaryContainer: AppColors.primaryExtraDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondaryExtraLight,
    onSecondaryContainer: AppColors.secondaryExtraDark,
    tertiary: AppColors.accent,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.accentLight,
    onTertiaryContainer: AppColors.accentDark,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorExtraLight,
    onErrorContainer: AppColors.errorDark,
    background: AppColors.lightBackground,
    onBackground: AppColors.lightTextPrimary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceVariant: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightBorderLight,
    shadow: AppColors.shadowLight,
    scrim: AppColors.overlay,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkTextPrimary,
    inversePrimary: AppColors.primaryLight,
  );

  /// ==================== DARK COLOR SCHEME ====================

  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryLight,
    onPrimary: AppColors.black,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryExtraLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryExtraLight,
    tertiary: AppColors.accentLight,
    onTertiary: AppColors.black,
    tertiaryContainer: AppColors.accentDark,
    onTertiaryContainer: AppColors.accentLight,
    error: AppColors.errorLight,
    onError: AppColors.black,
    errorContainer: AppColors.errorDark,
    onErrorContainer: AppColors.errorLight,
    background: AppColors.darkBackground,
    onBackground: AppColors.darkTextPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceVariant: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorderLight,
    shadow: AppColors.shadowDarkLight,
    scrim: AppColors.overlay,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightTextPrimary,
    inversePrimary: AppColors.primary,
  );

  /// ==================== HELPER METHODS ====================

  /// Get color scheme based on brightness
  static ColorScheme getColorScheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkColorScheme : lightColorScheme;
  }

  /// Create custom color scheme from seed color
  static ColorScheme createFromSeed({
    required Color seedColor,
    required Brightness brightness,
    Color? secondary,
    Color? tertiary,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      secondary: secondary,
      tertiary: tertiary,
    );
  }

  /// Create high contrast color scheme
  static ColorScheme createHighContrastColorScheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkColorScheme.copyWith(
            primary: AppColors.white,
            onPrimary: AppColors.black,
            surface: AppColors.black,
            onSurface: AppColors.white,
            outline: AppColors.white,
          )
        : lightColorScheme.copyWith(
            primary: AppColors.black,
            onPrimary: AppColors.white,
            surface: AppColors.white,
            onSurface: AppColors.black,
            outline: AppColors.black,
          );
  }
}
