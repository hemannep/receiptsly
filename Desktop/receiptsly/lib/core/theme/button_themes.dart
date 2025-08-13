// lib/core/theme/theme_parts/button_themes.dart

import 'package:flutter/material.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/theme/app_dimensions.dart';
import 'package:receiptsly/core/theme/app_typography.dart';

class ButtonThemes {
  static ElevatedButtonThemeData get lightElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.white,
          elevation: AppDimensions.elevation2,
          shadowColor: AppColors.primaryShadow,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLG,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontal,
            vertical: AppDimensions.buttonPaddingVertical,
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          maximumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: AppTypography.buttonPrimary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          animationDuration: const Duration(milliseconds: 200),
          enableFeedback: true,
          alignment: Alignment.center,
        ),
      );

  static ElevatedButtonThemeData get darkElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.white,
          elevation: AppDimensions.elevation2,
          shadowColor: AppColors.primaryShadow,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLG,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontal,
            vertical: AppDimensions.buttonPaddingVertical,
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          maximumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: AppTypography.buttonPrimary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          animationDuration: const Duration(milliseconds: 200),
          enableFeedback: true,
          alignment: Alignment.center,
        ),
      );

  static TextButtonThemeData get lightTextButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.buttonDisabled,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.buttonPaddingHorizontal,
        vertical: AppDimensions.buttonPaddingVertical,
      ),
      minimumSize: const Size(0, AppDimensions.buttonHeight),
      textStyle: AppTypography.buttonText,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: const Duration(milliseconds: 200),
      enableFeedback: true,
      alignment: Alignment.center,
    ),
  );

  static TextButtonThemeData get darkTextButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      disabledForegroundColor: AppColors.buttonDisabled,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.buttonPaddingHorizontal,
        vertical: AppDimensions.buttonPaddingVertical,
      ),
      minimumSize: const Size(0, AppDimensions.buttonHeight),
      textStyle: AppTypography.buttonText,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: const Duration(milliseconds: 200),
      enableFeedback: true,
      alignment: Alignment.center,
    ),
  );

  static OutlinedButtonThemeData get lightOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.buttonDisabled,
          backgroundColor: AppColors.transparent,
          surfaceTintColor: AppColors.transparent,
          side: const BorderSide(
            color: AppColors.primary,
            width: AppDimensions.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLG,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontal,
            vertical: AppDimensions.buttonPaddingVertical,
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          maximumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: AppTypography.buttonSecondary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          animationDuration: const Duration(milliseconds: 200),
          enableFeedback: true,
          alignment: Alignment.center,
        ),
      );

  static OutlinedButtonThemeData get darkOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.buttonDisabled,
          backgroundColor: AppColors.transparent,
          surfaceTintColor: AppColors.transparent,
          side: const BorderSide(
            color: AppColors.primaryLight,
            width: AppDimensions.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLG,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontal,
            vertical: AppDimensions.buttonPaddingVertical,
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          maximumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: AppTypography.buttonSecondary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          animationDuration: const Duration(milliseconds: 200),
          enableFeedback: true,
          alignment: Alignment.center,
        ),
      );

  static IconButtonThemeData get lightIconButtonTheme => IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.lightIconPrimary,
      disabledForegroundColor: AppColors.lightIconDisabled,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
      minimumSize: const Size(
        AppDimensions.minTapTarget,
        AppDimensions.minTapTarget,
      ),
      maximumSize: const Size(
        AppDimensions.minTapTarget,
        AppDimensions.minTapTarget,
      ),
      iconSize: AppDimensions.iconSizeLG,
      padding: const EdgeInsets.all(AppDimensions.spaceSM),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: const Duration(milliseconds: 200),
      enableFeedback: true,
    ),
  );

  static IconButtonThemeData get darkIconButtonTheme => IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.darkIconPrimary,
      disabledForegroundColor: AppColors.darkIconDisabled,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
      minimumSize: const Size(
        AppDimensions.minTapTarget,
        AppDimensions.minTapTarget,
      ),
      maximumSize: const Size(
        AppDimensions.minTapTarget,
        AppDimensions.minTapTarget,
      ),
      iconSize: AppDimensions.iconSizeLG,
      padding: const EdgeInsets.all(AppDimensions.spaceSM),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: const Duration(milliseconds: 200),
      enableFeedback: true,
    ),
  );

  static FloatingActionButtonThemeData get lightFabTheme =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledElevation: 0,
        elevation: AppDimensions.fabElevation,
        focusElevation: AppDimensions.elevation8,
        hoverElevation: AppDimensions.elevation8,
        highlightElevation: AppDimensions.elevation12,
        splashColor: AppColors.rippleLight,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusFull,
        ),
        enableFeedback: true,
        iconSize: AppDimensions.iconSizeLG,
        sizeConstraints: BoxConstraints.tightFor(
          width: AppDimensions.fabSize,
          height: AppDimensions.fabSize,
        ),
        smallSizeConstraints: BoxConstraints.tightFor(
          width: AppDimensions.fabSizeSmall,
          height: AppDimensions.fabSizeSmall,
        ),
        largeSizeConstraints: BoxConstraints.tightFor(
          width: AppDimensions.fabSizeLarge,
          height: AppDimensions.fabSizeLarge,
        ),
        extendedSizeConstraints: BoxConstraints.tightFor(
          height: AppDimensions.buttonHeightLarge,
        ),
        extendedIconLabelSpacing: AppDimensions.spaceSM,
        extendedPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
        ),
      );

  static FloatingActionButtonThemeData get darkFabTheme =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.black,
        disabledElevation: 0,
        elevation: AppDimensions.fabElevation,
        focusElevation: AppDimensions.elevation8,
        hoverElevation: AppDimensions.elevation8,
        highlightElevation: AppDimensions.elevation12,
        splashColor: AppColors.rippleDark,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusFull,
        ),
        enableFeedback: true,
        iconSize: AppDimensions.iconSizeLG,
        sizeConstraints: BoxConstraints.tightFor(
          width: AppDimensions.fabSize,
          height: AppDimensions.fabSize,
        ),
        smallSizeConstraints: BoxConstraints.tightFor(
          width: AppDimensions.fabSizeSmall,
          height: AppDimensions.fabSizeSmall,
        ),
        largeSizeConstraints: BoxConstraints.tightFor(
          width: AppDimensions.fabSizeLarge,
          height: AppDimensions.fabSizeLarge,
        ),
        extendedSizeConstraints: BoxConstraints.tightFor(
          height: AppDimensions.buttonHeightLarge,
        ),
        extendedIconLabelSpacing: AppDimensions.spaceSM,
        extendedPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
        ),
      );
}
