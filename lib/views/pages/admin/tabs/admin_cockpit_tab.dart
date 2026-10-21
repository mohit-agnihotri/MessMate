import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';
import '../admin_mission_control_page.dart';

/// Pulse / Platform Overview Tab.
/// Redesigned with the exact Executive Dark Luxury Obsidian & Warm Gold aesthetic
/// from Inspired UI (Screenshot 1).
class AdminCockpitTab extends ConsumerWidget {
  const AdminCockpitTab({super.key});

  void _showAuditLogSheet(BuildContext context, AdminService adminService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF16120E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF382F25), width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Audit log',
                      style: AdminCyberTheme.serifTitle(fontSize: 22),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4A3824)),
                      ),
                      child: Text(
                        'IMMUTABLE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AdminCyberTheme.neonAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF261F18), height: 1),
              Expanded(
                child: StreamBuilder<List<AdminAuditLogModel>>(
                  stream: adminService.streamAuditLogs(),
                  builder: (context, snapshot) {
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Center(
                        child: Text(
                          'No audit events logged yet.',
                          style: GoogleFonts.inter(
                            color: AdminCyberTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF241C16), height: 16),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AdminCyberTheme.neonAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.action.toUpperCase(),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFAF7F2),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log.details,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AdminCyberTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} • ${log.adminEmail}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AdminCyberTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);
    final configAsync = ref.watch(adminConfigStreamProvider);
    final config = configAsync.value ?? const AdminGlobalConfigModel();
    final studentsAsync = ref.watch(adminStudentsStreamProvider);
    final allStudents = studentsAsync.value ?? [];
    final activeStudentsCount = allStudents
        .where((s) => s.status == 'active' || s.status == 'approved')
        .length;

    return StreamBuilder<List<MessModel>>(
      stream: adminService.streamAllMesses(),
      builder: (context, messSnap) {
        final messes = messSnap.data ?? [];
        final totalMesses = messes.length;
        final verifiedMesses = messes.where((m) => m.isVerified).length;
        final unverifiedMesses = totalMesses - verifiedMesses;
        final trialMesses =
            messes.where((m) => m.subscriptionStatus == 'trial_active').length;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Overview Serif Heading + FCM v1 Active Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform overview',
                          style: AdminCyberTheme.serifTitle(fontSize: 27),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'All systems active • Mumbai',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AdminCyberTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2F22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF33573A),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF55B36A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FCM v1 active',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6EAE7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2x2 Metric Cards Grid
              Row(
                children: [
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Total messes',
                      value: '$totalMesses',
                      deltaText: '$trialMesses in 180D trial',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Active students',
                      value: '$activeStudentsCount',
                      deltaText: '${allStudents.length} total users',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Base plan',
                      value: '₹${config.baseSoftwareMonthlyFee.toInt()}/mo',
                      deltaText: 'Direct remittance',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberTelemetryMetric(
                      title: 'Platform fee',
                      value: '₹${config.platformFeeAmount.toInt()}/usr',
                      deltaText: '0% gateway cut',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Quick Actions Row
              Text(
                'QUICK ACTIONS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AdminCyberTheme.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Broadcast (Amber Filled)
                    InkWell(
                      onTap: () {
                        ref.read(adminActiveTabProvider.notifier).state = 4; // Ops
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Broadcast',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF140F09),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Grant VIP
                    InkWell(
                      onTap: () {
                        ref.read(adminActiveTabProvider.notifier).state = 1; // Messes
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241D17),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF382F25)),
                        ),
                        child: Text(
                          'Grant VIP',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFAF7F2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Banner Toggle
                    InkWell(
                      onTap: () async {
                        final nextVal = !config.emergencyBannerEnabled;
                        await adminService.updateGlobalToggles(
                            emergencyBannerEnabled: nextVal);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(nextVal
                                  ? 'Emergency maintenance banner ENABLED across app.'
                                  : 'Emergency maintenance banner turned off.'),
                              backgroundColor: nextVal
                                  ? AdminCyberTheme.neonRose
                                  : const Color(0xFF241D17),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: config.emergencyBannerEnabled
                              ? const Color(0xFF3D1C1B)
                              : const Color(0xFF241D17),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: config.emergencyBannerEnabled
                                ? AdminCyberTheme.neonRose
                                : const Color(0xFF382F25),
                          ),
                        ),
                        child: Text(
                          'Banner',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: config.emergencyBannerEnabled
                                ? AdminCyberTheme.neonRose
                                : const Color(0xFFFAF7F2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Freeze
                    InkWell(
                      onTap: () {
                        ref.read(adminActiveTabProvider.notifier).state = 1; // Messes
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E1715),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4C211D)),
                        ),
                        child: Text(
                          'Freeze',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF87171),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Needs Attention Card
              CyberCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEEDS ATTENTION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row 1: Messes in trial
                    _buildAttentionRow(
                      title: 'Messes in trial',
                      badgeText: '$trialMesses ›',
                      isGreen: false,
                      onTap: () {
                        ref.read(adminActiveTabProvider.notifier).state = 1;
                      },
                    ),
                    const Divider(color: Color(0xFF261F18), height: 22),

                    // Row 2: Awaiting verification badge
                    _buildAttentionRow(
                      title: 'Awaiting verification badge',
                      badgeText: '${unverifiedMesses < 0 ? 0 : unverifiedMesses} ›',
                      isGreen: false,
                      onTap: () {
                        ref.read(adminActiveTabProvider.notifier).state = 1;
                      },
                    ),
                    const Divider(color: Color(0xFF261F18), height: 22),

                    // Row 3: Open tickets
                    StreamBuilder<List<SupportTicketModel>>(
                      stream: adminService.streamSupportTickets(statusFilter: 'open'),
                      builder: (context, ticketSnap) {
                        final openCount = ticketSnap.data?.length ?? 0;
                        return _buildAttentionRow(
                          title: 'Open tickets',
                          badgeText: '$openCount ›',
                          isGreen: openCount == 0,
                          onTap: () {
                            ref.read(adminActiveTabProvider.notifier).state = 2; // Inbox
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // System Health Checklist Card
              CyberCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM HEALTH',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHealthItem(
                      title: 'Push pipeline active',
                      subtitle: 'REST notifications via OneSignal & FCM v1',
                    ),
                    const SizedBox(height: 16),
                    _buildHealthItem(
                      title: '6-month founder grant active',
                      subtitle: 'New messes get 180 days free VIP automatically',
                    ),
                    const SizedBox(height: 16),
                    _buildHealthItem(
                      title: 'Security vault live',
                      subtitle:
                          'Dual-gate auth: Google email whitelist + master PIN',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Direct UPI Remittance Engine Card
              CyberCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIRECT UPI REMITTANCE ENGINE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Owners collect directly from students. Software fees and the ₹19 platform fee balance are remitted via your UPI QR with zero gateway deductions.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AdminCyberTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Audit Log Card
              CyberCard(
                onTap: () => _showAuditLogSheet(context, adminService),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AUDIT LOG',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF382B1C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5A442A)),
                          ),
                          child: Text(
                            'New',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AdminCyberTheme.neonAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every admin action (freeze, VIP, PIN change, broadcast) will be listed here.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AdminCyberTheme.textSecondary,
                        height: 1.45,
                      ),
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

  Widget _buildAttentionRow({
    required String title,
    required String badgeText,
    required bool isGreen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFAF7F2),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGreen ? const Color(0xFF1E2F22) : const Color(0xFF261F18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGreen ? const Color(0xFF33573A) : const Color(0xFF382F25),
              ),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isGreen
                    ? const Color(0xFF6EAE7A)
                    : const Color(0xFFFAF7F2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF6EAE7A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6EAE7A).withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFAF7F2),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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
    );
  }
}
