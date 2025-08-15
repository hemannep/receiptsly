// lib/core/theme/bottom_sheet_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Bottom sheet theme configurations for light and dark themes
class AppBottomSheetTheme {
  AppBottomSheetTheme._();

  /// ==================== LIGHT BOTTOM SHEET THEME ====================

  static BottomSheetThemeData get lightBottomSheetTheme => BottomSheetThemeData(
    backgroundColor: AppColors.lightSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.bottomSheetElevation,
    modalElevation: AppDimensions.bottomSheetElevation,
    shadowColor: AppColors.shadowMedium,
    modalBarrierColor: AppColors.overlay,
    dragHandleColor: AppColors.gray300,
    dragHandleSize: const Size(32, 4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.bottomSheetRadius),
        topRight: Radius.circular(AppDimensions.bottomSheetRadius),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    showDragHandle: true,
    constraints: const BoxConstraints(
      maxWidth: AppDimensions.bottomSheetMaxWidth,
    ),
  );

  /// ==================== DARK BOTTOM SHEET THEME ====================

  static BottomSheetThemeData get darkBottomSheetTheme => BottomSheetThemeData(
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppDimensions.bottomSheetElevation,
    modalElevation: AppDimensions.bottomSheetElevation,
    shadowColor: AppColors.shadowDarkMedium,
    modalBarrierColor: AppColors.overlay,
    dragHandleColor: AppColors.slate600,
    dragHandleSize: const Size(32, 4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.bottomSheetRadius),
        topRight: Radius.circular(AppDimensions.bottomSheetRadius),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    showDragHandle: true,
    constraints: const BoxConstraints(
      maxWidth: AppDimensions.bottomSheetMaxWidth,
    ),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate bottom sheet theme
  static BottomSheetThemeData getBottomSheetTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkBottomSheetTheme
        : lightBottomSheetTheme;
  }

  /// Create custom bottom sheet theme
  static BottomSheetThemeData createCustomBottomSheetTheme({
    required Color backgroundColor,
    Color? dragHandleColor,
    double? elevation,
    BorderRadius? borderRadius,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getBottomSheetTheme(brightness);

    return baseTheme.copyWith(
      backgroundColor: backgroundColor,
      dragHandleColor: dragHandleColor ?? baseTheme.dragHandleColor,
      elevation: elevation ?? baseTheme.elevation,
      modalElevation: elevation ?? baseTheme.modalElevation,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ??
            const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.bottomSheetRadius),
              topRight: Radius.circular(AppDimensions.bottomSheetRadius),
            ),
      ),
    );
  }

  /// Create modal bottom sheet theme
  static BottomSheetThemeData createModalBottomSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;

    return baseTheme.copyWith(
      modalElevation: AppDimensions.elevation16,
      modalBarrierColor: AppColors.overlay.withOpacity(0.8),
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: screenHeight * 0.9,
      ),
    );
  }

  /// Create persistent bottom sheet theme
  static BottomSheetThemeData createPersistentBottomSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;

    return baseTheme.copyWith(
      elevation: AppDimensions.elevation8,
      showDragHandle: false,
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: screenHeight * 0.6,
      ),
    );
  }

  /// Create full screen bottom sheet theme
  static BottomSheetThemeData createFullScreenBottomSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;

    return baseTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: screenHeight,
      ),
      showDragHandle: false,
    );
  }

  /// Create compact bottom sheet theme
  static BottomSheetThemeData createCompactBottomSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;

    return baseTheme.copyWith(
      elevation: AppDimensions.elevation4,
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: screenHeight * 0.4,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
    );
  }

  /// Create expansion bottom sheet theme
  static BottomSheetThemeData createExpansionBottomSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;

    return baseTheme.copyWith(
      showDragHandle: true,
      dragHandleSize: const Size(48, 6),
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        minHeight: screenHeight * 0.3,
        maxHeight: screenHeight * 0.95,
      ),
    );
  }

  /// Create action sheet theme
  static BottomSheetThemeData createActionSheetTheme(Brightness brightness) {
    final baseTheme = getBottomSheetTheme(brightness);

    return baseTheme.copyWith(
      elevation: AppDimensions.elevation24,
      modalBarrierColor: AppColors.overlay.withOpacity(0.6),
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.bottomSheetRadius),
          topRight: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      showDragHandle: false,
    );
  }

  /// Create notification sheet theme
  static BottomSheetThemeData createNotificationSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;
    final bgColor = brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return baseTheme.copyWith(
      backgroundColor: bgColor,
      elevation: AppDimensions.elevation12,
      modalBarrierColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: screenHeight * 0.5,
      ),
      showDragHandle: true,
    );
  }

  /// Create form bottom sheet theme
  static BottomSheetThemeData createFormBottomSheetTheme(
    BuildContext context,
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final screenHeight = MediaQuery.of(context).size.height;

    return baseTheme.copyWith(
      constraints: BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: screenHeight * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.bottomSheetRadius),
          topRight: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      showDragHandle: true,
    );
  }

  /// Create success themed bottom sheet
  static BottomSheetThemeData createSuccessBottomSheetTheme(
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final successBg = brightness == Brightness.dark
        ? AppColors.successDark.withOpacity(0.1)
        : AppColors.success.withOpacity(0.05);

    return baseTheme.copyWith(
      backgroundColor: successBg,
      dragHandleColor: AppColors.success,
    );
  }

  /// Create warning themed bottom sheet
  static BottomSheetThemeData createWarningBottomSheetTheme(
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final warningBg = brightness == Brightness.dark
        ? AppColors.warningDark.withOpacity(0.1)
        : AppColors.warning.withOpacity(0.05);

    return baseTheme.copyWith(
      backgroundColor: warningBg,
      dragHandleColor: AppColors.warning,
    );
  }

  /// Create error themed bottom sheet
  static BottomSheetThemeData createErrorBottomSheetTheme(
    Brightness brightness,
  ) {
    final baseTheme = getBottomSheetTheme(brightness);
    final errorBg = brightness == Brightness.dark
        ? AppColors.errorDark.withOpacity(0.1)
        : AppColors.error.withOpacity(0.05);

    return baseTheme.copyWith(
      backgroundColor: errorBg,
      dragHandleColor: AppColors.error,
    );
  }

  /// Create rounded corners bottom sheet theme
  static BottomSheetThemeData createRoundedBottomSheetTheme({
    required double radius,
    required Brightness brightness,
  }) {
    final baseTheme = getBottomSheetTheme(brightness);

    return baseTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
      ),
    );
  }

  /// Create elevated bottom sheet theme
  static BottomSheetThemeData createElevatedBottomSheetTheme({
    required double elevation,
    required Brightness brightness,
  }) {
    final baseTheme = getBottomSheetTheme(brightness);

    return baseTheme.copyWith(
      elevation: elevation,
      modalElevation: elevation,
      shadowColor: brightness == Brightness.dark
          ? AppColors.shadowDarkMedium
          : AppColors.shadowMedium,
    );
  }
}
