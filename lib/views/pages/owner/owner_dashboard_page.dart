import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'owner_student_management_page.dart';
import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'owner_absentee_tracker_page.dart';
import 'widgets/owner_launch_partner_sheet.dart';
import 'widgets/post_today_meal_sheet.dart';
import 'widgets/schedule_closure_dialog.dart';
import 'widgets/manage_closed_slots_sheet.dart';
import 'theme/owner_inspired_theme.dart';

class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerDashboardProvider);
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[now.weekday - 1];

    final slot = state.currentSlot;
    final slotName = slot == 'closed' ? 'Night' : (slot[0].toUpperCase() + slot.substring(1));
    final daySlotOverline = '$dayName $slotName'.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: OwnerColors.sage),
              )
            : RefreshIndicator(
                color: OwnerColors.sage,
                onRefresh: () => ref.read(ownerDashboardProvider.notifier).reload(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Top Header (Screenshot 1)
                    SliverToBoxAdapter(
                      child: _buildHeader(context, ref, state, daySlotOverline),
                    ),

                    // VIP Pill + Search Bar Row (Screenshot 1)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _buildVipAndSearchRow(context, ref, state),
                      ),
                    ),

                    // Active / Scheduled Closure Banner
                    SliverToBoxAdapter(
                      child: _buildClosureBanner(context, ref, state),
                    ),

                    // Hero Card (Dark Walnut + Wavy Hills + Diner Count + CTA)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildHeroCard(context, ref, state),
                      ),
                    ),

                    // Today's Service Timeline / Stepper Card (Screenshot 1)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildTodayServiceStepper(context, ref, state),
                      ),
                    ),

                    // Split Action Cards: Announce & Join (Screenshot 1)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildSplitActionCards(context, ref, state),
                      ),
                    ),

                    // Absent Today Summary Card (Screenshot 1)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      sliver: SliverToBoxAdapter(
                        child: _buildAbsentTodayCard(context, ref, state),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Top Header matching Screenshot 1 ──
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
    String daySlotOverline,
  ) {
    final messName = state.mess?.name ?? 'Mahakal\nmess';
    final mess = state.mess;
    final isClosedNow = mess?.isClosedNow ?? false;
    final isUpcoming = mess?.isClosureUpcoming ?? false;
    final isOpen = mess?.isOpen ?? true;

    Color pillBg = OwnerColors.sageLight;
    Color pillBorder = OwnerColors.sageBorder.withValues(alpha: 0.5);
    Color dotColor = const Color(0xFF16A34A);
    Color textColor = OwnerColors.sageText;
    String pillText = 'Open · Close';

    if (isClosedNow) {
      pillBg = const Color(0xFFFEE2E2);
      pillBorder = const Color(0xFFFCA5A5);
      dotColor = const Color(0xFFDC2626);
      textColor = const Color(0xFFB91C1C);
      pillText = 'Closed';
    } else if (isUpcoming) {
      pillBg = const Color(0xFFFEF3C7);
      pillBorder = const Color(0xFFFCD34D);
      dotColor = const Color(0xFFD97706);
      textColor = const Color(0xFF92400E);
      pillText = 'Closure ⏳';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Overline + Serif Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daySlotOverline,
                  style: OwnerTypography.overline(
                    fontSize: 12,
                    color: OwnerColors.textOverline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  messName,
                  style: OwnerTypography.serifHeading(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.textDark,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Right: Alerts & Open/Close pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alerts pill
              Consumer(
                builder: (context, ref, _) {
                  final pendingCount = ref.watch(ownerStudentsProvider).pending.length;
                  return GestureDetector(
                    onTap: () => _showPendingRequests(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: OwnerColors.sageLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: OwnerColors.sageBorder.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Alerts',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: OwnerColors.sageText,
                            ),
                          ),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: OwnerColors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$pendingCount',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: OwnerColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Open · Close status pill
              GestureDetector(
                onTap: () => _showEmergencyCloseDialog(context, ref, isOpen, state.mess),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pillBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pillText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── VIP Pill + Global Search Row ──
  Widget _buildVipAndSearchRow(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    return Row(
      children: [
        // VIP Pill
        GestureDetector(
          onTap: () {
            if (state.mess != null) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => OwnerLaunchPartnerSheet(mess: state.mess!),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: OwnerColors.walnut,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: OwnerColors.amber),
                const SizedBox(width: 5),
                Text(
                  'VIP · 180 days free',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.amber,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Search Student or Dish Field
        Expanded(
          child: GestureDetector(
            onTap: () {
              showSearch(
                context: context,
                delegate: OwnerGlobalSearchDelegate(
                  students: state.activeStudentsList,
                  ref: ref,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: OwnerColors.cardPure,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: OwnerColors.cardBorder),
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
                  const Icon(Icons.search_rounded, size: 17, color: OwnerColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search student or dish...',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: OwnerColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Card with Wavy Hills and Expected Diners ──
  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final slot = state.currentSlot == 'closed' ? 'night' : state.currentSlot;
    final slotName = slot[0].toUpperCase() + slot.substring(1);
    final timings = state.mess?.mealTimings[slot];
    final startStr = timings?['start'] ?? '';
    final endStr = timings?['end'] ?? '';
    final timeRange = (startStr.isNotEmpty && endStr.isNotEmpty) ? '$startStr-$endStr' : '19:30-22:00';

    final menu = state.currentMeal;
    final isExplicitlyPosted = menu != null &&
        menu.isPublished &&
        (menu.menuType == 'special' || menu.menuType == 'regular') &&
        menu.dishes.isNotEmpty;
    final dishes = menu?.dishes ?? [];
    final slotAsset = 'assets/images/slot_$slot.png';

    return Container(
      decoration: BoxDecoration(
        color: OwnerColors.walnut,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Internal radial amber glow on top right
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      OwnerColors.amber.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Organic Wavy Sage Hills at the bottom of the card (Screenshot 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 90,
                child: CustomPaint(
                  painter: WavyHillsPainter(),
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overline Timing & Top-right Slot Image Frame
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${slot.toUpperCase()} SERVICE · $timeRange',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: OwnerColors.amber,
                          letterSpacing: 1.2,
                        ),
                      ),

                      // Circle thumbnail for slot image
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: OwnerColors.walnutSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          slotAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              'your $slotName\nimage',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Expected Diner Count Numeral Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${state.expectedHeadcount}',
                        style: OwnerTypography.serifNumeral(
                          fontSize: 68,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFDE8CD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'diner expected',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.skippingCurrentMeal} skipping · ${state.mess?.capacity ?? 150} seats',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Menu status / dishes description
                  Text(
                    isExplicitlyPosted
                        ? dishes.map((d) => d.name).join(' • ')
                        : 'Tonight\'s menu isn\'t posted. Students see your standard menu.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),

                  // Glowing Amber CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (state.mess != null) {
                          PostTodayMealSheet.show(
                            context,
                            mess: state.mess!,
                            initialSlot: state.currentSlot,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OwnerColors.amber,
                        foregroundColor: OwnerColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        isExplicitlyPosted
                            ? 'Edit ${slotName.toLowerCase()}\'s menu'
                            : 'Post ${slotName.toLowerCase()}\'s menu',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
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

  // ── Today's Service Timeline / Stepper Card (Screenshot 1) ──
  Widget _buildTodayServiceStepper(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final current = state.currentSlot;
    final timings = state.mess?.mealTimings ?? {};
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final isMorningClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'morning');
    final isNoonClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'noon');
    final isEveningClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'evening');
    final isNightClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'night');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: OwnerColors.cardPure,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OwnerColors.cardBorder),
        boxShadow: OwnerColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY\'S SERVICE',
                style: OwnerTypography.overline(
                  color: OwnerColors.textOverline,
                  fontSize: 11,
                ),
              ),
              if (isMorningClosed || isNoonClosed || isEveningClosed || isNightClosed)
                GestureDetector(
                  onTap: () {
                    if (state.mess != null) {
                      showManageClosedSlotsSheet(context, mess: state.mess!);
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        'Slots closed today',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Row with connecting line
          Row(
            children: [
              _buildStepItem(
                label: isMorningClosed ? 'Morning ❌' : 'Morning',
                enabled: timings['morning']?['enabled'] == 'true',
                isCurrent: current == 'morning',
                color: isMorningClosed ? const Color(0xFFEF4444) : OwnerColors.amber,
                isClosed: isMorningClosed,
                onTap: isMorningClosed
                    ? () => state.mess != null ? showManageClosedSlotsSheet(context, mess: state.mess!) : null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'morning'),
                          ),
                        ),
              ),
              _buildStepLine(),
              _buildStepItem(
                label: isNoonClosed ? 'Noon ❌' : 'Noon',
                enabled: timings['noon']?['enabled'] == 'true',
                isCurrent: current == 'noon',
                color: isNoonClosed ? const Color(0xFFEF4444) : OwnerColors.sage,
                isClosed: isNoonClosed,
                onTap: isNoonClosed
                    ? () => state.mess != null ? showManageClosedSlotsSheet(context, mess: state.mess!) : null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'noon'),
                          ),
                        ),
              ),
              _buildStepLine(),
              _buildStepItem(
                label: isEveningClosed
                    ? 'Evening ❌'
                    : ((timings['evening']?['enabled'] == 'true') ? 'Evening' : 'Evening off'),
                enabled: timings['evening']?['enabled'] == 'true',
                isCurrent: current == 'evening',
                color: isEveningClosed ? const Color(0xFFEF4444) : OwnerColors.sage,
                isClosed: isEveningClosed,
                onTap: isEveningClosed
                    ? () => state.mess != null ? showManageClosedSlotsSheet(context, mess: state.mess!) : null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'evening'),
                          ),
                        ),
              ),
              _buildStepLine(),
              _buildStepItem(
                label: isNightClosed ? 'Night ❌' : 'Night',
                enabled: timings['night']?['enabled'] == 'true',
                isCurrent: current == 'night' || current == 'closed',
                color: isNightClosed ? const Color(0xFFEF4444) : OwnerColors.amber,
                isClosed: isNightClosed,
                isGlow: !isNightClosed,
                onTap: isNightClosed
                    ? () => state.mess != null ? showManageClosedSlotsSheet(context, mess: state.mess!) : null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'night'),
                          ),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String label,
    required bool enabled,
    required bool isCurrent,
    required Color color,
    bool isGlow = false,
    bool isClosed = false,
    required VoidCallback onTap,
  }) {
    Color dotColor = enabled ? (isGlow ? OwnerColors.amber : color) : Colors.transparent;
    Color borderColor = enabled ? Colors.transparent : const Color(0xFFC7BCB3);
    if (isClosed) {
      dotColor = const Color(0xFFEF4444);
      borderColor = const Color(0xFFDC2626);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isGlow ? 22 : 16,
            height: isGlow ? 22 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: (isGlow && !isClosed)
                  ? [
                      BoxShadow(
                        color: OwnerColors.amber.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: (isCurrent || isClosed) ? FontWeight.w800 : FontWeight.w500,
              color: isClosed
                  ? const Color(0xFFDC2626)
                  : (isCurrent
                      ? OwnerColors.textDark
                      : (enabled ? OwnerColors.textMuted : const Color(0xFFB8B3AA))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 1.5,
        color: const Color(0xFFE2DDD3),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  // ── Split Action Cards: Announce & Join (Screenshot 1) ──
  Widget _buildSplitActionCards(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    return Row(
      children: [
        // Announce Card
        Expanded(
          child: GestureDetector(
            onTap: () => _showAnnouncementDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: OwnerColors.cardPure,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: OwnerColors.cardBorder),
                boxShadow: OwnerColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANNOUNCE',
                    style: OwnerTypography.overline(
                      fontSize: 10.5,
                      color: OwnerColors.textOverline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Message all students',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Join / Invite Card
        Expanded(
          child: GestureDetector(
            onTap: () => _showInviteDialog(context, ref, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: OwnerColors.cardPure,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: OwnerColors.cardBorder),
                boxShadow: OwnerColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOIN',
                    style: OwnerTypography.overline(
                      fontSize: 10.5,
                      color: OwnerColors.textOverline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invite a student',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Absent Today Summary Card (Screenshot 1) ──
  Widget _buildAbsentTodayCard(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.cardPure,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OwnerColors.cardBorder),
        boxShadow: OwnerColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ABSENT TODAY',
                style: OwnerTypography.overline(
                  fontSize: 11,
                  color: OwnerColors.textOverline,
                ),
              ),
              Text(
                '${state.upcomingLeaves.length} on leave soon',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: OwnerColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Numbers Row
          Row(
            children: [
              _buildAbsentNumber(
                count: '${state.morningAbsents}',
                slotName: 'Morning',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'morning'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildAbsentNumber(
                count: '${state.noonAbsents}',
                slotName: 'Noon',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'noon'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildAbsentNumber(
                count: '${state.nightAbsents}',
                slotName: 'Night',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerAbsenteeTrackerPage(initialSlot: 'night'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbsentNumber({
    required String count,
    required String slotName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            count,
            style: OwnerTypography.serifNumeral(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: OwnerColors.textDark,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            slotName,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: OwnerColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Existing Dialogs Preserved 100% ──
  void _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final messCode = state.mess?.messCode ?? 'N/A';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwnerColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Invite a student',
          style: OwnerTypography.serifHeading(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this unique mess code with your students to let them join your mess:',
              style: OwnerTypography.body(fontSize: 13, color: OwnerColors.textMuted),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: OwnerColors.amberLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OwnerColors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  messCode,
                  style: GoogleFonts.newsreader(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: OwnerColors.amberText,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: OwnerColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _showEmergencyCloseDialog(BuildContext context, WidgetRef ref, bool isOpen, MessModel? mess) {
    if (mess?.hasScheduledClosure == true) {
      showManageClosedSlotsSheet(context, mess: mess!);
    } else {
      showScheduleClosureDialog(context, ref, mess: mess);
    }
  }

  Widget _buildClosureBanner(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final mess = state.mess;
    if (mess == null || !mess.hasScheduledClosure) {
      return const SizedBox.shrink();
    }

    final isClosedNow = mess.isClosedNow;

    final bgColor = isClosedNow ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isClosedNow ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final iconColor = isClosedNow ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final titleColor = isClosedNow ? const Color(0xFF991B1B) : const Color(0xFF92400E);
    final bodyColor = isClosedNow ? const Color(0xFFB91C1C) : const Color(0xFFB45309);

    final title = isClosedNow ? 'Mess is Closed Today' : 'Closure Scheduled Ahead';

    String dateRangeStr = '';
    if (mess.closureStartDate != null && mess.temporarilyClosedUntil != null) {
      final s = mess.closureStartDate!;
      final e = mess.temporarilyClosedUntil!;
      final startSlot = mess.closureStartSlot ?? 'morning';
      final endSlot = mess.closureEndSlot ?? 'night';
      dateRangeStr = '${s.day}/${s.month} ($startSlot) → ${e.day}/${e.month} ($endSlot)';
    } else if (mess.temporarilyClosedUntil != null) {
      final e = mess.temporarilyClosedUntil!;
      dateRangeStr = 'Until ${e.day}/${e.month}/${e.year}';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isClosedNow ? Icons.lock_clock_rounded : Icons.calendar_month_rounded,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (dateRangeStr.isNotEmpty)
                      Text(
                        dateRangeStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: bodyColor,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showManageClosedSlotsSheet(context, mess: mess),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Manage',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: titleColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isClosedNow
                ? 'Your mess is currently closed for selected meals. Students have been notified, and refund deductions are active.'
                : 'Upcoming closure is set. Meal slots will automatically turn off on the scheduled date.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: bodyColor.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OwnerColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Send announcement',
          style: OwnerTypography.serifHeading(fontSize: 20),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Type your message...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: OwnerColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: OwnerColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: OwnerColors.cardBorder),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: OwnerColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(ownerDashboardProvider.notifier).sendAnnouncement(ctrl.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Announcement Sent!'),
                    backgroundColor: OwnerColors.sage,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OwnerColors.amber,
              foregroundColor: OwnerColors.textDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showPendingRequests(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OwnerColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        'Join requests',
                        style: OwnerTypography.serifHeading(fontSize: 22),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pending.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: OwnerColors.cardBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'No new requests',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: OwnerColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'New join requests will appear here',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: OwnerColors.textMuted,
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
                      itemCount: pending.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = pending[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: OwnerColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: OwnerColors.amberLight,
                                child: Text(
                                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                  style: GoogleFonts.newsreader(
                                    color: OwnerColors.amberText,
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: OwnerColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Room: ${student.roomNo} · ${student.college}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: OwnerColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(ownerStudentsProvider.notifier).accept(student.studentId);
                                      if (pending.length == 1) Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: OwnerColors.sageLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: OwnerColors.sage,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(ownerStudentsProvider.notifier).reject(student.studentId);
                                      if (pending.length == 1) Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 18,
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


class OwnerGlobalSearchDelegate extends SearchDelegate<String> {
  final List<StudentModel> students;
  final WidgetRef ref;

  OwnerGlobalSearchDelegate({required this.students, required this.ref});

  @override
  String get searchFieldLabel => 'Search student or dish...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: OwnerColors.canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: OwnerColors.canvas,
        elevation: 0,
        iconTheme: IconThemeData(color: OwnerColors.textDark),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: OwnerColors.textDark),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: OwnerColors.textDark),
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
          style: OwnerTypography.body(color: OwnerColors.textMuted),
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
          'No results found for "$query"',
          style: OwnerTypography.body(color: OwnerColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final joined = '${student.joinDate.day}/${student.joinDate.month}/${student.joinDate.year}';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: OwnerColors.cardPure,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OwnerColors.cardBorder),
            boxShadow: OwnerColors.softShadow,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: OwnerColors.amberLight,
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: GoogleFonts.newsreader(
                  color: OwnerColors.amberText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: OwnerColors.textDark),
            ),
            subtitle: Text(
              '${student.phone} · Room: ${student.roomNo}',
              style: GoogleFonts.inter(fontSize: 12, color: OwnerColors.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: OwnerColors.textMuted),
            onTap: () {
              close(context, '');
              const OwnerStudentManagementPage().showStudentDetailsModal(
                context,
                ref,
                student,
                joined,
              );
            },
          ),
        );
      },
    );
  }
}
