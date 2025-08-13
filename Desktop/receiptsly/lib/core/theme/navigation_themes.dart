// lib/core/theme/navigation_themes.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Navigation theme configurations for light and dark themes
class NavigationThemes {
  NavigationThemes._();

  /// ==================== BOTTOM NAVIGATION BAR THEMES ====================

  static BottomNavigationBarThemeData get lightBottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.navigationLight,
        selectedItemColor: AppColors.navigationSelected,
        unselectedItemColor: AppColors.navigationUnselected,
        selectedLabelStyle: AppTypography.navigationLabel,
        unselectedLabelStyle: AppTypography.navigationLabel,
        selectedIconTheme: const IconThemeData(
          color: AppColors.navigationSelected,
          size: AppDimensions.navIconSize,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.navigationUnselected,
          size: AppDimensions.navIconSize,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevation8,
        enableFeedback: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      );

  static BottomNavigationBarThemeData get darkBottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.navigationDark,
        selectedItemColor: AppColors.navigationSelected,
        unselectedItemColor: AppColors.navigationUnselected,
        selectedLabelStyle: AppTypography.navigationLabel,
        unselectedLabelStyle: AppTypography.navigationLabel,
        selectedIconTheme: const IconThemeData(
          color: AppColors.navigationSelected,
          size: AppDimensions.navIconSize,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.navigationUnselected,
          size: AppDimensions.navIconSize,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevation8,
        enableFeedback: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      );

  /// ==================== NAVIGATION RAIL THEMES ====================

  static NavigationRailThemeData get lightNavRailTheme =>
      NavigationRailThemeData(
        backgroundColor: AppColors.navigationLight,
        selectedIconTheme: const IconThemeData(
          color: AppColors.navigationSelected,
          size: AppDimensions.navIconSize,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.navigationUnselected,
          size: AppDimensions.navIconSize,
        ),
        selectedLabelTextStyle: AppTypography.navigationLabel,
        unselectedLabelTextStyle: AppTypography.navigationLabel,
        groupAlignment: -1.0,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: AppColors.selectionLight,
        elevation: AppDimensions.elevation4,
        minWidth: AppDimensions.sidebarWidthCompact,
        minExtendedWidth: AppDimensions.sidebarWidth,
      );

  static NavigationRailThemeData get darkNavRailTheme =>
      NavigationRailThemeData(
        backgroundColor: AppColors.navigationDark,
        selectedIconTheme: const IconThemeData(
          color: AppColors.navigationSelected,
          size: AppDimensions.navIconSize,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.navigationUnselected,
          size: AppDimensions.navIconSize,
        ),
        selectedLabelTextStyle: AppTypography.navigationLabel,
        unselectedLabelTextStyle: AppTypography.navigationLabel,
        groupAlignment: -1.0,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: AppColors.selectionDark,
        elevation: AppDimensions.elevation4,
        minWidth: AppDimensions.sidebarWidthCompact,
        minExtendedWidth: AppDimensions.sidebarWidth,
      );

  /// ==================== DRAWER THEMES ====================

  static DrawerThemeData get lightDrawerTheme => const DrawerThemeData(
    backgroundColor: AppColors.lightSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.elevation16,
    shadowColor: AppColors.shadowMedium,
    scrimColor: AppColors.overlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(AppDimensions.radiusXL),
        bottomRight: Radius.circular(AppDimensions.radiusXL),
      ),
    ),
    width: AppDimensions.sidebarWidth,
    clipBehavior: Clip.antiAlias,
  );

  static DrawerThemeData get darkDrawerTheme => const DrawerThemeData(
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.elevation16,
    shadowColor: AppColors.shadowDarkMedium,
    scrimColor: AppColors.overlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(AppDimensions.radiusXL),
        bottomRight: Radius.circular(AppDimensions.radiusXL),
      ),
    ),
    width: AppDimensions.sidebarWidth,
    clipBehavior: Clip.antiAlias,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate bottom navigation theme
  static BottomNavigationBarThemeData getBottomNavTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkBottomNavTheme
        : lightBottomNavTheme;
  }

  /// Get theme-appropriate navigation rail theme
  static NavigationRailThemeData getNavRailTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkNavRailTheme : lightNavRailTheme;
  }

  /// Get theme-appropriate drawer theme
  static DrawerThemeData getDrawerTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkDrawerTheme : lightDrawerTheme;
  }

  /// Create custom bottom navigation theme
  static BottomNavigationBarThemeData createCustomBottomNavTheme({
    required Color backgroundColor,
    required Color selectedItemColor,
    required Color unselectedItemColor,
    BottomNavigationBarType? type,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getBottomNavTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      type: type ?? baseTheme.type,
    );
  }

  /// Create custom navigation rail theme
  static NavigationRailThemeData createCustomNavRailTheme({
    required Color backgroundColor,
    required Color selectedIconColor,
    required Color unselectedIconColor,
    Color? indicatorColor,
    NavigationRailLabelType? labelType,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getNavRailTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: backgroundColor,
      indicatorColor: indicatorColor ?? baseTheme.indicatorColor,
      labelType: labelType ?? baseTheme.labelType,
      selectedIconTheme: IconThemeData(
        color: selectedIconColor,
        size: AppDimensions.navIconSize,
      ),
      unselectedIconTheme: IconThemeData(
        color: unselectedIconColor,
        size: AppDimensions.navIconSize,
      ),
    );
  }

  /// Create compact navigation rail theme
  static NavigationRailThemeData createCompactNavRailTheme(
    Brightness brightness,
  ) {
    final baseTheme = getNavRailTheme(brightness);

    return baseTheme.copyWith(
      labelType: NavigationRailLabelType.none,
      minWidth: AppDimensions.sidebarWidthCompact,
      groupAlignment: 0.0,
    );
  }

  /// Create extended navigation rail theme
  static NavigationRailThemeData createExtendedNavRailTheme(
    Brightness brightness,
  ) {
    final baseTheme = getNavRailTheme(brightness);

    return baseTheme.copyWith(
      labelType: NavigationRailLabelType.all,
      minExtendedWidth: AppDimensions.sidebarWidthExpanded,
      groupAlignment: -1.0,
    );
  }
}
