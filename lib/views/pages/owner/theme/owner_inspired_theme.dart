import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerColors {
  // Canvas & Surfaces
  static const Color canvas = Color(0xFFF5F3EC);
  static const Color canvasWarm = Color(0xFFF5F3EC);
  static const Color canvasTop = Color(0xFFF7F5EE);
  static const Color canvasBottom = Color(0xFFEFF2E9);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceWarm = Color(0xFFF7F5EE);
  static const Color borderSubtle = Color(0x1A2D231C);
  
  static const LinearGradient canvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [canvasTop, canvasBottom],
  );

  // Walnut Brown Suite
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

  // Card Surfaces & Borders
  static const Color card = Color(0xFFFAF8F3);
  static const Color cardPure = Colors.white;
  static const Color cardBorder = Color(0x142D231C);

  // Neutral / Typography Colors
  static const Color textDark = Color(0xFF231A14);
  static const Color textPrimary = Color(0xFF231A14);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF7A7971);
  static const Color textOverline = Color(0xFF5E6D59);
  static const Color textLight = Color(0xFFF5F3EC);

  // Shadow tokens
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

  static const List<BoxShadow> amberGlowShadow = [
    BoxShadow(
      color: Color(0x40F09E38),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
}

class OwnerShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A2D231C),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x142D231C),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
  ];
}

class OwnerTypography {
  // Editorial Serif for Headings & Title displays
  static TextStyle serifHeading({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = OwnerColors.textDark,
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

  static TextStyle editorialSerif({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = OwnerColors.textDark,
    double height = 1.15,
    double letterSpacing = -0.4,
  }) {
    return GoogleFonts.newsreader(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Display Serif for Large Numerals (e.g. "1", "368544", "4.0", "₹1306")
  static TextStyle serifNumeral({
    double fontSize = 48,
    FontWeight fontWeight = FontWeight.w700,
    Color color = OwnerColors.textDark,
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
    double? fontSize,
    double? size,
    FontWeight fontWeight = FontWeight.w800,
    Color color = OwnerColors.textOverline,
    double? letterSpacing,
    double? spacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size ?? fontSize ?? 11,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: spacing ?? letterSpacing ?? 1.2,
    );
  }

  // Primary Sans-serif Body & Buttons
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = OwnerColors.textDark,
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
    double size = 14,
    Color color = OwnerColors.textDark,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle regular({
    double size = 14,
    Color color = OwnerColors.textDark,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color,
      height: height,
    );
  }

  // Bold UI text for names, items, titles
  static TextStyle itemTitle({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w700,
    Color color = OwnerColors.textDark,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.2,
    );
  }
}

// Custom Painter for the organic sage hill layers at the bottom of the hero card
class WavyHillsPainter extends CustomPainter {
  final Color backColor;
  final Color frontColor;

  WavyHillsPainter({
    this.backColor = const Color(0xFF435845),
    this.frontColor = const Color(0xFF6E8670),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Back hill layer
    final backPaint = Paint()
      ..color = backColor
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, size.height * 0.45);
    backPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.15,
      size.width * 0.7,
      size.height * 0.5,
    );
    backPath.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.65,
      size.width,
      size.height * 0.4,
    );
    backPath.lineTo(size.width, size.height);
    backPath.lineTo(0, size.height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Front hill layer
    final frontPaint = Paint()
      ..color = frontColor
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, size.height * 0.6);
    frontPath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.45,
      size.width * 0.55,
      size.height * 0.7,
    );
    frontPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85,
      size.width,
      size.height * 0.55,
    );
    frontPath.lineTo(size.width, size.height);
    frontPath.lineTo(0, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
