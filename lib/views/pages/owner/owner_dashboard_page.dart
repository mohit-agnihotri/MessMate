import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'owner_student_management_page.dart';
import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'owner_absentee_tracker_page.dart';
import 'widgets/post_today_meal_sheet.dart';
import 'widgets/schedule_closure_dialog.dart';
import 'widgets/manage_closed_slots_sheet.dart';
import 'widgets/mess_qr_standee_sheet.dart';
import 'widgets/dish_battle_sheet.dart';
import 'owner_expense_ledger_page.dart';
import 'widgets/add_expense_sheet.dart';
import 'widgets/owner_set_location_sheet.dart';
import '../../../services/notification_service.dart';
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

                    // Active Feast Day Quick-Switch Card
                    SliverToBoxAdapter(
                      child: _buildFeastDayManagementCard(context, ref, state),
                    ),

                    // Unset Mess Location Reminder Banner
                    if (state.mess != null &&
                        (state.mess!.gpsLat == 0.0 || state.mess!.gpsLng == 0.0))
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: _buildUnsetLocationBanner(context, ref, state.mess!),
                        ),
                      ),

                    // Hero Card (Dark Walnut + Wavy Hills + Diner Count + CTA)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildHeroCard(context, ref, state),
                      ),
                    ),

                    // Food Vote is Live Banner (Screenshot 03.41.19.jpeg)
                    if (state.mess != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _OwnerLiveFoodVoteBanner(mess: state.mess!),
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

                    // Kitchen Kharcha & P&L Quick Card (Khaata)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildKitchenKhaataQuickCard(context, ref),
                      ),
                    ),

                    // Absent Today Summary Card (Screenshot 1)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildAbsentTodayCard(context, ref, state),
                      ),
                    ),

                    // PhonePe-Style Counter QR Standee (Always at the very bottom)
                    if (state.mess != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                        sliver: SliverToBoxAdapter(
                          child: _buildCounterQrStandeeCard(context, ref, state),
                        ),
                      )
                    else
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 110),
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

  // ── Unset Mess Location Reminder Banner ──
  Widget _buildUnsetLocationBanner(
    BuildContext context,
    WidgetRef ref,
    MessModel mess,
  ) {
    return GestureDetector(
      onTap: () => OwnerSetLocationSheet.show(context, ref, mess),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: OwnerColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_location_alt_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Mess Location 📍',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pin GPS location so nearby students can see your mess distance.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFFB45309),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Pin Now',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Global Search Bar (VIP Badge Removed for Clean Hierarchy) ──
  Widget _buildVipAndSearchRow(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    return GestureDetector(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
            const Icon(Icons.search_rounded, size: 18, color: OwnerColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search student by name, phone or room...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: OwnerColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEE6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Search',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: OwnerColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Card with Wavy Hills and Expected Diners ──
  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[now.weekday - 1];
    final isFeastDay = state.mess?.specialMealEnabled == true &&
        (state.mess?.specialMealDays.contains(dayName) ?? false);
    final isSingleMealFeast =
        isFeastDay && (state.mess?.specialMealCookedSlots.length ?? 0) <= 1;

    String slot;
    if (isSingleMealFeast && (state.mess?.specialMealSlot.isNotEmpty ?? false)) {
      slot = state.mess!.specialMealSlot;
    } else {
      slot = state.currentSlot == 'closed' ? 'night' : state.currentSlot;
    }

    final slotName = slot[0].toUpperCase() + slot.substring(1);
    final timings = state.mess?.mealTimings[slot];
    final startStr = timings?['start'] ?? '';
    final endStr = timings?['end'] ?? '';
    final timeRange = (startStr.isNotEmpty && endStr.isNotEmpty)
        ? '$startStr-$endStr'
        : '19:30-22:00';

    final isSpecialFeastSlot = isFeastDay && state.mess?.specialMealSlot == slot;
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
                        isSpecialFeastSlot
                            ? '${slot.toUpperCase()} FEAST SERVICE · $timeRange'
                            : '${slot.toUpperCase()} SERVICE · $timeRange',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: OwnerColors.amber,
                          letterSpacing: 1.2,
                        ),
                      ),

                      // Stylized circular slot badge
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: OwnerColors.walnutSurface,
                          border: Border.all(
                            color: OwnerColors.amber.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              slotAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  slot == 'morning'
                                      ? Icons.wb_twilight_rounded
                                      : (slot == 'noon'
                                          ? Icons.wb_sunny_rounded
                                          : Icons.nightlight_round),
                                  color: OwnerColors.amber,
                                  size: 24,
                                ),
                              ),
                            ),
                            // Subtle luxury vignette tint
                            Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                              '${state.expectedHeadcount == 1 ? "diner" : "diners"} expected',
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

                  // Menu status / dishes description (Dynamic slot name)
                  Text(
                    isExplicitlyPosted
                        ? dishes.map((d) => d.name).join(' • ')
                        : '$slotName\'s menu isn\'t posted. Students see your standard menu.',
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

    final now = DateTime.now();
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[now.weekday - 1];
    final isFeastDay = state.mess?.specialMealEnabled == true &&
        (state.mess?.specialMealDays.contains(dayName) ?? false);
    final feastSlot = state.mess?.specialMealSlot ?? '';
    final cookedSlots = state.mess?.specialMealCookedSlots ?? [];

    final isMorningClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'morning');
    final isNoonClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'noon');
    final isEveningClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'evening');
    final isNightClosed = state.closedSlots.any((c) => c['date'] == todayStr && c['mealSlot'] == 'night');

    final isMorningFeast = isFeastDay && feastSlot == 'morning';
    final isMorningCooked = !isFeastDay || cookedSlots.isEmpty || cookedSlots.contains('morning');
    final String morningLabel = isMorningClosed
        ? 'Morning ❌'
        : (isMorningFeast
            ? 'Morning ★'
            : (!isMorningCooked ? 'Morning Off' : 'Morning'));

    final isNoonFeast = isFeastDay && feastSlot == 'noon';
    final isNoonCooked = !isFeastDay || cookedSlots.isEmpty || cookedSlots.contains('noon');
    final String noonLabel = isNoonClosed
        ? 'Noon ❌'
        : (isNoonFeast
            ? 'Noon ★'
            : (!isNoonCooked ? 'Noon Off' : 'Noon'));

    final isEveningFeast = isFeastDay && feastSlot == 'evening';
    final isEveningCooked = !isFeastDay || cookedSlots.isEmpty || cookedSlots.contains('evening');
    final String eveningLabel = isEveningClosed
        ? 'Evening ❌'
        : (isEveningFeast
            ? 'Evening ★'
            : (!isEveningCooked
                ? 'Evening Off'
                : ((timings['evening']?['enabled'] == 'true') ? 'Evening' : 'Evening off')));

    final isNightFeast = isFeastDay && feastSlot == 'night';
    final isNightCooked = !isFeastDay || cookedSlots.isEmpty || cookedSlots.contains('night');
    final String nightLabel = isNightClosed
        ? 'Night ❌'
        : (isNightFeast
            ? 'Night ★'
            : (!isNightCooked ? 'Night Off' : 'Night'));

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
                )
              else
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: OwnerColors.sage,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live Schedule',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: OwnerColors.sageText,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Row with connecting line
          Row(
            children: [
              _buildStepItem(
                label: morningLabel,
                enabled: timings['morning']?['enabled'] == 'true' && isMorningCooked,
                isCurrent: current == 'morning',
                color: isMorningClosed ? const Color(0xFFEF4444) : (isMorningFeast ? OwnerColors.amber : OwnerColors.sage),
                isClosed: isMorningClosed || !isMorningCooked,
                isGlow: isMorningFeast && !isMorningClosed,
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
                label: noonLabel,
                enabled: timings['noon']?['enabled'] == 'true' && isNoonCooked,
                isCurrent: current == 'noon',
                color: isNoonClosed ? const Color(0xFFEF4444) : (isNoonFeast ? OwnerColors.amber : OwnerColors.sage),
                isClosed: isNoonClosed || !isNoonCooked,
                isGlow: isNoonFeast && !isNoonClosed,
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
                label: eveningLabel,
                enabled: timings['evening']?['enabled'] == 'true' && isEveningCooked,
                isCurrent: current == 'evening',
                color: isEveningClosed ? const Color(0xFFEF4444) : (isEveningFeast ? OwnerColors.amber : OwnerColors.sage),
                isClosed: isEveningClosed || !isEveningCooked,
                isGlow: isEveningFeast && !isEveningClosed,
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
                label: nightLabel,
                enabled: timings['night']?['enabled'] == 'true' && isNightCooked,
                isCurrent: current == 'night' || current == 'closed',
                color: isNightClosed ? const Color(0xFFEF4444) : (isNightFeast ? OwnerColors.amber : OwnerColors.sage),
                isClosed: isNightClosed || !isNightCooked,
                isGlow: isNightFeast && !isNightClosed,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ANNOUNCE',
                        style: OwnerTypography.overline(
                          fontSize: 10.5,
                          color: OwnerColors.textOverline,
                        ),
                      ),
                      const Icon(
                        Icons.campaign_rounded,
                        size: 16,
                        color: OwnerColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Broadcast notice',
                    style: GoogleFonts.inter(
                      fontSize: 13,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JOIN',
                        style: OwnerTypography.overline(
                          fontSize: 10.5,
                          color: OwnerColors.textOverline,
                        ),
                      ),
                      const Icon(
                        Icons.person_add_rounded,
                        size: 16,
                        color: OwnerColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Invite a student',
                    style: GoogleFonts.inter(
                      fontSize: 13,
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

          // Numbers Row (Equal-width interactive slot badges)
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
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
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
    final hasAbsents = (int.tryParse(count) ?? 0) > 0;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: hasAbsents ? const Color(0xFFFBF4ED) : const Color(0xFFF9F6F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAbsents ? const Color(0xFFEEDBCB) : const Color(0xFFECE4D9),
              width: 0.9,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: OwnerTypography.serifNumeral(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: hasAbsents ? const Color(0xFFBD5D38) : OwnerColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slotName,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: hasAbsents ? const Color(0xFF8D5B4C) : OwnerColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PhonePe-Style Counter QR Standee Card ──
  Widget _buildCounterQrStandeeCard(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final mess = state.mess;
    if (mess == null) return const SizedBox.shrink();

    final qrPayload =
        'https://mezzo-69cab.web.app/?id=${mess.messId}&code=${mess.messCode}';

    return Container(
      width: double.infinity,
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: OwnerColors.amberLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: OwnerColors.amberText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Counter QR Standee',
                        style: GoogleFonts.newsreader(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
                      Text(
                        'Keep at reception or dining table',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: OwnerColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live Counter',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code + Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFEAE2D7),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // QR Box (White squircle)
                GestureDetector(
                  onTap: () => MessQrStandeeSheet.show(context, mess),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0x182D231C),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 88,
                        padding: EdgeInsets.zero,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF231A14),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF231A14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details & Tap-to-Copy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mess.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.newsreader(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Mess Code Pill with Copy Action
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Clipboard.setData(ClipboardData(text: mess.messCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mess code #${mess.messCode} copied!'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: OwnerColors.amberLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: OwnerColors.amber.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#${mess.messCode}',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: OwnerColors.amberText,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: OwnerColors.amberText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Students scan to view live daily menu & join mess instantly.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: OwnerColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: [ Zoom Standee ] & [ Print PDF ]
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => MessQrStandeeSheet.show(context, mess),
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    size: 16,
                    color: OwnerColors.textDark,
                  ),
                  label: Text(
                    'Zoom Standee',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OwnerColors.textDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: OwnerColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => MessQrStandeeSheet.show(context, mess),
                  icon: const Icon(
                    Icons.print_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Print PDF',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: OwnerColors.walnut,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (state.mess != null) {
                    MessQrStandeeSheet.show(context, state.mess!);
                  }
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                label: const Text('View Counter QR Standee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.walnutDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ── Active Feast Day Quick-Switch Card ──
  Widget _buildFeastDayManagementCard(
    BuildContext context,
    WidgetRef ref,
    OwnerDashboardState state,
  ) {
    final mess = state.mess;
    if (mess == null || !mess.specialMealEnabled) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[now.weekday - 1];

    // Only show on configured feast days
    if (!mess.specialMealDays.contains(dayName)) {
      return const SizedBox.shrink();
    }

    final activeSlot = mess.specialMealSlot.isNotEmpty ? mess.specialMealSlot : 'night';
    final activeSlotName = activeSlot == 'noon' ? 'Lunch · Noon' : 'Dinner · Night';
    final targetSlot = activeSlot == 'night' ? 'noon' : 'night';
    final isSingleMealSchedule = mess.specialMealCookedSlots.length <= 1;

    final refundText = (mess.specialMealFlatRate != null && mess.specialMealFlatRate! > 0)
        ? '₹${mess.specialMealFlatRate!.toInt()}'
        : '2x regular';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF231A14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OwnerColors.amber.withValues(alpha: 0.35), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Internal radial ambient glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OwnerColors.amber.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overline tag & Skip Rule pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: OwnerColors.amber),
                          const SizedBox(width: 6),
                          Text(
                            'TODAY IS ${dayName.toUpperCase()} FEAST DAY',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: OwnerColors.amber,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OwnerColors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: OwnerColors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '$refundText Skip Rule',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFDE8CD),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Active slot description
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          activeSlot == 'noon' ? Icons.wb_sunny_rounded : Icons.bedtime_rounded,
                          size: 20,
                          color: OwnerColors.amber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Feast Slot: $activeSlotName ★',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSingleMealSchedule
                                  ? '1-Meal Schedule: Other meal is Kitchen Off'
                                  : 'Feast cooked at $activeSlot · other meals regular',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Actions: Switch Feast Slot & Post Menu
                  Row(
                    children: [
                      // Quick Switch Slot Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSwitchFeastSlot(context, ref, mess, targetSlot, dayName),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: Text(
                            'Switch to ${targetSlot == 'noon' ? 'Lunch' : 'Dinner'}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: OwnerColors.amber,
                            side: BorderSide(color: OwnerColors.amber.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Post Feast Menu Button
                      ElevatedButton.icon(
                        onPressed: () {
                          PostTodayMealSheet.show(
                            context,
                            mess: mess,
                            initialSlot: activeSlot,
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu_rounded, size: 15),
                        label: Text(
                          'Post Menu',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OwnerColors.amber,
                          foregroundColor: OwnerColors.textDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSwitchFeastSlot(
    BuildContext context,
    WidgetRef ref,
    MessModel mess,
    String targetSlot,
    String dayName,
  ) async {
    final timings = mess.mealTimings[targetSlot];
    final startStr = timings?['start'] ?? (targetSlot == 'noon' ? '12:00' : '19:30');
    final parts = startStr.split(':');
    final h = int.tryParse(parts[0]) ?? (targetSlot == 'noon' ? 12 : 19);
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final now = DateTime.now();
    final targetMealTime = DateTime(now.year, now.month, now.day, h, m);
    final targetCutoff = targetMealTime.subtract(Duration(hours: mess.cutoffHours));
    final isCutoffPassed = now.isAfter(targetCutoff);

    if (isCutoffPassed) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: OwnerColors.cardPure,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
              const SizedBox(width: 8),
              Text(
                'Cutoff Time Passed',
                style: OwnerTypography.serifHeading(fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'The skip cutoff time for ${targetSlot.toUpperCase()} ($startStr - ${mess.cutoffHours}h) has already passed. Students will not be able to skip. Are you sure you want to switch today\'s feast to ${targetSlot.toUpperCase()}?',
            style: GoogleFonts.inter(fontSize: 13, color: OwnerColors.textMuted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: OwnerColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerColors.amber,
                foregroundColor: OwnerColors.textDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Switch Anyway',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final isSingleMealSchedule = mess.specialMealCookedSlots.length <= 1;
    final updatedCookedSlots = isSingleMealSchedule
        ? [targetSlot]
        : (mess.specialMealCookedSlots.contains(targetSlot)
            ? mess.specialMealCookedSlots
            : [...mess.specialMealCookedSlots, targetSlot]);

    final updatedMess = mess.copyWith(
      specialMealSlot: targetSlot,
      specialMealCookedSlots: updatedCookedSlots,
    );

    await ref.read(ownerSettingsProvider.notifier).save(updatedMess);
    await ref.read(ownerDashboardProvider.notifier).reload();

    final targetLabel = targetSlot == 'noon' ? 'Lunch (Noon)' : 'Dinner (Night)';
    try {
      await NotificationService.sendMessNotification(
        messId: mess.messId,
        title: '✨ $dayName Feast Schedule Update',
        message: 'Today\'s special feast will be served at $targetLabel! ${isSingleMealSchedule ? 'Kitchen will be off for other meals.' : ''}',
        targetPref: 'announcements',
        data: {'type': 'feast_shift', 'slot': targetSlot},
      );
    } catch (e) {
      debugPrint('[NotificationService] Error sending feast switch push: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched feast to $targetLabel and notified students! 🚀'),
          backgroundColor: const Color(0xFF2B2019),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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

  // ── Kitchen Kharcha & P&L Quick Card (Khaata) ──
  Widget _buildKitchenKhaataQuickCard(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(ownerExpenseLedgerProvider);
    final todaySpent = ledgerState.todayExpenses;
    final inHandProfit = ledgerState.netCashProfit;
    final isProfitable = inHandProfit >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KITCHEN KHARCHA',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: const Color(0xFF887D75),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Daily ration & expense',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2218),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OwnerExpenseLedgerPage()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EBE2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open khaata',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A6B53),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: Color(0xFF4A6B53),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFECE4D9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s kharcha',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF887D75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${todaySpent.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E2218),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFECE4D9),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This month\'s cash profit',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF887D75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inHandProfit < 0
                          ? '-₹${inHandProfit.abs().toInt()}'
                          : (inHandProfit > 0 ? '+₹${inHandProfit.toInt()}' : '₹0'),
                      style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isProfitable
                            ? const Color(0xFF4A6B53)
                            : const Color(0xFFBD5D38),
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
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => AddExpenseSheet.show(context),
              icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF4E342E)),
              label: Text(
                'Log today\'s kharcha',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3E2723),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFAF6F0),
                side: const BorderSide(color: Color(0xFFE5DDD0), width: 1.2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
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

// ── Live Food Vote Banner for Owner Today Screen (Screenshot 03.41.19.jpeg) ──
class _OwnerLiveFoodVoteBanner extends ConsumerWidget {
  final MessModel mess;

  const _OwnerLiveFoodVoteBanner({required this.mess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battleAsync = ref.watch(activeDishBattleProvider(mess.messId));

    return battleAsync.when(
      data: (battle) {
        if (battle == null || battle.isClosed) return const SizedBox.shrink();

        final now = DateTime.now();
        if (now.isAfter(battle.closesAt)) return const SizedBox.shrink();

        final remaining = battle.closesAt.difference(now);
        final hours = remaining.inHours;
        final mins = remaining.inMinutes % 60;
        final timeStr = hours > 0 ? '${hours}h ${mins}m left' : '${mins}m left';

        int totalVotes = battle.totalVotes;
        if (totalVotes == 0) {
          totalVotes = battle.options.fold<int>(0, (s, o) => s + o.votes);
        }

        String slotLabel;
        switch (battle.targetSlot.toLowerCase()) {
          case 'morning':
            slotLabel = 'Breakfast';
            break;
          case 'noon':
            slotLabel = 'Lunch';
            break;
          case 'night':
            slotLabel = 'Dinner';
            break;
          default:
            slotLabel = battle.targetSlot;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5A93C),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: • FOOD VOTE IS LIVE & remaining pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBD5D38),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FOOD VOTE IS LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFFBD5D38),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9E5327),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                '${battle.title} · $slotLabel',
                style: GoogleFonts.newsreader(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: OwnerColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              // Dish Progress Bars
              for (int i = 0; i < battle.options.length; i++) ...[
                Builder(builder: (ctx) {
                  final opt = battle.options[i];
                  final pct = totalVotes > 0 ? (opt.votes / totalVotes) : 0.0;
                  final pctInt = (pct * 100).round();
                  final isAmber = i % 2 == 0;
                  final barColor = isAmber ? const Color(0xFFE89025) : const Color(0xFF86A386);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              opt.name,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: OwnerColors.textDark,
                              ),
                            ),
                            Text(
                              '$pctInt%',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: OwnerColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFEDE5D8),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 4),

              // Bottom Row: Votes pill & View live >
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8CD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalVotes votes',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E5327),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => DishBattleSheet.show(context, mess: mess),
                    child: Row(
                      children: [
                        Text(
                          'View live',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: OwnerColors.textDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
