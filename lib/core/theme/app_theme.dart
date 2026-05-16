import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.charcoal,
      primaryColor: AppColors.caramelGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.caramelGold,
        secondary: AppColors.caramelGold,
        surface: AppColors.darkGrey,
        background: AppColors.charcoal,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.softCream,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          titleLarge: TextStyle(
            color: AppColors.softCream,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          bodyLarge: TextStyle(
            color: AppColors.softCream,
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: AppColors.softCream,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.caramelGold,
          foregroundColor: AppColors.charcoal,
          textStyle: GoogleFonts.outfit(
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
