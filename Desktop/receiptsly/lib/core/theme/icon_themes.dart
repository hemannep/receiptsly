// lib/core/theme/theme_parts/icon_themes.dart

import 'package:flutter/material.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/theme/app_dimensions.dart';

class IconThemes {
  static const IconThemeData lightIconTheme = IconThemeData(
    color: AppColors.lightIconPrimary,
    size: AppDimensions.iconSizeLG,
    opacity: 1.0,
  );

  static const IconThemeData darkIconTheme = IconThemeData(
    color: AppColors.darkIconPrimary,
    size: AppDimensions.iconSizeLG,
    opacity: 1.0,
  );

  static const IconThemeData primaryIconTheme = IconThemeData(
    color: AppColors.white,
    size: AppDimensions.iconSizeLG,
    opacity: 1.0,
  );
}
