// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Color constants and theme colors for Receiptsly
/// Provides consistent color scheme across the application
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// ==================== PRIMARY BRAND COLORS ====================

  /// Primary Brand Color - Receiptsly Blue
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryExtraLight = Color(0xFF60A5FA); // Blue-400
  static const Color primaryExtraDark = Color(0xFF1E40AF); // Blue-800

  /// Secondary Brand Color - Receiptsly Green
  static const Color secondary = Color(0xFF059669); // Emerald-600
  static const Color secondaryLight = Color(0xFF10B981); // Emerald-500
  static const Color secondaryDark = Color(0xFF047857); // Emerald-700
  static const Color secondaryExtraLight = Color(0xFF34D399); // Emerald-400
  static const Color secondaryExtraDark = Color(0xFF065F46); // Emerald-800

  /// Accent Colors
  static const Color accent = Color(0xFF7C3AED); // Violet-600
  static const Color accentLight = Color(0xFF8B5CF6); // Violet-500
  static const Color accentDark = Color(0xFF6D28D9); // Violet-700

  /// ==================== SEMANTIC COLORS ====================

  /// Success Colors
  static const Color success = Color(0xFF059669); // Emerald-600
  static const Color successLight = Color(0xFF10B981); // Emerald-500
  static const Color successDark = Color(0xFF047857); // Emerald-700
  static const Color successExtraLight = Color(0xFFD1FAE5); // Emerald-100
  static const Color successSurface = Color(0xFFF0FDF4); // Emerald-50

  /// Error Colors
  static const Color error = Color(0xFFDC2626); // Red-600
  static const Color errorLight = Color(0xFFEF4444); // Red-500
  static const Color errorDark = Color(0xFFB91C1C); // Red-700
  static const Color errorExtraLight = Color(0xFFFECACA); // Red-200
  static const Color errorSurface = Color(0xFFFEF2F2); // Red-50

  /// Warning Colors
  static const Color warning = Color(0xFFD97706); // Amber-600
  static const Color warningLight = Color(0xFFF59E0B); // Amber-500
  static const Color warningDark = Color(0xFFB45309); // Amber-700
  static const Color warningExtraLight = Color(0xFFFDE68A); // Amber-200
  static const Color warningSurface = Color(0xFFFFFBEB); // Amber-50

  /// Info Colors
  static const Color info = Color(0xFF0EA5E9); // Sky-500
  static const Color infoLight = Color(0xFF38BDF8); // Sky-400
  static const Color infoDark = Color(0xFF0284C7); // Sky-600
  static const Color infoExtraLight = Color(0xFFBAE6FD); // Sky-200
  static const Color infoSurface = Color(0xFFF0F9FF); // Sky-50

  /// ==================== NEUTRAL COLORS ====================

  /// Light Theme Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  /// Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  /// Slate Scale (Alternative neutral)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  /// ==================== LIGHT THEME COLORS ====================

  /// Light Theme Background Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightBackgroundSecondary = Color(0xFFF9FAFB); // gray-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6); // gray-100
  static const Color lightCard = Color(0xFFFFFFFF);

  /// Light Theme Text Colors
  static const Color lightTextPrimary = Color(0xFF111827); // gray-900
  static const Color lightTextSecondary = Color(0xFF4B5563); // gray-600
  static const Color lightTextTertiary = Color(0xFF6B7280); // gray-500
  static const Color lightTextDisabled = Color(0xFF9CA3AF); // gray-400
  static const Color lightTextOnPrimary = Color(0xFFFFFFFF);

  /// Light Theme Border Colors
  static const Color lightBorder = Color(0xFFE5E7EB); // gray-200
  static const Color lightBorderLight = Color(0xFFF3F4F6); // gray-100
  static const Color lightDivider = Color(0xFFE5E7EB); // gray-200

  /// Light Theme Icon Colors
  static const Color lightIconPrimary = Color(0xFF374151); // gray-700
  static const Color lightIconSecondary = Color(0xFF6B7280); // gray-500
  static const Color lightIconDisabled = Color(0xFF9CA3AF); // gray-400

  /// ==================== DARK THEME COLORS ====================

  /// Dark Theme Background Colors
  static const Color darkBackground = Color(0xFF0F172A); // slate-900
  static const Color darkBackgroundSecondary = Color(0xFF1E293B); // slate-800
  static const Color darkSurface = Color(0xFF1E293B); // slate-800
  static const Color darkSurfaceVariant = Color(0xFF334155); // slate-700
  static const Color darkCard = Color(0xFF1E293B); // slate-800

  /// Dark Theme Text Colors
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // slate-300
  static const Color darkTextTertiary = Color(0xFF94A3B8); // slate-400
  static const Color darkTextDisabled = Color(0xFF64748B); // slate-500
  static const Color darkTextOnPrimary = Color(0xFFFFFFFF);

  /// Dark Theme Border Colors
  static const Color darkBorder = Color(0xFF334155); // slate-700
  static const Color darkBorderLight = Color(0xFF475569); // slate-600
  static const Color darkDivider = Color(0xFF334155); // slate-700

  /// Dark Theme Icon Colors
  static const Color darkIconPrimary = Color(0xFFE2E8F0); // slate-200
  static const Color darkIconSecondary = Color(0xFF94A3B8); // slate-400
  static const Color darkIconDisabled = Color(0xFF64748B); // slate-500

  /// ==================== COMPONENT SPECIFIC COLORS ====================

  /// AppBar Colors
  static const Color appBarLight = Color(0xFFFFFFFF);
  static const Color appBarDark = Color(0xFF1E293B); // slate-800
  static const Color appBarElevation = Color(0x14000000); // 8% black

  /// Navigation Colors
  static const Color navigationLight = Color(0xFFFFFFFF);
  static const Color navigationDark = Color(0xFF1E293B); // slate-800
  static const Color navigationSelected = primary;
  static const Color navigationUnselected = Color(0xFF6B7280); // gray-500

  /// Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = Color(0xFFF3F4F6); // gray-100
  static const Color buttonDanger = error;
  static const Color buttonSuccess = success;
  static const Color buttonDisabled = Color(0xFF9CA3AF); // gray-400

  /// Input Field Colors
  static const Color inputFill = Color(0xFFF9FAFB); // gray-50
  static const Color inputFillDark = Color(0xFF334155); // slate-700
  static const Color inputBorder = Color(0xFFD1D5DB); // gray-300
  static const Color inputBorderDark = Color(0xFF475569); // slate-600
  static const Color inputFocused = primary;
  static const Color inputError = error;

  /// Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B); // slate-800
  static const Color cardElevation = Color(0x0A000000); // 4% black
  static const Color cardBorder = Color(0xFFE5E7EB); // gray-200
  static const Color cardBorderDark = Color(0xFF334155); // slate-700

  /// ==================== FEATURE SPECIFIC COLORS ====================

  /// Receipt Colors
  static const Color receiptPending = Color(0xFFF59E0B); // amber-500
  static const Color receiptProcessed = success;
  static const Color receiptApproved = success;
  static const Color receiptRejected = error;
  static const Color receiptDraft = Color(0xFF6B7280); // gray-500

  /// Invoice Colors
  static const Color invoiceDraft = Color(0xFF6B7280); // gray-500
  static const Color invoiceSent = Color(0xFF0EA5E9); // sky-500
  static const Color invoicePaid = success;
  static const Color invoiceOverdue = error;
  static const Color invoicePartial = warning;

  /// Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF3B82F6), // blue-500
    Color(0xFF10B981), // emerald-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFFEF4444), // red-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFFEC4899), // pink-500
    Color(0xFF06B6D4), // cyan-500
    Color(0xFF84CC16), // lime-500
    Color(0xFFF97316), // orange-500
    Color(0xFF6366F1), // indigo-500
  ];

  /// Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // blue-500
    Color(0xFF10B981), // emerald-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFFEF4444), // red-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFFEC4899), // pink-500
    Color(0xFF06B6D4), // cyan-500
    Color(0xFF84CC16), // lime-500
    Color(0xFFF97316), // orange-500
    Color(0xFF6366F1), // indigo-500
    Color(0xFF14B8A6), // teal-500
    Color(0xFFA855F7), // purple-500
  ];

  /// ==================== GRADIENT COLORS ====================

  /// Primary Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Secondary Gradients
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success Gradients
  static const LinearGradient successGradient = LinearGradient(
    colors: [successLight, success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error Gradients
  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorLight, error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Background Gradients
  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [white, gray50],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [darkBackground, darkBackgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Card Gradients
  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [white, gray50],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [darkCard, darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// ==================== SHADOW COLORS ====================

  /// Light Theme Shadows
  static const Color shadowLight = Color(0x1A000000); // 10% black
  static const Color shadowMedium = Color(0x26000000); // 15% black
  static const Color shadowHeavy = Color(0x33000000); // 20% black

  /// Dark Theme Shadows
  static const Color shadowDarkLight = Color(0x1A000000); // 10% black
  static const Color shadowDarkMedium = Color(0x33000000); // 20% black
  static const Color shadowDarkHeavy = Color(0x4D000000); // 30% black

  /// Colored Shadows
  static const Color primaryShadow = Color(0x1A2563EB); // 10% primary
  static const Color successShadow = Color(0x1A059669); // 10% success
  static const Color errorShadow = Color(0x1ADC2626); // 10% error
  static const Color warningShadow = Color(0x1AD97706); // 10% warning

  /// ==================== OVERLAY COLORS ====================

  /// Modal and Dialog Overlays
  static const Color overlay = Color(0x4D000000); // 30% black
  static const Color overlayLight = Color(0x33000000); // 20% black
  static const Color overlayHeavy = Color(0x66000000); // 40% black

  /// Loading Overlays
  static const Color loadingOverlay = Color(0x80FFFFFF); // 50% white
  static const Color loadingOverlayDark = Color(0x80000000); // 50% black

  /// Shimmer Colors
  static const Color shimmerBase = Color(0xFFE5E7EB); // gray-200
  static const Color shimmerHighlight = Color(0xFFF3F4F6); // gray-100
  static const Color shimmerBaseDark = Color(0xFF334155); // slate-700
  static const Color shimmerHighlightDark = Color(0xFF475569); // slate-600

  /// ==================== SPECIAL EFFECT COLORS ====================

  /// Focus Ring Colors
  static const Color focusRing = Color(0x4D2563EB); // 30% primary
  static const Color focusRingError = Color(0x4DDC2626); // 30% error
  static const Color focusRingSuccess = Color(0x4D059669); // 30% success

  /// Selection Colors
  static const Color selectionLight = Color(0x1A2563EB); // 10% primary
  static const Color selectionDark = Color(0x332563EB); // 20% primary

  /// Ripple Colors
  static const Color rippleLight = Color(0x1F000000); // 12% black
  static const Color rippleDark = Color(0x1FFFFFFF); // 12% white
  static const Color ripplePrimary = Color(0x1F2563EB); // 12% primary

  /// ==================== BRAND VARIANTS ====================

  /// Alternative Brand Colors (for special occasions)
  static const Color brandGold = Color(0xFFF59E0B); // amber-500
  static const Color brandSilver = Color(0xFF9CA3AF); // gray-400
  static const Color brandBronze = Color(0xFFD97706); // amber-600

  /// Premium Colors
  static const Color premium = Color(0xFFAB47BC); // purple-500
  static const Color premiumLight = Color(0xFFBA68C8); // purple-400
  static const Color premiumDark = Color(0xFF8E24AA); // purple-600

  /// Business Colors
  static const Color business = Color(0xFF1976D2); // blue-700
  static const Color businessLight = Color(0xFF1E88E5); // blue-600
  static const Color businessDark = Color(0xFF1565C0); // blue-800

  /// ==================== ACCESSIBILITY COLORS ====================

  /// High Contrast Colors
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastBorder = Color(0xFF000000);

  /// Color Blind Friendly Palette
  static const Color colorBlindBlue = Color(0xFF0173B2);
  static const Color colorBlindOrange = Color(0xFFDE8F05);
  static const Color colorBlindGreen = Color(0xFF029E73);
  static const Color colorBlindPink = Color(0xFFCC78BC);
  static const Color colorBlindYellow = Color(0xFFECE133);
  static const Color colorBlindRed = Color(0xFFD55E00);
  static const Color colorBlindPurple = Color(0xFF9467BD);

  /// ==================== HELPER METHODS ====================

  /// Get category color by index
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// Get chart color by index
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }

  /// Get status color by status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'approved':
      case 'paid':
        return success;
      case 'error':
      case 'failed':
      case 'rejected':
        return error;
      case 'warning':
      case 'overdue':
      case 'partial':
        return warning;
      case 'info':
      case 'sent':
      case 'processing':
        return info;
      case 'pending':
      case 'draft':
        return gray500;
      default:
        return gray500;
    }
  }

  /// Get receipt status color
  static Color getReceiptStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return receiptPending;
      case 'processed':
        return receiptProcessed;
      case 'approved':
        return receiptApproved;
      case 'rejected':
        return receiptRejected;
      case 'draft':
        return receiptDraft;
      default:
        return gray500;
    }
  }

  /// Get invoice status color
  static Color getInvoiceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return invoiceDraft;
      case 'sent':
        return invoiceSent;
      case 'paid':
        return invoicePaid;
      case 'overdue':
        return invoiceOverdue;
      case 'partial':
        return invoicePartial;
      default:
        return gray500;
    }
  }

  /// Lighten a color by a percentage
  static Color lighten(Color color, double percentage) {
    assert(percentage >= 0 && percentage <= 1);
    final int red = (color.red + ((255 - color.red) * percentage)).round();
    final int green = (color.green + ((255 - color.green) * percentage))
        .round();
    final int blue = (color.blue + ((255 - color.blue) * percentage)).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  /// Darken a color by a percentage
  static Color darken(Color color, double percentage) {
    assert(percentage >= 0 && percentage <= 1);
    final int red = (color.red * (1 - percentage)).round();
    final int green = (color.green * (1 - percentage)).round();
    final int blue = (color.blue * (1 - percentage)).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  /// Add opacity to a color
  static Color withOpacity(Color color, double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    return color.withOpacity(opacity);
  }

  /// Get contrasting text color for a background
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final double luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;

    // Return white text for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? black : white;
  }

  /// Check if color is light
  static bool isLight(Color color) {
    final double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  /// Check if color is dark
  static bool isDark(Color color) {
    return !isLight(color);
  }

  /// Get theme-appropriate color
  static Color getThemeColor(
    Color lightColor,
    Color darkColor,
    bool isDarkTheme,
  ) {
    return isDarkTheme ? darkColor : lightColor;
  }

  /// Convert hex string to Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}
