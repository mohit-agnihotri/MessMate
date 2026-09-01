import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF22C55E); // tailwind green-500
  static const Color primaryGreenDark = Color(0xFF16A34A); // tailwind green-600
  static const Color primaryGreenLight = Color(
    0xFFDCFCE7,
  ); // tailwind green-100
  static const Color backgroundLight = Color(0xFFF9FAFB); // tailwind gray-50
  static const Color cardWhite = Colors.white;
  static const Color textMain = Color(0xFF111827); // tailwind gray-900
  static const Color textSecondary = Color(0xFF6B7280); // tailwind gray-500
  static const Color errorRed = Color(0xFFEF4444); // tailwind red-500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryGreenDark,
        surface: backgroundLight,
        error: errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          color: textMain,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.inter(
          color: textMain,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: textMain),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ), // tailwind gray-100
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textMain,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textMain),
      ),
    );
  }
}
