import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/student_inspired_theme.dart';

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

class StudentHistoryPage extends ConsumerStatefulWidget {
  const StudentHistoryPage({super.key});

  @override
  ConsumerState<StudentHistoryPage> createState() => _StudentHistoryPageState();
}

class _StudentHistoryPageState extends ConsumerState<StudentHistoryPage> {
  int _selectedTab = 0; // 0 = Attendance, 1 = Vacation

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentHistoryProvider);

    return Scaffold(
      backgroundColor: StudentColors.canvas,
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: StudentColors.amber),
              )
            : RefreshIndicator(
                color: StudentColors.amber,
                onRefresh: () => ref.read(studentHistoryProvider.notifier).load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // ── Header Title & Subtitle ──
                    Text(
                      'ATTENDANCE & LEAVES',
                      style: StudentTypography.overline(
                        fontSize: 11,
                        color: StudentColors.sageDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'My attendance',
                      style: StudentTypography.serifHeading(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your daily meal check-ins and leaves',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: StudentColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Segmented Pill Switch: [ Attendance ] | [ Vacation ] ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: StudentColors.surfaceLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: StudentColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? StudentColors.walnut
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    'Attendance',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : StudentColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? StudentColors.walnut
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    'Vacation',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : StudentColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Active Tab View ──
                    if (_selectedTab == 0)
                      _buildAttendanceSection(context, ref, state)
                    else
                      _buildVacationSection(context, ref, state),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Attendance Tab (3 Stat Cards + Modern Calendar + Vacation Hero Card)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAttendanceSection(
    BuildContext context,
    WidgetRef ref,
    StudentHistoryState outerState,
  ) {
    final records = outerState.records;
    final selfOff = records.where((r) => r.status == 'absent_self').length;
    final ownerOff = records.where((r) => r.status == 'absent_owner').length;
    final totalOff = selfOff + ownerOff;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 3 Stat Cards Row ──
        Row(
          children: [
            _buildStatCard(
              context,
              'Total meals off',
              '$totalOff',
              'Breakdown',
              StudentColors.brickRed,
              records
                  .where(
                    (r) =>
                        r.status == 'absent_self' || r.status == 'absent_owner',
                  )
                  .toList(),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Off by you',
              '$selfOff',
              'Skipped',
              StudentColors.amber,
              records.where((r) => r.status == 'absent_self').toList(),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              context,
              'Off by mess',
              '$ownerOff',
              'Mess closed',
              StudentColors.sageDark,
              records.where((r) => r.status == 'absent_owner').toList(),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Modern Attendance Calendar Card ──
        _buildCalendarCard(
          context,
          ref,
          records,
          outerState.selectedMonth,
          (newMonth) =>
              ref.read(studentHistoryProvider.notifier).changeMonth(newMonth),
        ),
        const SizedBox(height: 20),

        // ── "Going away?" Vacation Hero Card ──
        _buildGoingAwayCard(context, ref),
      ],
    );
  }

  // ── Stat Card with Left Accent Border ──────────────────────────────────────
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    Color accentColor,
    List<MealRecordModel> records,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showOffDetailsDialog(context, label, records),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StudentColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StudentColors.borderSubtle),
            boxShadow: StudentColors.softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: StudentColors.walnutMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: StudentTypography.serifNumeral(
                  fontSize: 26,
                  color: StudentColors.walnut,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: StudentColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: StudentColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Interactive Calendar Card ──────────────────────────────────────────────
  Widget _buildCalendarCard(
    BuildContext context,
    WidgetRef ref,
    List<MealRecordModel> records,
    DateTime selectedMonthDate,
    ValueChanged<DateTime> onMonthChanged,
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
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: StudentColors.textMuted,
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

      final selfOffRecords =
          dayRecords.where((r) => r.status == 'absent_self').toList();
      final ownerOffRecords =
          dayRecords.where((r) => r.status == 'absent_owner').toList();
      final guestRecords =
          dayRecords.where((r) => r.status == 'guest').toList();

      final isSelfOff = selfOffRecords.isNotEmpty;
      final isOwnerOff = ownerOffRecords.isNotEmpty;
      final isOff = isSelfOff || isOwnerOff;
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
                  decoration: BoxDecoration(
                    color: isOff
                        ? StudentColors.brickRedLight
                        : (hasGuest
                            ? StudentColors.amberLight
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isOff
                        ? Border.all(color: StudentColors.brickRedBorder)
                        : (hasGuest
                            ? Border.all(color: StudentColors.amberPill)
                            : null),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$i',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isOff || hasGuest
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isOff
                          ? StudentColors.brickRed
                          : (hasGuest
                              ? StudentColors.amberText
                              : StudentColors.textDark),
                    ),
                  ),
                ),
              ),
              if (hasGuest && !isOff)
                Positioned(
                  bottom: 2,
                  right: 8,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: StudentColors.amber,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(now.year, now.month - 1, 1),
                ),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: StudentColors.walnut,
                ),
              ),
              Text(
                '${_hMonthName(now.month)} ${now.year}',
                style: StudentTypography.serifHeading(fontSize: 18),
              ),
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(now.year, now.month + 1, 1),
                ),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: StudentColors.walnut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: days,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: StudentColors.borderSubtle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(StudentColors.brickRed, 'Meal Skipped / Off'),
              const SizedBox(width: 16),
              _buildLegend(StudentColors.amber, 'Guest Meal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: StudentColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── "Going away?" Vacation Hero Card ───────────────────────────────────────
  Widget _buildGoingAwayCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudentColors.walnut,
        borderRadius: BorderRadius.circular(22),
        boxShadow: StudentColors.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StudentColors.amber.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: StudentColors.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Going away for a few days?',
                      style: StudentTypography.serifHeading(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Apply for vacation to pause your meals and auto-save bill deductions',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: StudentColors.amber,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.event_note_rounded, size: 18),
              label: Text(
                'Apply for Vacation Leave',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _showApplyLeaveSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vacation Tab Content ───────────────────────────────────────────────────
  Widget _buildVacationSection(
    BuildContext context,
    WidgetRef ref,
    StudentHistoryState state,
  ) {
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoingAwayCard(context, ref),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'YOUR VACATION REQUESTS',
              style: StudentTypography.overline(fontSize: 11),
            ),
            if (state.leaves.isNotEmpty)
              Text(
                '${state.leaves.length} Total',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: StudentColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (state.leaves.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: StudentColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StudentColors.borderSubtle),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.beach_access_rounded,
                    size: 36,
                    color: StudentColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No vacation leaves recorded yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: StudentColors.walnut,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When you apply for a vacation leave, meals are paused and credits are applied to your bill.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: StudentColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.leaves.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final leave = state.leaves[i];
              final isCancelled = leave.status == 'cancelled';
              final startMonth = monthNames[leave.startDate.month];
              final endMonth = monthNames[leave.endDate.month];
              final dateRange = '${leave.startDate.day} $startMonth - ${leave.endDate.day} $endMonth ${leave.endDate.year}';
              final daysCount = leave.endDate.difference(leave.startDate).inDays + 1;

              final badgeColor = isCancelled ? StudentColors.brickRed : StudentColors.sageDark;
              final badgeBg = isCancelled ? StudentColors.brickRedLight : StudentColors.sageLight;
              final statusLabel = isCancelled ? 'Cancelled' : 'Active / Approved';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCancelled
                        ? StudentColors.borderSubtle
                        : StudentColors.sage.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? Colors.grey.shade100
                                : StudentColors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCancelled
                                ? Icons.event_busy_rounded
                                : Icons.flight_takeoff_rounded,
                            size: 20,
                            color: isCancelled
                                ? Colors.grey.shade600
                                : StudentColors.amberDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateRange,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: StudentColors.walnut,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$daysCount ${daysCount == 1 ? "day" : "days"} leave · ${leave.startSlot ?? "full"} to ${leave.endSlot ?? "full"}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: StudentColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isCancelled && leave.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: StudentColors.borderSubtle),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: StudentColors.brickRed,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 15),
                          label: Text(
                            'Cancel Leave',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Cancel Vacation Leave?'),
                                content: const Text(
                                  'Your meal check-ins will resume immediately and deductions will be adjusted.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: const Text('Keep Leave'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: StudentColors.brickRed,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dCtx);
                                      ref.read(studentHistoryProvider.notifier).cancelLeave(leave.leaveId);
                                    },
                                    child: const Text('Yes, Cancel'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ── Total Meals Off Details Dialog (Matching 22.48.50 (1).jpeg) ───────────
  void _showOffDetailsDialog(
    BuildContext context,
    String title,
    List<MealRecordModel> offRecords,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudentColors.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: StudentColors.brickRedLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: StudentColors.brickRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: StudentTypography.serifHeading(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: offRecords.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No skipped or off meal records found for this period.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: StudentColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: offRecords.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final r = offRecords[i];
                    String typeStr = 'Unknown';
                    Color badgeColor = StudentColors.textSecondary;
                    Color badgeBg = StudentColors.canvas;

                    if (r.status == 'absent_self') {
                      if (r.isSpecial) {
                        typeStr = '✨ Special Feast (2x)';
                        badgeColor = const Color(0xFFC26E00);
                        badgeBg = const Color(0xFFFFF3DC);
                      } else {
                        typeStr = 'You Cancelled';
                        badgeColor = StudentColors.amberDark;
                        badgeBg = StudentColors.amberLight;
                      }
                    } else if (r.status == 'absent_owner') {
                      typeStr = r.isSpecial ? '✨ Special Mess Closed' : 'Mess Closed';
                      badgeColor = StudentColors.brickRed;
                      badgeBg = StudentColors.brickRedLight;
                    } else if (r.status == 'guest') {
                      typeStr = 'Guest Meal';
                      badgeColor = StudentColors.sageDark;
                      badgeBg = StudentColors.sageLight;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: StudentColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.date.day} ${_hMonthName(r.date.month)} ${r.date.year}',
                                  style: StudentTypography.bold(fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${r.mealSlot[0].toUpperCase()}${r.mealSlot.substring(1)} Meal',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: StudentColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeStr,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.walnut,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Apply Vacation Leave Sheet (With Strict Date Bounds Security) ─────────
  void _showApplyLeaveSheet(BuildContext context, WidgetRef ref) {
    DateTime? start;
    DateTime? end;
    String? startSlot = 'morning';
    String? endSlot = 'night';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: StudentColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                      color: StudentColors.walnutMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Apply for Vacation Leave',
                  style: StudentTypography.serifHeading(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'Meals in this date range will be automatically cancelled before cutoff.',
                  style: GoogleFonts.inter(
                    color: StudentColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        context,
                        'Start Date',
                        start,
                        (d) => setModalState(() {
                          start = d;
                          if (end != null && end!.isBefore(start!)) {
                            end = start;
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        context,
                        'End Date',
                        end,
                        (d) => setModalState(() {
                          if (start != null && d.isBefore(start!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('End date cannot be before start date.'),
                                backgroundColor: StudentColors.brickRed,
                              ),
                            );
                            return;
                          }
                          end = d;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: startSlot,
                        decoration: InputDecoration(
                          labelText: 'From Slot',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: StudentColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: StudentColors.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: StudentColors.borderSubtle,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'noon', child: Text('Noon')),
                          DropdownMenuItem(value: 'evening', child: Text('Evening')),
                          DropdownMenuItem(value: 'night', child: Text('Night')),
                        ],
                        onChanged: (val) => setModalState(() => startSlot = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: endSlot,
                        decoration: InputDecoration(
                          labelText: 'To Slot',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: StudentColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: StudentColors.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: StudentColors.borderSubtle,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'noon', child: Text('Noon')),
                          DropdownMenuItem(value: 'evening', child: Text('Evening')),
                          DropdownMenuItem(value: 'night', child: Text('Night')),
                        ],
                        onChanged: (val) => setModalState(() => endSlot = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.walnut,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (start != null && end != null)
                        ? () async {
                            // Enforce date validation strictly
                            if (end!.isBefore(start!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End date cannot be before start date.',
                                  ),
                                  backgroundColor: StudentColors.brickRed,
                                ),
                              );
                              return;
                            }
                            await ref
                                .read(studentHistoryProvider.notifier)
                                .applyLeave(
                                  start!,
                                  end!,
                                  startSlot: startSlot,
                                  endSlot: endSlot,
                                );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vacation leave applied!'),
                                  backgroundColor: StudentColors.sage,
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      'Submit Vacation Request',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: StudentColors.walnut,
                onPrimary: Colors.white,
                onSurface: StudentColors.textDark,
              ),
            ),
            child: child!,
          ),
        );
        if (d != null) onSelect(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: StudentColors.borderSubtle),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: StudentColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selected != null
                  ? '${selected.day} ${_hMonthName(selected.month)} ${selected.year}'
                  : 'Select Date',
              style: StudentTypography.bold(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
