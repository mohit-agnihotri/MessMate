import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'owner_student_management_page.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../services/localization_service.dart';
import 'owner_absentee_tracker_page.dart';

class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerDashboardProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : RefreshIndicator(
              color: const Color(0xFF22C55E),
              onRefresh: () => ref.read(ownerDashboardProvider.notifier).reload(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context, ref, state, greeting)),
                  SliverToBoxAdapter(child: _buildAnnouncementBanner(context, ref, state)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildStatsGrid(context, state)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildAbsentSummaryCard(context, state)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildCurrentMealCard(state)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    sliver: SliverToBoxAdapter(child: _buildUpcomingLeaves()),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, OwnerDashboardState state, String greeting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            Text(state.mess?.name ?? 'Welcome back.'.tr(context, ref),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
          ])),
          Consumer(builder: (context, ref, _) {
            final pendingCount = ref.watch(ownerStudentsProvider).pending.length;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF374151)),
                  onPressed: () => _showPendingRequests(context, ref),
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          GestureDetector(
            onTap: () => _showEmergencyCloseDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(children: [
                const Icon(Icons.dangerous_rounded, color: Color(0xFFEF4444), size: 14),
                const SizedBox(width: 4),
                Text('Close', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // Global Search Bar
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
            hintText: 'Search student or dish...',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22C55E))),
          ),
        ),
      ]),
    );
  }

  Widget _buildAnnouncementBanner(BuildContext context, WidgetRef ref, OwnerDashboardState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GestureDetector(
        onTap: () => _showAnnouncementDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.campaign_rounded, color: Color(0xFF92400E), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              state.announcement ?? 'Tap to send announcement to all students',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF92400E)),
            )),
            const Icon(Icons.chevron_right, color: Color(0xFF92400E), size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, OwnerDashboardState state) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
        _StatCard(
          icon: Icons.school_rounded,
          iconBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF16A34A),
          label: 'Total Students', value: '${state.activeStudents}',
          badgeText: '', badgeBg: Colors.transparent, badgeColor: Colors.transparent,
          subtitle: 'Active students', subtitleColor: const Color(0xFF6B7280),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerStudentManagementPage()));
          },
        ),
        _StatCard(
          icon: Icons.dining_rounded,
          iconBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF16A34A),
          label: 'Expected Headcount', value: '${state.expectedHeadcount}',
          badgeText: 'Live', badgeBg: const Color(0xFFDCFCE7), badgeColor: const Color(0xFF16A34A),
          subtitle: 'Expected diners', subtitleColor: const Color(0xFF16A34A),
          isHighlighted: true,
        ),
        _StatCard(
          icon: Icons.notifications_off_rounded,
          iconBg: const Color(0xFFFEE2E2), iconColor: const Color(0xFFEF4444),
          label: 'Skipping Current Meal', value: '${state.skippingCurrentMeal}',
          badgeText: '', badgeBg: Colors.transparent, badgeColor: Colors.transparent,
          subtitle: 'Total skipping', subtitleColor: const Color(0xFFEF4444),
          progressColor: const Color(0xFFEF4444), progressValue: (state.mess?.capacity ?? 1) > 0 ? state.skippingCurrentMeal / (state.mess?.capacity ?? 1) : 0,
        ),
        _StatCard(
          icon: Icons.people_outline_rounded,
          iconBg: const Color(0xFFEDE9FE), iconColor: const Color(0xFF7C3AED),
          label: 'Capacity', value: '${state.mess?.capacity ?? 0}',
          badgeText: '', badgeBg: Colors.transparent, badgeColor: Colors.transparent,
          subtitle: '${state.mess != null && state.mess!.capacity > 0 ? ((state.activeStudents / state.mess!.capacity) * 100).toStringAsFixed(0) : 0}% filled', subtitleColor: const Color(0xFF6B7280),
          progressColor: const Color(0xFF7C3AED), progressValue: (state.mess?.capacity ?? 1) > 0 ? state.activeStudents / (state.mess?.capacity ?? 1) : 0,
        ),
      ],
    ),
    ]);
  }

  Widget _buildAbsentSummaryCard(BuildContext context, OwnerDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Text('Today\'s Absent Summary', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF111827))),
        ]),
        const SizedBox(height: 16),
        Row(
          children: [
            if (state.mess?.mealTimings['morning']?['enabled'] == 'true')
              _buildAbsentPill('Morning', '${state.morningAbsents}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'morning')))),
            if (state.mess?.mealTimings['noon']?['enabled'] == 'true') ...[
              if (state.mess?.mealTimings['morning']?['enabled'] == 'true') const SizedBox(width: 8),
              _buildAbsentPill('Noon', '${state.noonAbsents}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'noon')))),
            ],
            if (state.mess?.mealTimings['evening']?['enabled'] == 'true') ...[
              if (state.mess?.mealTimings['morning']?['enabled'] == 'true' || state.mess?.mealTimings['noon']?['enabled'] == 'true') const SizedBox(width: 8),
              _buildAbsentPill('Evening', '${state.eveningAbsents}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'evening')))),
            ],
            if (state.mess?.mealTimings['night']?['enabled'] == 'true') ...[
              if (state.mess?.mealTimings['morning']?['enabled'] == 'true' || state.mess?.mealTimings['noon']?['enabled'] == 'true' || state.mess?.mealTimings['evening']?['enabled'] == 'true') const SizedBox(width: 8),
              _buildAbsentPill('Night', '${state.nightAbsents}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'night')))),
            ],
          ],
        ),
      ]),
    );
  }

  Widget _buildAbsentPill(String label, String count, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(count, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF991B1B))),
          ]),
        ),
      ),
    );
  }

  Widget _buildCurrentMealCard(OwnerDashboardState state) {
    if (state.currentSlot == 'closed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            const Icon(Icons.nightlight_round, color: Color(0xFF9CA3AF), size: 48),
            const SizedBox(height: 12),
            Text('Mess Closed for Today', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
            const SizedBox(height: 4),
            Text('All meals for today have concluded.', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      );
    }
    
    if (state.currentMeal == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Text('No menu set for the current meal.', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
      );
    }
    
    final menu = state.currentMeal!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text('Current Meal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
                  Text("Today's ${menu.mealSlot[0].toUpperCase()}${menu.mealSlot.substring(1)} Menu",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                ]
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Live', style: GoogleFonts.inter(color: const Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w600)),
              )
            ]
          )
        ),
        if (menu.dishes.isEmpty)
           Padding(
             padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
             child: Text('No dishes added yet.', style: GoogleFonts.inter(color: Colors.grey)),
           )
        else
          ...menu.dishes.map((dish) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.network(
                      (dish.imageUrl?.isNotEmpty ?? false) ? dish.imageUrl! : 'https://via.placeholder.com/50',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name, 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dish.category, 
                        style: GoogleFonts.inter(
                          fontSize: 11, 
                          color: dish.category == 'Veg' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ),
                ),
                Text('1 Portion', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
              ],
            ),
          )),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildUpcomingLeaves() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Upcoming Long Leaves',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('No upcoming leaves',
            style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))),
        )),
      ]),
    );
  }

  void _showEmergencyCloseDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Emergency Close?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: Text('This will notify all students that the mess is closed today.', style: GoogleFonts.inter()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter())),
        ElevatedButton(
          onPressed: () { ref.read(ownerDashboardProvider.notifier).emergencyClose(); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          child: Text('Close Mess', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showAnnouncementDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Send Announcement', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: 'Type your message...',
          hintStyle: GoogleFonts.inter(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter())),
        ElevatedButton(
          onPressed: () {
            ref.read(ownerDashboardProvider.notifier).sendAnnouncement(ctrl.text);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
          child: Text('Send', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showPendingRequests(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final pending = ref.watch(ownerStudentsProvider).pending;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Requests', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pending.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No new requests.', style: GoogleFonts.inter(color: Colors.grey))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pending.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = pending[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFDCFCE7),
                                child: Text(student.name.isNotEmpty ? student.name[0] : '?', style: GoogleFonts.inter(color: const Color(0xFF16A34A), fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('Room: ${student.roomNo} | ${student.college}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(ownerStudentsProvider.notifier).accept(student.studentId);
                                      if (pending.length == 1) Navigator.pop(context); // close if last one
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(ownerStudentsProvider.notifier).reject(student.studentId);
                                      if (pending.length == 1) Navigator.pop(context); // close if last one
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value, subtitle, badgeText;
  final Color subtitleColor, badgeBg, badgeColor;
  final bool isHighlighted;
  final Color? progressColor;
  final double progressValue;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconBg, required this.iconColor,
    required this.label, required this.value,
    required this.subtitle, required this.subtitleColor,
    required this.badgeText, required this.badgeBg, required this.badgeColor,
    this.isHighlighted = false,
    this.progressColor,
    this.progressValue = 0.14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? Border.all(color: const Color(0xFF22C55E), width: 1.5) : null,
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (badgeText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(badgeText, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor)),
              ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
            if (progressColor != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: const Color(0xFFF3F4F6),
                  color: progressColor,
                  minHeight: 3,
                ),
              ),
            ],
            Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: subtitleColor)),
          ]),
        ],
      ),
    ));
  }
}
