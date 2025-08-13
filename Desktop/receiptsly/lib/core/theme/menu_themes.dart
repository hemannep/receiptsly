// lib/core/theme/menu_themes.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Menu theme configurations for light and dark themes
class MenuThemes {
  MenuThemes._();

  /// ==================== MENU THEMES ====================

  static MenuThemeData get lightMenuTheme => MenuThemeData(
    style: MenuStyle(
      backgroundColor: MaterialStateProperty.all(AppColors.lightSurface),
      surfaceTintColor: MaterialStateProperty.all(AppColors.transparent),
      elevation: MaterialStateProperty.all(AppDimensions.menuElevation),
      shadowColor: MaterialStateProperty.all(AppColors.shadowMedium),
      padding: MaterialStateProperty.all(AppDimensions.paddingMD),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
      ),
      side: MaterialStateProperty.all(
        const BorderSide(
          color: AppColors.lightBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
    ),
  );

  static MenuThemeData get darkMenuTheme => MenuThemeData(
    style: MenuStyle(
      backgroundColor: MaterialStateProperty.all(AppColors.darkSurface),
      surfaceTintColor: MaterialStateProperty.all(AppColors.transparent),
      elevation: MaterialStateProperty.all(AppDimensions.menuElevation),
      shadowColor: MaterialStateProperty.all(AppColors.shadowDarkMedium),
      padding: MaterialStateProperty.all(AppDimensions.paddingMD),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
      ),
      side: MaterialStateProperty.all(
        const BorderSide(
          color: AppColors.darkBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
    ),
  );

  /// ==================== POPUP MENU THEMES ====================

  static PopupMenuThemeData get lightPopupMenuTheme => PopupMenuThemeData(
    color: AppColors.lightSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.menuElevation,
    shadowColor: AppColors.shadowMedium,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
    position: PopupMenuPosition.under,
    enableFeedback: true,
    mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
    textStyle: AppTypography.bodyMedium,
    labelTextStyle: MaterialStateProperty.all(AppTypography.bodyMedium),
  );

  static PopupMenuThemeData get darkPopupMenuTheme => PopupMenuThemeData(
    color: AppColors.darkSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.menuElevation,
    shadowColor: AppColors.shadowDarkMedium,
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLG),
    position: PopupMenuPosition.under,
    enableFeedback: true,
    mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
    textStyle: AppTypography.withColor(
      AppTypography.bodyMedium,
      AppColors.darkTextPrimary,
    ),
    labelTextStyle: MaterialStateProperty.all(
      AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.darkTextPrimary,
      ),
    ),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate menu theme
  static MenuThemeData getMenuTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkMenuTheme : lightMenuTheme;
  }

  /// Get theme-appropriate popup menu theme
  static PopupMenuThemeData getPopupMenuTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkPopupMenuTheme
        : lightPopupMenuTheme;
  }

  /// Create custom menu theme
  static MenuThemeData createCustomMenuTheme({
    required Color backgroundColor,
    Color? borderColor,
    double? elevation,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Brightness brightness = Brightness.light,
  }) {
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: MaterialStateProperty.all(backgroundColor),
        surfaceTintColor: MaterialStateProperty.all(AppColors.transparent),
        elevation: MaterialStateProperty.all(
          elevation ?? AppDimensions.menuElevation,
        ),
        shadowColor: MaterialStateProperty.all(
          brightness == Brightness.dark
              ? AppColors.shadowDarkMedium
              : AppColors.shadowMedium,
        ),
        padding: MaterialStateProperty.all(padding ?? AppDimensions.paddingMD),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: borderRadius ?? AppDimensions.borderRadiusLG,
          ),
        ),
        side: MaterialStateProperty.all(
          BorderSide(
            color:
                borderColor ??
                (brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
    );
  }

  /// Create custom popup menu theme
  static PopupMenuThemeData createCustomPopupMenuTheme({
    required Color backgroundColor,
    Color? textColor,
    double? elevation,
    BorderRadius? borderRadius,
    PopupMenuPosition? position,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getPopupMenuTheme(brightness);

    return baseTheme.copyWith(
      color: backgroundColor,
      elevation: elevation ?? baseTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppDimensions.borderRadiusLG,
      ),
      position: position ?? baseTheme.position,
      textStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        textColor ??
            (brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
      ),
    );
  }

  /// Create context menu theme
  static PopupMenuThemeData createContextMenuTheme(Brightness brightness) {
    return createCustomPopupMenuTheme(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      elevation: AppDimensions.elevation8,
      position: PopupMenuPosition.over,
      brightness: brightness,
    );
  }

  /// Create dropdown menu theme
  static MenuThemeData createDropdownMenuTheme(Brightness brightness) {
    return createCustomMenuTheme(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      elevation: AppDimensions.elevation4,
      borderRadius: AppDimensions.borderRadiusMD,
      padding: AppDimensions.paddingSM,
      brightness: brightness,
    );
  }

  /// Create action menu theme
  static PopupMenuThemeData createActionMenuTheme(Brightness brightness) {
    return createCustomPopupMenuTheme(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.slate800
          : AppColors.white,
      elevation: AppDimensions.elevation12,
      borderRadius: AppDimensions.borderRadiusXL,
      brightness: brightness,
    );
  }

  /// Create minimal menu theme
  static MenuThemeData createMinimalMenuTheme(Brightness brightness) {
    return createCustomMenuTheme(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      borderColor: AppColors.transparent,
      elevation: 0,
      padding: AppDimensions.paddingXS,
      brightness: brightness,
    );
  }
}
