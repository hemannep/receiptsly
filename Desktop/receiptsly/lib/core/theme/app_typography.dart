// lib/core/theme/app_typography.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Receiptsly
/// Provides consistent text styles across the application
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  /// ==================== FONT FAMILIES ====================

  /// Primary font family for most text
  static const String primaryFontFamily = 'Inter';

  /// Secondary font family for headings and display text
  static const String secondaryFontFamily = 'Poppins';

  /// Monospace font family for code, numbers, and data
  static const String monoFontFamily = 'JetBrains Mono';

  /// ==================== FONT WEIGHTS ====================

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  /// ==================== DISPLAY TEXT STYLES ====================

  /// Display Large - Hero sections, landing pages
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: bold,
    height: 1.12,
    letterSpacing: -0.25,
  );

  /// Display Medium - Page headers, main titles
  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: bold,
    height: 1.16,
    letterSpacing: 0,
  );

  /// Display Small - Section headers
  static TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: semiBold,
    height: 1.22,
    letterSpacing: 0,
  );

  /// ==================== HEADLINE TEXT STYLES ====================

  /// Headline Large - Main page titles
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0,
  );

  /// Headline Medium - Card titles, section headers
  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.29,
    letterSpacing: 0,
  );

  /// Headline Small - Subsection headers
  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0,
  );

  /// ==================== TITLE TEXT STYLES ====================

  /// Title Large - AppBar titles, dialog titles
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: semiBold,
    height: 1.27,
    letterSpacing: 0,
  );

  /// Title Medium - List item titles, card headers
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Title Small - Tab labels, small headers
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// ==================== LABEL TEXT STYLES ====================

  /// Label Large - Button text, prominent labels
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Label Medium - Form labels, secondary buttons
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );

  /// Label Small - Captions, fine print
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
  );

  /// ==================== BODY TEXT STYLES ====================

  /// Body Large - Main content, descriptions
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body Medium - Secondary content, list items
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// Body Small - Supporting text, metadata
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// ==================== SPECIALIZED TEXT STYLES ====================

  /// Numbers and Currency
  static TextStyle currency = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0,
  );

  static TextStyle currencyLarge = GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.33,
    letterSpacing: 0,
  );

  static TextStyle currencySmall = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0,
  );

  /// Dates and Time
  static TextStyle dateTime = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static TextStyle dateTimeLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Code and Technical Text
  static TextStyle code = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: regular,
    height: 1.4,
    letterSpacing: 0,
  );

  static TextStyle codeSmall = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0,
  );

  /// ==================== BUTTON TEXT STYLES ====================

  /// Primary Button Text
  static TextStyle buttonPrimary = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.1,
  );

  /// Secondary Button Text
  static TextStyle buttonSecondary = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Small Button Text
  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );

  /// Text Button Style
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// ==================== FORM TEXT STYLES ====================

  /// Input Field Text
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Input Hint Text
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Input Label Text
  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// Input Error Text
  static TextStyle inputError = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// Input Helper Text
  static TextStyle inputHelper = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// ==================== NAVIGATION TEXT STYLES ====================

  /// Bottom Navigation Labels
  static TextStyle navigationLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );

  /// Tab Labels
  static TextStyle tabLabel = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Breadcrumb Text
  static TextStyle breadcrumb = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// ==================== CARD TEXT STYLES ====================

  /// Card Title
  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.33,
    letterSpacing: 0,
  );

  /// Card Subtitle
  static TextStyle cardSubtitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// Card Content
  static TextStyle cardContent = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// ==================== LIST TEXT STYLES ====================

  /// List Item Title
  static TextStyle listTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// List Item Subtitle
  static TextStyle listSubtitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// List Item Caption
  static TextStyle listCaption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// ==================== DIALOG TEXT STYLES ====================

  /// Dialog Title
  static TextStyle dialogTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Dialog Content
  static TextStyle dialogContent = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// ==================== SNACKBAR TEXT STYLES ====================

  /// Snackbar Message
  static TextStyle snackbarMessage = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// Snackbar Action
  static TextStyle snackbarAction = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// ==================== TOOLTIP TEXT STYLES ====================

  /// Tooltip Text
  static TextStyle tooltip = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// ==================== OVERLINE TEXT STYLES ====================

  /// Overline Text - Section labels, category headers
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: medium,
    height: 1.6,
    letterSpacing: 1.5,
  );

  /// ==================== HELPER METHODS ====================

  /// Get text style with color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Get text style with size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Get text style with height
  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  /// Get text style with letter spacing
  static TextStyle withLetterSpacing(TextStyle style, double letterSpacing) {
    return style.copyWith(letterSpacing: letterSpacing);
  }

  /// Get text style with decoration
  static TextStyle withDecoration(TextStyle style, TextDecoration decoration) {
    return style.copyWith(decoration: decoration);
  }

  /// Get underlined text style
  static TextStyle underlined(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Get strikethrough text style
  static TextStyle strikethrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }

  /// Get italic text style
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Get text style for responsive design
  static TextStyle responsive(TextStyle baseStyle, double screenWidth) {
    double scaleFactor = 1.0;

    if (screenWidth < 360) {
      scaleFactor = 0.9; // Small screens
    } else if (screenWidth > 768) {
      scaleFactor = 1.1; // Large screens/tablets
    }

    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scaleFactor,
    );
  }

  /// Get text style based on importance level
  static TextStyle getImportanceStyle(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'critical':
        return titleLarge;
      case 'medium':
      case 'important':
        return titleMedium;
      case 'low':
      case 'normal':
        return bodyMedium;
      default:
        return bodyMedium;
    }
  }

  /// Get text style for status messages
  static TextStyle getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return withWeight(bodyMedium, medium);
      case 'error':
      case 'failed':
        return withWeight(bodyMedium, semiBold);
      case 'warning':
        return withWeight(bodyMedium, medium);
      case 'info':
        return bodyMedium;
      default:
        return bodyMedium;
    }
  }

  /// Get monospace style for numbers
  static TextStyle getNumberStyle(double fontSize) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: medium,
      height: 1.4,
      letterSpacing: 0,
    );
  }

  /// Create text theme for Material Theme
  static TextTheme createTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
    );
  }

  /// Apply text theme colors
  static TextTheme applyTextThemeColors(TextTheme textTheme, Color textColor) {
    return textTheme.apply(bodyColor: textColor, displayColor: textColor);
  }
}
