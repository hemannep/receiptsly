// lib/core/theme/data_table_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Data table theme configurations for light and dark themes
class AppDataTableTheme {
  AppDataTableTheme._();

  /// ==================== LIGHT DATA TABLE THEME ====================

  static DataTableThemeData get lightDataTableTheme => DataTableThemeData(
    decoration: BoxDecoration(
      color: AppColors.lightSurface,
      borderRadius: AppDimensions.borderRadiusLG,
      border: Border.all(
        color: AppColors.lightBorder,
        width: AppDimensions.borderWidth,
      ),
    ),
    columnSpacing: AppDimensions.spaceXL,
    horizontalMargin: AppDimensions.spaceLG,
    dividerThickness: AppDimensions.dividerThickness,
    checkboxHorizontalMargin: AppDimensions.spaceMD,
    dataRowColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.selectionLight;
      }
      if (states.contains(MaterialState.hovered)) {
        return AppColors.gray50;
      }
      return AppColors.transparent;
    }),
    dataRowHeight: AppDimensions.listItemHeight,
    dataRowMinHeight: AppDimensions.listItemHeightSmall,
    dataRowMaxHeight: AppDimensions.listItemHeightThreeLine,
    dataTextStyle: AppTypography.bodyMedium,
    headingRowColor: MaterialStateProperty.all(AppColors.gray50),
    headingRowHeight: AppDimensions.listItemHeight,
    headingTextStyle: AppTypography.withWeight(
      AppTypography.labelLarge,
      AppTypography.semiBold,
    ),
  );

  /// ==================== DARK DATA TABLE THEME ====================

  static DataTableThemeData get darkDataTableTheme => DataTableThemeData(
    decoration: BoxDecoration(
      color: AppColors.darkSurface,
      borderRadius: AppDimensions.borderRadiusLG,
      border: Border.all(
        color: AppColors.darkBorder,
        width: AppDimensions.borderWidth,
      ),
    ),
    columnSpacing: AppDimensions.spaceXL,
    horizontalMargin: AppDimensions.spaceLG,
    dividerThickness: AppDimensions.dividerThickness,
    checkboxHorizontalMargin: AppDimensions.spaceMD,
    dataRowColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.selectionDark;
      }
      if (states.contains(MaterialState.hovered)) {
        return AppColors.slate800;
      }
      return AppColors.transparent;
    }),
    dataRowHeight: AppDimensions.listItemHeight,
    dataRowMinHeight: AppDimensions.listItemHeightSmall,
    dataRowMaxHeight: AppDimensions.listItemHeightThreeLine,
    dataTextStyle: AppTypography.withColor(
      AppTypography.bodyMedium,
      AppColors.darkTextPrimary,
    ),
    headingRowColor: MaterialStateProperty.all(AppColors.slate800),
    headingRowHeight: AppDimensions.listItemHeight,
    headingTextStyle: AppTypography.withColor(
      AppTypography.withWeight(
        AppTypography.labelLarge,
        AppTypography.semiBold,
      ),
      AppColors.darkTextPrimary,
    ),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate data table theme
  static DataTableThemeData getDataTableTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkDataTableTheme
        : lightDataTableTheme;
  }

  /// Create custom data table theme
  static DataTableThemeData createCustomDataTableTheme({
    required Color backgroundColor,
    required Color borderColor,
    Color? headingRowColor,
    Color? selectedRowColor,
    Color? hoveredRowColor,
    double? dataRowHeight,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getDataTableTheme(brightness);

    return baseTheme.copyWith(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(
          color: borderColor,
          width: AppDimensions.borderWidth,
        ),
      ),
      headingRowColor: MaterialStateProperty.all(
        headingRowColor ??
            (brightness == Brightness.dark
                ? AppColors.slate800
                : AppColors.gray50),
      ),
      dataRowColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return selectedRowColor ??
              (brightness == Brightness.dark
                  ? AppColors.selectionDark
                  : AppColors.selectionLight);
        }
        if (states.contains(MaterialState.hovered)) {
          return hoveredRowColor ??
              (brightness == Brightness.dark
                  ? AppColors.slate800
                  : AppColors.gray50);
        }
        return AppColors.transparent;
      }),
      dataRowHeight: dataRowHeight ?? baseTheme.dataRowHeight,
    );
  }

  /// Create compact data table theme
  static DataTableThemeData createCompactDataTableTheme(Brightness brightness) {
    final baseTheme = getDataTableTheme(brightness);

    return baseTheme.copyWith(
      dataRowHeight: AppDimensions.listItemHeightSmall,
      dataRowMinHeight: AppDimensions.listItemHeightSmall - 8,
      headingRowHeight: AppDimensions.listItemHeightSmall,
      columnSpacing: AppDimensions.spaceLG,
      horizontalMargin: AppDimensions.spaceMD,
      checkboxHorizontalMargin: AppDimensions.spaceSM,
    );
  }

  /// Create dense data table theme
  static DataTableThemeData createDenseDataTableTheme(Brightness brightness) {
    final baseTheme = getDataTableTheme(brightness);

    return baseTheme.copyWith(
      dataRowHeight: AppDimensions.listItemHeightSmall - 4,
      dataRowMinHeight: AppDimensions.listItemHeightSmall - 8,
      headingRowHeight: AppDimensions.listItemHeightSmall,
      columnSpacing: AppDimensions.spaceMD,
      horizontalMargin: AppDimensions.spaceSM,
      dividerThickness: 0.5,
    );
  }

  /// Create borderless data table theme
  static DataTableThemeData createBorderlessDataTableTheme(
    Brightness brightness,
  ) {
    final baseTheme = getDataTableTheme(brightness);

    return baseTheme.copyWith(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
      ),
      dividerThickness: 0,
    );
  }

  /// Create striped data table theme
  static DataTableThemeData createStripedDataTableTheme(Brightness brightness) {
    final baseTheme = getDataTableTheme(brightness);

    return baseTheme.copyWith(
      dataRowColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return brightness == Brightness.dark
              ? AppColors.selectionDark
              : AppColors.selectionLight;
        }
        if (states.contains(MaterialState.hovered)) {
          return brightness == Brightness.dark
              ? AppColors.slate700
              : AppColors.gray100;
        }
        // This would need to be handled at the widget level for actual striping
        return AppColors.transparent;
      }),
    );
  }

  /// Create card-style data table theme
  static DataTableThemeData createCardDataTableTheme(Brightness brightness) {
    final baseTheme = getDataTableTheme(brightness);

    return baseTheme.copyWith(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: AppDimensions.borderRadiusXL,
        border: Border.all(
          color: brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          width: AppDimensions.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: brightness == Brightness.dark
                ? AppColors.shadowDarkLight
                : AppColors.shadowLight,
            blurRadius: AppDimensions.elevation4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
