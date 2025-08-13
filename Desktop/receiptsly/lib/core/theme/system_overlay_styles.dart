// lib/core/theme/system_overlay_styles.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// System UI overlay style configurations for light and dark themes
class SystemOverlayStyles {
  SystemOverlayStyles._();

  /// ==================== LIGHT SYSTEM OVERLAY STYLE ====================

  static const SystemUiOverlayStyle lightSystemOverlayStyle =
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.lightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: AppColors.lightBorder,
        systemNavigationBarContrastEnforced: true,
      );

  /// ==================== DARK SYSTEM OVERLAY STYLE ====================

  static const SystemUiOverlayStyle darkSystemOverlayStyle =
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: AppColors.darkBorder,
        systemNavigationBarContrastEnforced: true,
      );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate system overlay style
  static SystemUiOverlayStyle getSystemOverlayStyle(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkSystemOverlayStyle
        : lightSystemOverlayStyle;
  }

  /// Create custom system overlay style
  static SystemUiOverlayStyle createCustomSystemOverlayStyle({
    Color? statusBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? statusBarBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
    Color? systemNavigationBarDividerColor,
    bool? systemNavigationBarContrastEnforced,
  }) {
    return SystemUiOverlayStyle(
      statusBarColor: statusBarColor ?? AppColors.transparent,
      statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
      statusBarBrightness: statusBarBrightness ?? Brightness.light,
      systemNavigationBarColor:
          systemNavigationBarColor ?? AppColors.lightBackground,
      systemNavigationBarIconBrightness:
          systemNavigationBarIconBrightness ?? Brightness.dark,
      systemNavigationBarDividerColor:
          systemNavigationBarDividerColor ?? AppColors.lightBorder,
      systemNavigationBarContrastEnforced:
          systemNavigationBarContrastEnforced ?? true,
    );
  }

  /// Create immersive system overlay style (hides system UI)
  static SystemUiOverlayStyle createImmersiveSystemOverlayStyle(
    Brightness brightness,
  ) {
    return SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: AppColors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: AppColors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  /// Create overlay style for specific color background
  static SystemUiOverlayStyle createColoredBackgroundOverlayStyle({
    required Color backgroundColor,
    required Brightness brightness,
  }) {
    final isDark = backgroundColor.computeLuminance() < 0.5;

    return SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: isDark
          ? AppColors.darkBorder
          : AppColors.lightBorder,
      systemNavigationBarContrastEnforced: true,
    );
  }

  /// Create overlay style for primary color background
  static SystemUiOverlayStyle createPrimaryBackgroundOverlayStyle() {
    return createColoredBackgroundOverlayStyle(
      backgroundColor: AppColors.primary,
      brightness: Brightness.dark, // Primary is typically dark
    );
  }

  /// Create overlay style for surface color background
  static SystemUiOverlayStyle createSurfaceBackgroundOverlayStyle(
    Brightness brightness,
  ) {
    return createColoredBackgroundOverlayStyle(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      brightness: brightness,
    );
  }

  /// Apply system overlay style
  static void applySystemOverlayStyle(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// Apply theme-appropriate system overlay style
  static void applyThemeSystemOverlayStyle(Brightness brightness) {
    applySystemOverlayStyle(getSystemOverlayStyle(brightness));
  }

  /// Hide system UI for immersive experience
  static void hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  /// Show system UI
  static void showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Set system UI mode with overlay style
  static void setSystemUIMode({
    required SystemUiMode mode,
    SystemUiOverlayStyle? overlayStyle,
  }) {
    SystemChrome.setEnabledSystemUIMode(mode);
    if (overlayStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    }
  }

  /// Set full screen mode
  static void setFullScreenMode(Brightness brightness) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    applySystemOverlayStyle(createImmersiveSystemOverlayStyle(brightness));
  }

  /// Exit full screen mode
  static void exitFullScreenMode(Brightness brightness) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    applyThemeSystemOverlayStyle(brightness);
  }
}
