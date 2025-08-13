// lib/core/theme/slider_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Slider theme configurations for light and dark themes
class AppSliderTheme {
  AppSliderTheme._();

  /// ==================== LIGHT SLIDER THEME ====================

  static SliderThemeData get lightSliderTheme => SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.gray200,
    disabledActiveTrackColor: AppColors.gray300,
    disabledInactiveTrackColor: AppColors.gray100,
    thumbColor: AppColors.primary,
    disabledThumbColor: AppColors.gray300,
    overlayColor: AppColors.primary.withOpacity(0.12),
    valueIndicatorColor: AppColors.primary,
    valueIndicatorTextStyle: AppTypography.labelSmall.copyWith(
      color: AppColors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    trackHeight: 4.0,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
    tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.0),
    activeTickMarkColor: AppColors.primary,
    inactiveTickMarkColor: AppColors.gray300,
    valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
    rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12.0),
    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
    rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
  );

  /// ==================== DARK SLIDER THEME ====================

  static SliderThemeData get darkSliderTheme => SliderThemeData(
    activeTrackColor: AppColors.primaryLight,
    inactiveTrackColor: AppColors.slate600,
    disabledActiveTrackColor: AppColors.slate500,
    disabledInactiveTrackColor: AppColors.slate700,
    thumbColor: AppColors.primaryLight,
    disabledThumbColor: AppColors.slate500,
    overlayColor: AppColors.primaryLight.withOpacity(0.12),
    valueIndicatorColor: AppColors.primaryLight,
    valueIndicatorTextStyle: AppTypography.labelSmall.copyWith(
      color: AppColors.black,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    trackHeight: 4.0,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
    tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.0),
    activeTickMarkColor: AppColors.primaryLight,
    inactiveTickMarkColor: AppColors.slate500,
    valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
    rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12.0),
    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
    rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate slider theme
  static SliderThemeData getSliderTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkSliderTheme : lightSliderTheme;
  }

  /// Create custom slider theme
  static SliderThemeData createCustomSliderTheme({
    required Color activeColor,
    required Color inactiveColor,
    Color? thumbColor,
    double? trackHeight,
    double? thumbRadius,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getSliderTheme(brightness);

    return baseTheme.copyWith(
      activeTrackColor: activeColor,
      inactiveTrackColor: inactiveColor,
      thumbColor: thumbColor ?? activeColor,
      valueIndicatorColor: activeColor,
      trackHeight: trackHeight ?? 4.0,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: thumbRadius ?? 12.0,
      ),
      activeTickMarkColor: activeColor,
      overlayColor: activeColor.withOpacity(0.12),
    );
  }

  /// Create discrete slider theme
  static SliderThemeData createDiscreteSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);

    return baseTheme.copyWith(
      showValueIndicator: ShowValueIndicator.always,
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3.0),
      valueIndicatorShape: const DropSliderValueIndicatorShape(),
    );
  }

  /// Create range slider theme
  static SliderThemeData createRangeSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);

    return baseTheme.copyWith(
      rangeThumbShape: const RoundRangeSliderThumbShape(
        enabledThumbRadius: 14.0,
      ),
      rangeTrackShape: const RectangularRangeSliderTrackShape(),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
    );
  }

  /// Create minimal slider theme
  static SliderThemeData createMinimalSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);

    return baseTheme.copyWith(
      trackHeight: 2.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
      showValueIndicator: ShowValueIndicator.never,
      tickMarkShape: SliderTickMarkShape.noTickMark,
    );
  }

  /// Create success-themed slider
  static SliderThemeData createSuccessSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);
    final successColor = brightness == Brightness.dark
        ? AppColors.success
        : AppColors.successDark;

    return baseTheme.copyWith(
      activeTrackColor: successColor,
      thumbColor: successColor,
      valueIndicatorColor: successColor,
      overlayColor: successColor.withOpacity(0.12),
      activeTickMarkColor: successColor,
    );
  }

  /// Create warning-themed slider
  static SliderThemeData createWarningSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);
    final warningColor = brightness == Brightness.dark
        ? AppColors.warning
        : AppColors.warningDark;

    return baseTheme.copyWith(
      activeTrackColor: warningColor,
      thumbColor: warningColor,
      valueIndicatorColor: warningColor,
      overlayColor: warningColor.withOpacity(0.12),
      activeTickMarkColor: warningColor,
    );
  }

  /// Create error-themed slider
  static SliderThemeData createErrorSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);
    final errorColor = brightness == Brightness.dark
        ? AppColors.error
        : AppColors.errorDark;

    return baseTheme.copyWith(
      activeTrackColor: errorColor,
      thumbColor: errorColor,
      valueIndicatorColor: errorColor,
      overlayColor: errorColor.withOpacity(0.12),
      activeTickMarkColor: errorColor,
    );
  }

  /// Create large slider theme for accessibility
  static SliderThemeData createAccessibleSliderTheme(Brightness brightness) {
    final baseTheme = getSliderTheme(brightness);

    return baseTheme.copyWith(
      trackHeight: 6.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16.0),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 32.0),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4.0),
      showValueIndicator: ShowValueIndicator.always,
    );
  }

  /// Create gradient slider theme
  static SliderThemeData createGradientSliderTheme({
    required Gradient gradient,
    required Brightness brightness,
  }) {
    final baseTheme = getSliderTheme(brightness);

    return baseTheme.copyWith(
      activeTrackColor: Colors.transparent,
      trackShape: GradientSliderTrackShape(gradient: gradient),
      thumbColor: gradient.colors.first,
      valueIndicatorColor: gradient.colors.first,
      overlayColor: gradient.colors.first.withOpacity(0.12),
    );
  }
}

/// Custom track shape for gradient sliders
class GradientSliderTrackShape extends SliderTrackShape {
  const GradientSliderTrackShape({required this.gradient});

  final Gradient gradient;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect);

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final double thumbCenterX = thumbCenter.dx;

    // Draw active track (gradient)
    final Rect activeTrackRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenterX,
      trackRect.bottom,
    );

    // Draw inactive track
    final Rect inactiveTrackRect = Rect.fromLTRB(
      thumbCenterX,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeTrackRect, const Radius.circular(2)),
      activePaint,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(inactiveTrackRect, const Radius.circular(2)),
      inactivePaint,
    );
  }
}
