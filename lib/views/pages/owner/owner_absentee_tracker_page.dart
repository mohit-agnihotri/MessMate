import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class OwnerAbsenteeTrackerPage extends ConsumerStatefulWidget {
  final String? initialSlot;
  const OwnerAbsenteeTrackerPage({super.key, this.initialSlot});

  @override
  ConsumerState<OwnerAbsenteeTrackerPage> createState() =>
      _OwnerAbsenteeTrackerPageState();
}

class _OwnerAbsenteeTrackerPageState
    extends ConsumerState<OwnerAbsenteeTrackerPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getTabIconData(String slot) {
    switch (slot) {
      case 'morning':
        return Icons.wb_twilight;
      case 'noon':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nights_stay_outlined;
      case 'night':
        return Icons.bedtime;
      default:
        return Icons.calendar_today;
    }
  }

  String _getTabLabel(String slot) {
    if (slot == 'fullday') return 'Full Day Off';
    return slot[0].toUpperCase() + slot.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerDashboardProvider);
    final mess = state.mess;
    if (mess == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );
    }

    final slotsOrder = ['morning', 'noon', 'evening', 'night'];
    final dynamicSlots = slotsOrder
        .where((s) => mess.mealTimings[s]?['enabled'] == 'true')
        .toList();
    final allTabs = [...dynamicSlots, 'fullday'];

    int initialIndex = 0;
    if (widget.initialSlot != null && allTabs.contains(widget.initialSlot)) {
      initialIndex = allTabs.indexOf(widget.initialSlot!);
    } else {
      final hour = DateTime.now().hour;
      if (hour < 11 && allTabs.contains('morning')) {
        initialIndex = allTabs.indexOf('morning');
      } else if (hour < 15 && allTabs.contains('noon')) {
        initialIndex = allTabs.indexOf('noon');
      } else if (hour < 19 && allTabs.contains('evening')) {
        initialIndex = allTabs.indexOf('evening');
      } else if (allTabs.contains('night')) {
        initialIndex = allTabs.indexOf('night');
      }
    }

    return DefaultTabController(
      length: allTabs.length,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(
            'Absentee Tracker',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF22C55E),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF22C55E),
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: allTabs
                .map(
                  (slot) => Tab(
                    icon: Icon(_getTabIconData(slot), size: 18),
                    text: _getTabLabel(slot),
                  ),
                )
                .toList(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF9CA3AF)),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  hintText: 'Search student name...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF22C55E)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: allTabs
                    .map(
                      (slot) => _AbsenteeList(
                        slot: slot,
                        searchQuery: _searchCtrl.text.trim().toLowerCase(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbsenteeList extends ConsumerWidget {
  final String slot;
  final String searchQuery;

  const _AbsenteeList({required this.slot, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerDashboardProvider);
    final allStudents = state.activeStudentsList;

    // Filter records for this slot
    final slotRecords = state.todayRecords
        .where(
          (r) =>
              (slot == 'fullday' || r.mealSlot == slot) &&
              (r.status == 'absent_self' || r.status == 'absent_owner'),
        )
        .toList();

    // Map each record to student and apply search query
    final absentees = <_AbsenteeItem>[];
    for (final r in slotRecords) {
      final student = allStudents.firstWhere(
        (s) => s.studentId == r.studentId,
        orElse: () => StudentModel(
          studentId: r.studentId,
          messId: '',
          name: 'Diner ${r.studentId.substring(0, r.studentId.length.clamp(0, 5))}',
          phone: '',
          status: 'active',
          college: '',
          course: '',
          email: '',
          joinDate: DateTime.now(),
          roomNo: 'N/A',
        ),
      );

      if (searchQuery.isNotEmpty &&
          !student.name.toLowerCase().contains(searchQuery)) {
        continue;
      }

      absentees.add(_AbsenteeItem(record: r, student: student));
    }

    if (absentees.isEmpty) {
      final slotTitle = slot == 'fullday'
          ? 'Today'
          : '${slot[0].toUpperCase()}${slot.substring(1)}';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All present for $slotTitle! 🎉',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'No absentees match "$searchQuery"'
                    : 'Zero cancellations recorded for this slot',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: absentees.length,
      itemBuilder: (context, index) {
        final item = absentees[index];
        return AbsenteeTile(
          name: item.student.name,
          roomNo: item.student.roomNo,
          photoUrl: item.student.photoUrl,
          phone: item.student.phone,
          status: item.record.status,
          cancelledAt: item.record.cancelledAt ?? item.record.date,
        );
      },
    );
  }
}

class _AbsenteeItem {
  final MealRecordModel record;
  final StudentModel student;

  _AbsenteeItem({required this.record, required this.student});
}

class AbsenteeTile extends StatelessWidget {
  final String name;
  final String roomNo;
  final String? photoUrl;
  final String phone;
  final String status; // 'absent_self' or 'absent_owner'
  final DateTime cancelledAt;

  const AbsenteeTile({
    super.key,
    required this.name,
    required this.roomNo,
    this.photoUrl,
    required this.phone,
    required this.status,
    required this.cancelledAt,
  });

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = cancelledAt.hour;
    final minute = cancelledAt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    final isOwnerClosed = status == 'absent_owner';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isOwnerClosed
                ? const Color(0xFFDBEAFE)
                : const Color(0xFFFEF3C7),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: isOwnerClosed
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD97706),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Room: $roomNo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                // Separate visual badges: Student Cancelled vs Mess Closed
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOwnerClosed
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOwnerClosed
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOwnerClosed
                            ? Icons.storefront_outlined
                            : Icons.person_off_outlined,
                        size: 12,
                        color: isOwnerClosed
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOwnerClosed
                            ? 'Mess Closed'
                            : 'Student Cancelled ($h:$minute $ampm)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOwnerClosed
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone_outlined),
              color: const Color(0xFF22C55E),
              tooltip: 'Call $name',
              onPressed: () => _makeCall(phone),
            ),
        ],
      ),
    );
  }
}
