import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentColors {
  // Canvas & Surfaces
  static const Color canvas = Color(0xFFF5F3EC);
  static const Color canvasWarm = Color(0xFFF7F5EE);
  static const Color canvasBottom = Color(0xFFEFF2E9);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceWarm = Color(0xFFFAF8F3);
  static const Color borderSubtle = Color(0x1A2D231C);

  // Walnut Suite
  static const Color walnut = Color(0xFF2D231C);
  static const Color walnutDark = Color(0xFF231B15);
  static const Color walnutSurface = Color(0xFF382E25);
  static const Color walnutPill = Color(0xFF2A2019);
  static const Color walnutMuted = Color(0xFF7A7971);

  // Sage Green Suite
  static const Color sage = Color(0xFF4E654F);
  static const Color sageGreen = Color(0xFF4E654F);
  static const Color sageDark = Color(0xFF3D523E);
  static const Color sageLight = Color(0xFFE2E8DE);
  static const Color sageBorder = Color(0xFFCBD6C7);
  static const Color sageText = Color(0xFF2B3B2C);

  // Amber Glow Suite
  static const Color amber = Color(0xFFF09E38);
  static const Color amberGlow = Color(0xFFFFAE42);
  static const Color amberDark = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFDF1E2);
  static const Color amberPill = Color(0xFFFCE3BF);
  static const Color amberText = Color(0xFF8F4700);

  // Brick Red Suite (Skip meal, Closed pill, Delete action)
  static const Color brickRed = Color(0xFFB93822);
  static const Color brickRedLight = Color(0xFFFDE8E5);
  static const Color brickRedBorder = Color(0xFFF2B8B1);

  // Blue / Info
  static const Color blueLight = Color(0xFFE6F0FA);
  static const Color blueText = Color(0xFF1E5B94);

  // Card Surfaces & Borders
  static const Color card = Color(0xFFFAF8F3);
  static const Color cardPure = Colors.white;
  static const Color cardBorder = Color(0x142D231C);

  // Typography Colors
  static const Color textDark = Color(0xFF231A14);
  static const Color textPrimary = Color(0xFF231A14);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF7A7971);
  static const Color textOverline = Color(0xFF5E6D59);
  static const Color textLight = Color(0xFFF5F3EC);

  // Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0C2D231C),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x042D231C),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x142D231C),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> dockShadow = [
    BoxShadow(
      color: Color(0x33231B15),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

class StudentTypography {
  // Editorial Serif Headings
  static TextStyle serifHeading({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = StudentColors.textDark,
    double height = 1.15,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: -0.4,
    );
  }

  // Display Serif for Large Numerals (e.g. "4.0", "₹1261", "12", "0")
  static TextStyle serifNumeral({
    double fontSize = 42,
    FontWeight fontWeight = FontWeight.w700,
    Color color = StudentColors.textDark,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5,
    );
  }

  // Tracked Uppercase Overline / Micro-label
  static TextStyle overline({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w800,
    Color color = StudentColors.textOverline,
    double letterSpacing = 1.2,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Primary Sans-serif Body & Buttons
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = StudentColors.textDark,
    double height = 1.35,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle bold({
    double fontSize = 14,
    Color color = StudentColors.textDark,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle regular({
    double fontSize = 14,
    Color color = StudentColors.textDark,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      height: height,
    );
  }

  static TextStyle itemTitle({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w700,
    Color color = StudentColors.textDark,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.2,
    );
  }
}
