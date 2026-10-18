import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Cockpit / Ecosystem Pulse tab for high-level telemetry and live activity.
class AdminCockpitTab extends ConsumerWidget {
  const AdminCockpitTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);

    return StreamBuilder<List<MessModel>>(
      stream: adminService.streamAllMesses(),
      builder: (context, messSnap) {
        final messes = messSnap.data ?? [];
        final totalMesses = messes.length;
        final verifiedMesses = messes.where((m) => m.isVerified).length;
        final trialMesses =
            messes.where((m) => m.subscriptionStatus == 'trial_active').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Health & Header (Zero Overflow Guarantee)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLATFORM OVERVIEW',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const PulsingBeacon(
                              color: AdminCyberTheme.neonEmerald,
                              size: 7,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'All Systems Active • Mumbai',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AdminCyberTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AdminCyberTheme.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            AdminCyberTheme.neonCyan.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hub_rounded,
                            size: 11, color: AdminCyberTheme.neonCyan),
                        const SizedBox(width: 4),
                        Text(
                          'FCM v1 Active',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // KPI Metric Cards Grid (100% Overflow Proof)
              Row(
                children: [
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Total Messes',
                      value: '$totalMesses',
                      deltaText: '$trialMesses in 6M Trial',
                      icon: Icons.storefront_rounded,
                      accentColor: AdminCyberTheme.neonEmerald,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Verified Messes',
                      value: '$verifiedMesses',
                      deltaText: 'Verified Partners',
                      icon: Icons.verified_rounded,
                      accentColor: AdminCyberTheme.neonCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Base Plan',
                      value: '₹499/mo',
                      deltaText: 'Direct Remittance',
                      icon: Icons.payments_rounded,
                      accentColor: AdminCyberTheme.neonViolet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Platform Fee',
                      value: '₹19/usr',
                      deltaText: '0% Gateway Cut',
                      icon: Icons.shield_rounded,
                      accentColor: AdminCyberTheme.neonAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Zero Gateway Cut Direct UPI Highlight
              CyberCard(
                glowColor: AdminCyberTheme.neonEmerald,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AdminCyberTheme.neonEmerald
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AdminCyberTheme.neonEmerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DIRECT UPI REMITTANCE ENGINE',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AdminCyberTheme.neonEmerald,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owners collect directly from students. Monthly software fees & ₹19 platform fee balance are remitted via your UPI QR with zero gateway fee deductions.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AdminCyberTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Live Platform Event Feed
              Text(
                'LIVE PLATFORM TICKER',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              CyberCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildTickerItem(
                      timeAgo: 'Just now',
                      icon: Icons.fiber_manual_record_rounded,
                      iconColor: AdminCyberTheme.neonEmerald,
                      title: 'Push Notification Pipeline Active',
                      subtitle:
                          'REST notification system ready with OneSignal & FCM v1 integration.',
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    _buildTickerItem(
                      timeAgo: 'Automated',
                      icon: Icons.card_giftcard_rounded,
                      iconColor: AdminCyberTheme.neonCyan,
                      title: '6-Month Founder Grant Active',
                      subtitle:
                          'New mess registrations automatically receive 180 days free VIP tier.',
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    _buildTickerItem(
                      timeAgo: 'System',
                      icon: Icons.lock_clock_rounded,
                      iconColor: AdminCyberTheme.neonViolet,
                      title: 'Security Vault Live',
                      subtitle:
                          'Dual-gate authentication active with Google Email Whitelist & Master PIN.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTickerItem({
    required String timeAgo,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AdminCyberTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AdminCyberTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
