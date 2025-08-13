// lib/core/theme/app_theme.dart

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receiptsly/core/theme/card_theme.dart';
import 'package:receiptsly/core/theme/icon_themes.dart';
import 'package:receiptsly/core/theme/input_decoration_theme.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';
import 'color_scheme.dart';
import 'app_bar_theme.dart';
import 'button_themes.dart';

import 'list_tile_theme.dart';
import 'chip_theme.dart';
import 'dialog_theme.dart';
import 'bottom_sheet_theme.dart';
import 'tab_bar_theme.dart';
import 'navigation_themes.dart';
import 'form_control_themes.dart';
import 'slider_theme.dart';
import 'progress_indicator_theme.dart';
import 'tooltip_theme.dart';
import 'snackbar_theme.dart';
import 'divider_theme.dart';
import 'scrollbar_theme.dart';
import 'data_table_theme.dart';
import 'menu_themes.dart';
import 'additional_themes.dart';
import 'system_overlay_styles.dart';
import 'theme_extension.dart';

/// Main theme configuration for Receiptsly
/// Provides complete light and dark themes with consistent styling
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// ==================== THEME CONSTANTS ====================

  static const String fontFamily = 'Inter';
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration longAnimationDuration = Duration(milliseconds: 300);

  /// ==================== LIGHT THEME ====================

  static ThemeData get lightTheme {
    return ThemeData(
      // Basic theme properties
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,

      // Color scheme
      colorScheme: AppColorScheme.lightColorScheme,

      // Typography
      textTheme: AppTypography.createTextTheme(),

      // Visual density for better touch targets
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Material properties
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

      // Platform brightness for adaptive components
      platform: TargetPlatform.iOS, // Adjust based on your needs
      // Component Themes - Using correct class names
      appBarTheme: AppBarThemes.lightAppBarTheme,
      cardTheme: CardThemes.lightCardTheme,
      elevatedButtonTheme: ButtonThemes.lightElevatedButtonTheme,
      textButtonTheme: ButtonThemes.lightTextButtonTheme,
      outlinedButtonTheme: ButtonThemes.lightOutlinedButtonTheme,
      iconButtonTheme: ButtonThemes.lightIconButtonTheme,
      floatingActionButtonTheme: ButtonThemes.lightFabTheme,
      inputDecorationTheme: InputDecorationThemes.lightInputDecorationTheme,
      iconTheme: IconThemes.lightIconTheme,
      primaryIconTheme: IconThemes.primaryIconTheme,
      listTileTheme: AppListTileTheme.lightListTileTheme,
      chipTheme: AppChipTheme.lightChipTheme,
      dialogTheme: AppDialogTheme.lightDialogTheme,
      bottomSheetTheme: AppBottomSheetTheme.lightBottomSheetTheme,
      tabBarTheme: AppTabBarTheme.lightTabBarTheme,
      bottomNavigationBarTheme: NavigationThemes.lightBottomNavTheme,
      navigationRailTheme: NavigationThemes.lightNavRailTheme,
      drawerTheme: NavigationThemes.lightDrawerTheme,
      switchTheme: FormControlThemes.lightSwitchTheme,
      checkboxTheme: FormControlThemes.lightCheckboxTheme,
      radioTheme: FormControlThemes.lightRadioTheme,
      sliderTheme: AppSliderTheme.lightSliderTheme,
      progressIndicatorTheme:
          AppProgressIndicatorTheme.lightProgressIndicatorTheme,
      tooltipTheme: AppTooltipTheme.lightTooltipTheme,
      snackBarTheme: AppSnackBarTheme.lightSnackBarTheme,
      dividerTheme: AppDividerTheme.lightDividerTheme,
      scrollbarTheme: AppScrollbarTheme.lightScrollbarTheme,
      dataTableTheme: AppDataTableTheme.lightDataTableTheme,
      menuTheme: MenuThemes.lightMenuTheme,
      popupMenuTheme: MenuThemes.lightPopupMenuTheme,
      bannerTheme: AdditionalThemes.lightBannerTheme,
      badgeTheme: AdditionalThemes.lightBadgeTheme,
      searchBarTheme: AdditionalThemes.lightSearchBarTheme,

      // Additional theme configurations
      splashColor: AppColors.primary.withOpacity(0.12),
      highlightColor: AppColors.primary.withOpacity(0.08),
      hoverColor: AppColors.primary.withOpacity(0.04),
      focusColor: AppColors.primary.withOpacity(0.12),

      // Scaffold theme
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightSurface,

      // Divider color
      dividerColor: AppColors.gray200,

      // Disabled color
      disabledColor: AppColors.gray400,

      // Hint color
      hintColor: AppColors.gray500,

      // Secondary header color
      secondaryHeaderColor: AppColors.gray100,

      // Selection color
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.selectionLight,
        selectionHandleColor: AppColors.primary,
      ),

      // Extensions
      extensions: [ReceiptslyThemeExtension.themeExtension],
    );
  }

  /// ==================== DARK THEME ====================

  static ThemeData get darkTheme {
    return ThemeData(
      // Basic theme properties
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,

      // Color scheme
      colorScheme: AppColorScheme.darkColorScheme,

      // Typography with dark theme colors
      textTheme: AppTypography.applyTextThemeColors(
        AppTypography.createTextTheme(),
        AppColors.darkTextPrimary,
      ),

      // Visual density for better touch targets
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Material properties
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

      // Platform brightness for adaptive components
      platform: TargetPlatform.iOS, // Adjust based on your needs
      // Component Themes - Using correct class names
      appBarTheme: AppBarThemes.darkAppBarTheme,
      cardTheme: CardThemes.darkCardTheme,
      elevatedButtonTheme: ButtonThemes.darkElevatedButtonTheme,
      textButtonTheme: ButtonThemes.darkTextButtonTheme,
      outlinedButtonTheme: ButtonThemes.darkOutlinedButtonTheme,
      iconButtonTheme: ButtonThemes.darkIconButtonTheme,
      floatingActionButtonTheme: ButtonThemes.darkFabTheme,
      inputDecorationTheme: InputDecorationThemes.darkInputDecorationTheme,
      iconTheme: IconThemes.darkIconTheme,
      primaryIconTheme: IconThemes.primaryIconTheme,
      listTileTheme: AppListTileTheme.darkListTileTheme,
      chipTheme: AppChipTheme.darkChipTheme,
      dialogTheme: AppDialogTheme.darkDialogTheme,
      bottomSheetTheme: AppBottomSheetTheme.darkBottomSheetTheme,
      tabBarTheme: AppTabBarTheme.darkTabBarTheme,
      bottomNavigationBarTheme: NavigationThemes.darkBottomNavTheme,
      navigationRailTheme: NavigationThemes.darkNavRailTheme,
      drawerTheme: NavigationThemes.darkDrawerTheme,
      switchTheme: FormControlThemes.darkSwitchTheme,
      checkboxTheme: FormControlThemes.darkCheckboxTheme,
      radioTheme: FormControlThemes.darkRadioTheme,
      sliderTheme: AppSliderTheme.darkSliderTheme,
      progressIndicatorTheme:
          AppProgressIndicatorTheme.darkProgressIndicatorTheme,
      tooltipTheme: AppTooltipTheme.darkTooltipTheme,
      snackBarTheme: AppSnackBarTheme.darkSnackBarTheme,
      dividerTheme: AppDividerTheme.darkDividerTheme,
      scrollbarTheme: AppScrollbarTheme.darkScrollbarTheme,
      dataTableTheme: AppDataTableTheme.darkDataTableTheme,
      menuTheme: MenuThemes.darkMenuTheme,
      popupMenuTheme: MenuThemes.darkPopupMenuTheme,
      bannerTheme: AdditionalThemes.darkBannerTheme,
      badgeTheme: AdditionalThemes.darkBadgeTheme,
      searchBarTheme: AdditionalThemes.darkSearchBarTheme,

      // Additional theme configurations
      splashColor: AppColors.primaryLight.withOpacity(0.12),
      highlightColor: AppColors.primaryLight.withOpacity(0.08),
      hoverColor: AppColors.primaryLight.withOpacity(0.04),
      focusColor: AppColors.primaryLight.withOpacity(0.12),

      // Scaffold theme
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkSurface,

      // Divider color
      dividerColor: AppColors.slate600,

      // Disabled color
      disabledColor: AppColors.slate500,

      // Hint color
      hintColor: AppColors.slate400,

      // Secondary header color
      secondaryHeaderColor: AppColors.slate800,

      // Selection color
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryLight,
        selectionColor: AppColors.selectionDark,
        selectionHandleColor: AppColors.primaryLight,
      ),

      // Extensions
      extensions: [ReceiptslyThemeExtension.darkThemeExtension],
    );
  }

  /// ==================== HELPER METHODS ====================

  /// Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Get system overlay style based on brightness
  static SystemUiOverlayStyle getSystemOverlayStyle(Brightness brightness) {
    return brightness == Brightness.dark
        ? SystemOverlayStyles.darkSystemOverlayStyle
        : SystemOverlayStyles.lightSystemOverlayStyle;
  }

  /// Get color scheme based on brightness
  static ColorScheme getColorScheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColorScheme.darkColorScheme
        : AppColorScheme.lightColorScheme;
  }

  /// Check if theme is dark
  static bool isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get theme-appropriate color
  static Color getThemeColor(
    BuildContext context,
    Color lightColor,
    Color darkColor,
  ) {
    return isDarkTheme(context) ? darkColor : lightColor;
  }

  /// Apply theme override for specific component
  static ThemeData applyThemeOverride(ThemeData baseTheme, ThemeData override) {
    return baseTheme.copyWith(
      colorScheme: override.colorScheme ?? baseTheme.colorScheme,
      textTheme: override.textTheme ?? baseTheme.textTheme,
      appBarTheme: override.appBarTheme ?? baseTheme.appBarTheme,
      elevatedButtonTheme:
          override.elevatedButtonTheme ?? baseTheme.elevatedButtonTheme,
      textButtonTheme: override.textButtonTheme ?? baseTheme.textButtonTheme,
      outlinedButtonTheme:
          override.outlinedButtonTheme ?? baseTheme.outlinedButtonTheme,
      iconButtonTheme: override.iconButtonTheme ?? baseTheme.iconButtonTheme,
      floatingActionButtonTheme:
          override.floatingActionButtonTheme ??
          baseTheme.floatingActionButtonTheme,
      inputDecorationTheme:
          override.inputDecorationTheme ?? baseTheme.inputDecorationTheme,
      cardTheme: override.cardTheme ?? baseTheme.cardTheme,
      dialogTheme: override.dialogTheme ?? baseTheme.dialogTheme,
      bottomSheetTheme: override.bottomSheetTheme ?? baseTheme.bottomSheetTheme,
      snackBarTheme: override.snackBarTheme ?? baseTheme.snackBarTheme,
    );
  }

  /// Create custom color scheme
  static ColorScheme createCustomColorScheme({
    required Color primary,
    required Color secondary,
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: brightness,
    );
  }

  /// Get responsive theme based on screen size
  static ThemeData getResponsiveTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTheme = getTheme(brightness);

    if (AppDimensions.isTablet(screenWidth) ||
        AppDimensions.isDesktop(screenWidth)) {
      // Adjust for larger screens
      return baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontSizeFactor: 1.1),
        appBarTheme: baseTheme.appBarTheme.copyWith(
          toolbarHeight: AppDimensions.appBarHeightLarge,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: baseTheme.elevatedButtonTheme.style?.copyWith(
            minimumSize: MaterialStateProperty.all(
              const Size(double.infinity, AppDimensions.buttonHeightLarge),
            ),
          ),
        ),
      );
    }

    return baseTheme;
  }

  /// Create theme with custom accent color
  static ThemeData createAccentTheme(Color accentColor, Brightness brightness) {
    final baseTheme = getTheme(brightness);
    final customColorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
    );

    return baseTheme.copyWith(
      colorScheme: customColorScheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.getContrastingTextColor(accentColor),
        ),
      ),
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: accentColor,
        foregroundColor: AppColors.getContrastingTextColor(accentColor),
      ),
    );
  }

  /// Get high contrast theme for accessibility
  static ThemeData getHighContrastTheme(Brightness brightness) {
    final baseTheme = getTheme(brightness);

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: brightness == Brightness.dark
            ? AppColors.white
            : AppColors.black,
        onPrimary: brightness == Brightness.dark
            ? AppColors.black
            : AppColors.white,
        surface: brightness == Brightness.dark
            ? AppColors.black
            : AppColors.white,
        onSurface: brightness == Brightness.dark
            ? AppColors.white
            : AppColors.black,
        outline: brightness == Brightness.dark
            ? AppColors.white
            : AppColors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightness == Brightness.dark
              ? AppColors.white
              : AppColors.black,
          foregroundColor: brightness == Brightness.dark
              ? AppColors.black
              : AppColors.white,
          side: BorderSide(
            color: brightness == Brightness.dark
                ? AppColors.white
                : AppColors.black,
            width: AppDimensions.borderWidthThick,
          ),
        ),
      ),
    );
  }

  /// Apply theme to system UI
  static void applySystemUiOverlay(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(getSystemOverlayStyle(brightness));
  }

  /// Get extension from theme
  static ReceiptslyThemeExtension getExtension(BuildContext context) {
    return Theme.of(context).extension<ReceiptslyThemeExtension>() ??
        ReceiptslyThemeExtension.themeExtension;
  }

  /// ==================== SPECIALIZED THEMES ====================

  /// Create compact theme for smaller devices
  static ThemeData createCompactTheme(Brightness brightness) {
    final baseTheme = getTheme(brightness);

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontSizeFactor: 0.9),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        toolbarHeight: AppDimensions.appBarHeightSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          minimumSize: MaterialStateProperty.all(
            const Size(double.infinity, AppDimensions.buttonHeightSmall),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD),
          ),
        ),
      ),
    );
  }

  /// Create large theme for accessibility
  static ThemeData createLargeTheme(Brightness brightness) {
    final baseTheme = getTheme(brightness);

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontSizeFactor: 1.3),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        toolbarHeight: AppDimensions.appBarHeightLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          minimumSize: MaterialStateProperty.all(
            const Size(double.infinity, AppDimensions.buttonHeightLarge),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXL,
              vertical: AppDimensions.spaceLG,
            ),
          ),
        ),
      ),
    );
  }

  /// Create business theme variant
  static ThemeData createBusinessTheme(Brightness brightness) {
    final baseTheme = getTheme(brightness);

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: brightness == Brightness.dark
            ? AppColors.slate200
            : AppColors.slate800,
        secondary: brightness == Brightness.dark
            ? AppColors.info
            : AppColors.infoDark,
      ),
    );
  }

  /// Create festive theme variant
  static ThemeData createFestiveTheme(Brightness brightness) {
    final baseTheme = getTheme(brightness);

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: brightness == Brightness.dark
            ? AppColors.warningLight
            : AppColors.warning,
        secondary: brightness == Brightness.dark
            ? AppColors.errorLight
            : AppColors.error,
      ),
    );
  }

  /// ==================== THEME TRANSITIONS ====================

  /// Create animated theme transition
  static Widget createThemeTransition({
    required Widget child,
    required ThemeData theme,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return AnimatedTheme(data: theme, duration: duration, child: child);
  }

  /// ==================== DEBUGGING HELPERS ====================

  /// Debug theme properties
  static void debugTheme(BuildContext context) {
    if (kDebugMode) {
      final theme = Theme.of(context);
      print('=== THEME DEBUG INFO ===');
      print('Brightness: ${theme.brightness}');
      print('Primary Color: ${theme.colorScheme.primary}');
      print('Surface Color: ${theme.colorScheme.surface}');
      print('Background Color: ${theme.colorScheme.background}');
      print('Text Theme: ${theme.textTheme.bodyMedium?.color}');
      print('=======================');
    }
  }
}
