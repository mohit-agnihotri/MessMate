import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';

class StudentHistoryPage extends ConsumerWidget {
  const StudentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentHistoryProvider);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(ref, state, months)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(child: _buildStatsRow(state)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverToBoxAdapter(child: _buildCalendar(state)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  sliver: SliverToBoxAdapter(child: _buildLegend()),
                ),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'student_leave_fab',
        onPressed: () => _showApplyLeaveBottomSheet(context, ref),
        backgroundColor: const Color(0xFF22C55E),
        icon: const Icon(Icons.event_busy_rounded, color: Colors.white),
        label: Text('Apply Leave', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showApplyLeaveBottomSheet(BuildContext context, WidgetRef ref) {
    DateTime? start;
    DateTime? end;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Apply for Leave', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('Select the date range you will be away. Auto-cancellation will apply to meals in this period if before cutoff.', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _buildDateSelector(context, 'Start Date', start, (d) => setModalState(() => start = d))),
                const SizedBox(width: 16),
                Expanded(child: _buildDateSelector(context, 'End Date', end, (d) => setModalState(() => end = d))),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: (start != null && end != null) ? () {
                    ref.read(studentHistoryProvider.notifier).applyLeave(start!, end!);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave applied successfully!'), backgroundColor: Color(0xFF22C55E)));
                  } : null,
                  child: Text('Submit Leave Request', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          );
        }
      )
    );
  }

  Widget _buildDateSelector(BuildContext context, String label, DateTime? selected, ValueChanged<DateTime> onSelect) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: selected ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (d != null) onSelect(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(10), color: const Color(0xFFF9FAFB)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(selected != null ? '${selected.day}/${selected.month}/${selected.year}' : 'Select', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ]),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, StudentHistoryState state, List<String> months) {
    final vm = ref.read(studentHistoryProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My History',
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 16),
        Row(children: [
          GestureDetector(
            onTap: () => vm.changeMonth(
              DateTime(state.selectedMonth.year, state.selectedMonth.month - 1)),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)],
              ),
              child: const Icon(Icons.chevron_left, color: Color(0xFF374151)),
            ),
          ),
          Expanded(child: Text(
            '${months[state.selectedMonth.month - 1]} ${state.selectedMonth.year}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
          )),
          GestureDetector(
            onTap: () => vm.changeMonth(
              DateTime(state.selectedMonth.year, state.selectedMonth.month + 1)),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)],
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFF374151)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildStatsRow(StudentHistoryState state) {
    final totalOff = state.selfAbsent + state.ownerOff;
    return Row(children: [
      _buildStatCard('$totalOff', 'Total Off', const Color(0xFFEF4444)),
      const SizedBox(width: 10),
      _buildStatCard('${state.selfAbsent}', 'Off by Me', const Color(0xFFF59E0B)),
      const SizedBox(width: 10),
      _buildStatCard('${state.ownerOff}', 'Off by Mess', const Color(0xFF9CA3AF)),
    ]);
  }

  Widget _buildStatCard(String value, String label, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: accentColor, width: 3)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text('View Details', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildCalendar(StudentHistoryState state) {
    final year = state.selectedMonth.year;
    final month = state.selectedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final selfAbsentDays = state.records.where((r) => r.status == 'absent_self').map((r) => r.date.day).toSet();
    final ownerOffDays = state.records.where((r) => r.status == 'absent_owner').map((r) => r.date.day).toSet();
    final startWeekday = firstDay.weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: ['M','T','W','T','F','S','S'].map((d) => Expanded(
          child: Center(child: Text(d, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF6B7280)))),
        )).toList()),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 1.1, crossAxisSpacing: 4, mainAxisSpacing: 4,
          ),
          itemCount: (startWeekday - 1) + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday - 1) return const SizedBox();
            final day = i - (startWeekday - 1) + 1;
            Color? bgColor;
            Color textColor = const Color(0xFF374151);
            if (selfAbsentDays.contains(day)) {
              bgColor = const Color(0xFFEF4444);
              textColor = Colors.white;
            } else if (ownerOffDays.contains(day)) {
              bgColor = const Color(0xFFFBBF24);
              textColor = Colors.white;
            }
            String tooltipText = 'Present / Normal';
            if (selfAbsentDays.contains(day)) tooltipText = 'You were absent';
            else if (ownerOffDays.contains(day)) tooltipText = 'Mess was closed';
            
            return Tooltip(
              message: tooltipText,
              preferBelow: false,
              textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(8)),
              child: Container(
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Center(child: Text('$day',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textColor))),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildLegendItem(const Color(0xFFEF4444), 'You were\nabsent'),
        _buildLegendItem(const Color(0xFFFBBF24), 'Mess was\nclosed'),
        _buildLegendItem(const Color(0xFFE5E7EB), 'Present /\nNormal'),
      ]),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
    ]);
  }
}
