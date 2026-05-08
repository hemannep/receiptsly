import 'package:flutter/material.dart';

class AppTheme {
  // ===== LIGHT THEME COLORS =====
  static const Color lightBackground = Color(0xFFFAFBFC);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightCellBackground = Colors.white;
  static const Color lightCellHighlight = Color(0xFFE2F6E5);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ===== DARK THEME COLORS =====
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceElevated = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFEAEAEA);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkCellBackground = Color(0xFF1E1E1E);
  static const Color darkCellHighlight = Color(0xFF2D4A33);
  static const Color darkDivider = Color(0xFF3A3A3A);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Poppins',
      cardColor: darkSurface,
      dividerColor: darkDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
