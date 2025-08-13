// lib/core/theme/additional_themes.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Additional theme configurations for specialized components
class AdditionalThemes {
  AdditionalThemes._();

  /// ==================== BANNER THEMES ====================

  static MaterialBannerThemeData get lightBannerTheme =>
      MaterialBannerThemeData(
        backgroundColor: AppColors.infoSurface,
        surfaceTintColor: AppColors.transparent,
        elevation: AppDimensions.elevation2,
        shadowColor: AppColors.shadowLight,
        dividerColor: AppColors.lightDivider,
        contentTextStyle: AppTypography.bodyMedium,
        padding: AppDimensions.paddingLG,
        leadingPadding: AppDimensions.paddingLG,
      );

  static MaterialBannerThemeData get darkBannerTheme => MaterialBannerThemeData(
    backgroundColor: AppColors.darkSurfaceVariant,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.elevation2,
    shadowColor: AppColors.shadowDarkLight,
    dividerColor: AppColors.darkDivider,
    contentTextStyle: AppTypography.withColor(
      AppTypography.bodyMedium,
      AppColors.darkTextPrimary,
    ),
    padding: AppDimensions.paddingLG,
    leadingPadding: AppDimensions.paddingLG,
  );

  /// ==================== BADGE THEMES ====================

  static final BadgeThemeData lightBadgeTheme = BadgeThemeData(
    backgroundColor: AppColors.error,
    textColor: AppColors.white,
    smallSize: 12.0,
    largeSize: 16.0,
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
    alignment: AlignmentDirectional.topEnd,
    offset: const Offset(4, -4),
    textStyle: AppTypography.labelSmall,
  );

  static final BadgeThemeData darkBadgeTheme = BadgeThemeData(
    backgroundColor: AppColors.errorLight,
    textColor: AppColors.black,
    smallSize: 12.0,
    largeSize: 16.0,
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
    alignment: AlignmentDirectional.topEnd,
    offset: const Offset(4, -4),
    textStyle: AppTypography.labelSmall,
  );

  /// ==================== SEARCH BAR THEMES ====================

