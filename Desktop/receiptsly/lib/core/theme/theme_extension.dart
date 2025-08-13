// lib/core/theme/theme_extension.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart' as colors;
import 'app_dimensions.dart';

/// Custom theme extension for Receiptsly-specific properties
@immutable
class ReceiptslyThemeExtension
    extends ThemeExtension<ReceiptslyThemeExtension> {
  const ReceiptslyThemeExtension({
    required this.receiptCardElevation,
    required this.invoiceCardElevation,
    required this.fabExtendedHeight,
    required this.bottomSheetDragHandleColor,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.receiptStatusColors,
    required this.invoiceStatusColors,
    required this.chartColors,
    required this.gradientColors,
  });

  final double receiptCardElevation;
  final double invoiceCardElevation;
  final double fabExtendedHeight;
  final Color bottomSheetDragHandleColor;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final ReceiptStatusColors receiptStatusColors;
  final InvoiceStatusColors invoiceStatusColors;
  final ChartColors chartColors;
  final GradientColors gradientColors;

  /// Default theme extension
  static ReceiptslyThemeExtension get themeExtension {
    return const ReceiptslyThemeExtension(
      receiptCardElevation: AppDimensions.elevation2,
      invoiceCardElevation: AppDimensions.elevation3,
      fabExtendedHeight: AppDimensions.buttonHeightLarge,
      bottomSheetDragHandleColor: colors.AppColors.gray300,
      successColor: colors.AppColors.success,
      warningColor: colors.AppColors.warning,
      infoColor: colors.AppColors.info,
      receiptStatusColors: ReceiptStatusColors.defaultColors,
      invoiceStatusColors: InvoiceStatusColors.defaultColors,
      chartColors: ChartColors.defaultColors,
      gradientColors: GradientColors.defaultColors,
    );
  }

  /// Dark theme extension
  static ReceiptslyThemeExtension get darkThemeExtension {
    return const ReceiptslyThemeExtension(
      receiptCardElevation: AppDimensions.elevation2,
      invoiceCardElevation: AppDimensions.elevation3,
      fabExtendedHeight: AppDimensions.buttonHeightLarge,
      bottomSheetDragHandleColor: colors.AppColors.slate600,
      successColor: colors.AppColors.successLight,
      warningColor: colors.AppColors.warningLight,
      infoColor: colors.AppColors.infoLight,
      receiptStatusColors: ReceiptStatusColors.darkColors,
      invoiceStatusColors: InvoiceStatusColors.darkColors,
      chartColors: ChartColors.darkColors,
      gradientColors: GradientColors.darkColors,
    );
  }

  @override
  ReceiptslyThemeExtension copyWith({
    double? receiptCardElevation,
    double? invoiceCardElevation,
    double? fabExtendedHeight,
    Color? bottomSheetDragHandleColor,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    ReceiptStatusColors? receiptStatusColors,
    InvoiceStatusColors? invoiceStatusColors,
    ChartColors? chartColors,
    GradientColors? gradientColors,
  }) {
    return ReceiptslyThemeExtension(
      receiptCardElevation: receiptCardElevation ?? this.receiptCardElevation,
      invoiceCardElevation: invoiceCardElevation ?? this.invoiceCardElevation,
      fabExtendedHeight: fabExtendedHeight ?? this.fabExtendedHeight,
      bottomSheetDragHandleColor:
          bottomSheetDragHandleColor ?? this.bottomSheetDragHandleColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      receiptStatusColors: receiptStatusColors ?? this.receiptStatusColors,
      invoiceStatusColors: invoiceStatusColors ?? this.invoiceStatusColors,
      chartColors: chartColors ?? this.chartColors,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }

  @override
  ReceiptslyThemeExtension lerp(
    ThemeExtension<ReceiptslyThemeExtension>? other,
    double t,
  ) {
    if (other is! ReceiptslyThemeExtension) {
      return this;
    }
    return ReceiptslyThemeExtension(
      receiptCardElevation:
          lerpDouble(receiptCardElevation, other.receiptCardElevation, t) ??
          receiptCardElevation,
      invoiceCardElevation:
          lerpDouble(invoiceCardElevation, other.invoiceCardElevation, t) ??
          invoiceCardElevation,
      fabExtendedHeight:
          lerpDouble(fabExtendedHeight, other.fabExtendedHeight, t) ??
          fabExtendedHeight,
      bottomSheetDragHandleColor:
          Color.lerp(
            bottomSheetDragHandleColor,
            other.bottomSheetDragHandleColor,
            t,
          ) ??
          bottomSheetDragHandleColor,
      successColor:
          Color.lerp(successColor, other.successColor, t) ?? successColor,
      warningColor:
          Color.lerp(warningColor, other.warningColor, t) ?? warningColor,
      infoColor: Color.lerp(infoColor, other.infoColor, t) ?? infoColor,
      receiptStatusColors: ReceiptStatusColors.lerp(
        receiptStatusColors,
        other.receiptStatusColors,
        t,
      ),
      invoiceStatusColors: InvoiceStatusColors.lerp(
        invoiceStatusColors,
        other.invoiceStatusColors,
        t,
      ),
      chartColors: ChartColors.lerp(chartColors, other.chartColors, t),
      gradientColors: GradientColors.lerp(
        gradientColors,
        other.gradientColors,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ReceiptslyThemeExtension &&
        other.receiptCardElevation == receiptCardElevation &&
        other.invoiceCardElevation == invoiceCardElevation &&
        other.fabExtendedHeight == fabExtendedHeight &&
        other.bottomSheetDragHandleColor == bottomSheetDragHandleColor &&
        other.successColor == successColor &&
        other.warningColor == warningColor &&
        other.infoColor == infoColor &&
        other.receiptStatusColors == receiptStatusColors &&
        other.invoiceStatusColors == invoiceStatusColors &&
        other.chartColors == chartColors &&
        other.gradientColors == gradientColors;
  }

  @override
  int get hashCode {
    return Object.hash(
      receiptCardElevation,
      invoiceCardElevation,
      fabExtendedHeight,
      bottomSheetDragHandleColor,
      successColor,
      warningColor,
      infoColor,
      receiptStatusColors,
      invoiceStatusColors,
      chartColors,
      gradientColors,
    );
  }
}

/// Receipt status colors
@immutable
class ReceiptStatusColors {
  const ReceiptStatusColors({
    required this.pending,
    required this.processing,
    required this.approved,
    required this.rejected,
    required this.archived,
  });

  final Color pending;
  final Color processing;
  final Color approved;
  final Color rejected;
  final Color archived;

  static const ReceiptStatusColors defaultColors = ReceiptStatusColors(
    pending: colors.AppColors.warning,
    processing: colors.AppColors.info,
    approved: colors.AppColors.success,
    rejected: colors.AppColors.error,
    archived: colors.AppColors.gray400,
  );

  static const ReceiptStatusColors darkColors = ReceiptStatusColors(
    pending: colors.AppColors.warningLight,
    processing: colors.AppColors.infoLight,
    approved: colors.AppColors.successLight,
    rejected: colors.AppColors.errorLight,
    archived: colors.AppColors.slate500,
  );

  static ReceiptStatusColors lerp(
    ReceiptStatusColors a,
    ReceiptStatusColors b,
    double t,
  ) {
    return ReceiptStatusColors(
      pending: Color.lerp(a.pending, b.pending, t) ?? a.pending,
      processing: Color.lerp(a.processing, b.processing, t) ?? a.processing,
      approved: Color.lerp(a.approved, b.approved, t) ?? a.approved,
      rejected: Color.lerp(a.rejected, b.rejected, t) ?? a.rejected,
      archived: Color.lerp(a.archived, b.archived, t) ?? a.archived,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptStatusColors &&
        other.pending == pending &&
        other.processing == processing &&
        other.approved == approved &&
        other.rejected == rejected &&
        other.archived == archived;
  }

  @override
  int get hashCode {
    return Object.hash(pending, processing, approved, rejected, archived);
  }
}

/// Invoice status colors
@immutable
class InvoiceStatusColors {
  const InvoiceStatusColors({
    required this.draft,
    required this.sent,
    required this.viewed,
    required this.paid,
    required this.overdue,
    required this.cancelled,
  });

  final Color draft;
  final Color sent;
  final Color viewed;
  final Color paid;
  final Color overdue;
  final Color cancelled;

  static const InvoiceStatusColors defaultColors = InvoiceStatusColors(
    draft: colors.AppColors.gray400,
    sent: colors.AppColors.info,
    viewed: colors.AppColors.warning,
    paid: colors.AppColors.success,
    overdue: colors.AppColors.error,
    cancelled: colors.AppColors.gray600,
  );

  static const InvoiceStatusColors darkColors = InvoiceStatusColors(
    draft: colors.AppColors.slate500,
    sent: colors.AppColors.infoLight,
    viewed: colors.AppColors.warningLight,
    paid: colors.AppColors.successLight,
    overdue: colors.AppColors.errorLight,
    cancelled: colors.AppColors.slate400,
  );

  static InvoiceStatusColors lerp(
    InvoiceStatusColors a,
    InvoiceStatusColors b,
    double t,
  ) {
    return InvoiceStatusColors(
      draft: Color.lerp(a.draft, b.draft, t) ?? a.draft,
      sent: Color.lerp(a.sent, b.sent, t) ?? a.sent,
      viewed: Color.lerp(a.viewed, b.viewed, t) ?? a.viewed,
      paid: Color.lerp(a.paid, b.paid, t) ?? a.paid,
      overdue: Color.lerp(a.overdue, b.overdue, t) ?? a.overdue,
      cancelled: Color.lerp(a.cancelled, b.cancelled, t) ?? a.cancelled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceStatusColors &&
        other.draft == draft &&
        other.sent == sent &&
        other.viewed == viewed &&
        other.paid == paid &&
        other.overdue == overdue &&
        other.cancelled == cancelled;
  }

  @override
  int get hashCode {
    return Object.hash(draft, sent, viewed, paid, overdue, cancelled);
  }
}

/// Chart colors for data visualization
@immutable
class ChartColors {
  const ChartColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
    required this.quinary,
    required this.background,
    required this.grid,
    required this.text,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;
  final Color quinary;
  final Color background;
  final Color grid;
  final Color text;

  static const ChartColors defaultColors = ChartColors(
    primary: colors.AppColors.primary,
    secondary: colors.AppColors.secondary,
    tertiary: colors.AppColors.accent,
    quaternary: colors.AppColors.success,
    quinary: colors.AppColors.warning,
    background: colors.AppColors.lightSurface,
    grid: colors.AppColors.lightBorderLight,
    text: colors.AppColors.lightTextSecondary,
  );

  static const ChartColors darkColors = ChartColors(
    primary: colors.AppColors.primaryLight,
    secondary: colors.AppColors.secondaryLight,
    tertiary: colors.AppColors.accentLight,
    quaternary: colors.AppColors.successLight,
    quinary: colors.AppColors.warningLight,
    background: colors.AppColors.darkSurface,
    grid: colors.AppColors.darkBorderLight,
    text: colors.AppColors.darkTextSecondary,
  );

  static ChartColors lerp(ChartColors a, ChartColors b, double t) {
    return ChartColors(
      primary: Color.lerp(a.primary, b.primary, t) ?? a.primary,
      secondary: Color.lerp(a.secondary, b.secondary, t) ?? a.secondary,
      tertiary: Color.lerp(a.tertiary, b.tertiary, t) ?? a.tertiary,
      quaternary: Color.lerp(a.quaternary, b.quaternary, t) ?? a.quaternary,
      quinary: Color.lerp(a.quinary, b.quinary, t) ?? a.quinary,
      background: Color.lerp(a.background, b.background, t) ?? a.background,
      grid: Color.lerp(a.grid, b.grid, t) ?? a.grid,
      text: Color.lerp(a.text, b.text, t) ?? a.text,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartColors &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.tertiary == tertiary &&
        other.quaternary == quaternary &&
        other.quinary == quinary &&
        other.background == background &&
        other.grid == grid &&
        other.text == text;
  }

  @override
  int get hashCode {
    return Object.hash(
      primary,
      secondary,
      tertiary,
      quaternary,
      quinary,
      background,
      grid,
      text,
    );
  }
}

/// Gradient colors for backgrounds and effects
@immutable
class GradientColors {
  const GradientColors({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.successGradient,
    required this.warningGradient,
    required this.errorGradient,
    required this.backgroundGradient,
  });

  final List<Color> primaryGradient;
  final List<Color> secondaryGradient;
  final List<Color> successGradient;
  final List<Color> warningGradient;
  final List<Color> errorGradient;
  final List<Color> backgroundGradient;

  static const GradientColors defaultColors = GradientColors(
    primaryGradient: [colors.AppColors.primary, colors.AppColors.primaryLight],
    secondaryGradient: [
      colors.AppColors.secondary,
      colors.AppColors.secondaryLight,
    ],
    successGradient: [colors.AppColors.success, colors.AppColors.successLight],
    warningGradient: [colors.AppColors.warning, colors.AppColors.warningLight],
    errorGradient: [colors.AppColors.error, colors.AppColors.errorLight],
    backgroundGradient: [
      colors.AppColors.lightBackground,
      colors.AppColors.lightSurface,
    ],
  );

  static const GradientColors darkColors = GradientColors(
    primaryGradient: [colors.AppColors.primaryDark, colors.AppColors.primary],
    secondaryGradient: [
      colors.AppColors.secondaryDark,
      colors.AppColors.secondary,
    ],
    successGradient: [colors.AppColors.successDark, colors.AppColors.success],
    warningGradient: [colors.AppColors.warningDark, colors.AppColors.warning],
    errorGradient: [colors.AppColors.errorDark, colors.AppColors.error],
    backgroundGradient: [
      colors.AppColors.darkBackground,
      colors.AppColors.darkSurface,
    ],
  );

  static GradientColors lerp(GradientColors a, GradientColors b, double t) {
    return GradientColors(
      primaryGradient: _lerpColorList(a.primaryGradient, b.primaryGradient, t),
      secondaryGradient: _lerpColorList(
        a.secondaryGradient,
        b.secondaryGradient,
        t,
      ),
      successGradient: _lerpColorList(a.successGradient, b.successGradient, t),
      warningGradient: _lerpColorList(a.warningGradient, b.warningGradient, t),
      errorGradient: _lerpColorList(a.errorGradient, b.errorGradient, t),
      backgroundGradient: _lerpColorList(
        a.backgroundGradient,
        b.backgroundGradient,
        t,
      ),
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    final length = a.length < b.length ? a.length : b.length;
    final result = <Color>[];
    for (int i = 0; i < length; i++) {
      result.add(Color.lerp(a[i], b[i], t) ?? a[i]);
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GradientColors &&
        _listEquals(other.primaryGradient, primaryGradient) &&
        _listEquals(other.secondaryGradient, secondaryGradient) &&
        _listEquals(other.successGradient, successGradient) &&
        _listEquals(other.warningGradient, warningGradient) &&
        _listEquals(other.errorGradient, errorGradient) &&
        _listEquals(other.backgroundGradient, backgroundGradient);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(primaryGradient),
      Object.hashAll(secondaryGradient),
      Object.hashAll(successGradient),
      Object.hashAll(warningGradient),
      Object.hashAll(errorGradient),
      Object.hashAll(backgroundGradient),
    );
  }
}
