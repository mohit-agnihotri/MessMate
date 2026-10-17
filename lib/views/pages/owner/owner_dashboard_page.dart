import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'owner_student_management_page.dart';
import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../services/localization_service.dart';
import 'owner_absentee_tracker_page.dart';
import 'widgets/post_today_meal_sheet.dart';

class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerDashboardProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              )
            : RefreshIndicator(
                color: const Color(0xFF22C55E),
                onRefresh: () =>
                    ref.read(ownerDashboardProvider.notifier).reload(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context, ref, state, greeting),
                    ),
                    SliverToBoxAdapter(
                      child: _buildAnnouncementBanner(context, ref, state),
                    ),
                    SliverToBoxAdapter(
                      child: _buildGuestBanner(context, state),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildStatsGrid(context, state),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildAbsentSummaryCard(context, state),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildCurrentMealCard(context, state),
                      ),
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

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
    String greeting,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      state.mess?.name ?? 'Welcome back.'.tr(context, ref),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final pendingCount = ref
                      .watch(ownerStudentsProvider)
                      .pending
                      .length;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF374151),
                        ),
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
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              pendingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              GestureDetector(
                onTap: () => _showEmergencyCloseDialog(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.dangerous_rounded,
                        color: Color(0xFFEF4444),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Global Search Bar
          GestureDetector(
            onTap: () {
              showSearch(
                context: context,
                delegate: OwnerGlobalSearchDelegate(
                  students: state.activeStudentsList,
                  ref: ref,
                ),
              );
            },
            child: AbsorbPointer(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  hintText: 'Search student or dish...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
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
          child: Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                color: Color(0xFF92400E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap to send announcement to all students',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF92400E),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context, OwnerDashboardState state) {
    int totalGuests = 0;
    state.guestsBySlot.forEach((k, v) => totalGuests += v.length);

    if (totalGuests == 0) return const SizedBox.shrink();

    // Just show a quick summary e.g. "Morning: 2, Night: 5"
    final summaryParts = <String>[];
    if ((state.guestsBySlot['morning']?.length ?? 0) > 0) summaryParts.add('Morning: ${state.guestsBySlot['morning']!.length}');
    if ((state.guestsBySlot['noon']?.length ?? 0) > 0) summaryParts.add('Noon: ${state.guestsBySlot['noon']!.length}');
    if ((state.guestsBySlot['evening']?.length ?? 0) > 0) summaryParts.add('Evening: ${state.guestsBySlot['evening']!.length}');
    if ((state.guestsBySlot['night']?.length ?? 0) > 0) summaryParts.add('Night: ${state.guestsBySlot['night']!.length}');

    final summaryText = summaryParts.join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5), // Light Green
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF34D399).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.group_add_rounded,
              color: Color(0xFF065F46), // Dark Green
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalGuests Extra Guest${totalGuests > 1 ? 's' : ''} Today',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF064E3B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summaryText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          childAspectRatio: 1.35,
          children: [
            _StatCard(
              icon: Icons.school_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              label: 'Total Students',
              value: '${state.activeStudents}',
              badgeText: '',
              badgeBg: Colors.transparent,
              badgeColor: Colors.transparent,
              subtitle: 'Active students',
              subtitleColor: const Color(0xFF6B7280),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerStudentManagementPage(),
                  ),
                );
              },
            ),
            _StatCard(
              icon: Icons.dining_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              label: 'Expected Headcount',
              value: '${state.expectedHeadcount}',
              badgeText: 'Live',
              badgeBg: const Color(0xFFDCFCE7),
              badgeColor: const Color(0xFF16A34A),
              subtitle: 'Expected diners',
              subtitleColor: const Color(0xFF16A34A),
              isHighlighted: true,
            ),
            _StatCard(
              icon: Icons.notifications_off_rounded,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFEF4444),
              label: 'Skipping Current Meal',
              value: '${state.skippingCurrentMeal}',
              badgeText: '',
              badgeBg: Colors.transparent,
              badgeColor: Colors.transparent,
              subtitle: 'Total skipping',
              subtitleColor: const Color(0xFFEF4444),
              progressColor: const Color(0xFFEF4444),
              progressValue: (state.mess?.capacity ?? 1) > 0
                  ? state.skippingCurrentMeal / (state.mess?.capacity ?? 1)
                  : 0,
            ),
            _StatCard(
              icon: Icons.people_outline_rounded,
              iconBg: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF7C3AED),
              label: 'Capacity',
              value: '${state.mess?.capacity ?? 0}',
              badgeText: '',
              badgeBg: Colors.transparent,
              badgeColor: Colors.transparent,
              subtitle:
                  '${state.mess != null && state.mess!.capacity > 0 ? ((state.activeStudents / state.mess!.capacity) * 100).toStringAsFixed(0) : 0}% filled',
              subtitleColor: const Color(0xFF6B7280),
              progressColor: const Color(0xFF7C3AED),
              progressValue: (state.mess?.capacity ?? 1) > 0
                  ? state.activeStudents / (state.mess?.capacity ?? 1)
                  : 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAbsentSummaryCard(
    BuildContext context,
    OwnerDashboardState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Absent Summary',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (state.mess?.mealTimings['morning']?['enabled'] == 'true')
                _buildAbsentPill(
                  'Morning',
                  '${state.morningAbsents}',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerAbsenteeTrackerPage(
                        initialSlot: 'morning',
                      ),
                    ),
                  ),
                ),
              if (state.mess?.mealTimings['noon']?['enabled'] == 'true') ...[
                if (state.mess?.mealTimings['morning']?['enabled'] == 'true')
                  const SizedBox(width: 8),
                _buildAbsentPill(
                  'Noon',
                  '${state.noonAbsents}',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const OwnerAbsenteeTrackerPage(initialSlot: 'noon'),
                    ),
                  ),
                ),
              ],
              if (state.mess?.mealTimings['evening']?['enabled'] == 'true') ...[
                if (state.mess?.mealTimings['morning']?['enabled'] == 'true' ||
                    state.mess?.mealTimings['noon']?['enabled'] == 'true')
                  const SizedBox(width: 8),
                _buildAbsentPill(
                  'Evening',
                  '${state.eveningAbsents}',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerAbsenteeTrackerPage(
                        initialSlot: 'evening',
                      ),
                    ),
                  ),
                ),
              ],
              if (state.mess?.mealTimings['night']?['enabled'] == 'true') ...[
                if (state.mess?.mealTimings['morning']?['enabled'] == 'true' ||
                    state.mess?.mealTimings['noon']?['enabled'] == 'true' ||
                    state.mess?.mealTimings['evening']?['enabled'] == 'true')
                  const SizedBox(width: 8),
                _buildAbsentPill(
                  'Night',
                  '${state.nightAbsents}',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const OwnerAbsenteeTrackerPage(initialSlot: 'night'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbsentPill(String label, String count, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMealCard(BuildContext context, OwnerDashboardState state) {
    if (state.currentSlot == 'closed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.nightlight_round,
              color: Color(0xFF9CA3AF),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Mess Closed for Today',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All meals for today have concluded.',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final menu = state.currentMeal;
    final slot = state.currentSlot;
    final slotName = slot[0].toUpperCase() + slot.substring(1);
    final timings = state.mess?.mealTimings[slot];
    final startStr = timings?['start'] ?? '';
    final endStr = timings?['end'] ?? '';
    final timeRange = (startStr.isNotEmpty && endStr.isNotEmpty) ? '$startStr - $endStr' : '';
    final isExplicitlyPosted = menu != null &&
        menu.isPublished &&
        (menu.menuType == 'special' || menu.menuType == 'regular') &&
        menu.dishes.isNotEmpty;
    final isSpecial = isExplicitlyPosted && menu.menuType == 'special';
    final dishes = menu?.dishes ?? [];

    final slotIcon = slot == 'morning'
        ? '🌅'
        : slot == 'noon'
            ? '☀️'
            : slot == 'evening'
                ? '🌇'
                : '🌙';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpecial
              ? const Color(0xFFFDE68A)
              : (isExplicitlyPosted ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB)),
          width: isExplicitlyPosted ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(slotIcon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Meal: $slotName',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (timeRange.isNotEmpty)
                          Text(
                            'Serving Timings: $timeRange',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSpecial
                        ? const Color(0xFFFFFBEB)
                        : (isExplicitlyPosted
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSpecial
                          ? const Color(0xFFFDE68A)
                          : (isExplicitlyPosted
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    isSpecial
                        ? '✨ Special'
                        : (isExplicitlyPosted ? 'Cooked Today' : 'Standard Menu'),
                    style: GoogleFonts.inter(
                      color: isSpecial
                          ? const Color(0xFFD97706)
                          : (isExplicitlyPosted
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B)),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body: Either Posted Dishes or Unposted Info
          if (isExplicitlyPosted) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Icon(
                    isSpecial ? Icons.auto_awesome : Icons.check_circle_outline,
                    size: 16,
                    color: isSpecial ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSpecial
                        ? "Today's Special Dishes Announced:"
                        : "Today's Cooked Dishes Announced:",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSpecial ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
            // Horizontal scroll of dishes
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: dishes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final dish = dishes[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Image.network(
                              (dish.imageUrl?.isNotEmpty ?? false)
                                  ? dish.imageUrl!
                                  : 'https://via.placeholder.com/40',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE5E7EB),
                                child: const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dish.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              dish.category,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: dish.category.toLowerCase() == 'non-veg'
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Edit button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (state.mess != null) {
                      PostTodayMealSheet.show(
                        context,
                        mess: state.mess!,
                        initialSlot: state.currentSlot,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(
                    "Edit Today's Meal Post",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF6EE7B7)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ] else ...[
            // State: Not posted for today yet
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Today's specific meal not posted yet. Students are shown your general template menu.",
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (dishes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Template Offerings ($slotName):",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dishes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final dish = dishes[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: Image.network(
                                (dish.imageUrl?.isNotEmpty ?? false)
                                    ? dish.imageUrl!
                                    : 'https://via.placeholder.com/20',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dish.name,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Post button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (state.mess != null) {
                      PostTodayMealSheet.show(
                        context,
                        mess: state.mess!,
                        initialSlot: state.currentSlot,
                      );
                    }
                  },
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: Text(
                    "Post What's Cooking Today (Regular / Special)",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingLeaves() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Long Leaves',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No upcoming leaves',
                style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyCloseDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ScheduleClosureDialog(ref: ref),
    );
  }

  void _showAnnouncementDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Announcement',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref
                  .read(ownerDashboardProvider.notifier)
                  .sendAnnouncement(ctrl.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Announcement Sent!', style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: const Color(0xFF22C55E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
            ),
            child: Text('Send', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPendingRequests(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                      Text(
                        'Pending Requests',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      child: Center(
                        child: Text(
                          'No new requests.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pending.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
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
                                child: Text(
                                  student.name.isNotEmpty
                                      ? student.name[0]
                                      : '?',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF16A34A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Room: ${student.roomNo} | ${student.college}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(ownerStudentsProvider.notifier)
                                          .accept(student.studentId);
                                      if (pending.length == 1)
                                        Navigator.pop(
                                          context,
                                        ); // close if last one
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Color(0xFF16A34A),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(ownerStudentsProvider.notifier)
                                          .reject(student.studentId);
                                      if (pending.length == 1)
                                        Navigator.pop(
                                          context,
                                        ); // close if last one
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
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
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
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
          border: isHighlighted
              ? Border.all(color: const Color(0xFF22C55E), width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                if (badgeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
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
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: subtitleColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleClosureDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ScheduleClosureDialog({required this.ref});
  @override
  State<_ScheduleClosureDialog> createState() => _ScheduleClosureDialogState();
}

class _ScheduleClosureDialogState extends State<_ScheduleClosureDialog> {
  DateTime _startDate = DateTime.now();
  String _startSlot = 'night';
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _endSlot = 'morning';
  bool _isLoading = false;

  final List<String> _slots = ['morning', 'noon', 'evening', 'night'];

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFEF4444)),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = date;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  Widget _buildDropdown(String value, bool isStart) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
          items: _slots
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (isStart)
                  _startSlot = val;
                else
                  _endSlot = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDatePickerBtn(DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF111827),
              ),
            ),
            const Icon(
              Icons.calendar_month,
              color: Color(0xFF6B7280),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Schedule Closure',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDatePickerBtn(_startDate, true)),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown(_startSlot, true)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'To:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDatePickerBtn(_endDate, false)),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown(_endSlot, false)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'This will close all meals between these two dates/slots and send an announcement to your students.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await widget.ref
                      .read(ownerDashboardProvider.notifier)
                      .emergencyClose(
                        _startDate,
                        _startSlot,
                        _endDate,
                        _endSlot,
                        "Emergency Closure",
                      );
                  if (mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Confirm Closure',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}


class OwnerGlobalSearchDelegate extends SearchDelegate<String> {
  final List<StudentModel> students;
  final WidgetRef ref;

  OwnerGlobalSearchDelegate({required this.students, required this.ref});

  @override
  String get searchFieldLabel => 'Search student...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      return Center(
        child: Text(
          'Type to search students...',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }
    final filteredStudents = students.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
             s.email.toLowerCase().contains(lowerQuery) ||
             s.roomNo.toLowerCase().contains(lowerQuery) ||
             s.phone.contains(lowerQuery);
    }).toList();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Text(
          'No results for ""',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final joined = '${student.joinDate.day} ${_monthName(student.joinDate.month)} ${student.joinDate.year}';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.2),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF16A34A)),
            ),
          ),
          title: Text(student.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          subtitle: Text('${student.phone}  Room: ${student.roomNo}'),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            close(context, '');
            const OwnerStudentManagementPage().showStudentDetailsModal(
              context, 
              ref, 
              student, 
              joined,
            );
          },
        );
      },
    );
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
