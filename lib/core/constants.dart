import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class AppConstants {
  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static const String appName = 'Level Up';
}

class AppColors {
  // Paleta Premium
  static const Color primary = Color(0xFF0A192F);       // Azul profundo corporativo
  static const Color primaryLight = Color(0xFF112240);  // Azul ligeramente más claro
  static const Color secondary = Color(0xFF1E3A5F);     // Azul tarjetas
  static const Color accent = Color(0xFF64FFDA);        // Verde/Cyan luminoso
  static const Color accentGold = Color(0xFFFFD700);    // Dorado para alertas
  static const Color cardColor = Color(0xFF172A45);     // Fondo de tarjetas
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8892B0); // Gris elegante
  static const Color textMuted = Color(0xFF4A5568);
  static const Color background = Color(0xFF0A192F);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.secondary,
          surface: AppColors.cardColor,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.primaryLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.primaryLight,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textSecondary,
        ),
      );
}
