import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    // Outfit font sudah di-bundle sebagai local assets di pubspec.yaml.
    // Tidak menggunakan GoogleFonts package untuk menghindari async font swap glitch.
    const String fontFamily = 'Outfit';

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.charcoal,
      primaryColor: AppColors.caramelGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.caramelGold,
        secondary: AppColors.caramelGold,
        surface: AppColors.darkGrey,
      ),
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.softCream,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.softCream,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.softCream,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.softCream,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.softCream,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.caramelGold,
          foregroundColor: AppColors.charcoal,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
