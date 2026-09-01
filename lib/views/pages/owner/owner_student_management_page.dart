import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class OwnerStudentManagementPage extends ConsumerWidget {
  const OwnerStudentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerStudentsProvider);
    final allStudents = [...state.students, ...state.pending];
    final pendingStudents = state.pending;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref, state),
              TabBar(
                labelColor: const Color(0xFF16A34A),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF16A34A),
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  Tab(text: 'All Students (${allStudents.length})'),
                  Tab(text: 'Pending Requests (${pendingStudents.length})'),
                ],
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF22C55E),
                        ),
                      )
                    : TabBarView(
                        children: [
                          allStudents.isEmpty
                              ? _buildEmpty()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                  itemCount: allStudents.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, i) =>
                                      _buildStudentRow(context, ref, allStudents[i]),
                                ),
                          pendingStudents.isEmpty
                              ? Center(child: Text('No pending requests.', style: GoogleFonts.inter(color: const Color(0xFF6B7280))))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                  itemCount: pendingStudents.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, i) =>
                                      _buildStudentRow(context, ref, pendingStudents[i]),
                                ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    OwnerStudentsState state,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              Expanded(
                child: Text(
                  'All Students',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final messCode =
                      ref.read(ownerDashboardProvider).mess?.messCode ?? 'N/A';
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        'Invite Students',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Share this code with your students to let them join your mess:',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              messCode,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F46E5),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(
                  'Invite',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Search students...',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Mess Code: ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.messCode,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: state.messCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mess code copied!')),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    ref.read(ownerStudentsProvider.notifier).regenerateCode(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) {
    Color statusBg, statusColor;
    String statusText;
    switch (student.status) {
      case 'active':
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF16A34A);
        statusText = 'Active';
        break;
      case 'pending':
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFF92400E);
        statusText = 'Pending';
        break;
      default:
        statusBg = const Color(0xFFF3F4F6);
        statusColor = const Color(0xFF6B7280);
        statusText = 'Inactive';
    }

    const monthNames = [
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
    final joined =
        '${monthNames[student.joinDate.month]} ${student.joinDate.day}, ${student.joinDate.year}';

    return GestureDetector(
      onTap: () {
        if (student.status != 'pending') {
          _showStudentDetailsModal(context, ref, student, joined);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFDCFCE7),
              child: Text(
                student.name[0],
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  Text(
                    'Room ${student.roomNo} - $joined',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (student.status == 'pending') ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref
                            .read(ownerStudentsProvider.notifier)
                            .accept(student.studentId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => ref
                            .read(ownerStudentsProvider.notifier)
                            .reject(student.studentId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 60, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            'No students yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            'Share your mess code to onboard students',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailsModal(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
    String joined,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle for dragging
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFDCFCE7),
                            child: Text(
                              student.name[0],
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  'ID: ${student.studentId.substring(0, 8)} • Room ${student.roomNo}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  'Joined: $joined',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse('tel:${student.phone}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not launch phone dialer')),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone,
                                size: 20,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3 Summary Cards
                      _buildAttendanceSummary(context, ref, student),
                      const SizedBox(height: 24),

                      // Billing Summary
                      Text(
                        'Billing Summary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBillingSummary(context, ref, student),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
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
    return monthNames[month];
  }

  Widget _buildAttendanceSummary(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) {
    DateTime selectedMonthDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder<List<MealRecordModel>>(
          future: ref.read(appServiceProvider).getMealRecords(
                student.studentId,
                selectedMonthDate.month,
                selectedMonthDate.year,
              ),
          builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final records = snapshot.data!;
        final selfOff = records.where((r) => r.status == 'absent_self').length;
        final ownerOff = records
            .where((r) => r.status == 'absent_owner')
            .length;
        final totalOff = selfOff + ownerOff;
        return Column(
          children: [
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
            _buildInteractiveCalendar(
              context, 
              records,
              selectedMonthDate,
              () {
                setLocalState(() {
                  selectedMonthDate = DateTime(selectedMonthDate.year, selectedMonthDate.month - 1, 1);
                });
              },
              () {
                setLocalState(() {
                  selectedMonthDate = DateTime(selectedMonthDate.year, selectedMonthDate.month + 1, 1);
                });
              },
            ),
          ],
        );
      },
    );
      },
    );
  }

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
                    final date = r.date;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_busy, color: Colors.red),
                      title: Text(
                        '${date.day} ${_getMonthName(date.month)} ${date.year}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${r.mealSlot[0].toUpperCase()}${r.mealSlot.substring(1)} (${r.status == 'absent_self' ? 'Student Cancelled' : 'Mess Closed'})',
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

  Widget _buildInteractiveCalendar(
    BuildContext context,
    List<MealRecordModel> records,
    DateTime selectedMonthDate,
    VoidCallback onPreviousMonth,
    VoidCallback onNextMonth,
  ) {
    final now = selectedMonthDate;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

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

      final isOff = offRecords.isNotEmpty;

      days.add(
        GestureDetector(
          onTap: isOff
              ? () => _showOffDetailsDialog(
                  context,
                  'Absents on $i ${_getMonthName(now.month)}',
                  offRecords,
                )
              : null,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: isOff
                  ? const BoxDecoration(
                      color: Color(0xFFFECDD3),
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
                      : const Color(0xFF111827),
                ),
              ),
            ),
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
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
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

  Future<BillModel> _calculateBillPreview(
    WidgetRef ref,
    StudentModel student,
  ) async {
    final service = ref.read(appServiceProvider);
    final now = DateTime.now();
    final bill = await service.getBill(student.studentId, now.month, now.year);
    if (bill != null) return bill;

    final mess = await service.getMessById(student.messId);
    if (mess == null) throw Exception("Mess not found");
    
    final records = await service.getMealRecords(
      student.studentId,
      now.month,
      now.year,
    );
    
    final previousDues = await service.getPreviousUnpaidDues(student.studentId, now.month, now.year);
    
    return generateAdvancedBill(
      student: student,
      mess: mess,
      month: now.month,
      year: now.year,
      records: records,
      previousDues: previousDues,
    );
  }

  Widget _buildBillingSummary(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) {
    return FutureBuilder<BillModel>(
      future: _calculateBillPreview(ref, student),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Billing Summary Error: ${snapshot.error}\n${snapshot.stackTrace}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var bill = snapshot.data!;
        bool localIsPaid = bill.isPaid;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic Fee',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bill.baseFee.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deductions',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${bill.totalDeductions.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Final Payable',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bill.finalPayable.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatefulBuilder(
                    builder: (context, setLocalState) {
                      return Row(
                        children: [
                          Text(
                            localIsPaid ? 'Paid' : 'Mark as Paid',
                            style: GoogleFonts.inter(
                              color: localIsPaid ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: localIsPaid,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (value) async {
                              setLocalState(() => localIsPaid = value);
                              // We use copyWith behavior manually for toggle
                              final updatedBill = BillModel(
                                billId: bill.billId,
                                studentId: bill.studentId,
                                messId: bill.messId,
                                month: bill.month,
                                year: bill.year,
                                baseFee: bill.baseFee,
                                proratedDiscount: bill.proratedDiscount,
                                totalDeductions: bill.totalDeductions,
                                extraMealsAddon: bill.extraMealsAddon,
                                guestAddons: bill.guestAddons,
                                finalPayable: bill.finalPayable,
                                isPaid: value,
                                deductions: bill.deductions,
                              );
                              await ref
                                  .read(ownerStudentsProvider.notifier)
                                  .toggleBillPaymentStatus(student, updatedBill, value);
                              
                              // We also update the initial bill variable so it stays consistent 
                              // across StatefulBuilder rebuilds if anything else triggers it
                              bill = updatedBill;

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value ? 'Bill marked as paid!' : 'Bill marked as unpaid!'),
                                    backgroundColor: value ? Colors.green : Colors.orange,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showDetailedBreakdown(context, bill),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final message =
                        "Hi ${student.name}, your Mess bill of ₹${bill.finalPayable.toStringAsFixed(0)} is pending. Please pay at your earliest convenience.";
                    final url = Uri.parse(
                      "https://wa.me/91${student.phone}?text=${Uri.encodeComponent(message)}",
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch WhatsApp'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF25D366),
                  ),
                  label: Text(
                    'Send WhatsApp Reminder',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    Color borderColor,
    List<MealRecordModel> offRecords,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showOffDetailsDialog(context, title, offRecords),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: borderColor, width: 4)),
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
                title,
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
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color bgColor, Color textColor, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
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
}
