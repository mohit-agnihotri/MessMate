import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/student_inspired_theme.dart';
import 'widgets/rate_mess_sheet.dart';
import 'widgets/view_mess_menu_sheet.dart';

const _slotIcons = {
  'morning': '🌅',
  'noon': '☀️',
  'evening': '🌇',
  'night': '🌙',
};

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  // ── Compute cutoff time remaining for any slot ──
  Duration _cutoffForSlot(MessModel mess, String slot, bool isToday) {
    final timings = mess.mealTimings[slot];
    if (timings == null) return Duration.zero;
    final startStr = timings['start'] ?? '00:00';
    final parts = startStr.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final now = DateTime.now();
    final mealDate = isToday ? now : now.add(const Duration(days: 1));
    final cutoff = DateTime(
      mealDate.year,
      mealDate.month,
      mealDate.day,
      h,
      m,
    ).subtract(Duration(hours: mess.cutoffHours));
    final diff = cutoff.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return 'Closed';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}hr ${m}m' : '${m}m';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentHomeProvider);

    return Scaffold(
      backgroundColor: StudentColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: StudentColors.amber,
          backgroundColor: Colors.white,
          onRefresh: () => ref.read(studentHomeProvider.notifier).load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: _Header(
                  state: state,
                  greeting: _greeting(),
                  ref: ref,
                  onBellTap: () {
                    ref.read(studentHomeProvider.notifier).markAnnouncementsAsSeen();
                    _showAnnouncementDialog(context, state);
                  },
                ),
              ),

              // ── Mess Closure Banner ──
              if (state.mess != null && (state.mess!.isClosedNow || state.mess!.isClosureUpcoming))
                SliverToBoxAdapter(
                  child: _MessClosureBanner(mess: state.mess!),
                ),

              // ── On-leave banner ──
              if (state.activeLeave != null)
                SliverToBoxAdapter(
                  child: _OnLeaveBanner(state: state, ref: ref),
                ),

              // ── Meal Choices (If student has a flexible plan) ──
              SliverToBoxAdapter(
                child: _ChoiceGroupsSection(state: state, ref: ref),
              ),

              // ── Current Meal Section Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT MEAL',
                        style: StudentTypography.overline(
                          fontSize: 12,
                          color: StudentColors.walnutMuted,
                          letterSpacing: 1.4,
                        ),
                      ),
                      if (state.currentSlot != 'closed')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: StudentColors.sageLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: StudentColors.sage,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'NOW SERVING',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: StudentColors.sageText,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Current Meal Card ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _buildCurrentMealCard(context, ref, state),
                ),
              ),

              // ── Quick Info Action Cards (My Mess Menu & My Rating) ──
              if (state.mess != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildMiddleActionCards(context, ref, state),
                  ),
                ),

              // ── Upcoming Meals ──
              SliverToBoxAdapter(
                child: Builder(
                  builder: (ctx) {
                    final allSlots = ['morning', 'noon', 'evening', 'night'];
                    final enabledSlots = allSlots
                        .where(
                          (s) =>
                              state.mess?.mealTimings[s]?['enabled'] == 'true',
                        )
                        .toList();

                    final now = DateTime.now();
                    const dayNames = [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday'
                    ];
                    final dayName = dayNames[now.weekday - 1];
                    final isSpecialDay = state.mess?.specialMealEnabled == true &&
                        (state.mess?.specialMealDays.contains(dayName) ?? false);
                    final cookedTodaySlots = (isSpecialDay && (state.mess?.specialMealCookedSlots.isNotEmpty ?? false))
                        ? enabledSlots.where((s) => state.mess!.specialMealCookedSlots.contains(s)).toList()
                        : enabledSlots;

                    final currentIdx = allSlots.indexOf(state.currentSlot);
                    final todayRemaining = state.currentSlot == 'closed'
                        ? <String>[]
                        : cookedTodaySlots
                            .where((s) => allSlots.indexOf(s) > currentIdx)
                            .toList();

                    final tomorrowSlots = enabledSlots;

                    final tomorrowDate = now.add(const Duration(days: 1));
                    final todayIso = now.toIso8601String().substring(0, 10);
                    final tomorrowIso = tomorrowDate.toIso8601String().substring(0, 10);

                    final items = [
                      for (final s in todayRemaining)
                        _UpcomingItem(
                          slot: s,
                          isToday: true,
                          menu: state.todayMenus[s],
                          label: '${s[0].toUpperCase()}${s.substring(1)}',
                          isSkipped: state.skippedUpcomingMeals.containsKey(
                            '${todayIso}_$s',
                          ),
                          isClosed: state.mess?.isSlotClosed(now, s) ?? false,
                        ),
                      for (final s in tomorrowSlots)
                        _UpcomingItem(
                          slot: s,
                          isToday: false,
                          menu: state.tomorrowMenus[s],
                          label: "Tomorrow's ${s[0].toUpperCase()}${s.substring(1)}",
                          isSkipped: state.skippedUpcomingMeals.containsKey(
                            '${tomorrowIso}_$s',
                          ),
                          isClosed: state.mess?.isSlotClosed(tomorrowDate, s) ?? false,
                        ),
                    ];

                    if (items.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Text(
                            'UPCOMING MEALS',
                            style: StudentTypography.overline(
                              fontSize: 12,
                              color: StudentColors.walnutMuted,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 168,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final item = items[i];
                              return _UpcomingMealCard(
                                slot: item.slot,
                                menu: item.menu,
                                state: state,
                                label: item.label,
                                isSkipped: item.isSkipped,
                                isClosed: item.isClosed,
                                onTap: () => _showMealBottomSheet(
                                  context,
                                  ref,
                                  state,
                                  item.slot,
                                  item.menu,
                                  isToday: item.isToday,
                                  isSkipped: item.isSkipped,
                                  isClosed: item.isClosed,
                                  date: item.isToday
                                      ? DateTime.now()
                                      : DateTime.now().add(const Duration(days: 1)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Current Meal Card (Warm Walnut Editorial Hero Card) ───────────────────────
  Widget _buildCurrentMealCard(
    BuildContext context,
    WidgetRef ref,
    StudentHomeState state,
  ) {
    if (state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: StudentColors.amber),
        ),
      );
    }

    if (state.mess?.isClosedNow == true) {
      return _MessClosureCard(mess: state.mess!);
    }

    if (state.currentSlot == 'closed') return _ClosedCard();

    // ── Choice-Aligned Slot Resolution ──
    // If student has a flexible meal plan, align hero card with student's active choice
    String slot = state.currentSlot;
    MenuModel? menu = state.currentMeal;
    bool isChosenMealActive = false;

    final plan = state.assignedPlan;
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);

    if (plan != null && plan.choiceGroups.isNotEmpty && state.mess != null) {
      for (final group in plan.choiceGroups) {
        if (group.availableMeals.contains(state.currentSlot) ||
            group.availableMeals.contains(state.nextSlot)) {
          final chosenSlot = state.student?.datePreferences[todayIso]?[group.groupId] ??
              state.student?.regularMealPreference[group.groupId] ??
              group.availableMeals.first;

          final timings = state.mess!.mealTimings[chosenSlot];
          final endStr = timings?['end'] ?? '23:59';
          final parts = endStr.split(':');
          final endH = int.tryParse(parts[0]) ?? 23;
          final endM = int.tryParse(parts.length > 1 ? parts[1] : '59') ?? 59;
          final now = DateTime.now();
          final currentMin = now.hour * 60 + now.minute;
          final endMin = endH * 60 + endM;

          if (currentMin <= endMin) {
            slot = chosenSlot;
            menu = state.todayMenus[chosenSlot];
            isChosenMealActive = true;
          }
          break;
        }
      }
    }

    final isExplicitlyPosted = menu != null &&
        menu.isPublished &&
        (menu.menuType == 'special' || menu.menuType == 'regular') &&
        menu.dishes.isNotEmpty;

    final now = DateTime.now();
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[now.weekday - 1];
    final isConfiguredFeastDay = state.mess?.specialMealEnabled == true &&
        (state.mess?.specialMealDays.contains(dayName) ?? false);
    final isFeastSlot = isConfiguredFeastDay && state.mess?.specialMealSlot == slot;
    final isSpecial = (isExplicitlyPosted && menu.menuType == 'special' && isConfiguredFeastDay) || isFeastSlot;
    final isRegularToday = isExplicitlyPosted && menu.menuType == 'regular';

    final slotDisplayName = slot == 'morning'
        ? 'Morning'
        : slot == 'noon'
            ? 'Noon'
            : slot == 'evening'
                ? 'Evening'
                : 'Night';

    final timings = state.mess?.mealTimings[slot];
    final startStr = timings?['start'] ?? '';
    final endStr = timings?['end'] ?? '';
    final timeRange = (startStr.isNotEmpty && endStr.isNotEmpty) ? '$startStr - $endStr' : '';

    final cutoff = isChosenMealActive && state.mess != null
        ? _cutoffForSlot(state.mess!, slot, true)
        : (state.timeLeftToCutoff ?? Duration.zero);
    final cutoffStr = _formatDuration(cutoff);
    final hasCutoff = cutoff != Duration.zero;

    String mealTitle;
    if (isSpecial) {
      final dishName = (menu != null && menu.dishes.isNotEmpty)
          ? menu.dishes.first.name
          : '$dayName Special Feast';
      mealTitle = '✨ $dishName';
    } else if (isRegularToday) {
      mealTitle = 'Today\'s $slotDisplayName Meal';
    } else {
      mealTitle = 'Homestyle Mess Meal';
    }

    return Container(
      decoration: BoxDecoration(
        color: StudentColors.walnut,
        borderRadius: BorderRadius.circular(24),
        boxShadow: StudentColors.elevated,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Background Slot Illustration with Smooth Gradient Blend ──
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 230,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.35, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/slot_$slot.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Subtle dark overlay to ensure 100% text contrast and readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      StudentColors.walnut,
                      StudentColors.walnut.withValues(alpha: 0.92),
                      StudentColors.walnut.withValues(alpha: 0.35),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Ambient Warm Glow Behind Content
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StudentColors.amber.withValues(alpha: 0.12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Tag & Timings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          isSpecial ? '✨ SPECIAL FEAST · ${slot.toUpperCase()}' : '${slot.toUpperCase()} MEAL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: StudentColors.amber,
                          ),
                        ),
                      ),
                      if (timeRange.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeRange,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Main Heading
                  Text(
                    mealTitle,
                    style: StudentTypography.serifHeading(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (isSpecial) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: StudentColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: StudentColors.amberPill),
                      ),
                      child: Text(
                        (menu != null && menu.dishes.isNotEmpty)
                            ? menu.dishes.map((d) => d.name).join(' • ')
                            : '✨ $dayName Royal Feast Today · Prepared fresh',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: StudentColors.amberLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Inset Action Card ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cutoff Status Row
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: hasCutoff ? StudentColors.amber : const Color(0xFFF87171),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hasCutoff
                                    ? 'Cancellation closes in: $cutoffStr'
                                    : 'Cutoff passed ($cutoffStr)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: hasCutoff
                                      ? StudentColors.amberLight
                                      : const Color(0xFFFCA5A5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons Row
                        if (!hasCutoff)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: StudentColors.amber),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Cutoff closed • Enjoy your meal!',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (state.hasSelfSkipped)
                          _UndoButton(ref: ref, slot: slot)
                        else
                          Row(
                            children: [
                              if ((state.mess?.allowMealSkipping ?? true) || state.hasSelfSkipped) ...[
                                Expanded(
                                  flex: 3,
                                  child: _SkipButton(
                                    ref: ref,
                                    mealSlot: slot,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                flex: ((state.mess?.allowMealSkipping ?? true) || state.hasSelfSkipped) ? 2 : 5,
                                child: _GuestButton(
                                  onAddGuest: () => _showAddGuestDialog(
                                    context,
                                    ref,
                                    state,
                                    slot,
                                    DateTime.now(),
                                  ),
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
          ],
        ),
      ),
    );
  }

  // ── Combined Middle Action Cards (Mess Menu & My Rating) ─────────────────────
  Widget _buildMiddleActionCards(
    BuildContext context,
    WidgetRef ref,
    StudentHomeState state,
  ) {
    final mess = state.mess;
    if (mess == null) return const SizedBox.shrink();

    final reviewsAsync = ref.watch(messReviewsProvider(mess.messId));
    final reviews = reviewsAsync.valueOrNull ?? [];
    final currentUid =
        state.student?.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final myReview = reviews.where((r) => r.studentId == currentUid).firstOrNull;

    return Row(
      children: [
        // ── Card 1: My Mess Menu ──
        Expanded(
          child: GestureDetector(
            onTap: () {
              ViewMessMenuSheet.show(
                context,
                mess: mess,
                initialMenus: state.todayMenus.values.toList(),
              );
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: StudentColors.borderSubtle),
                boxShadow: StudentColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: StudentColors.sageLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 18,
                          color: StudentColors.sageDark,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: StudentColors.walnutMuted,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My mess menu',
                        style: StudentTypography.bold(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Weekly dishes schedule',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: StudentColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Card 2: My Rating ──
        Expanded(
          child: GestureDetector(
            onTap: () {
              RateMessSheet.show(context, mess: mess, existingReview: myReview);
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: StudentColors.borderSubtle),
                boxShadow: StudentColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 22,
                            color: StudentColors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            myReview != null
                                ? myReview.rating.toStringAsFixed(1)
                                : 'Rate',
                            style: StudentTypography.serifNumeral(
                              fontSize: 20,
                              color: StudentColors.walnut,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: StudentColors.amberLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          myReview != null ? 'Edit' : 'Rate',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: StudentColors.amberText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My rating',
                        style: StudentTypography.bold(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myReview != null
                            ? (myReview.comment != null && myReview.comment!.isNotEmpty
                                ? myReview.comment!
                                : 'Reviewed this mess')
                            : 'Rate food & cleanliness',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: StudentColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Announcement dialog ──────────────────────────────────────────────────
  void _showAnnouncementDialog(BuildContext context, StudentHomeState state) {
    final anns = state.announcements;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: StudentColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Announcements',
                        style: StudentTypography.serifHeading(fontSize: 24),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Notices and updates from mess owner',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: StudentColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: StudentColors.walnut),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (anns.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StudentColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      'No new announcements right now.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: StudentColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: anns.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = anns[index];
                      final date = '${a.timestamp.day}/${a.timestamp.month}/${a.timestamp.year}';
                      final time =
                          '${a.timestamp.hour.toString().padLeft(2, '0')}:${a.timestamp.minute.toString().padLeft(2, '0')}';
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: StudentColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.campaign_rounded,
                                  size: 18,
                                  color: StudentColors.amber,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$date at $time',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: StudentColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a.message,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.4,
                                color: StudentColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.walnut,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upcoming meal bottom sheet ───────────────────────────────────────────
  void _showMealBottomSheet(
    BuildContext context,
    WidgetRef ref,
    StudentHomeState state,
    String slot,
    MenuModel? menu, {
    required bool isToday,
    required bool isSkipped,
    bool isClosed = false,
    DateTime? date,
  }) {
    final mealDate = date ?? DateTime.now();
    final icon = _slotIcons[slot] ?? '🍽';
    final slotName = '${slot[0].toUpperCase()}${slot.substring(1)}';
    final timings = state.mess?.mealTimings[slot];
    final timeRange = timings != null
        ? '${timings['start']} - ${timings['end']}'
        : '';
    final cutoff = (state.mess != null)
        ? _cutoffForSlot(state.mess!, slot, isToday)
        : Duration.zero;
    final cutoffStr = _formatDuration(cutoff);
    final hasCutoff = cutoff != Duration.zero;

    final isExplicitlyPosted = menu != null &&
        menu.isPublished &&
        (menu.menuType == 'special' || menu.menuType == 'regular') &&
        menu.dishes.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: StudentColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? slotName : "Tomorrow's $slotName",
                        style: StudentTypography.serifHeading(fontSize: 22),
                      ),
                      if (timeRange.isNotEmpty)
                        Text(
                          timeRange,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: StudentColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StudentColors.brickRedLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'CLOSED',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: StudentColors.brickRed,
                      ),
                    ),
                  )
                else if (isSkipped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StudentColors.brickRedLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'SKIPPED',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: StudentColors.brickRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Cutoff Info or Closed Notice
            if (isClosed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: StudentColors.brickRedLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StudentColors.brickRedBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.door_sliding_outlined,
                      size: 20,
                      color: StudentColors.brickRed,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This meal slot is closed by the mess administration. All closed slots are 100% credited back to your bill.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: StudentColors.brickRed,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StudentColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: hasCutoff ? StudentColors.amber : StudentColors.brickRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasCutoff
                          ? 'Cancellation closes in: $cutoffStr'
                          : 'Cutoff passed ($cutoffStr)',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: hasCutoff ? StudentColors.amberText : StudentColors.brickRed,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Dishes list
            Text(
              'PLANNED DISHES',
              style: StudentTypography.overline(fontSize: 11),
            ),
            const SizedBox(height: 8),
            if (isClosed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StudentColors.borderSubtle),
                ),
                child: Text(
                  'No dishes scheduled for this slot due to temporary mess closure.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: StudentColors.textSecondary,
                  ),
                ),
              )
            else if (isExplicitlyPosted)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: menu.dishes.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: StudentColors.borderSubtle),
                    ),
                    child: Text(
                      d.name,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: StudentColors.textDark,
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Text(
                'Standard seasonal menu for this slot.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: StudentColors.textSecondary,
                ),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            if (isClosed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.walnut,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Got It',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (hasCutoff)
              Row(
                children: [
                  if (!isSkipped)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(studentHomeProvider.notifier)
                              .skipMeal(slot, date: mealDate);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(
                          'Skip Meal',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.brickRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final dateIso = mealDate.toIso8601String().substring(0, 10);
                          final recordId =
                              state.skippedUpcomingMeals['${dateIso}_$slot'];
                          if (recordId != null) {
                            ref
                                .read(studentHomeProvider.notifier)
                                .undoSkip(recordId);
                          }
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text(
                          'Undo Skip',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.walnut,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddGuestDialog(
                          context,
                          ref,
                          state,
                          slot,
                          mealDate,
                        );
                      },
                      icon: const Icon(Icons.group_add_rounded, size: 16),
                      label: Text(
                        '+ Add Guest',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: StudentColors.walnut,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: StudentColors.walnut),
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
      ),
    );
  }

  // ── Add Guest Dialog (Bounded 1-10 with Stepper) ──────────────────────────
  void _showAddGuestDialog(
    BuildContext context,
    WidgetRef ref,
    StudentHomeState state,
    String slot,
    DateTime mealDate,
  ) {
    int count = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: StudentColors.canvas,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: StudentColors.amberLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    color: StudentColors.amberDark,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Add Guests',
                  style: StudentTypography.serifHeading(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'How many guests are joining you for $slot?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: StudentColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: StudentColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: count > 1 ? () => setState(() => count--) : null,
                        icon: Icon(
                          Icons.remove_circle_rounded,
                          color: count > 1 ? StudentColors.brickRed : StudentColors.walnutMuted,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Text(
                        '$count',
                        style: StudentTypography.serifNumeral(
                          fontSize: 32,
                          color: StudentColors.walnut,
                        ),
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        onPressed: count < 10 ? () => setState(() => count++) : null,
                        icon: Icon(
                          Icons.add_circle_rounded,
                          color: count < 10 ? StudentColors.sage : StudentColors.walnutMuted,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: StudentColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Bound guest count strictly between 1 and 10 for security
                          final safeCount = count.clamp(1, 10);
                          ref
                              .read(studentHomeProvider.notifier)
                              .addGuest(
                                slot,
                                state.mess?.perMealRate ?? 0.0,
                                date: mealDate,
                                count: safeCount,
                              );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$safeCount Guest(s) added successfully!'),
                              backgroundColor: StudentColors.sage,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper data class for upcoming items ─────────────────────────────────────
class _UpcomingItem {
  final String slot;
  final bool isToday;
  final MenuModel? menu;
  final String label;
  final bool isSkipped;
  final bool isClosed;

  _UpcomingItem({
    required this.slot,
    required this.isToday,
    required this.menu,
    required this.label,
    this.isSkipped = false,
    this.isClosed = false,
  });
}

// ─── Header Widget ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final StudentHomeState state;
  final String greeting;
  final VoidCallback onBellTap;
  final WidgetRef ref;

  const _Header({
    required this.state,
    required this.greeting,
    required this.onBellTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = state.student?.name ?? 'Student';
    final firstName = fullName.split(' ').first;
    final isClosed = state.currentSlot == 'closed';
    final hasAnnouncement = state.unseenAnnouncementsCount > 0;
    final photoUrl = state.student?.photoUrl;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Circle Avatar with Letter or Photo
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: StudentColors.walnut,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Greeting & Student Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: StudentTypography.overline(
                    fontSize: 11,
                    color: StudentColors.sageDark,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  firstName,
                  style: StudentTypography.serifHeading(fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Alerts Button Pill
          GestureDetector(
            onTap: onBellTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: StudentColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 16,
                    color: hasAnnouncement ? StudentColors.amberDark : StudentColors.walnut,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Alerts',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: StudentColors.walnut,
                    ),
                  ),
                  if (hasAnnouncement) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: StudentColors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Mess Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isClosed ? StudentColors.brickRedLight : StudentColors.sageLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isClosed ? StudentColors.brickRedBorder : StudentColors.sageBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isClosed ? StudentColors.brickRed : StudentColors.sage,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isClosed ? 'Closed' : 'Mess open',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isClosed ? StudentColors.brickRed : StudentColors.sageText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Meal Card ────────────────────────────────────────────────────────
class _UpcomingMealCard extends StatelessWidget {
  final String slot;
  final MenuModel? menu;
  final StudentHomeState state;
  final VoidCallback onTap;
  final String? label;
  final bool isSkipped;
  final bool isClosed;

  const _UpcomingMealCard({
    required this.slot,
    required this.menu,
    required this.state,
    required this.onTap,
    this.label,
    this.isSkipped = false,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    final slotName = label ?? '${slot[0].toUpperCase()}${slot.substring(1)}';
    final timings = state.mess?.mealTimings[slot];
    final timeRange = timings != null ? '${timings['start']} - ${timings['end']}' : '';
    final icon = _slotIcons[slot] ?? '🍽';

    final isExplicitlyPosted = menu != null &&
        menu!.isPublished &&
        (menu!.menuType == 'special' || menu!.menuType == 'regular') &&
        menu!.dishes.isNotEmpty;
    final isSpecial = isExplicitlyPosted && menu!.menuType == 'special';
    final dishesStr = isClosed
        ? 'Mess Closed • Auto Refunded'
        : (isExplicitlyPosted
            ? (isSpecial
                ? '✨ Special: ${menu!.dishes.map((d) => d.name).join(", ")}'
                : menu!.dishes.map((d) => d.name).join(", "))
            : 'Regular Homestyle Meal');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: StudentColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSpecial ? StudentColors.amber : StudentColors.borderSubtle,
            width: isSpecial ? 1.5 : 1.0,
          ),
          boxShadow: StudentColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    slotName,
                    style: StudentTypography.bold(
                      fontSize: 14,
                      color: (isSkipped || isClosed) ? StudentColors.walnutMuted : StudentColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: StudentColors.brickRedLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CLOSED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: StudentColors.brickRed,
                      ),
                    ),
                  )
                else if (isSkipped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: StudentColors.brickRedLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SKIPPED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: StudentColors.brickRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (timeRange.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: StudentColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeRange,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: StudentColors.textSecondary,
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Text(
              dishesStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isExplicitlyPosted ? FontWeight.w600 : FontWeight.w400,
                color: isSpecial
                    ? StudentColors.amberDark
                    : (isExplicitlyPosted
                        ? StudentColors.sageDark
                        : StudentColors.textSecondary),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Closed Card ─────────────────────────────────────────────────────────────
class _ClosedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text(
            'Mess Closed for Today',
            style: StudentTypography.serifHeading(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'All meals for today have concluded. Check tomorrow\'s schedule below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: StudentColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mess Closure Card (Shown in Current Meal spot when closed) ──────────────
const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
String _formatDateShort(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';
String _formatDateFull(DateTime d) => '${d.day} ${_monthsFull[d.month - 1]} ${d.year}';

class _MessClosureCard extends StatelessWidget {
  final MessModel mess;
  const _MessClosureCard({required this.mess});

  @override
  Widget build(BuildContext context) {
    final reopenDate = mess.temporarilyClosedUntil != null
        ? _formatDateFull(mess.temporarilyClosedUntil!)
        : 'soon';
    final reopenSlot = mess.closureEndSlot != null
        ? ' (${mess.closureEndSlot![0].toUpperCase()}${mess.closureEndSlot!.substring(1)})'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudentColors.brickRedBorder),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: StudentColors.brickRedLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.door_sliding_outlined,
              size: 32,
              color: StudentColors.brickRed,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mess Temporarily Closed',
            style: StudentTypography.serifHeading(
              fontSize: 20,
              color: StudentColors.brickRed,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Regular service resumes on $reopenDate$reopenSlot.\nAll closed meals will be 100% credited back to your bill.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: StudentColors.textDark,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (mess.closureReason != null && mess.closureReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: StudentColors.canvasWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StudentColors.borderSubtle),
              ),
              child: Text(
                'Note: "${mess.closureReason}"',
                style: GoogleFonts.inter(
                  color: StudentColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: StudentColors.sage,
              ),
              const SizedBox(width: 6),
              Text(
                'No manual skipping needed for closed meals',
                style: GoogleFonts.inter(
                  color: StudentColors.sageDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mess Closure Banner (Notification strip below header) ────────────────────
class _MessClosureBanner extends StatelessWidget {
  final MessModel mess;
  const _MessClosureBanner({required this.mess});

  @override
  Widget build(BuildContext context) {
    final isClosedNow = mess.isClosedNow;
    final bgColor = isClosedNow ? StudentColors.brickRedLight : StudentColors.amberLight;
    final borderColor = isClosedNow ? StudentColors.brickRedBorder : StudentColors.amberPill;
    final iconColor = isClosedNow ? StudentColors.brickRed : StudentColors.amberText;
    final title = isClosedNow ? 'Mess Currently Closed' : 'Scheduled Mess Closure';

    String detailText;
    if (isClosedNow) {
      final tillDate = mess.temporarilyClosedUntil != null
          ? _formatDateShort(mess.temporarilyClosedUntil!)
          : 'soon';
      final tillSlot = mess.closureEndSlot != null
          ? ' (${mess.closureEndSlot![0].toUpperCase()}${mess.closureEndSlot!.substring(1)})'
          : '';
      detailText = 'Service reopens on $tillDate$tillSlot. All closed slots are credited 100% to your bill.';
    } else {
      final startDate = mess.closureStartDate != null
          ? _formatDateShort(mess.closureStartDate!)
          : 'Upcoming';
      final startSlot = mess.closureStartSlot != null
          ? ' (${mess.closureStartSlot![0].toUpperCase()}${mess.closureStartSlot!.substring(1)})'
          : '';
      final endDate = mess.temporarilyClosedUntil != null
          ? _formatDateShort(mess.temporarilyClosedUntil!)
          : '';
      final endSlot = mess.closureEndSlot != null
          ? ' (${mess.closureEndSlot![0].toUpperCase()}${mess.closureEndSlot!.substring(1)})'
          : '';
      detailText = 'Closed from $startDate$startSlot to $endDate$endSlot. Auto deductions will be credited.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isClosedNow ? Icons.door_sliding_outlined : Icons.event_busy_rounded,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: StudentTypography.bold(
                        fontSize: 13.5,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isClosedNow ? 'ACTIVE' : 'UPCOMING',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  detailText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: StudentColors.textDark,
                    height: 1.35,
                  ),
                ),
                if (mess.closureReason != null && mess.closureReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: "${mess.closureReason}"',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: StudentColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── On Leave Banner ──────────────────────────────────────────────────────────
class _OnLeaveBanner extends StatelessWidget {
  final StudentHomeState state;
  final WidgetRef ref;
  const _OnLeaveBanner({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudentColors.sageLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudentColors.sageBorder),
      ),
      child: Row(
        children: [
          const Text('🌴', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are On Vacation / Leave',
                  style: StudentTypography.bold(
                    fontSize: 14,
                    color: StudentColors.sageText,
                  ),
                ),
                Text(
                  'Meals are auto-cancelled during your leave.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: StudentColors.sageDark,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(studentHomeProvider.notifier).cancelLeave();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Leave cancelled!'),
                  backgroundColor: StudentColors.sage,
                ),
              );
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: StudentColors.sageDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skip Button ─────────────────────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final WidgetRef ref;
  final String mealSlot;
  const _SkipButton({required this.ref, required this.mealSlot});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(studentHomeProvider.notifier).skipMeal(mealSlot);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal skipped!'),
            backgroundColor: StudentColors.brickRed,
          ),
        );
      },
      icon: const Icon(Icons.close_rounded, size: 16),
      label: Text(
        'Skip this meal',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: StudentColors.brickRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}

// ─── Guest Button ─────────────────────────────────────────────────────────────
class _GuestButton extends StatelessWidget {
  final VoidCallback onAddGuest;
  const _GuestButton({required this.onAddGuest});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onAddGuest,
      icon: const Icon(Icons.group_add_rounded, size: 16, color: Colors.white),
      label: Text(
        '+ Add guests',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── Undo Skip Button ─────────────────────────────────────────────────────────
class _UndoButton extends StatefulWidget {
  final WidgetRef ref;
  final String slot;
  const _UndoButton({required this.ref, required this.slot});

  @override
  State<_UndoButton> createState() => _UndoButtonState();
}

class _UndoButtonState extends State<_UndoButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                try {
                  final state = widget.ref.read(studentHomeProvider);
                  final todayIso = DateTime.now().toIso8601String().substring(0, 10);
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? state.student?.studentId;
                  final recordId = state.skippedUpcomingMeals['${todayIso}_${widget.slot}'] ??
                      state.skippedUpcomingMeals['${todayIso}_${state.currentSlot}'] ??
                      (uid != null ? '${uid}_${widget.slot}_$todayIso' : null);

                  if (recordId == null) {
                    throw Exception('Could not find skipped meal record.');
                  }

                  await widget.ref.read(studentHomeProvider.notifier).undoSkip(recordId);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meal skip cancelled! You can now enjoy your meal.'),
                        backgroundColor: StudentColors.sageGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not undo skip: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: StudentColors.brickRed,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: StudentColors.amber,
                ),
              )
            : const Icon(Icons.undo_rounded, size: 18, color: StudentColors.amber),
        label: Text(
          _isLoading ? 'Cancelling skip...' : 'Undo Skip',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: StudentColors.amber,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: StudentColors.amber),
        ),
      ),
    );
  }
}

// ─── Choice Groups Section (Flexi Meal Picker) ─────────────────────────────────
class _ChoiceGroupsSection extends ConsumerWidget {
  final StudentHomeState state;
  final WidgetRef ref;

  const _ChoiceGroupsSection({required this.state, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = state.assignedPlan;
    final mess = state.mess;
    if (plan == null || mess == null || plan.choiceGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final todayIso = DateTime.now().toIso8601String().substring(0, 10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S CHOICE",
                style: StudentTypography.overline(
                  fontSize: 12,
                  color: StudentColors.walnutMuted,
                  letterSpacing: 1.4,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (plan.choiceGroups.isNotEmpty) {
                    _showDefaultPreferenceModal(context, ref, plan.choiceGroups.first);
                  }
                },
                child: Text(
                  'Set daily default >',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: StudentColors.sageDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...plan.choiceGroups.map((group) {
            final cutoff = CutoffHelper.getChoiceGroupCutoffTime(DateTime.now(), group, mess);
            final isCutoffPassed = DateTime.now().isAfter(cutoff);
            final diff = cutoff.difference(DateTime.now());

            final chosenSlot = state.student?.datePreferences[todayIso]?[group.groupId] ??
                state.student?.regularMealPreference[group.groupId] ??
                group.availableMeals.first;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: StudentColors.borderSubtle),
                boxShadow: StudentColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name.isNotEmpty ? group.name : 'Flexi Plan Choice',
                          style: StudentTypography.bold(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCutoffPassed
                              ? StudentColors.brickRedLight
                              : StudentColors.amberLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isCutoffPassed
                              ? '🔒 Locked'
                              : '🔒 Closes in ${_formatDuration(diff)}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCutoffPassed
                                ? StudentColors.brickRed
                                : StudentColors.amberText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick any 1 meal for today:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: StudentColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Meal Choice Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.availableMeals.map((slot) {
                      final isSelected = chosenSlot == slot;
                      final slotLabel = '${slot[0].toUpperCase()}${slot.substring(1)}';

                      return GestureDetector(
                        onTap: () {
                          if (isSelected) return;
                          if (isCutoffPassed) {
                            _showCutoffPassedChoiceModal(context, ref, group, slot);
                          } else {
                            ref
                                .read(studentHomeProvider.notifier)
                                .selectChoiceMeal(
                                  group.groupId,
                                  slot,
                                );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? StudentColors.walnut : StudentColors.sageLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? StudentColors.walnut
                                  : StudentColors.sageBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                slotLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? Colors.white : StudentColors.sageText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Passed';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}hr ${m}m' : '${m}m';
  }

  void _showCutoffPassedChoiceModal(
    BuildContext context,
    WidgetRef ref,
    ChoiceGroupModel group,
    String targetSlot,
  ) {
    final slotLabel = '${targetSlot[0].toUpperCase()}${targetSlot.substring(1)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: StudentColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      color: StudentColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: StudentColors.amberLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: StudentColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: StudentColors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cutoff Closed for Today',
                            style: StudentTypography.serifHeading(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Today\'s cutoff time for $slotLabel meal has passed.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: StudentColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StudentColors.borderSubtle),
                  ),
                  child: Text(
                    'You cannot change today\'s meal after cutoff. Would you like to set $slotLabel as your daily preference starting from tomorrow?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: StudentColors.walnut,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: StudentColors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Keep Current',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: StudentColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.sage,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref
                              .read(studentHomeProvider.notifier)
                              .saveRegularPreference(group.groupId, targetSlot);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$slotLabel set as your daily choice from tomorrow!'),
                                backgroundColor: StudentColors.sage,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Set for Tomorrow',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDefaultPreferenceModal(
    BuildContext context,
    WidgetRef ref,
    ChoiceGroupModel group,
  ) {
    final studentState = ref.read(studentHomeProvider);
    final currentDefault =
        studentState.student?.regularMealPreference[group.groupId] ?? group.availableMeals.first;
    String selectedSlot = currentDefault;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: StudentColors.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      'Set Daily Default Meal',
                      style: StudentTypography.serifHeading(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automatically selected for you for all upcoming days',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: StudentColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...group.availableMeals.map((slot) {
                      final isSelected = selectedSlot == slot;
                      final slotLabel = '${slot[0].toUpperCase()}${slot.substring(1)}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setModalState(() => selectedSlot = slot),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? StudentColors.walnut
                                    : StudentColors.borderSubtle,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? StudentColors.walnut
                                      : StudentColors.walnutMuted,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  slotLabel,
                                  style: StudentTypography.bold(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final mess = ref.read(studentHomeProvider).mess;
                          final isCutoffPassed = mess != null &&
                              CutoffHelper.isChoiceGroupCutoffPassed(DateTime.now(), group, mess);

                          await ref
                              .read(studentHomeProvider.notifier)
                              .saveRegularPreference(
                                group.groupId,
                                selectedSlot,
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCutoffPassed
                                      ? 'Default preference saved! Applies from tomorrow.'
                                      : 'Default preference saved and applied for today!',
                                ),
                                backgroundColor: StudentColors.sage,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.walnut,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Save Default Choice',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
