import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';
import '../../../services/pdf_service.dart';

class StudentBillPage extends ConsumerWidget {
  const StudentBillPage({super.key});

  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentBillProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(ref, state)),
                if (state.bill != null) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildStatusPill(state.bill!)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildBillSummaryCard(state.bill!)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildBreakdownSection(state.bill!)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    sliver: SliverToBoxAdapter(child: _buildDownloadButton(state.bill!)),
                  ),
                ] else
                  const SliverFillRemaining(
                    child: Center(child: Text('No bill available'))),
              ],
            ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, StudentBillState state) {
    final vm = ref.read(studentBillProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(children: [
        Text('My Bill',
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => vm.changeMonth(
              DateTime(state.selectedMonth.year, state.selectedMonth.month - 1)),
            child: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28)),
          const SizedBox(width: 12),
          Text(
            '${_months[state.selectedMonth.month - 1]} ${state.selectedMonth.year}',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => vm.changeMonth(
              DateTime(state.selectedMonth.year, state.selectedMonth.month + 1)),
            child: const Icon(Icons.chevron_right, color: Color(0xFF374151), size: 28)),
        ]),
      ]),
    );
  }

  Widget _buildStatusPill(BillModel bill) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bill.isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: bill.isPaid ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: bill.isPaid ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            bill.isPaid ? 'Payment Done' : 'Payment Pending',
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: bill.isPaid ? const Color(0xFF16A34A) : const Color(0xFF92400E)),
          ),
        ]),
      ),
    );
  }

  Widget _buildBillSummaryCard(BillModel bill) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        _buildBillRow('Basic Monthly Fee', 'Rs ${bill.baseFee.toInt()}', const Color(0xFF111827)),
        const Divider(height: 20, color: Color(0xFFF3F4F6)),
        _buildBillRow('Total Deductions', '-Rs ${bill.totalDeductions.toInt()}', const Color(0xFFEF4444)),
        const SizedBox(height: 8),
        _buildBillRow('Guest Add-on (Oct 15)', '+Rs ${bill.guestAddons.toInt()}', const Color(0xFFF59E0B)),
        const Divider(height: 20),
        _buildBillRow('Final Payable', 'Rs ${bill.finalPayable.toInt()}', const Color(0xFF111827), isBold: true),
      ]),
    );
  }

  Widget _buildBillRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 14,
        color: isBold ? const Color(0xFF111827) : const Color(0xFF374151),
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      )),
      Text(value, style: GoogleFonts.inter(
        fontSize: 14, color: valueColor,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      )),
    ]);
  }

  Widget _buildBreakdownSection(BillModel bill) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How was this calculated?',
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
      const SizedBox(height: 8),
      Text('Deduction Breakdown',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      const SizedBox(height: 12),
      ...bill.deductions.map((d) => _buildDeductionRow(d)),
    ]);
  }

  Widget _buildDeductionRow(DeductionItem d) {
    const monthNames = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final isOwnerOff = d.type == 'owner_off';
    return Column(children: [
      Row(children: [
        Expanded(child: Text(
          '${monthNames[d.date.month]} ${d.date.day} - ${d.mealSlot} - ${d.type == 'self_cancelled' ? 'Self-Cancelled' : 'Off by Owner'}',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
        )),
        const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        if (isOwnerOff)
          Text('Rs 0 (No Charge)',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E)))
        else
          Text('${d.amount.isNegative ? '-' : '+'}Rs ${d.amount.abs().toInt()}',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      ]),
      const Divider(height: 20, color: Color(0xFFF3F4F6)),
    ]);
  }

  Widget _buildDownloadButton(BillModel bill) {
    return OutlinedButton.icon(
      onPressed: () async {
        await PdfService.generateAndDownloadBill(bill);
      },
      icon: const Icon(Icons.file_download_outlined, color: Color(0xFF374151)),
      label: Text('Download Bill PDF',
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        backgroundColor: Colors.white,
      ),
    );
  }
}
