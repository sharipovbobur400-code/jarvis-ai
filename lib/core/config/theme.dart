import 'package:flutter/material.dart';

class JarvisTheme {
  // Color Palette - Tony Stark / Cyan Holographic Theme
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color cyanGlow = Color(0x6600E5FF);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color darkBackground = Color(0xFF080C14);
  static const Color cardBackground = Color(0xFF10192A);
  static const Color cardBorder = Color(0xFF1E2D48);
  static const Color textPrimary = Color(0xFFE0F7FA);
  static const Color textSecondary = Color(0xFF80CBC4);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color danger = Color(0xFFFF5252);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentGold,
        surface: cardBackground,
        error: danger,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryCyan,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan.withOpacity(0.15),
          foregroundColor: primaryCyan,
          elevation: 0,
          side: const BorderSide(color: primaryCyan, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }
}
