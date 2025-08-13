// lib/core/theme/tab_bar_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Tab bar theme configurations for light and dark themes
class AppTabBarTheme {
  AppTabBarTheme._();

  /// ==================== LIGHT TAB BAR THEME ====================

  static TabBarTheme get lightTabBarTheme => TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.lightTextTertiary,
    labelStyle: AppTypography.tabLabel,
    unselectedLabelStyle: AppTypography.tabLabel,
    indicator: UnderlineTabIndicator(
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: AppDimensions.borderWidthThick,
      ),
      insets: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
    ),
    indicatorColor: AppColors.primary,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: AppColors.lightDivider,
    overlayColor: MaterialStateProperty.all(AppColors.rippleLight),
    splashFactory: InkRipple.splashFactory,
    mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
    tabAlignment: TabAlignment.center,
  );

  /// ==================== DARK TAB BAR THEME ====================

  static TabBarTheme get darkTabBarTheme => TabBarTheme(
    labelColor: AppColors.primaryLight,
    unselectedLabelColor: AppColors.darkTextTertiary,
    labelStyle: AppTypography.withColor(
      AppTypography.tabLabel,
      AppColors.primaryLight,
    ),
    unselectedLabelStyle: AppTypography.withColor(
      AppTypography.tabLabel,
      AppColors.darkTextTertiary,
    ),
    indicator: UnderlineTabIndicator(
      borderSide: const BorderSide(
        color: AppColors.primaryLight,
        width: AppDimensions.borderWidthThick,
      ),
      insets: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
    ),
    indicatorColor: AppColors.primaryLight,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: AppColors.darkDivider,
    overlayColor: MaterialStateProperty.all(AppColors.rippleDark),
    splashFactory: InkRipple.splashFactory,
    mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
    tabAlignment: TabAlignment.center,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate tab bar theme
  static TabBarTheme getTabBarTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTabBarTheme : lightTabBarTheme;
  }

  /// Create custom tab bar theme
  static TabBarTheme createCustomTabBarTheme({
    required Color labelColor,
    required Color unselectedLabelColor,
    required Color indicatorColor,
    TabBarIndicatorSize? indicatorSize,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getTabBarTheme(brightness);

    return baseTheme.copyWith(
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      indicatorColor: indicatorColor,
      indicatorSize: indicatorSize ?? baseTheme.indicatorSize,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: indicatorColor,
          width: AppDimensions.borderWidthThick,
        ),
        insets: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
      ),
    );
  }

  /// Create pill-style tab bar theme
  static TabBarTheme createPillTabBarTheme(Brightness brightness) {
    final baseTheme = getTabBarTheme(brightness);

    return baseTheme.copyWith(
      indicator: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        borderRadius: AppDimensions.borderRadiusFull,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: brightness == Brightness.dark
          ? AppColors.primaryLight
          : AppColors.primary,
      unselectedLabelColor: brightness == Brightness.dark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
    );
  }

  /// Create secondary tab bar theme
  static TabBarTheme createSecondaryTabBarTheme(Brightness brightness) {
    final baseTheme = getTabBarTheme(brightness);

    return baseTheme.copyWith(
      labelColor: brightness == Brightness.dark
          ? AppColors.secondaryLight
          : AppColors.secondary,
      indicatorColor: brightness == Brightness.dark
          ? AppColors.secondaryLight
          : AppColors.secondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: brightness == Brightness.dark
              ? AppColors.secondaryLight
              : AppColors.secondary,
          width: AppDimensions.borderWidthThick,
        ),
        insets: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
      ),
    );
  }
}
