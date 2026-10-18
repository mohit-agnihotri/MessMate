import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens, palettes, and cyber-styling primitives for the Super Admin Mission Control.
class AdminCyberTheme {
  AdminCyberTheme._();

  // Backgrounds
  static const Color bgObsidian = Color(0xFF06090F);
  static const Color bgSurface = Color(0xFF0B0F19);
  static const Color bgGlass = Color(0x1AFFFFFF);
  static const Color bgCard = Color(0xFF101726);

  // Neon Accent Colors
  static const Color neonEmerald = Color(0xFF10B981);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonRose = Color(0xFFF43F5E);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Borders
  static Border cyberBorder([Color? color, double width = 1.0]) => Border.all(
        color: color ?? Colors.white.withValues(alpha: 0.10),
        width: width,
      );

  // Gradients
  static const LinearGradient emeraldCyanGradient = LinearGradient(
    colors: [neonEmerald, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetCyanGradient = LinearGradient(
    colors: [neonViolet, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF0B0F19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Frosted Glass Cyber Card with subtle border highlights and optional glow.
class CyberCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const CyberCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.glowColor,
    this.borderRadius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1322).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (glowColor ?? Colors.white).withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (glowColor ?? AdminCyberTheme.neonCyan).withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: content,
        ),
      );
    }
    return content;
  }
}

/// Pulsing Live Beacon Indicator (animated glowing dot).
class PulsingBeacon extends StatefulWidget {
  final Color color;
  final double size;
  final String? label;

  const PulsingBeacon({
    super.key,
    this.color = AdminCyberTheme.neonEmerald,
    this.size = 9,
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
    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.9).animate(
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
                  color: widget.color.withValues(alpha: _opacityAnimation.value * 0.35),
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
                    color: widget.color.withValues(alpha: 0.8),
                    blurRadius: 8,
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
          const SizedBox(width: 8),
          Text(
            widget.label!,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: widget.color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }
    return beacon;
  }
}

/// Monospace Telemetry KPI Metric Card.
class CyberTelemetryMetric extends StatelessWidget {
  final String title;
  final String value;
  final String? deltaText;
  final bool isPositiveDelta;
  final IconData icon;
  final Color accentColor;

  const CyberTelemetryMetric({
    super.key,
    required this.title,
    required this.value,
    this.deltaText,
    this.isPositiveDelta = true,
    required this.icon,
    this.accentColor = AdminCyberTheme.neonEmerald,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      glowColor: accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AdminCyberTheme.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AdminCyberTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (deltaText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isPositiveDelta ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 13,
                  color: isPositiveDelta ? AdminCyberTheme.neonEmerald : AdminCyberTheme.neonRose,
                ),
                const SizedBox(width: 4),
                Text(
                  deltaText!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositiveDelta
                        ? AdminCyberTheme.neonEmerald
                        : AdminCyberTheme.neonRose,
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
