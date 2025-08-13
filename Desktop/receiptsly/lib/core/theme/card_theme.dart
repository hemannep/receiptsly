// lib/core/theme/theme_parts/card_theme.dart

import 'package:flutter/material.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/theme/app_dimensions.dart';

class CardThemes {
  static CardTheme get lightCardTheme => CardTheme(
    color: AppColors.cardLight,
    shadowColor: AppColors.cardElevation,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.cardElevation,
    margin: AppDimensions.paddingMD,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: AppDimensions.borderRadiusXL,
      side: const BorderSide(
        color: AppColors.cardBorder,
        width: AppDimensions.borderWidth,
      ),
    ),
  );

  static CardTheme get darkCardTheme => CardTheme(
    color: AppColors.cardDark,
    shadowColor: AppColors.cardElevation,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.cardElevation,
    margin: AppDimensions.paddingMD,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: AppDimensions.borderRadiusXL,
      side: const BorderSide(
        color: AppColors.cardBorderDark,
        width: AppDimensions.borderWidth,
      ),
    ),
  );
}
