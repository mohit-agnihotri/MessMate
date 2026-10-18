import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Monetization, Monthly Settlement & Direct UPI Remittance Desk.
/// Calculates the ₹499 base + (Active Billed Students × ₹19) model with 0% gateway loss.
class AdminMonetizationTab extends ConsumerStatefulWidget {
  const AdminMonetizationTab({super.key});

  @override
  ConsumerState<AdminMonetizationTab> createState() =>
      _AdminMonetizationTabState();
}

class _AdminMonetizationTabState extends ConsumerState<AdminMonetizationTab> {
  final DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);
    final configAsync = ref.watch(adminConfigStreamProvider);
    final config = configAsync.value ?? const AdminGlobalConfigModel();

    return StreamBuilder<List<MessModel>>(
      stream: adminService.streamAllMesses(),
      builder: (context, snapshot) {
        final messes = snapshot.data ?? [];
        final totalMesses = messes.length;

        // Estimated revenue breakdown
        final double baseSoftwareTotal =
            totalMesses * config.baseSoftwareMonthlyFee;
        final int estimatedStudents =
            totalMesses * 45; // average 45 students per mess
        final double platformFeeTotal =
            config.platformFeeEnabled ? (estimatedStudents * config.platformFeeAmount) : 0.0;
        final double totalGrossRevenue = baseSoftwareTotal + platformFeeTotal;
        final double gatewayCutSaved = totalGrossRevenue * 0.02; // 2% saved!

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'MONETIZATION & SETTLEMENTS',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Formula: ₹499 Base SaaS + (Active Billed Students × ₹19)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AdminCyberTheme.neonEmerald,
                ),
              ),
              const SizedBox(height: 18),

              // Monthly Projection Card
              CyberCard(
                glowColor: AdminCyberTheme.neonEmerald,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROJECTED MONTHLY REVENUE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AdminCyberTheme.neonEmerald
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AdminCyberTheme.neonEmerald
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '0% GATEWAY CUT 🛡️',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AdminCyberTheme.neonEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹ ${totalGrossRevenue.toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 14),

                    // Itemized summary lines
                    _buildLedgerRow(
                      'Base SaaS Plan (₹${config.baseSoftwareMonthlyFee.toInt()} × $totalMesses Messes)',
                      '₹ ${baseSoftwareTotal.toStringAsFixed(0)}',
                      AdminCyberTheme.neonCyan,
                    ),
                    const SizedBox(height: 8),
                    _buildLedgerRow(
                      'Student Platform Fees (₹${config.platformFeeAmount.toInt()} × ~$estimatedStudents users)',
                      '₹ ${platformFeeTotal.toStringAsFixed(0)}',
                      AdminCyberTheme.neonEmerald,
                    ),
                    const SizedBox(height: 8),
                    _buildLedgerRow(
                      'Payment Gateway Cut Saved (Direct UPI)',
                      '₹ ${gatewayCutSaved.toStringAsFixed(0)} saved',
                      AdminCyberTheme.neonAmber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Developer UPI Account Pill Card
              CyberCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            AdminCyberTheme.neonCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          color: AdminCyberTheme.neonCyan, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REMITTANCE UPI ID (DIRECT TO YOU)',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AdminCyberTheme.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            config.developerUpiId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AdminCyberTheme.neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AdminCyberTheme.neonCyan.withValues(alpha: 0.15),
                        foregroundColor: AdminCyberTheme.neonCyan,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: AdminCyberTheme.neonCyan
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _showEditUpiDialog(
                          context, config.developerUpiId, adminService),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: Text(
                        'Change',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Per-Mess Settlement Directory
              Text(
                'MESS SETTLEMENT INVOICES',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              if (messes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No messes registered yet.',
                      style: GoogleFonts.inter(
                          color: AdminCyberTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ...messes.map((mess) => _buildMessInvoiceTile(mess, config, adminService)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerRow(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AdminCyberTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMessInvoiceTile(
    MessModel mess,
    AdminGlobalConfigModel config,
    AdminService adminService,
  ) {
    final isTrial = mess.subscriptionStatus == 'trial_active';
    final isLifetimeVip = mess.subscriptionStatus == 'lifetime_vip';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mess.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isTrial || isLifetimeVip
                        ? AdminCyberTheme.neonEmerald.withValues(alpha: 0.15)
                        : AdminCyberTheme.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLifetimeVip
                        ? 'LIFETIME VIP (₹0)'
                        : isTrial
                            ? '6M TRIAL (₹0 DUE)'
                            : 'BILLING ACTIVE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isTrial || isLifetimeVip
                          ? AdminCyberTheme.neonEmerald
                          : AdminCyberTheme.neonAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Owner: ${mess.ownerName} • 📞 ${mess.ownerPhone}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AdminCyberTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL DUE THIS CYCLE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AdminCyberTheme.textMuted,
                      ),
                    ),
                    Text(
                      isTrial || isLifetimeVip
                          ? '₹ 0.00'
                          : '₹ ${config.baseSoftwareMonthlyFee.toInt()}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isTrial || isLifetimeVip
                            ? AdminCyberTheme.neonEmerald
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showAuditDialog(context, mess, adminService),
                  icon: const Icon(Icons.people_outline_rounded,
                      size: 15, color: AdminCyberTheme.neonCyan),
                  label: Text(
                    'Audit Students',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditDialog(
    BuildContext context,
    MessModel mess,
    AdminService adminService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF070B14),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future:
              adminService.getBilledStudentsForMess(mess.messId, _selectedMonth),
          builder: (context, snapshot) {
            final students = snapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZERO DISPUTE STUDENT AUDIT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminCyberTheme.neonEmerald,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Billed Students for ${mess.name}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No individual student bills generated yet this cycle.',
                          style: GoogleFonts.inter(
                            color: AdminCyberTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, idx) {
                          final st = students[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    st['studentName']?.toString() ?? 'Student',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹ ${st['finalAmount']} (₹19 platform fee)',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    color: AdminCyberTheme.neonCyan,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUpiDialog(
    BuildContext context,
    String currentUpiId,
    AdminService adminService,
  ) {
    final controller = TextEditingController(text: currentUpiId);
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF070B14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AdminCyberTheme.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              title: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      color: AdminCyberTheme.neonCyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'UPDATE REMITTANCE UPI ID',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your direct UPI ID where mess owners will remit subscription & platform fee balances. Changes apply universally and instantly in real-time.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AdminCyberTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: GoogleFonts.jetBrainsMono(
                      color: AdminCyberTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. yourname@okaxis',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: AdminCyberTheme.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AdminCyberTheme.neonCyan,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(
                      color: AdminCyberTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminCyberTheme.neonCyan,
                    foregroundColor: const Color(0xFF04202C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newUpi = controller.text.trim();
                          if (newUpi.isEmpty || !newUpi.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid UPI ID (e.g. name@bank)'),
                                backgroundColor: AdminCyberTheme.neonRose,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isLoading = true);
                          try {
                            await adminService.updateGlobalToggles(
                                developerUpiId: newUpi);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Remittance UPI ID updated to $newUpi universally! 🚀'),
                                  backgroundColor: const Color(0xFF04202C),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF04202C),
                          ),
                        )
                      : Text(
                          'SAVE GLOBALLY',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
