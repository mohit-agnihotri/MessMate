import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getTabIcon(String slot) {
    switch (slot) {
      case 'morning':
        return '☀️';
      case 'noon':
        return '🌤️';
      case 'evening':
        return '🌅';
      case 'night':
        return '🌙';
      default:
        return '📅';
    }
  }

  String _getTabLabel(String slot) {
    if (slot == 'fullday') return 'Full Day';
    return slot[0].toUpperCase() + slot.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerDashboardProvider);
    final mess = state.mess;
    if (mess == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
      if (hour < 11 && allTabs.contains('morning'))
        initialIndex = allTabs.indexOf('morning');
      else if (hour < 15 && allTabs.contains('noon'))
        initialIndex = allTabs.indexOf('noon');
      else if (hour < 19 && allTabs.contains('evening'))
        initialIndex = allTabs.indexOf('evening');
      else if (allTabs.contains('night'))
        initialIndex = allTabs.indexOf('night');
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
          bottom: TabBar(
            labelColor: const Color(0xFF22C55E),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            indicatorColor: const Color(0xFF22C55E),
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: allTabs
                .map(
                  (slot) =>
                      Tab(text: '${_getTabIcon(slot)} ${_getTabLabel(slot)}'),
                )
                .toList(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                  ),
                  hintText: 'Search student name...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
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
                    .map((slot) => _AbsenteeList(slot: slot))
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

  const _AbsenteeList({required this.slot});

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

    if (slotRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'All present for ${slot == 'fullday' ? 'Today' : slot[0].toUpperCase() + slot.substring(1)}!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No cancellations recorded yet',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: slotRecords.length,
      itemBuilder: (context, index) {
        final record = slotRecords[index];
        final student = allStudents.firstWhere(
          (s) => s.studentId == record.studentId,
          orElse: () => StudentModel(
            studentId: record.studentId,
            messId: '',
            name: 'Unknown',
            phone: '',
            status: '',
            college: '',
            course: '',
            email: '',
            joinDate: DateTime.now(),
            roomNo: 'N/A',
          ),
        );

        return AbsenteeTile(
          name: student.name,
          roomNo: student.roomNo,
          cancelledAt: record.date,
        );
      },
    );
  }
}

// When data is available, show this tile:
class AbsenteeTile extends StatelessWidget {
  final String name;
  final String roomNo;
  final String? photoUrl;
  final DateTime cancelledAt;

  const AbsenteeTile({
    super.key,
    required this.name,
    required this.roomNo,
    this.photoUrl,
    required this.cancelledAt,
  });

  @override
  Widget build(BuildContext context) {
    final hour = cancelledAt.hour;
    final minute = cancelledAt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : hour;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFDCFCE7),
            child: Text(
              name[0],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Room: $roomNo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Cancelled at $h:$minute $ampm',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
