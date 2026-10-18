import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens, modern palettes, and executive styling primitives for the Super Admin Mission Control.
/// Inspired by high-end modern developer dashboards (Stripe, Linear, Supabase, Vercel).
class AdminCyberTheme {
  AdminCyberTheme._();

  // Premium Slate & Obsidian Backgrounds
  static const Color bgObsidian = Color(0xFF090D16);
  static const Color bgSurface = Color(0xFF0F172A);
  static const Color bgCard = Color(0xFF131D2E);
  static const Color cardSurface = Color(0xFF131D2E);
  static const Color bgGlass = Color(0x1AFFFFFF);

  // Subtle Executive Borders & Dividers
  static const Color borderSubtle = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)

  // Refined Brand Accents (Vibrant yet executive)
  static const Color neonEmerald = Color(0xFF10B981); // Emerald / Success
  static const Color neonCyan = Color(0xFF0EA5E9);    // Sky Blue / Info
  static const Color neonViolet = Color(0xFF6366F1);  // Indigo / Premium
  static const Color neonAmber = Color(0xFFF59E0B);   // Warm Amber / Notice
  static const Color neonRose = Color(0xFFF43F5E);    // Rose / Alert

  // Typography Palette
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Subtle Executive Borders
  static Border cyberBorder([Color? color, double width = 1.0]) => Border.all(
        color: color ?? borderSubtle,
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
    colors: [Color(0xFF131D2E), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Modern Glass Card with subtle border highlights and soft elevation.
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
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.glowColor,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (glowColor ?? Colors.white).withValues(alpha: glowColor != null ? 0.35 : 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.12),
              blurRadius: 16,
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
          splashColor: (glowColor ?? AdminCyberTheme.neonCyan).withValues(alpha: 0.12),
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
    this.color = AdminCyberTheme.neonEmerald,
    this.size = 8,
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
                    color: widget.color.withValues(alpha: 0.6),
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

/// Fully Overflow-Proof Executive KPI Metric Card.
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminCyberTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AdminCyberTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (deltaText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isPositiveDelta
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 13,
                  color: isPositiveDelta
                      ? AdminCyberTheme.neonEmerald
                      : AdminCyberTheme.neonAmber,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deltaText!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositiveDelta
                          ? AdminCyberTheme.neonEmerald
                          : AdminCyberTheme.textMuted,
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
