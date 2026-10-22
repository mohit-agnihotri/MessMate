import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../services/pdf_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/student_inspired_theme.dart';

class StudentBillPage extends ConsumerWidget {
  const StudentBillPage({super.key});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentBillProvider);

    return Scaffold(
      backgroundColor: StudentColors.canvas,
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: StudentColors.amber),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(ref, state)),
                  if (state.bill != null) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: _buildMainBillCard(state.bill!, state),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildBreakdownCard(context, state.bill!),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildPaymentDetails(state.bill!),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                      sliver: SliverToBoxAdapter(
                        child: _buildDownloadButton(state.bill!),
                      ),
                    ),
                  ] else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🧾', style: TextStyle(fontSize: 42)),
                            const SizedBox(height: 12),
                            Text(
                              'No bill generated for this month',
                              style: StudentTypography.serifHeading(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Switch months using the navigation bar above.',
                              style: GoogleFonts.inter(
                                color: StudentColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ── Header & Month Switcher ────────────────────────────────────────────────
  Widget _buildHeader(WidgetRef ref, StudentBillState state) {
    final vm = ref.read(studentBillProvider.notifier);
    final monthName = _months[state.selectedMonth.month - 1];
    final year = state.selectedMonth.year;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY INVOICE & LEDGER',
            style: StudentTypography.overline(
              fontSize: 11,
              color: StudentColors.sageDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Billing',
            style: StudentTypography.serifHeading(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Detailed breakdown of your mess dues and payments',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: StudentColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Month Switcher Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: StudentColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: StudentColors.borderSubtle),
              boxShadow: StudentColors.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => vm.changeMonth(
                    DateTime(
                      state.selectedMonth.year,
                      state.selectedMonth.month - 1,
                    ),
                  ),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: StudentColors.walnut,
                    size: 22,
                  ),
                ),
                Text(
                  '$monthName $year',
                  style: StudentTypography.bold(
                    fontSize: 15,
                    color: StudentColors.walnut,
                  ),
                ),
                IconButton(
                  onPressed: () => vm.changeMonth(
                    DateTime(
                      state.selectedMonth.year,
                      state.selectedMonth.month + 1,
                    ),
                  ),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: StudentColors.walnut,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dark Walnut Bill Hero Card (Matching 22.48.48.jpeg) ──────────────────────
  Widget _buildMainBillCard(BillModel bill, StudentBillState state) {
    final monthName = _months[state.selectedMonth.month - 1].toUpperCase();
    final year = state.selectedMonth.year;
    final totalCredits = bill.proratedDiscount + bill.totalDeductions;

    return Container(
      decoration: BoxDecoration(
        color: StudentColors.walnut,
        borderRadius: BorderRadius.circular(24),
        boxShadow: StudentColors.elevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient Warm Glow in background
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StudentColors.amber.withValues(alpha: 0.12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$monthName $year BILL',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: StudentColors.amber,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: bill.isPaid
                            ? StudentColors.sageLight
                            : StudentColors.amberLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: bill.isPaid
                                  ? StudentColors.sage
                                  : StudentColors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            bill.isPaid ? 'PAID' : 'PAYMENT PENDING',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: bill.isPaid
                                  ? StudentColors.sageText
                                  : StudentColors.amberText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Serif Numeral Amount
                Text(
                  '₹${bill.finalPayable.toInt()}',
                  style: StudentTypography.serifNumeral(
                    fontSize: 46,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bill.isPaid
                      ? 'Paid successfully • Settled with mess owner'
                      : 'Due this month • Pay via UPI or cash',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 14),

                // Bottom stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base plan fee',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '₹${bill.baseFee.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (totalCredits > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Credits saved',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '-₹${totalCredits.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Clean Breakdown Card ───────────────────────────────────────────────────
  Widget _buildBreakdownCard(BuildContext context, BillModel bill) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BILL BREAKDOWN',
            style: StudentTypography.overline(fontSize: 11),
          ),
          const SizedBox(height: 14),
          _buildBreakdownRow(
            'Basic Monthly Fee',
            'Base plan charge',
            '₹${bill.baseFee.toInt()}',
          ),
          if (bill.proratedDiscount > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Mid-Month Join Discount',
              'Pro-rated deduction',
              '-₹${bill.proratedDiscount.toInt()}',
              isCredit: true,
            ),
          ],
          if (bill.specialSkipsCount > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              '✨ Special Feast Skips (${bill.specialSkipsCount} meal${bill.specialSkipsCount > 1 ? "s" : ""})',
              'Double value feast rebate',
              '-₹${bill.specialSkipsDeduction.toInt()}',
              isCredit: true,
            ),
          ],
          if (bill.normalSkipsCount > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Regular Meal Skips (${bill.normalSkipsCount} meal${bill.normalSkipsCount > 1 ? "s" : ""})',
              'Standard per-meal rebate',
              '-₹${bill.normalSkipsDeduction.toInt()}',
              isCredit: true,
            ),
          ] else if (bill.totalDeductions > 0 && bill.specialSkipsCount == 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Skipped Meal Credits',
              'Valid cancellations',
              '-₹${bill.totalDeductions.toInt()}',
              isCredit: true,
            ),
          ],
          if (bill.extraMealsAddon > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Extra Meals',
              'Beyond regular plan',
              '₹${bill.extraMealsAddon.toInt()}',
            ),
          ],
          if (bill.guestAddons > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Guest Meals Added',
              'Meals hosted for guests',
              '₹${bill.guestAddons.toInt()}',
            ),
          ],
          if (bill.extraFeesAddon > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Other Add-ons / Charges',
              'Feast or maintenance',
              '₹${bill.extraFeesAddon.toInt()}',
            ),
          ],
          if (bill.previousDues > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Previous Unpaid Dues',
              'Arrears from past cycle',
              '₹${bill.previousDues.toInt()}',
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: StudentColors.borderSubtle, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: StudentTypography.bold(fontSize: 16),
              ),
              Text(
                '₹${bill.finalPayable.toInt()}',
                style: StudentTypography.serifNumeral(
                  fontSize: 24,
                  color: StudentColors.walnut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDetailedBreakdown(context, bill),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: StudentColors.walnut),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'View Detailed Itemized List',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: StudentColors.walnut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String title,
    String subtitle,
    String amount, {
    bool isCredit = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: StudentTypography.bold(fontSize: 13.5),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: StudentColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isCredit ? StudentColors.sageDark : StudentColors.textDark,
          ),
        ),
      ],
    );
  }

  // ── Payment Details Card ───────────────────────────────────────────────────
  Widget _buildPaymentDetails(BillModel bill) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: StudentTypography.overline(fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: StudentColors.amberLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: StudentColors.amberDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.isPaid ? 'Payment Confirmed' : 'Settle with Mess Owner',
                      style: StudentTypography.bold(fontSize: 14),
                    ),
                    Text(
                      bill.isPaid
                          ? 'Receipt has been issued by owner'
                          : 'Pay in cash or UPI directly at the counter',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: StudentColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Download Invoice PDF Button ───────────────────────────────────────────
  Widget _buildDownloadButton(BillModel bill) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => PdfService.generateAndDownloadBill(bill),
        icon: const Icon(Icons.download_rounded, size: 20),
        label: Text(
          'Download Invoice PDF',
          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: StudentColors.walnut,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ── Detailed Itemized List Modal ──────────────────────────────────────────
  void _showDetailedBreakdown(BuildContext context, BillModel bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: StudentColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: StudentColors.walnutMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Detailed Bill Breakdown',
                style: StudentTypography.serifHeading(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete itemized summary for this billing cycle',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: StudentColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: StudentColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Base Plan Fee', '₹${bill.baseFee.toInt()}'),
                    if (bill.proratedDiscount > 0)
                      _buildModalRow(
                        'Prorated Joining Discount',
                        '-₹${bill.proratedDiscount.toInt()}',
                        isCredit: true,
                      ),
                    if (bill.totalDeductions > 0)
                      _buildModalRow(
                        'Skipped Meals Credit',
                        '-₹${bill.totalDeductions.toInt()}',
                        isCredit: true,
                      ),
                    if (bill.guestAddons > 0)
                      _buildModalRow(
                        'Guest Meals',
                        '+₹${bill.guestAddons.toInt()}',
                      ),
                    if (bill.extraFeesAddon > 0)
                      _buildModalRow(
                        'Other Charges',
                        '+₹${bill.extraFeesAddon.toInt()}',
                      ),
                    if (bill.previousDues > 0)
                      _buildModalRow(
                        'Previous Dues',
                        '+₹${bill.previousDues.toInt()}',
                      ),
                    const Divider(height: 20, color: StudentColors.borderSubtle),
                    _buildModalRow(
                      'Final Amount',
                      '₹${bill.finalPayable.toInt()}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.walnut,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Close',
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

  Widget _buildModalRow(
    String label,
    String value, {
    bool isCredit = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: StudentColors.textDark,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isCredit
                  ? StudentColors.sageDark
                  : (isBold ? StudentColors.walnut : StudentColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
