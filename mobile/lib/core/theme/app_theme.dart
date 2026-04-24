import 'package:flutter/material.dart';

import '../../features/company_settings/domain/models/company_settings_model.dart';

class AppTheme {
  static const Color brandPrimary = Color(0xFF1E4D6B);
  static const Color brandSecondary = Color(0xFF2FA37F);
  static const Color background = Color(0xFFF2F5F8);

  static ThemeData light([CompanySettingsModel? settings]) {
    final config = settings ?? CompanySettingsModel.defaults;
    final primary = CompanySettingsModel.parseColor(config.primaryColor);
    final secondary = CompanySettingsModel.parseColor(config.secondaryColor);
    final bg = CompanySettingsModel.parseColor(config.backgroundColor);
    final button = CompanySettingsModel.parseColor(config.buttonColor);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: secondary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? primary : Colors.black54,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: button,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