  static SearchBarThemeData get lightSearchBarTheme => SearchBarThemeData(
    backgroundColor: MaterialStateProperty.all(AppColors.lightSurfaceVariant),
    surfaceTintColor: MaterialStateProperty.all(AppColors.transparent),
    elevation: MaterialStateProperty.all(AppDimensions.elevation1),
    shadowColor: MaterialStateProperty.all(AppColors.shadowLight),
    overlayColor: MaterialStateProperty.all(AppColors.overlay),
    side: MaterialStateProperty.all(
      const BorderSide(
        color: AppColors.lightBorder,
        width: AppDimensions.borderWidth,
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusFull),
    ),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
    ),
    textStyle: MaterialStateProperty.all(AppTypography.bodyLarge),
    hintStyle: MaterialStateProperty.all(
      AppTypography.withColor(
        AppTypography.bodyLarge,
        AppColors.lightTextTertiary,
      ),
    ),
    constraints: const BoxConstraints(
      minHeight: AppDimensions.inputHeightLarge,
      maxHeight: AppDimensions.inputHeightLarge,
    ),
  );

  static SearchBarThemeData get darkSearchBarTheme => SearchBarThemeData(
    backgroundColor: MaterialStateProperty.all(AppColors.darkSurfaceVariant),
    surfaceTintColor: MaterialStateProperty.all(AppColors.transparent),
    elevation: MaterialStateProperty.all(AppDimensions.elevation1),
    shadowColor: MaterialStateProperty.all(AppColors.shadowDarkLight),
    overlayColor: MaterialStateProperty.all(AppColors.overlay),
    side: MaterialStateProperty.all(
      const BorderSide(
        color: AppColors.darkBorder,
        width: AppDimensions.borderWidth,
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusFull),
    ),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
    ),
    textStyle: MaterialStateProperty.all(
      AppTypography.withColor(
        AppTypography.bodyLarge,
        AppColors.darkTextPrimary,
      ),
    ),
    hintStyle: MaterialStateProperty.all(
      AppTypography.withColor(
        AppTypography.bodyLarge,
        AppColors.darkTextTertiary,
      ),
    ),
    constraints: const BoxConstraints(
      minHeight: AppDimensions.inputHeightLarge,
      maxHeight: AppDimensions.inputHeightLarge,
    ),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate banner theme
  static MaterialBannerThemeData getBannerTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkBannerTheme : lightBannerTheme;
  }

  /// Get theme-appropriate badge theme
  static BadgeThemeData getBadgeTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkBadgeTheme : lightBadgeTheme;
  }

  /// Get theme-appropriate search bar theme
  static SearchBarThemeData getSearchBarTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkSearchBarTheme
        : lightSearchBarTheme;
  }

  /// Create custom banner theme
  static MaterialBannerThemeData createCustomBannerTheme({
    required Color backgroundColor,
    Color? textColor,
    Color? dividerColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialBannerThemeData(
      backgroundColor: backgroundColor,
      surfaceTintColor: AppColors.transparent,
      elevation: elevation ?? AppDimensions.elevation2,
      shadowColor: brightness == Brightness.dark
          ? AppColors.shadowDarkLight
          : AppColors.shadowLight,
      dividerColor:
          dividerColor ??
          (brightness == Brightness.dark
              ? AppColors.darkDivider
              : AppColors.lightDivider),
      contentTextStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        textColor ??
            (brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
      ),
      padding: padding ?? AppDimensions.paddingLG,
      leadingPadding: padding ?? AppDimensions.paddingLG,
    );
  }

  /// Create success banner theme
  static MaterialBannerThemeData createSuccessBannerTheme(
    Brightness brightness,
  ) {
    return createCustomBannerTheme(
      backgroundColor: AppColors.successSurface,
      textColor: AppColors.successDark,
      brightness: brightness,
    );
  }

  /// Create error banner theme
  static MaterialBannerThemeData createErrorBannerTheme(Brightness brightness) {
    return createCustomBannerTheme(
      backgroundColor: AppColors.errorSurface,
      textColor: AppColors.errorDark,
      brightness: brightness,
    );
  }

  /// Create warning banner theme
  static MaterialBannerThemeData createWarningBannerTheme(
    Brightness brightness,
  ) {
    return createCustomBannerTheme(
      backgroundColor: AppColors.warningSurface,
      textColor: AppColors.warningDark,
      brightness: brightness,
    );
  }

  /// Create custom badge theme
  static BadgeThemeData createCustomBadgeTheme({
    required Color backgroundColor,
    required Color textColor,
    double? smallSize,
    double? largeSize,
    AlignmentGeometry? alignment,
    Offset? offset,
  }) {
    return BadgeThemeData(
      backgroundColor: backgroundColor,
      textColor: textColor,
      smallSize: smallSize ?? 12.0,
      largeSize: largeSize ?? 16.0,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
      alignment: alignment ?? AlignmentDirectional.topEnd,
      offset: offset ?? const Offset(4, -4),
      textStyle: AppTypography.labelSmall,
    );
  }

  /// Create notification badge theme
  static BadgeThemeData createNotificationBadgeTheme(Brightness brightness) {
    return createCustomBadgeTheme(
      backgroundColor: AppColors.primary,
      textColor: AppColors.white,
      smallSize: 8.0,
      largeSize: 12.0,
    );
  }

  /// Create success badge theme
  static BadgeThemeData createSuccessBadgeTheme(Brightness brightness) {
    return createCustomBadgeTheme(
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
    );
  }

  /// Create warning badge theme
  static BadgeThemeData createWarningBadgeTheme(Brightness brightness) {
    return createCustomBadgeTheme(
      backgroundColor: AppColors.warning,
      textColor: AppColors.black,
    );
  }

  /// Create custom search bar theme
  static SearchBarThemeData createCustomSearchBarTheme({
    required Color backgroundColor,
    Color? textColor,
    Color? hintColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    double? elevation,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getSearchBarTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: MaterialStateProperty.all(backgroundColor),
      elevation: MaterialStateProperty.all(
        elevation ?? AppDimensions.elevation1,
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
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: borderRadius ?? AppDimensions.borderRadiusFull,
        ),
      ),
      textStyle: MaterialStateProperty.all(
        AppTypography.withColor(
          AppTypography.bodyLarge,
          textColor ??
              (brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
        ),
      ),
      hintStyle: MaterialStateProperty.all(
        AppTypography.withColor(
          AppTypography.bodyLarge,
          hintColor ??
              (brightness == Brightness.dark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary),
        ),
      ),
    );
  }

  /// Create minimal search bar theme
  static SearchBarThemeData createMinimalSearchBarTheme(Brightness brightness) {
    return createCustomSearchBarTheme(
      backgroundColor: AppColors.transparent,
      borderColor: brightness == Brightness.dark
          ? AppColors.darkBorderLight
          : AppColors.lightBorderLight,
      elevation: 0,
      borderRadius: AppDimensions.borderRadiusLG,
      brightness: brightness,
    );
  }
}
