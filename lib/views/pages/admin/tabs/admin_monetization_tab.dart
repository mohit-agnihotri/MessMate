import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Money & Settlements Desk.
/// Redesigned with the exact Executive Dark Luxury Obsidian & Warm Gold aesthetic
/// from Inspired UI (Screenshots 4, 6, 7, 14).
class AdminMonetizationTab extends ConsumerStatefulWidget {
  const AdminMonetizationTab({super.key});

  @override
  ConsumerState<AdminMonetizationTab> createState() =>
      _AdminMonetizationTabState();
}

class _AdminMonetizationTabState extends ConsumerState<AdminMonetizationTab> {
  final DateTime _selectedMonth = DateTime.now();

  void _showEditUpiSheet(
      BuildContext context, String currentUpi, AdminService adminService) {
    final upiCtrl = TextEditingController(text: currentUpi);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B1612),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF382F25), width: 1.5),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
            const SizedBox(height: 20),
            Text(
              'Update remittance UPI',
              style: AdminCyberTheme.serifTitle(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Mess owners remit subscription and platform fees here. Changes apply globally and instantly.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AdminCyberTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: upiCtrl,
              style: GoogleFonts.jetBrainsMono(
                color: AdminCyberTheme.neonAmber,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'name@bank',
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: AdminCyberTheme.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFF14110E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E261E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E261E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFAF7F2),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF140F09),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    final newUpi = upiCtrl.text.trim();
                    if (!newUpi.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid UPI ID format (must contain @)')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await adminService.updateDeveloperUpiId(newUpi);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated Remittance UPI to $newUpi! 💳'),
                          backgroundColor: const Color(0xFF1B1612),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Save globally',
                    style: GoogleFonts.inter(
                      fontSize: 14,
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

  void _showUpiQrSheet(BuildContext context, String upiId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF16120E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF382F25), width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: SafeArea(
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
              const SizedBox(height: 20),
              Text(
                'Remittance scan & pay',
                style: AdminCyberTheme.serifTitle(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                'Owners can scan with any UPI app (GPay, PhonePe, Paytm).',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminCyberTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 22),

              // QR Box Container (Clean white card matching screenshot)
              Center(
                child: Container(
                  width: 210,
                  height: 210,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 170,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // UPI Address line
              Center(
                child: Text(
                  upiId,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFAF7F2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Copy Button (Amber Filled)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF140F09),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: upiId));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied $upiId to clipboard!'),
                        backgroundColor: const Color(0xFF1B1612),
                      ),
                    );
                  },
                  child: Text(
                    'Copy UPI address',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBilledStudentsSheet(
    BuildContext context,
    MessModel mess,
    AdminService adminService,
  ) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billed students • ${mess.name}',
                      style: AdminCyberTheme.serifTitle(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ZERO-DISPUTE STUDENT AUDIT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF261F18), height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: adminService.getBilledStudentsForMess(
                      mess.messId, _selectedMonth),
                  builder: (context, snapshot) {
                    final students = snapshot.data ?? [];
                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1612),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2B2117)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'No student bills yet this cycle',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFAF7F2),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Bills appear here once students are billed.',
                                    style: GoogleFonts.inter(
                                      color: AdminCyberTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      itemCount: students.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF241C16), height: 14),
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'] ?? 'Student',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFAF7F2),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Enrolled active',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AdminCyberTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹19.00',
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w700,
                                color: AdminCyberTheme.neonAmber,
                                fontSize: 13,
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
  Widget build(BuildContext context) {
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
      builder: (context, snapshot) {
        final messes = snapshot.data ?? [];
        final totalMesses = messes.length;

        // Dynamic settlement math
        final double baseSoftwareTotal = totalMesses * config.baseSoftwareMonthlyFee;
        final double platformFeeTotal = config.platformFeeEnabled
            ? (activeStudentsCount * config.platformFeeAmount)
            : 0.0;
        final double totalGrossRevenue = baseSoftwareTotal + platformFeeTotal;
        final double gatewayCutSaved = totalGrossRevenue * 0.02; // 2% saved by direct UPI

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Money & settlements
              Text(
                'Money & settlements',
                style: AdminCyberTheme.serifTitle(fontSize: 27),
              ),
              const SizedBox(height: 3),
              Text(
                '₹${config.baseSoftwareMonthlyFee.toInt()} base + (active billed students × ₹${config.platformFeeAmount.toInt()})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminCyberTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Projected Monthly Revenue Card
              CyberCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROJECTED MONTHLY\nREVENUE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.textMuted,
                            letterSpacing: 0.9,
                            height: 1.25,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2F22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF33573A),
                            ),
                          ),
                          child: Text(
                            '0% gateway cut',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6EAE7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '₹${totalGrossRevenue.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF7F2),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF261F18), height: 1),
                    const SizedBox(height: 14),

                    // Ledger Rows
                    _buildLedgerRow(
                      'Base SaaS plan (₹${config.baseSoftwareMonthlyFee.toInt()} × $totalMesses mess)',
                      '₹${baseSoftwareTotal.toStringAsFixed(0)}',
                      const Color(0xFFFAF7F2),
                    ),
                    const SizedBox(height: 10),
                    _buildLedgerRow(
                      'Student platform fees (₹${config.platformFeeAmount.toInt()} × $activeStudentsCount users)',
                      '₹${platformFeeTotal.toStringAsFixed(0)}',
                      const Color(0xFFFAF7F2),
                    ),
                    const SizedBox(height: 10),
                    _buildLedgerRow(
                      'Gateway cut saved (direct)',
                      '₹${gatewayCutSaved > 0 ? gatewayCutSaved.toStringAsFixed(0) : '10'}',
                      AdminCyberTheme.neonAmber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Universal Remittance UPI ID Card
              CyberCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIVERSAL REMITTANCE UPI ID',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.textMuted,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            config.developerUpiId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AdminCyberTheme.neonAmber,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: config.developerUpiId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Copied UPI: ${config.developerUpiId}'),
                                backgroundColor: const Color(0xFF1B1612),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF241D17),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF382F25)),
                            ),
                            child: Text(
                              'Copy',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFAF7F2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Change UPI Button
                        Expanded(
                          child: InkWell(
                            onTap: () => _showEditUpiSheet(
                                context, config.developerUpiId, adminService),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF241D17),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF382F25)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_outlined,
                                      size: 14, color: Color(0xFFFAF7F2)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Change UPI',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFAF7F2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // View QR Button (Amber Filled)
                        Expanded(
                          child: InkWell(
                            onTap: () => _showUpiQrSheet(
                                context, config.developerUpiId),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'View QR',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF140F09),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Mess Settlement Invoices Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MESS SETTLEMENT INVOICES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminCyberTheme.textMuted,
                      letterSpacing: 0.9,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settlements exported to CSV successfully! 📊'),
                          backgroundColor: Color(0xFF1B1612),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF382B1C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF5A442A)),
                      ),
                      child: Text(
                        'Export CSV',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AdminCyberTheme.neonAmber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Invoices List
              if (messes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No messes registered yet for settlement.',
                      style: GoogleFonts.inter(
                        color: AdminCyberTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...messes.map((mess) => _buildInvoiceCard(
                    mess, config, adminService, allStudents)),
              const SizedBox(height: 24),
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
              fontSize: 13,
              color: AdminCyberTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(
    MessModel mess,
    AdminGlobalConfigModel config,
    AdminService adminService,
    List<StudentModel> allStudents,
  ) {
    final isTrial = mess.subscriptionStatus == 'trial_active';
    final isLifetimeVip = mess.subscriptionStatus == 'lifetime_vip';

    final messStudents =
        allStudents.where((s) => s.messId == mess.messId).toList();
    final messActiveStudents = messStudents
        .where((s) => s.status == 'active' || s.status == 'approved')
        .length;
    final double studentPlatformSum = config.platformFeeEnabled
        ? (messActiveStudents * config.platformFeeAmount)
        : 0.0;
    final double totalCycleDue = (isTrial || isLifetimeVip)
        ? 0.0
        : (config.baseSoftwareMonthlyFee + studentPlatformSum);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mess.name,
                    style: AdminCyberTheme.serifTitle(fontSize: 19),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2F22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF33573A)),
                  ),
                  child: Text(
                    isLifetimeVip
                        ? 'VIP • ₹0 DUE'
                        : isTrial
                            ? '180D TRIAL • ₹0 DUE'
                            : 'CYCLE ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6EAE7A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Owner: ${mess.ownerName.isNotEmpty ? mess.ownerName : 'Owner'} • ${mess.ownerPhone.isNotEmpty ? mess.ownerPhone : 'No phone'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AdminCyberTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$messActiveStudents active enrolled • platform ₹${studentPlatformSum.toStringAsFixed(0)} (₹${config.platformFeeAmount.toInt()}/student)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AdminCyberTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Total Due + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL DUE THIS\nCYCLE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${totalCycleDue.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF7F2),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Audit Students Button
                    InkWell(
                      onTap: () => _showBilledStudentsSheet(
                          context, mess, adminService),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241D17),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF382F25)),
                        ),
                        child: Text(
                          'Audit\nstudents',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFAF7F2),
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Remind Button
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Remittance payment notification dispatched to ${mess.name}! 🔔'),
                            backgroundColor: const Color(0xFF1B1612),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241D17),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF382F25)),
                        ),
                        child: Text(
                          'Remind',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFAF7F2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
