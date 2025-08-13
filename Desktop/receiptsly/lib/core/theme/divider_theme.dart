// lib/core/theme/divider_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Divider theme configurations for light and dark themes
class AppDividerTheme {
  AppDividerTheme._();

  /// ==================== LIGHT DIVIDER THEME ====================

  static const DividerThemeData lightDividerTheme = DividerThemeData(
    color: AppColors.lightDivider,
    thickness: AppDimensions.dividerThickness,
    space: AppDimensions.spaceLG,
    indent: 0,
    endIndent: 0,
  );

  /// ==================== DARK DIVIDER THEME ====================

  static const DividerThemeData darkDividerTheme = DividerThemeData(
    color: AppColors.darkDivider,
    thickness: AppDimensions.dividerThickness,
    space: AppDimensions.spaceLG,
    indent: 0,
    endIndent: 0,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate divider theme
  static DividerThemeData getDividerTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkDividerTheme : lightDividerTheme;
  }

  /// Create custom divider theme
  static DividerThemeData createCustomDividerTheme({
    required Color color,
    double? thickness,
    double? space,
    double? indent,
    double? endIndent,
    Brightness brightness = Brightness.light,
  }) {
    return DividerThemeData(
      color: color,
      thickness: thickness ?? AppDimensions.dividerThickness,
      space: space ?? AppDimensions.spaceLG,
      indent: indent ?? 0,
      endIndent: endIndent ?? 0,
    );
  }

  /// Create thick divider theme
  static DividerThemeData createThickDividerTheme(Brightness brightness) {
    return createCustomDividerTheme(
      color: brightness == Brightness.dark
          ? AppColors.darkDivider
          : AppColors.lightDivider,
      thickness: 2.0,
      brightness: brightness,
    );
  }

  /// Create thin divider theme
  static DividerThemeData createThinDividerTheme(Brightness brightness) {
    return createCustomDividerTheme(
      color: brightness == Brightness.dark
          ? AppColors.darkDivider
          : AppColors.lightDivider,
      thickness: 0.5,
      brightness: brightness,
    );
  }

  /// Create indented divider theme
  static DividerThemeData createIndentedDividerTheme(
    Brightness brightness, {
    double indent = 16.0,
  }) {
    return createCustomDividerTheme(
      color: brightness == Brightness.dark
          ? AppColors.darkDivider
          : AppColors.lightDivider,
      indent: indent,
      endIndent: indent,
      brightness: brightness,
    );
  }

  /// Create section divider theme (with more space)
  static DividerThemeData createSectionDividerTheme(Brightness brightness) {
    return createCustomDividerTheme(
      color: brightness == Brightness.dark
          ? AppColors.darkDivider
          : AppColors.lightDivider,
      space: AppDimensions.spaceXXL,
      thickness: 1.0,
      brightness: brightness,
    );
  }

  /// Create list divider theme (minimal space)
  static DividerThemeData createListDividerTheme(Brightness brightness) {
    return createCustomDividerTheme(
      color: brightness == Brightness.dark
          ? AppColors.darkDivider
          : AppColors.lightDivider,
      space: AppDimensions.spaceMD,
      thickness: 0.5,
      brightness: brightness,
    );
  }
}
