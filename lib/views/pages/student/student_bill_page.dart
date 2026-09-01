import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';
import '../../../services/pdf_service.dart';

class StudentBillPage extends ConsumerWidget {
  const StudentBillPage({super.key});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentBillProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(ref, state)),
                  if (state.bill != null) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(child: _buildMainBillCard(state.bill!, state)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(child: _buildPaymentDetails(state.bill!)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 80),
                      sliver: SliverToBoxAdapter(child: _buildDownloadButton(state.bill!)),
                    ),
                  ] else
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No bill generated for this month.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, StudentBillState state) {
    final vm = ref.read(studentBillProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing & Payment',
            style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => vm.changeMonth(DateTime(state.selectedMonth.year, state.selectedMonth.month - 1)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 20),
                ),
              ),
              Text(
                '${_months[state.selectedMonth.month - 1]} ${state.selectedMonth.year}',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
              ),
              GestureDetector(
                onTap: () => vm.changeMonth(DateTime(state.selectedMonth.year, state.selectedMonth.month + 1)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: Color(0xFF374151), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainBillCard(BillModel bill, StudentBillState state) {
    final cancelledCount = bill.deductions.where((d) => d.type == 'self_cancelled' || d.type == 'owner_off').length;
    final guestCount = bill.deductions.where((d) => d.type == 'guest').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          // Top Section (Total)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  '${_months[state.selectedMonth.month - 1]} ${state.selectedMonth.year} Bill',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${bill.finalPayable.toInt()}',
                  style: GoogleFonts.inter(
                      fontSize: 48, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: bill.isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bill.isPaid ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: bill.isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bill.isPaid ? 'Paid Successfully' : 'Payment Pending',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: bill.isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Issued on: ${DateTime.now().day} ${_months[DateTime.now().month - 1]}, ${DateTime.now().year}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),

          // Dashed Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = constraints.constrainWidth();
                const dashWidth = 8.0;
                const dashHeight = 1.0;
                final dashCount = (boxWidth / (2 * dashWidth)).floor();
                return Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dashCount, (_) {
                    return const SizedBox(
                      width: dashWidth,
                      height: dashHeight,
                      child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE5E7EB))),
                    );
                  }),
                );
              },
            ),
          ),

          // Bottom Section (Breakdown)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildCleanRow('Basic Monthly Fee', 'Base active cycle', '₹${bill.baseFee.toInt()}'),
                if (bill.proratedDiscount > 0) ...[
                  const SizedBox(height: 16),
                  _buildCleanRow('Mid-Month Join Discount', 'Pro-rated deduction', '-₹${bill.proratedDiscount.toInt()}', isDeduction: true),
                ],
                if (bill.totalDeductions > 0) ...[
                  const SizedBox(height: 16),
                  _buildCleanRow('Meals Cancelled', 'Valid skip refunds', '-₹${bill.totalDeductions.toInt()}', isDeduction: true),
                ],
                if (bill.extraMealsAddon > 0) ...[
                  const SizedBox(height: 16),
                  _buildCleanRow('Extra Meals', 'Consumed beyond plan', '₹${bill.extraMealsAddon.toInt()}'),
                ],
                if (bill.guestAddons > 0) ...[
                  const SizedBox(height: 16),
                  _buildCleanRow('Guest Meals', 'Meals for guests', '₹${bill.guestAddons.toInt()}'),
                ],
                if (bill.previousDues > 0) ...[
                  const SizedBox(height: 16),
                  _buildCleanRow('Previous Unpaid Dues', 'Arrears from past months', '₹${bill.previousDues.toInt()}'),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFE5E7EB), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                    Text('₹${bill.finalPayable.toInt()}',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (btnContext) => TextButton.icon(
                      onPressed: () => _showDetailedBreakdown(btnContext, bill),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: Text('View Detailed Breakdown', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanRow(String title, String subtitle, String amount, {bool isDeduction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
          ],
        ),
        Text(amount,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDeduction ? const Color(0xFF16A34A) : const Color(0xFF111827))),
      ],
    );
  }

  Widget _buildPaymentDetails(BillModel bill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildDetailRow('Status', bill.isPaid ? 'PAID' : 'PENDING', 
                valueColor: bill.isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
              const SizedBox(height: 12),
              _buildDetailRow('Date', bill.isPaid ? '${DateTime.now().day} ${_months[DateTime.now().month-1]} ${DateTime.now().year}' : 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Method', bill.isPaid ? 'Paid to Owner directly' : 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Bill ID', bill.billId.length > 8 ? bill.billId.substring(0, 8).toUpperCase() : bill.billId.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF111827))),
      ],
    );
  }

  Widget _buildDownloadButton(BillModel bill) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () async {
          await PdfService.generateAndDownloadBill(bill);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Download PDF Invoice',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            Text('₹${bill.finalPayable.toInt()}',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showDetailedBreakdown(BuildContext context, BillModel bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill Breakdown',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildBillRow('Basic Fee', '₹${bill.baseFee.toStringAsFixed(0)}'),
              if (bill.proratedDiscount > 0)
                _buildBillRow('Mid-Month Joining Discount', '-₹${bill.proratedDiscount.toStringAsFixed(0)}', color: Colors.green),
              if (bill.totalDeductions > 0)
                _buildBillRow('Valid Skipped Meals Refunds', '-₹${bill.totalDeductions.toStringAsFixed(0)}', color: Colors.green),
              if (bill.extraMealsAddon > 0)
                _buildBillRow('Extra Meals Consumed', '+₹${bill.extraMealsAddon.toStringAsFixed(0)}', color: Colors.red),
              if (bill.guestAddons > 0)
                _buildBillRow('Guest Meals', '+₹${bill.guestAddons.toStringAsFixed(0)}', color: Colors.red),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              _buildBillRow('Final Payable', '₹${bill.finalPayable.toStringAsFixed(0)}', isBold: true, size: 18),
              
              const SizedBox(height: 24),
              Text(
                'Itemized Details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: bill.deductions.isEmpty
                    ? Center(child: Text("No itemized details this month.", style: GoogleFonts.inter(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: bill.deductions.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final item = bill.deductions[index];
                          final isDeduction = item.amount < 0;
                          final typeStr = item.type.replaceAll('_', ' ').toUpperCase();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.date.day}/${item.date.month} - ${item.mealSlot}',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      typeStr,
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isDeduction ? '' : '+'}₹${item.amount.abs().toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDeduction ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillRow(
    String label,
    String amount, {
    bool isBold = false,
    Color color = const Color(0xFF111827),
    double size = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
