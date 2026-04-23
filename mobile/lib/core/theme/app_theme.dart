import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandPrimary = Color(0xFF1E4D6B);
  static const Color brandSecondary = Color(0xFF2FA37F);
  static const Color surfaceLight = Color(0xFFF5F7FA);
  static const Color accentWarning = Color(0xFFF7A531);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: surfaceLight,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: brandPrimary,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: brandPrimary, brightness: Brightness.dark),
    );
  }
}
