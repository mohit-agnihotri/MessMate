import 'package:flutter/material.dart';

/// Concept 05 Mezzo Logo: Fork and spoon forming the letter "M" in a plate
/// with warm amber glow, walnut background, and fresh sage leaf accent.
class MezzoLogo extends StatelessWidget {
  final double size;
  final bool showSquircle;
  final bool showShadow;
  final Color? backgroundColor;

  const MezzoLogo({
    super.key,
    this.size = 64,
    this.showSquircle = true,
    this.showShadow = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/mezzo_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );

    if (showShadow) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF09E38).withValues(alpha: 0.22),
              blurRadius: size * 0.35,
              spreadRadius: 1,
              offset: Offset(0, size * 0.08),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
