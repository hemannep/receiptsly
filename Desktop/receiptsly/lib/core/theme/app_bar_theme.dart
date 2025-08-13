// lib/core/theme/theme_parts/app_bar_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/theme/app_dimensions.dart';
import 'package:receiptsly/core/theme/app_typography.dart';
import 'package:receiptsly/core/theme/system_overlay_styles.dart';

class AppBarThemes {
  static AppBarTheme get lightAppBarTheme => AppBarTheme(
    backgroundColor: AppColors.appBarLight,
    foregroundColor: AppColors.lightTextPrimary,
    elevation: AppDimensions.appBarElevation,
    shadowColor: AppColors.shadowLight,
    surfaceTintColor: AppColors.transparent,
    centerTitle: true,
    titleSpacing: AppDimensions.spaceLG,
    toolbarHeight: AppDimensions.appBarHeight,
    systemOverlayStyle: SystemOverlayStyles.lightSystemOverlayStyle,
    titleTextStyle: AppTypography.withColor(
      AppTypography.titleLarge,
      AppColors.lightTextPrimary,
    ),
    toolbarTextStyle: AppTypography.withColor(
      AppTypography.bodyMedium,
      AppColors.lightTextSecondary,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.lightIconPrimary,
      size: AppDimensions.appBarIconSize,
    ),
    actionsIconTheme: const IconThemeData(
      color: AppColors.lightIconPrimary,
      size: AppDimensions.appBarIconSize,
    ),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  );

  static AppBarTheme get darkAppBarTheme => AppBarTheme(
    backgroundColor: AppColors.appBarDark,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: AppDimensions.appBarElevation,
    shadowColor: AppColors.shadowDarkLight,
    surfaceTintColor: AppColors.transparent,
    centerTitle: true,
    titleSpacing: AppDimensions.spaceLG,
    toolbarHeight: AppDimensions.appBarHeight,
    systemOverlayStyle: SystemOverlayStyles.darkSystemOverlayStyle,
    titleTextStyle: AppTypography.withColor(
      AppTypography.titleLarge,
      AppColors.darkTextPrimary,
    ),
    toolbarTextStyle: AppTypography.withColor(
      AppTypography.bodyMedium,
      AppColors.darkTextSecondary,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.darkIconPrimary,
      size: AppDimensions.appBarIconSize,
    ),
    actionsIconTheme: const IconThemeData(
      color: AppColors.darkIconPrimary,
      size: AppDimensions.appBarIconSize,
    ),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  );
}
