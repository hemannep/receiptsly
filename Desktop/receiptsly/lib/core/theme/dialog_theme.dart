import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Dialog theme configurations for light and dark themes
class AppDialogTheme {
  AppDialogTheme._();

  /// ==================== LIGHT DIALOG THEME ====================

  static DialogTheme get lightDialogTheme => DialogTheme(
    backgroundColor: AppColors.lightSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.dialogElevation,
    shadowColor: AppColors.shadowMedium,
    alignment: Alignment.center,
    iconColor: AppColors.lightIconPrimary,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusXXL),
    clipBehavior: Clip.antiAlias,
    titleTextStyle: AppTypography.dialogTitle,
    contentTextStyle: AppTypography.dialogContent,
    actionsPadding: AppDimensions.paddingLG,
    insetPadding: AppDimensions.paddingXXL,
  );

  /// ==================== DARK DIALOG THEME ====================

  static DialogTheme get darkDialogTheme => DialogTheme(
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.dialogElevation,
    shadowColor: AppColors.shadowDarkMedium,
    alignment: Alignment.center,
    iconColor: AppColors.darkIconPrimary,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusXXL),
    clipBehavior: Clip.antiAlias,
    titleTextStyle: AppTypography.withColor(
      AppTypography.dialogTitle,
      AppColors.darkTextPrimary,
    ),
    contentTextStyle: AppTypography.withColor(
      AppTypography.dialogContent,
      AppColors.darkTextSecondary,
    ),
    actionsPadding: AppDimensions.paddingLG,
    insetPadding: AppDimensions.paddingXXL,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate dialog theme
  static DialogTheme getDialogTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkDialogTheme : lightDialogTheme;
  }

  /// Create custom dialog theme with specific styling
  static DialogTheme createCustomDialogTheme({
    required Color backgroundColor,
    required Color textColor,
    double? elevation,
    BorderRadius? borderRadius,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getDialogTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: backgroundColor,
      elevation: elevation ?? baseTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppDimensions.borderRadiusXXL,
      ),
      titleTextStyle: AppTypography.withColor(
        AppTypography.dialogTitle,
        textColor,
      ),
      contentTextStyle: AppTypography.withColor(
        AppTypography.dialogContent,
        textColor,
      ),
    );
  }

  /// Create alert dialog theme
  static DialogTheme createAlertDialogTheme(Brightness brightness) {
    final baseTheme = getDialogTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.errorDark
          : AppColors.errorExtraLight,
      iconColor: AppColors.error,
      titleTextStyle: AppTypography.withColor(
        AppTypography.dialogTitle,
        brightness == Brightness.dark
            ? AppColors.errorLight
            : AppColors.errorDark,
      ),
    );
  }

  /// Create full screen dialog theme
  static DialogTheme createFullScreenDialogTheme(Brightness brightness) {
    final baseTheme = getDialogTheme(brightness);

    return baseTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: EdgeInsets.zero,
      elevation: 0,
    );
  }
}
