import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/owner_inspired_theme.dart';
import 'widgets/owner_drawer.dart';

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
  int _selectedTabIndex = 0;

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
        return Icons.wb_twilight_rounded;
      case 'noon':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_outlined;
      case 'night':
        return Icons.bedtime_rounded;
      default:
        return Icons.calendar_today_rounded;
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
    final messName = mess?.name ?? 'Mahakal';

    if (mess == null) {
      return const Scaffold(
        backgroundColor: OwnerColors.canvasWarm,
        body: Center(
          child: CircularProgressIndicator(color: OwnerColors.sageGreen),
        ),
      );
    }

    final slotsOrder = ['morning', 'noon', 'evening', 'night'];
    final dynamicSlots = slotsOrder
        .where((s) => mess.mealTimings[s]?['enabled'] == 'true')
        .toList();
    final allTabs = [...dynamicSlots, 'fullday'];

    // Ensure selected tab is in range
    if (_selectedTabIndex >= allTabs.length) {
      _selectedTabIndex = 0;
    }

    // Initialize slot if passed
    if (widget.initialSlot != null && allTabs.contains(widget.initialSlot)) {
      final idx = allTabs.indexOf(widget.initialSlot!);
      if (idx != _selectedTabIndex && _searchCtrl.text.isEmpty) {
        // Only override on fresh view
      }
    }

    final currentSlot = allTabs[_selectedTabIndex];

    return Scaffold(
      backgroundColor: OwnerColors.canvasWarm,
      endDrawer: const OwnerDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, messName),
            Expanded(
              child: RefreshIndicator(
                color: OwnerColors.sageGreen,
                backgroundColor: OwnerColors.surfaceLight,
                onRefresh: () async {
                  ref.invalidate(ownerDashboardProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: [
                    // Segmented Filter Pills (Screenshot 9)
                    _buildSlotPills(allTabs, state),
                    const SizedBox(height: 14),

                    // Search Input (Screenshot 9)
                    _buildSearchBar(),
                    const SizedBox(height: 18),

                    // List or Empty State for current slot
                    _buildSlotAbsentees(
                      slot: currentSlot,
                      state: state,
                      searchQuery: _searchCtrl.text.trim().toLowerCase(),
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

  // ─── Header (Screenshot 9) ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String messName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: const BoxDecoration(
        color: OwnerColors.canvasWarm,
        border: Border(
          bottom: BorderSide(color: OwnerColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "TODAY'S TURNOUT",
                style: OwnerTypography.overline(color: OwnerColors.walnutMuted),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OwnerColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OwnerColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$messName · Settings',
                        style: OwnerTypography.regular(
                          size: 12,
                          color: OwnerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: OwnerColors.walnutMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: OwnerColors.walnutDark,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Absentees',
                style: OwnerTypography.editorialSerif(
                  size: 28,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Slot Pills Row (Screenshot 9) ─────────────────────────────────────────
  Widget _buildSlotPills(List<String> allTabs, OwnerDashboardState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(allTabs.length, (index) {
          final slot = allTabs[index];
          final isSelected = _selectedTabIndex == index;

          // Count absentees for this slot
          final count = state.todayRecords
              .where((r) =>
                  (slot == 'fullday' || r.mealSlot == slot) &&
                  (r.status == 'absent_self' || r.status == 'absent_owner'))
              .length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? OwnerColors.walnutDark
                      : OwnerColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? OwnerColors.walnutDark
                        : OwnerColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTabIconData(slot),
                      size: 14,
                      color: isSelected
                          ? OwnerColors.amberGlow
                          : OwnerColors.walnutMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_getTabLabel(slot)} ($count)',
                      style: OwnerTypography.bold(
                        size: 12,
                        color: isSelected
                            ? OwnerColors.textLight
                            : OwnerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Search Bar (Screenshot 9) ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: OwnerColors.walnutMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: OwnerTypography.regular(
                size: 13,
                color: OwnerColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search student name or room...',
                hintStyle: OwnerTypography.regular(
                  size: 13,
                  color: OwnerColors.walnutMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () => _searchCtrl.clear(),
              child: const Icon(
                Icons.cancel,
                size: 16,
                color: OwnerColors.walnutMuted,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Slot Absentees List & Empty State (Screenshot 9) ──────────────────────
  Widget _buildSlotAbsentees({
    required String slot,
    required OwnerDashboardState state,
    required String searchQuery,
  }) {
    final allStudents = state.activeStudentsList;

    final slotRecords = state.todayRecords
        .where(
          (r) =>
              (slot == 'fullday' || r.mealSlot == slot) &&
              (r.status == 'absent_self' || r.status == 'absent_owner'),
        )
        .toList();

    final absentees = <_AbsenteeItem>[];
    for (final r in slotRecords) {
      final student = allStudents.firstWhere(
        (s) => s.studentId == r.studentId,
        orElse: () => StudentModel(
          studentId: r.studentId,
          messId: '',
          name:
              'Diner ${r.studentId.substring(0, r.studentId.length.clamp(0, 5))}',
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
          !student.name.toLowerCase().contains(searchQuery) &&
          !student.roomNo.toLowerCase().contains(searchQuery)) {
        continue;
      }

      absentees.add(_AbsenteeItem(record: r, student: student));
    }

    if (absentees.isEmpty) {
      final slotTitle = slot == 'fullday'
          ? 'Today'
          : '${slot[0].toUpperCase()}${slot.substring(1)}';

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Sage Green badge with checkmark (Screenshot 9)
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: OwnerColors.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 38,
                color: OwnerColors.sageDark,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Everyone's here for $slotTitle! 🎉",
              textAlign: TextAlign.center,
              style: OwnerTypography.editorialSerif(
                size: 20,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searchQuery.isNotEmpty
                  ? 'No absentees match "$searchQuery"'
                  : 'Zero cancellations recorded for this meal slot.',
              textAlign: TextAlign.center,
              style: OwnerTypography.regular(
                size: 13,
                color: OwnerColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: absentees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = absentees[index];
        return _AbsenteeTile(
          name: item.student.name,
          roomNo: item.student.roomNo,
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

class _AbsenteeTile extends StatelessWidget {
  final String name;
  final String roomNo;
  final String phone;
  final String status;
  final DateTime cancelledAt;

  const _AbsenteeTile({
    required this.name,
    required this.roomNo,
    required this.phone,
    required this.status,
    required this.cancelledAt,
  });

  Future<void> _makeCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isOwnerClosed
                ? OwnerColors.surfaceWarm
                : OwnerColors.amberGlow.withValues(alpha: 0.18),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: OwnerTypography.editorialSerif(
                size: 16,
                weight: FontWeight.w700,
                color: isOwnerClosed
                    ? OwnerColors.walnutDark
                    : OwnerColors.amberDark,
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
                  style: OwnerTypography.bold(
                    size: 14,
                    color: OwnerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Room: $roomNo',
                  style: OwnerTypography.regular(
                    size: 12,
                    color: OwnerColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOwnerClosed
                        ? OwnerColors.surfaceWarm
                        : OwnerColors.amberLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOwnerClosed
                          ? OwnerColors.borderSubtle
                          : OwnerColors.amberGlow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOwnerClosed
                            ? Icons.storefront_outlined
                            : Icons.person_off_outlined,
                        size: 11,
                        color: isOwnerClosed
                            ? OwnerColors.walnutMuted
                            : OwnerColors.amberDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOwnerClosed
                            ? 'Mess Closed'
                            : 'Student Cancelled ($h:$minute $ampm)',
                        style: OwnerTypography.bold(
                          size: 10,
                          color: isOwnerClosed
                              ? OwnerColors.walnutDark
                              : OwnerColors.amberDark,
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
              color: OwnerColors.sageGreen,
              tooltip: 'Call $name',
              onPressed: () => _makeCall(phone),
            ),
        ],
      ),
    );
  }
}
