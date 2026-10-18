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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Health & Telemetry Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ECOSYSTEM PULSE',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
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
                          Text(
                            'All Cloud Systems Nominal • Asia-South1',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AdminCyberTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          AdminCyberTheme.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            AdminCyberTheme.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hub_rounded,
                            size: 13, color: AdminCyberTheme.neonCyan),
                        const SizedBox(width: 5),
                        Text(
                          'FCM v1 Active',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Metric Cards Grid
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Verified Partners',
                      value: '$verifiedMesses',
                      deltaText: 'Blue/Green Tick',
                      icon: Icons.verified_rounded,
                      accentColor: AdminCyberTheme.neonCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Base Software Tier',
                      value: '₹499/mo',
                      deltaText: 'Direct Remittance',
                      icon: Icons.payments_rounded,
                      accentColor: AdminCyberTheme.neonViolet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Platform Fee',
                      value: '₹19/usr',
                      deltaText: '0% Gateway Loss 🛡️',
                      icon: Icons.shield_rounded,
                      accentColor: AdminCyberTheme.neonAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Zero Gateway Cut Philosophy Card
              CyberCard(
                glowColor: AdminCyberTheme.neonEmerald,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AdminCyberTheme.neonEmerald
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AdminCyberTheme.neonEmerald
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AdminCyberTheme.neonEmerald,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DIRECT UPI REMITTANCE ENGINE',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AdminCyberTheme.neonEmerald,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Students pay mess owners directly. Owners remit your ₹499 + (Students × ₹19) via UPI QR with zero 2% gateway commissions.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
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
              const SizedBox(height: 24),

              // Live Platform Event Feed
              Text(
                'LIVE PLATFORM TICKER',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              CyberCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildTickerItem(
                      timeAgo: 'Just now',
                      icon: Icons.fiber_manual_record_rounded,
                      iconColor: AdminCyberTheme.neonEmerald,
                      title: 'OneSignal Push Engine Live',
                      subtitle:
                          'REST notification pipeline synced with FCM v1 service account.',
                    ),
                    const Divider(color: Colors.white10, height: 18),
                    _buildTickerItem(
                      timeAgo: 'Automated',
                      icon: Icons.card_giftcard_rounded,
                      iconColor: AdminCyberTheme.neonCyan,
                      title: '6-Month Founder Grant Active',
                      subtitle:
                          'New mess registrations automatically receive 180 days free VIP tier.',
                    ),
                    const Divider(color: Colors.white10, height: 18),
                    _buildTickerItem(
                      timeAgo: 'System',
                      icon: Icons.lock_clock_rounded,
                      iconColor: AdminCyberTheme.neonViolet,
                      title: 'Cutoff Timing Guardian',
                      subtitle:
                          'Choice meal preferences securely locked at earliest meal window.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AdminCyberTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminCyberTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
