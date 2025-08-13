// lib/core/theme/theme_parts/input_decoration_theme.dart

import 'package:flutter/material.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/theme/app_dimensions.dart';
import 'package:receiptsly/core/theme/app_typography.dart';

class InputDecorationThemes {
  static InputDecorationTheme get lightInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        alignLabelWithHint: false,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputFocused,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputError,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputError,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.lightBorderLight,
            width: AppDimensions.borderWidth,
          ),
        ),
        contentPadding: AppDimensions.paddingLG,
        isDense: false,
        isCollapsed: false,
        hintStyle: AppTypography.withColor(
          AppTypography.inputHint,
          AppColors.lightTextTertiary,
        ),
        labelStyle: AppTypography.withColor(
          AppTypography.inputLabel,
          AppColors.lightTextSecondary,
        ),
        floatingLabelStyle: AppTypography.withColor(
          AppTypography.inputLabel,
          AppColors.primary,
        ),
        helperStyle: AppTypography.withColor(
          AppTypography.inputHelper,
          AppColors.lightTextTertiary,
        ),
        helperMaxLines: 2,
        errorStyle: AppTypography.withColor(
          AppTypography.inputError,
          AppColors.error,
        ),
        errorMaxLines: 2,
        prefixIconColor: AppColors.lightIconSecondary,
        suffixIconColor: AppColors.lightIconSecondary,
        iconColor: AppColors.lightIconSecondary,
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
      );

  static InputDecorationTheme get darkInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,
        alignLabelWithHint: false,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputBorderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputBorderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputFocused,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputError,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.inputError,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          borderSide: const BorderSide(
            color: AppColors.darkBorderLight,
            width: AppDimensions.borderWidth,
          ),
        ),
        contentPadding: AppDimensions.paddingLG,
        isDense: false,
        isCollapsed: false,
        hintStyle: AppTypography.withColor(
          AppTypography.inputHint,
          AppColors.darkTextTertiary,
        ),
        labelStyle: AppTypography.withColor(
          AppTypography.inputLabel,
          AppColors.darkTextSecondary,
        ),
        floatingLabelStyle: AppTypography.withColor(
          AppTypography.inputLabel,
          AppColors.primaryLight,
        ),
        helperStyle: AppTypography.withColor(
          AppTypography.inputHelper,
          AppColors.darkTextTertiary,
        ),
        helperMaxLines: 2,
        errorStyle: AppTypography.withColor(
          AppTypography.inputError,
          AppColors.error,
        ),
        errorMaxLines: 2,
        prefixIconColor: AppColors.darkIconSecondary,
        suffixIconColor: AppColors.darkIconSecondary,
        iconColor: AppColors.darkIconSecondary,
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
      );
}
