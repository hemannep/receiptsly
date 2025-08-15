// lib/core/theme/snackbar_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Snackbar theme configurations for light and dark themes
class AppSnackBarTheme {
  AppSnackBarTheme._();

  /// ==================== LIGHT SNACKBAR THEME ====================

  static SnackBarThemeData get lightSnackBarTheme => SnackBarThemeData(
    backgroundColor: AppColors.gray800,
    elevation: AppDimensions.elevation6,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
    behavior: SnackBarBehavior.floating,
    insetPadding: AppDimensions.paddingLG,
    showCloseIcon: true,
    closeIconColor: AppColors.white,
    actionTextColor: AppColors.primaryLight,
    disabledActionTextColor: AppColors.gray400,
    contentTextStyle: AppTypography.withColor(
      AppTypography.snackbarMessage,
      AppColors.white,
    ),
    actionBackgroundColor: AppColors.transparent,
    dismissDirection: DismissDirection.horizontal,
  );

  /// ==================== DARK SNACKBAR THEME ====================

  static SnackBarThemeData get darkSnackBarTheme => SnackBarThemeData(
    backgroundColor: AppColors.gray200,
    elevation: AppDimensions.elevation6,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
    behavior: SnackBarBehavior.floating,
    insetPadding: AppDimensions.paddingLG,
    showCloseIcon: true,
    closeIconColor: AppColors.black,
    actionTextColor: AppColors.primary,
    disabledActionTextColor: AppColors.gray600,
    contentTextStyle: AppTypography.withColor(
      AppTypography.snackbarMessage,
      AppColors.black,
    ),
    actionBackgroundColor: AppColors.transparent,
    dismissDirection: DismissDirection.horizontal,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate snackbar theme
  static SnackBarThemeData getSnackBarTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkSnackBarTheme
        : lightSnackBarTheme;
  }

  /// Create custom snackbar theme
  static SnackBarThemeData createCustomSnackBarTheme({
    required Color backgroundColor,
    required Color textColor,
    Color? actionTextColor,
    SnackBarBehavior? behavior,
    double? elevation,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getSnackBarTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: backgroundColor,
      contentTextStyle: AppTypography.withColor(
        AppTypography.snackbarMessage,
        textColor,
      ),
      actionTextColor: actionTextColor ?? baseTheme.actionTextColor,
      behavior: behavior ?? baseTheme.behavior,
      elevation: elevation ?? baseTheme.elevation,
      shape: borderRadius != null
          ? RoundedRectangleBorder(borderRadius: borderRadius)
          : baseTheme.shape,
      insetPadding: padding ?? baseTheme.insetPadding,
    );
  }

  /// Create success snackbar theme
  static SnackBarThemeData createSuccessSnackBarTheme(Brightness brightness) {
    return createCustomSnackBarTheme(
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
      actionTextColor: AppColors.white,
      brightness: brightness,
    );
  }

  /// Create error snackbar theme
  static SnackBarThemeData createErrorSnackBarTheme(Brightness brightness) {
    return createCustomSnackBarTheme(
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      actionTextColor: AppColors.white,
      brightness: brightness,
    );
  }

  /// Create warning snackbar theme
  static SnackBarThemeData createWarningSnackBarTheme(Brightness brightness) {
    return createCustomSnackBarTheme(
      backgroundColor: AppColors.warning,
      textColor: AppColors.black,
      actionTextColor: AppColors.black,
      brightness: brightness,
    );
  }

  /// Create info snackbar theme
  static SnackBarThemeData createInfoSnackBarTheme(Brightness brightness) {
    return createCustomSnackBarTheme(
      backgroundColor: AppColors.info,
      textColor: AppColors.white,
      actionTextColor: AppColors.white,
      brightness: brightness,
    );
  }

  /// Create fixed snackbar theme (bottom of screen)
  static SnackBarThemeData createFixedSnackBarTheme(Brightness brightness) {
    final baseTheme = getSnackBarTheme(brightness);

    return baseTheme.copyWith(
      behavior: SnackBarBehavior.fixed,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  /// Create minimal snackbar theme
  static SnackBarThemeData createMinimalSnackBarTheme(Brightness brightness) {
    final baseTheme = getSnackBarTheme(brightness);

    return baseTheme.copyWith(
      elevation: 0,
      showCloseIcon: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      behavior: SnackBarBehavior.fixed,
    );
  }
}
