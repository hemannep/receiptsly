// lib/core/theme/list_tile_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart' as colors;
import 'app_typography.dart';
import 'app_dimensions.dart';

/// List tile theme configurations for light and dark themes
class AppListTileTheme {
  AppListTileTheme._();

  /// ==================== LIGHT LIST TILE THEME ====================

  static ListTileThemeData get lightListTileTheme => ListTileThemeData(
    tileColor: colors.AppColors.transparent,
    selectedTileColor: colors.AppColors.selectionLight,
    selectedColor: colors.AppColors.primary,
    iconColor: colors.AppColors.lightIconSecondary,
    textColor: colors.AppColors.lightTextPrimary,
    contentPadding: AppDimensions.paddingHorizontalLG,
    horizontalTitleGap: AppDimensions.spaceMD,
    minVerticalPadding: AppDimensions.spaceMD,
    minLeadingWidth: AppDimensions.iconSizeLG + AppDimensions.spaceMD,
    enableFeedback: true,
    mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
    visualDensity: VisualDensity.standard,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
    style: ListTileStyle.list,
    titleTextStyle: AppTypography.listTitle,
    subtitleTextStyle: AppTypography.listSubtitle,
    leadingAndTrailingTextStyle: AppTypography.listCaption,
  );

  /// ==================== DARK LIST TILE THEME ====================

  static ListTileThemeData get darkListTileTheme => ListTileThemeData(
    tileColor: colors.AppColors.transparent,
    selectedTileColor: colors.AppColors.selectionDark,
    selectedColor: colors.AppColors.primaryLight,
    iconColor: colors.AppColors.darkIconSecondary,
    textColor: colors.AppColors.darkTextPrimary,
    contentPadding: AppDimensions.paddingHorizontalLG,
    horizontalTitleGap: AppDimensions.spaceMD,
    minVerticalPadding: AppDimensions.spaceMD,
    minLeadingWidth: AppDimensions.iconSizeLG + AppDimensions.spaceMD,
    enableFeedback: true,
    mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
    visualDensity: VisualDensity.standard,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
    style: ListTileStyle.list,
    titleTextStyle: AppTypography.withColor(
      AppTypography.listTitle,
      colors.AppColors.darkTextPrimary,
    ),
    subtitleTextStyle: AppTypography.withColor(
      AppTypography.listSubtitle,
      colors.AppColors.darkTextSecondary,
    ),
    leadingAndTrailingTextStyle: AppTypography.withColor(
      AppTypography.listCaption,
      colors.AppColors.darkTextTertiary,
    ),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate list tile theme
  static ListTileThemeData getListTileTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkListTileTheme
        : lightListTileTheme;
  }

  /// Create custom list tile theme with specific colors
  static ListTileThemeData createCustomListTileTheme({
    required Color backgroundColor,
    required Color selectedColor,
    required Color textColor,
    required Color iconColor,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getListTileTheme(brightness);

    return baseTheme.copyWith(
      tileColor: backgroundColor,
      selectedColor: selectedColor,
      textColor: textColor,
      iconColor: iconColor,
    );
  }
}
