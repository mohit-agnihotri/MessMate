import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Executive Dark Luxury Design System & Theme Tokens for MessMate Admin Mission Control.
/// Meticulously crafted to match the Inspired Admin UI (Obsidian & Amber Gold aesthetic).
class AdminCyberTheme {
  AdminCyberTheme._();

  // Deep Obsidian & Warm Espresso Canvas
  static const Color bgObsidian = Color(0xFF0E0C0A);
  static const Color bgSurface = Color(0xFF14110E);
  static const Color bgCard = Color(0xFF1B1713);
  static const Color cardSurface = Color(0xFF1B1713);
  static const Color bgCardAlt = Color(0xFF221D18);
  static const Color bgCardInner = Color(0xFF15120F);

  // Warm Executive Borders & Dividers
  static const Color borderSubtle = Color(0xFF2D251D);
  static const Color borderLight = Color(0xFF382F25);
  static const Color borderHighlight = Color(0x38F59E0B);

  // Luxury Brand Accents
  static const Color neonAmber = Color(0xFFF59E0B);      // Primary Warm Gold / Amber
  static const Color neonAmberGlow = Color(0x3DF59E0B);
  static const Color neonEmerald = Color(0xFF4E654F);    // Sage Muted Olive-Green
  static const Color neonEmeraldBright = Color(0xFF22C55E); // Live indicator bright green
  static const Color neonCyan = Color(0xFF38BDF8);       // Sky Blue
  static const Color neonViolet = Color(0xFF818CF8);     // Indigo
  static const Color neonRose = Color(0xFFDC2626);       // Alert / Freeze Red
  static const Color neonRoseBg = Color(0xFF2B1414);     // Freeze soft background

  // Typography Palette
  static const Color textPrimary = Color(0xFFFAF7F2);
  static const Color textSecondary = Color(0xFFB5ABA1);
  static const Color textMuted = Color(0xFF7A7067);
  static const Color textAmber = Color(0xFFF59E0B);

  // Subtle Executive Borders
  static Border cyberBorder([Color? color, double width = 1.0]) => Border.all(
        color: color ?? borderSubtle,
        width: width,
      );

  // Gradients
  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sageGradient = LinearGradient(
    colors: [Color(0xFF4E654F), Color(0xFF364837)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E1915), Color(0xFF16120E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography standard helpers matching the Inspired UI
  static TextStyle serifTitle({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textPrimary,
    double height = 1.15,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle sansHeader({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textPrimary,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}

/// Executive Dark Luxury Card with warm border and soft elevation.
class CyberCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const CyberCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.glowColor,
    this.backgroundColor,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AdminCyberTheme.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (glowColor ?? AdminCyberTheme.borderSubtle).withValues(
            alpha: glowColor != null ? 0.45 : 1.0,
          ),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (glowColor ?? AdminCyberTheme.neonAmber).withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: content,
        ),
      );
    }
    return content;
  }
}

/// Pulsing Live Beacon Indicator (clean glowing status dot).
class PulsingBeacon extends StatefulWidget {
  final Color color;
  final double size;
  final String? label;

  const PulsingBeacon({
    super.key,
    this.color = AdminCyberTheme.neonEmeraldBright,
    this.size = 7,
    this.label,
  });

  @override
  State<PulsingBeacon> createState() => _PulsingBeaconState();
}

class _PulsingBeaconState extends State<PulsingBeacon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget beacon = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size * 2.2,
                height: widget.size * 2.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: _opacityAnimation.value * 0.3),
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.7),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (widget.label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          beacon,
          const SizedBox(width: 6),
          Text(
            widget.label!,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
          ),
        ],
      );
    }
    return beacon;
  }
}

/// Fully Overflow-Proof Executive KPI Metric Card matching Inspired UI.
class CyberTelemetryMetric extends StatelessWidget {
  final String title;
  final String value;
  final String? deltaText;
  final bool isPositiveDelta;
  final IconData? icon;
  final Color accentColor;

  const CyberTelemetryMetric({
    super.key,
    required this.title,
    required this.value,
    this.deltaText,
    this.isPositiveDelta = true,
    this.icon,
    this.accentColor = AdminCyberTheme.neonAmber,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AdminCyberTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AdminCyberTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (deltaText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '↑ ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AdminCyberTheme.neonAmber,
                  ),
                ),
                Expanded(
                  child: Text(
                    deltaText!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AdminCyberTheme.neonAmber,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
