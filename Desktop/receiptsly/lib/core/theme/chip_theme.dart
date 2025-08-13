// lib/core/theme/chip_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Chip theme configurations for light and dark themes
class AppChipTheme {
  AppChipTheme._();

  /// ==================== LIGHT CHIP THEME ====================

  static ChipThemeData get lightChipTheme => ChipThemeData(
    backgroundColor: AppColors.gray100,
    deleteIconColor: AppColors.lightIconSecondary,
    disabledColor: AppColors.gray200,
    selectedColor: AppColors.primaryExtraLight,
    secondarySelectedColor: AppColors.secondaryExtraLight,
    shadowColor: AppColors.shadowLight,
    surfaceTintColor: AppColors.transparent,
    labelStyle: AppTypography.labelMedium,
    secondaryLabelStyle: AppTypography.labelSmall,
    brightness: Brightness.light,
    elevation: AppDimensions.elevation1,
    pressElevation: AppDimensions.elevation2,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusFull),
    side: const BorderSide(color: AppColors.transparent),
    iconTheme: const IconThemeData(
      color: AppColors.lightIconSecondary,
      size: AppDimensions.chipIconSize,
    ),
    padding: AppDimensions.paddingHorizontalMD,
    labelPadding: AppDimensions.paddingHorizontalSM,
    checkmarkColor: AppColors.primary,
    showCheckmark: true,
  );

  /// ==================== DARK CHIP THEME ====================

  static ChipThemeData get darkChipTheme => ChipThemeData(
    backgroundColor: AppColors.slate700,
    deleteIconColor: AppColors.darkIconSecondary,
    disabledColor: AppColors.slate600,
    selectedColor: AppColors.primaryDark,
    secondarySelectedColor: AppColors.secondaryDark,
    shadowColor: AppColors.shadowDarkLight,
    surfaceTintColor: AppColors.transparent,
    labelStyle: AppTypography.withColor(
      AppTypography.labelMedium,
      AppColors.darkTextPrimary,
    ),
    secondaryLabelStyle: AppTypography.withColor(
      AppTypography.labelSmall,
      AppColors.darkTextSecondary,
    ),
    brightness: Brightness.dark,
    elevation: AppDimensions.elevation1,
    pressElevation: AppDimensions.elevation2,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusFull),
    side: const BorderSide(color: AppColors.transparent),
    iconTheme: const IconThemeData(
      color: AppColors.darkIconSecondary,
      size: AppDimensions.chipIconSize,
    ),
    padding: AppDimensions.paddingHorizontalMD,
    labelPadding: AppDimensions.paddingHorizontalSM,
    checkmarkColor: AppColors.primaryLight,
    showCheckmark: true,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate chip theme
  static ChipThemeData getChipTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkChipTheme : lightChipTheme;
  }

  /// Create custom chip theme with specific colors
  static ChipThemeData createCustomChipTheme({
    required Color backgroundColor,
    required Color selectedColor,
    required Color labelColor,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getChipTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
      labelStyle: AppTypography.withColor(baseTheme.labelStyle!, labelColor),
    );
  }

  /// Create filter chip theme
  static ChipThemeData createFilterChipTheme(Brightness brightness) {
    final baseTheme = getChipTheme(brightness);

    return baseTheme.copyWith(
      showCheckmark: false,
      selectedColor: brightness == Brightness.dark
          ? AppColors.primaryDark
          : AppColors.primaryLight,
      side: BorderSide(
        color: brightness == Brightness.dark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
        width: AppDimensions.borderWidth,
      ),
    );
  }

  /// Create action chip theme
  static ChipThemeData createActionChipTheme(Brightness brightness) {
    final baseTheme = getChipTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      elevation: AppDimensions.elevation2,
      pressElevation: AppDimensions.elevation4,
    );
  }
}
