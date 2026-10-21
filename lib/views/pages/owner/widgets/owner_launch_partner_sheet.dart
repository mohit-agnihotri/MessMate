import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../theme/owner_inspired_theme.dart';

/// Celebratory Welcome & VIP Partner Grant Sheet for Mess Owners.
/// Matches WhatsApp Image 2026-10-20 at 16.27.27.jpeg.
class OwnerLaunchPartnerSheet extends StatelessWidget {
  final MessModel mess;

  const OwnerLaunchPartnerSheet({
    super.key,
    required this.mess,
  });

  @override
  Widget build(BuildContext context) {
    int daysLeft = 180;
    if (mess.trialExpiresAt != null) {
      daysLeft = mess.trialExpiresAt!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    return Container(
      decoration: const BoxDecoration(
        color: OwnerColors.walnutDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Main Title (Serif)
                Text(
                  'VIP launch benefits',
                  style: OwnerTypography.editorialSerif(
                    size: 24,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Tier Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF382C24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: OwnerColors.amberGlow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'FOUNDER PARTNER TIER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: OwnerColors.amberGlow,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Badhai Ho! 6 Mahine\n100% Free VIP Access',
                  style: OwnerTypography.editorialSerif(
                    size: 24,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 18),

                // Countdown Highlight Card
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF382C24),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FREE TRIAL REMAINING',
                        style: OwnerTypography.overline(
                          fontSize: 11,
                          color: OwnerColors.amberGlow,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$daysLeft Din Baaki Hain',
                        style: OwnerTypography.editorialSerif(
                          size: 30,
                          weight: FontWeight.w700,
                          color: const Color(0xFFF3EEDF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Feature checkmarks
                _buildBenefitRow('Unlimited student management & passbook'),
                _buildBenefitRow('Live kitchen headcount & cutoff guardian'),
                _buildBenefitRow('Instant WhatsApp & push updates'),
                _buildBenefitRow('Zero platform charges (₹0 / mo)'),

                const SizedBox(height: 14),

                // Transparency note
                Text(
                  'After 6 months, the basic plan (₹499/mo) keeps you going. No auto deduction.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9E8F84),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.amberGlow,
                      foregroundColor: OwnerColors.textDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'SHURU KAREIN',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: OwnerColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_rounded,
            color: OwnerColors.sageGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
