// lib/core/theme/scrollbar_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Scrollbar theme configurations for light and dark themes
class AppScrollbarTheme {
  AppScrollbarTheme._();

  /// ==================== LIGHT SCROLLBAR THEME ====================

  static ScrollbarThemeData get lightScrollbarTheme => ScrollbarThemeData(
    thumbVisibility: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.dragged)) return true;
      if (states.contains(MaterialState.hovered)) return true;
      return false;
    }),
    trackVisibility: MaterialStateProperty.all(false),
    thumbColor: MaterialStateProperty.all(AppColors.gray400),
    trackColor: MaterialStateProperty.all(AppColors.gray100),
    trackBorderColor: MaterialStateProperty.all(AppColors.transparent),
    radius: const Radius.circular(AppDimensions.radiusLG),
    thickness: MaterialStateProperty.all(8.0),
    minThumbLength: 48.0,
    interactive: true,
    crossAxisMargin: 4.0,
    mainAxisMargin: 4.0,
  );

  /// ==================== DARK SCROLLBAR THEME ====================

  static ScrollbarThemeData get darkScrollbarTheme => ScrollbarThemeData(
    thumbVisibility: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.dragged)) return true;
      if (states.contains(MaterialState.hovered)) return true;
      return false;
    }),
    trackVisibility: MaterialStateProperty.all(false),
    thumbColor: MaterialStateProperty.all(AppColors.slate500),
    trackColor: MaterialStateProperty.all(AppColors.slate700),
    trackBorderColor: MaterialStateProperty.all(AppColors.transparent),
    radius: const Radius.circular(AppDimensions.radiusLG),
    thickness: MaterialStateProperty.all(8.0),
    minThumbLength: 48.0,
    interactive: true,
    crossAxisMargin: 4.0,
    mainAxisMargin: 4.0,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate scrollbar theme
  static ScrollbarThemeData getScrollbarTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkScrollbarTheme
        : lightScrollbarTheme;
  }

  /// Create custom scrollbar theme
  static ScrollbarThemeData createCustomScrollbarTheme({
    required Color thumbColor,
    Color? trackColor,
    double? thickness,
    Radius? radius,
    bool? interactive,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getScrollbarTheme(brightness);

    return baseTheme.copyWith(
      thumbColor: MaterialStateProperty.all(thumbColor),
      trackColor: MaterialStateProperty.all(
        trackColor ?? AppColors.transparent,
      ),
      thickness: MaterialStateProperty.all(thickness ?? 8.0),
      radius: radius ?? const Radius.circular(AppDimensions.radiusLG),
      interactive: interactive ?? true,
    );
  }

  /// Create always visible scrollbar theme
  static ScrollbarThemeData createAlwaysVisibleScrollbarTheme(
    Brightness brightness,
  ) {
    final baseTheme = getScrollbarTheme(brightness);

    return baseTheme.copyWith(
      thumbVisibility: MaterialStateProperty.all(true),
      trackVisibility: MaterialStateProperty.all(true),
    );
  }

  /// Create thin scrollbar theme
  static ScrollbarThemeData createThinScrollbarTheme(Brightness brightness) {
    return createCustomScrollbarTheme(
      thumbColor: brightness == Brightness.dark
          ? AppColors.slate400
          : AppColors.gray500,
      thickness: 4.0,
      radius: const Radius.circular(2.0),
      brightness: brightness,
    );
  }

  /// Create thick scrollbar theme
  static ScrollbarThemeData createThickScrollbarTheme(Brightness brightness) {
    return createCustomScrollbarTheme(
      thumbColor: brightness == Brightness.dark
          ? AppColors.slate400
          : AppColors.gray500,
      thickness: 12.0,
      radius: const Radius.circular(6.0),
      brightness: brightness,
    );
  }

  /// Create primary colored scrollbar theme
  static ScrollbarThemeData createPrimaryScrollbarTheme(Brightness brightness) {
    return createCustomScrollbarTheme(
      thumbColor: brightness == Brightness.dark
          ? AppColors.primaryLight
          : AppColors.primary,
      trackColor: brightness == Brightness.dark
          ? AppColors.primaryDark.withOpacity(0.3)
          : AppColors.primaryLight.withOpacity(0.3),
      brightness: brightness,
    );
  }

  /// Create minimal scrollbar theme (very subtle)
  static ScrollbarThemeData createMinimalScrollbarTheme(Brightness brightness) {
    final baseTheme = getScrollbarTheme(brightness);

    return baseTheme.copyWith(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.dragged)) {
          return brightness == Brightness.dark
              ? AppColors.slate400
              : AppColors.gray400;
        }
        if (states.contains(MaterialState.hovered)) {
          return brightness == Brightness.dark
              ? AppColors.slate500
              : AppColors.gray300;
        }
        return brightness == Brightness.dark
            ? AppColors.slate600.withOpacity(0.5)
            : AppColors.gray200.withOpacity(0.5);
      }),
      thickness: MaterialStateProperty.all(6.0),
      radius: const Radius.circular(3.0),
      crossAxisMargin: 2.0,
      mainAxisMargin: 2.0,
    );
  }
}
