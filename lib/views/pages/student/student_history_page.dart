import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

String _hMonthName(int m) {
  const months = [
    '',
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
  return months[m];
}

class StudentHistoryPage extends ConsumerWidget {
  const StudentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'My Attendance',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 3 Stat Cards ────────────────────────────────────
                    _buildAttendanceSection(context, ref, state),

                    const SizedBox(height: 32),

                    // ── Apply for Leave Button ───────────────────────────
                    Text(
                      'Vacation Leave',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLeaveSection(context, ref),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Attendance Section  (mirrors owner's _buildAttendanceSummary exactly)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAttendanceSection(
    BuildContext context,
    WidgetRef ref,
    StudentHistoryState outerState,
  ) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        DateTime selectedMonth = outerState.selectedMonth;

        return FutureBuilder<List<MealRecordModel>>(
          future: ref
              .read(appServiceProvider)
              .getMealRecords(
                ref.read(studentHistoryProvider).records.isNotEmpty
                    ? ref.read(studentHistoryProvider).records.first.studentId
                    : '',
                selectedMonth.month,
                selectedMonth.year,
              ),
          builder: (context, snapshot) {
            final records = snapshot.data ?? outerState.records;

            final selfOff = records
                .where((r) => r.status == 'absent_self')
                .length;
            final ownerOff = records
                .where((r) => r.status == 'absent_owner')
                .length;
            final totalOff = selfOff + ownerOff;

            return Column(
              children: [
                // 3 stat cards
                Row(
                  children: [
                    _buildSummaryCard(
                      context,
                      'Total Meals Off',
                      '$totalOff',
                      const Color(0xFFEF4444),
                      records
                          .where(
                            (r) =>
                                r.status == 'absent_self' ||
                                r.status == 'absent_owner',
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      context,
                      'Off by Student',
                      '$selfOff',
                      const Color(0xFFF59E0B),
                      records.where((r) => r.status == 'absent_self').toList(),
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      context,
                      'Off by Mess',
                      '$ownerOff',
                      const Color(0xFF6B7280),
                      records.where((r) => r.status == 'absent_owner').toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Calendar
                _buildInteractiveCalendar(
                  context,
                  records,
                  selectedMonth,
                  () => setLocalState(() {
                    selectedMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month - 1,
                      1,
                    );
                  }),
                  () => setLocalState(() {
                    selectedMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                      1,
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Stat Card (same look as owner side) ─────────────────────────────────
  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    Color accentColor,
    List<MealRecordModel> records,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showOffDetailsDialog(context, label, records),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: accentColor, width: 4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Off-details dialog (same as owner side) ──────────────────────────────
  void _showOffDetailsDialog(
    BuildContext context,
    String title,
    List<MealRecordModel> offRecords,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: offRecords.isEmpty
              ? Text(
                  'No records found.',
                  style: GoogleFonts.inter(color: Colors.grey),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: offRecords.length,
                  itemBuilder: (ctx, i) {
                    final r = offRecords[i];
                    String typeStr = 'Unknown';
                    IconData icon = Icons.info;
                    Color iconColor = Colors.grey;

                    if (r.status == 'absent_self') {
                      typeStr = 'You Cancelled';
                      icon = Icons.event_busy;
                      iconColor = Colors.red;
                    } else if (r.status == 'absent_owner') {
                      typeStr = 'Mess Closed';
                      icon = Icons.event_busy;
                      iconColor = Colors.red;
                    } else if (r.status == 'guest') {
                      typeStr = 'Guest Meal';
                      icon = Icons.person_add;
                      iconColor = Colors.orange;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(icon, color: iconColor),
                      title: Text(
                        '${r.date.day} ${_hMonthName(r.date.month)} ${r.date.year}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${r.mealSlot[0].toUpperCase()}${r.mealSlot.substring(1)} ($typeStr)',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Interactive Calendar (same as owner side) ────────────────────────────
  Widget _buildInteractiveCalendar(
    BuildContext context,
    List<MealRecordModel> records,
    DateTime selectedMonthDate,
    VoidCallback onPrev,
    VoidCallback onNext,
  ) {
    final now = selectedMonthDate;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final days = <Widget>[];
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (var w in weekDays) {
      days.add(
        Center(
          child: Text(
            w,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}';
      final dayRecords = records
          .where(
            (r) =>
                '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}' ==
                dateStr,
          )
          .toList();
      final offRecords = dayRecords
          .where((r) => r.status == 'absent_self' || r.status == 'absent_owner')
          .toList();
      final guestRecords = dayRecords
          .where((r) => r.status == 'guest')
          .toList();

      final isOff = offRecords.isNotEmpty;
      final hasGuest = guestRecords.isNotEmpty;

      days.add(
        GestureDetector(
          onTap: () {
            if (isOff || hasGuest) {
              _showOffDetailsDialog(
                context,
                'Details on $i ${_hMonthName(now.month)}',
                dayRecords.where((r) => r.status != 'present').toList(),
              );
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: isOff
                      ? const BoxDecoration(
                          color: Color(0xFFFECDD3),
                          shape: BoxShape.circle,
                        )
                      : hasGuest
                      ? const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '$i',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isOff
                          ? const Color(0xFF9F1239)
                          : (hasGuest
                                ? const Color(0xFFD97706)
                                : const Color(0xFF111827)),
                    ),
                  ),
                ),
              ),
              if (hasGuest)
                Positioned(
                  bottom: -2,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_hMonthName(now.month)} ${now.year}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: days,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Vacation Leave Section  (replaces Billing Summary)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLeaveSection(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.beach_access_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Going away?',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Apply for vacation and auto-cancel meals',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.event_available_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                'Apply for Vacation Leave',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: () => _showApplyLeaveSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // ── Apply Leave Bottom Sheet ─────────────────────────────────────────────
  void _showApplyLeaveSheet(BuildContext context, WidgetRef ref) {
    DateTime? start;
    DateTime? end;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Apply for Vacation Leave',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Meals within this date range will be automatically cancelled before cutoff.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      context,
                      'Start Date',
                      start,
                      (d) => setModalState(() => start = d),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(
                      context,
                      'End Date',
                      end,
                      (d) => setModalState(() => end = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (start != null && end != null)
                      ? () async {
                          await ref
                              .read(studentHistoryProvider.notifier)
                              .applyLeave(start!, end!);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vacation leave applied!'),
                                backgroundColor: Color(0xFF22C55E),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    'Submit Request',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime? selected,
    ValueChanged<DateTime> onSelect,
  ) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF22C55E),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
        if (d != null) onSelect(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF9FAFB),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selected != null
                  ? '${selected.day} ${_hMonthName(selected.month)} ${selected.year}'
                  : 'Select Date',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
