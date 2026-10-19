import '../../../services/localization_service.dart';
import '../../../viewmodels/cutoff_helper.dart';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';
import 'widgets/view_mess_menu_sheet.dart';
import 'widgets/rate_mess_sheet.dart';

// ─── Slot Illustration Banners ──────────────────────────────────────────────
const _slotBannerAssets = {
  'morning': 'assets/images/slot_morning.png',
  'noon': 'assets/images/slot_noon.png',
  'evening': 'assets/images/slot_evening.png',
  'night': 'assets/images/slot_night.png',
};

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
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentHomeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF22C55E),
          onRefresh: () => ref.read(studentHomeProvider.notifier).load(),
          child: CustomScrollView(
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

              // ── On-leave banner ──
              if (state.activeLeave != null)
                SliverToBoxAdapter(
                  child: _OnLeaveBanner(state: state, ref: ref),
                ),

              // ── Meal Choices (If student has a flexible plan) ──
              SliverToBoxAdapter(
                child: _ChoiceGroupsSection(state: state, ref: ref),
              ),

              // ── Current Meal ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'Current Meal',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _buildCurrentMealCard(context, ref, state),
                ),
              ),

              // ── My Mess Menu Button Card ──
              if (state.mess != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildMessMenuButtonCard(context, state),
                  ),
                ),

              // ── Rate My Mess Card ──
              if (state.mess != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildRateMessCard(context, ref, state),
                  ),
                ),

              // ── Upcoming Meals ──
              SliverToBoxAdapter(
                child: Builder(
                  builder: (ctx) {
                    // Build combined upcoming: today's remaining + tomorrow's enabled
                    final allSlots = ['morning', 'noon', 'evening', 'night'];
                    final enabledSlots = allSlots
                        .where(
                          (s) =>
                              state.mess?.mealTimings[s]?['enabled'] == 'true',
                        )
                        .toList();

                    // Today's remaining (after current slot)
                    final currentIdx = allSlots.indexOf(state.currentSlot);
                    final todayRemaining = state.currentSlot == 'closed'
                        ? <String>[]
                        : enabledSlots
                              .where((s) => allSlots.indexOf(s) > currentIdx)
                              .toList();

                    // Tomorrow's slots
                    final tomorrowSlots = enabledSlots;

                    final todayIso = DateTime.now().toIso8601String().substring(
                      0,
                      10,
                    );
                    final tomorrowIso = DateTime.now()
                        .add(const Duration(days: 1))
                        .toIso8601String()
                        .substring(0, 10);

                    // Combine: today remaining then tomorrow
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
                        ),
                      for (final s in tomorrowSlots)
                        _UpcomingItem(
                          slot: s,
                          isToday: false,
                          menu: state.tomorrowMenus[s],
                          label:
                              "Tomorrow's ${s[0].toUpperCase()}${s.substring(1)}",
                          isSkipped: state.skippedUpcomingMeals.containsKey(
                            '${tomorrowIso}_$s',
                          ),
                        ),
                    ];

                    if (items.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                          child: Text(
                            'Upcoming Meals',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 155, // Increased height to prevent bottom overflow
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
                                onTap: () => _showMealBottomSheet(
                                  context,
                                  ref,
                                  state,
                                  item.slot,
                                  item.menu,
                                  isToday: item.isToday,
                                  isSkipped: item.isSkipped,
                                  date: item.isToday
                                      ? DateTime.now()
                                      : DateTime.now().add(
                                          const Duration(days: 1),
                                        ),
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

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Current Meal Card ────────────────────────────────────────────────────
  Widget _buildCurrentMealCard(
    BuildContext context,
    WidgetRef ref,
    StudentHomeState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );
    }

    if (state.currentSlot == 'closed') return _ClosedCard();

    final slot = state.currentSlot;
    final menu = state.currentMeal;

    final isExplicitlyPosted = menu != null &&
        menu.isPublished &&
        (menu.menuType == 'special' || menu.menuType == 'regular') &&
        menu.dishes.isNotEmpty;
    final isSpecial = isExplicitlyPosted && menu.menuType == 'special';
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

    final cutoff = state.timeLeftToCutoff ?? Duration.zero;
    final cutoffStr = _formatDuration(cutoff);
    final hasCutoff = cutoff != Duration.zero;
    final bannerAsset = _slotBannerAssets[slot] ?? _slotBannerAssets['noon']!;
    final isNight = slot == 'night';

    Color slotAccentColor;
    Color slotBgBadgeColor;
    IconData slotIconData;
    switch (slot) {
      case 'morning':
        slotAccentColor = const Color(0xFFB45309);
        slotBgBadgeColor = const Color(0xFFFEF3C7);
        slotIconData = Icons.wb_sunny_rounded;
        break;
      case 'noon':
        slotAccentColor = const Color(0xFF0284C7);
        slotBgBadgeColor = const Color(0xFFE0F2FE);
        slotIconData = Icons.wb_sunny_rounded;
        break;
      case 'evening':
        slotAccentColor = const Color(0xFFEA580C);
        slotBgBadgeColor = const Color(0xFFFFEDD5);
        slotIconData = Icons.wb_twilight_rounded;
        break;
      case 'night':
      default:
        slotAccentColor = const Color(0xFF93C5FD);
        slotBgBadgeColor = const Color(0xFF1E293B);
        slotIconData = Icons.nightlight_round;
        break;
    }

    String mealTitle;
    if (isSpecial) {
      mealTitle = '✨ ${menu.dishes.isNotEmpty ? menu.dishes.first.name : "Special Meal"}';
    } else if (isRegularToday) {
      mealTitle = 'Today\'s $slotDisplayName Meal';
    } else {
      mealTitle = 'Homestyle Mess Meal';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isNight ? Colors.white12 : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Slot Illustration Banner Background ──
            Positioned.fill(
              child: Image.asset(
                bannerAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, __, ___) => Container(
                  color: isNight ? const Color(0xFF19203A) : const Color(0xFFF8FAFC),
                ),
              ),
            ),

            // ── Foreground Content ──
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner Row (Image 3 layout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Themed Icon Badge
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: slotBgBadgeColor,
                          borderRadius: BorderRadius.circular(14),
                          border: isNight ? Border.all(color: Colors.white24) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            slotIconData,
                            color: isNight ? const Color(0xFFFCD34D) : slotAccentColor,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text Info Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                                color: slotAccentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mealTitle,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white : const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (timeRange.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isNight ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeRange,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isNight ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            // Live Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isNight
                                    ? Colors.white.withValues(alpha: 0.14)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                                border: isNight
                                    ? Border.all(color: Colors.white24)
                                    : Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_active_rounded,
                                    size: 12,
                                    color: isNight ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Serving now',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isNight ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Menu > Button (Top Right)
                      if (state.mess != null)
                        GestureDetector(
                          onTap: () {
                            ViewMessMenuSheet.show(
                              context,
                              mess: state.mess!,
                              initialMenus: state.todayMenus.values.toList(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isNight ? Colors.white.withValues(alpha: 0.18) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isNight ? Colors.white30 : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: isNight
                                  ? null
                                  : const [
                                      BoxShadow(
                                        color: Color(0x0E000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Menu',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isNight ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 15,
                                  color: isNight ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom Action & Cutoff Panel
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNight
                        ? const Color(0xFF0F172A).withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNight ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timer row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Cancellation closes in: ',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isNight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                          Text(
                            cutoffStr,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: hasCutoff
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: hasCutoff
                                ? const Color(0xFFD97706)
                                : const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Action buttons
                      if (!hasCutoff)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isNight ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isNight ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Meal concluded • Rate dishes in Mess Menu',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isNight ? Colors.white : const Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (state.hasSelfSkipped)
                        _UndoButton(ref: ref)
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
          ],
        ),
      ),
    );
  }

  // ── My Mess Menu Button Card ─────────────────────────────────────────────
  Widget _buildMessMenuButtonCard(BuildContext context, StudentHomeState state) {
    final mess = state.mess;
    if (mess == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        ViewMessMenuSheet.show(
          context,
          mess: mess,
          initialMenus: state.todayMenus.values.toList(),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📋', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Mess Menu (मेन्यू देखें)',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Standard breakfast, lunch & dinner offerings',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rate My Mess Card ────────────────────────────────────────────────────
  Widget _buildRateMessCard(
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
    final myReview =
        reviews.where((r) => r.studentId == currentUid).firstOrNull;

    final isHi = ref.watch(localizationProvider) == 'hi';

    return InkWell(
      onTap: () {
        RateMessSheet.show(context, mess: mess, existingReview: myReview);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: myReview != null
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE5E7EB),
          ),
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
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    myReview != null
                        ? (isHi
                            ? 'मेरी रेटिंग: ⭐ ${myReview.rating.toStringAsFixed(1)}'
                            : 'My Rating: ⭐ ${myReview.rating.toStringAsFixed(1)}')
                        : (isHi
                            ? 'मेस को रेटिंग दें (Rate Mess)'
                            : 'Rate & Review This Mess'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    myReview != null
                        ? (isHi
                            ? 'रिव्यू अपडेट या एडिट करने के लिए टैप करें'
                            : 'Tap to edit or update your review')
                        : (isHi
                            ? 'खाने का स्वाद, सर्विस व सफाई पर फीडबैक दें'
                            : 'Rate food quality, cleanliness & service'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    myReview != null ? 'Edit' : 'Rate',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFFD97706),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Announcement dialog ──────────────────────────────────────────────────
  void _showAnnouncementDialog(BuildContext context, StudentHomeState state) {
    final anns = state.announcements;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📢', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Announcements',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: anns.isEmpty
              ? Text(
                  'No new announcements from your mess owner.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4B5563),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: anns.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final a = anns[index];
                    final date = '${a.timestamp.day}/${a.timestamp.month}/${a.timestamp.year}';
                    final time = '${a.timestamp.hour.toString().padLeft(2, '0')}:${a.timestamp.minute.toString().padLeft(2, '0')}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.message,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$date at $time',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
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
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slotName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (timeRange.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeRange,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isExplicitlyPosted) ...[
              if (menu.menuType == 'special')
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '✨ SPECIAL MEAL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              Text(
                menu.dishes.map((d) => d.name).join(', '),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF374151),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                'Regular Mess Meal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 6),
              if (state.mess != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    ViewMessMenuSheet.show(
                      context,
                      mess: state.mess!,
                      initialMenus: state.todayMenus.values.toList(),
                    );
                  },
                  child: Text(
                    'View regular offerings in Mess Menu ➔',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            // Timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Cancellation closes in: ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  Text(
                    cutoffStr,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasCutoff
                          ? const Color(0xFFFFB347)
                          : const Color(0xFFF87171),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Color(0xFF92400E),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (hasCutoff)
              Row(
                children: [
                  if ((state.mess?.allowMealSkipping ?? true) || isSkipped) ...[
                    Expanded(
                      flex: 3,
                      child: isSkipped
                          ? ElevatedButton(
                              onPressed: () {
                                final mealIso = mealDate
                                    .toIso8601String()
                                    .substring(0, 10);
                                final recordId = state
                                    .skippedUpcomingMeals['${mealIso}_$slot'];
                                if (recordId != null) {
                                  ref
                                      .read(studentHomeProvider.notifier)
                                      .undoSkip(recordId);
                                }
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$slotName skip undone!'),
                                    backgroundColor: const Color(0xFF22C55E),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEE2E2),
                                foregroundColor: const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Undo Skip',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(studentHomeProvider.notifier)
                                    .skipMeal(slot, date: mealDate);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$slotName skipped!'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Skip This Meal',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: ((state.mess?.allowMealSkipping ?? true) || isSkipped) ? 2 : 5,
                    child: OutlinedButton(
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF22C55E),
                        side: const BorderSide(color: Color(0xFF22C55E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '+ Guest(s)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.star_outline_rounded,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                  label: Text(
                    'Rate This Meal',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add Guests',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How many guests are joining you?',
                style: GoogleFonts.inter(color: const Color(0xFF4B5563)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: count > 1 ? () => setState(() => count--) : null,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: count < 10
                        ? () => setState(() => count++)
                        : null,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF22C55E),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(studentHomeProvider.notifier)
                    .addGuest(
                      slot,
                      state.mess?.perMealRate ?? 0.0,
                      date: mealDate,
                      count: count,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count Guest(s) added successfully!'),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper data class for upcoming items ────────────────────────────────────
class _UpcomingItem {
  final String slot;
  final bool isToday;
  final MenuModel? menu;
  final String label;
  final bool isSkipped;
  const _UpcomingItem({
    required this.slot,
    required this.isToday,
    required this.menu,
    required this.label,
    required this.isSkipped,
  });
}

// ─── Header ─────────────────────────────────────────────────────────────────
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
    final name = state.student?.name.split(' ').first ?? 'Student';
    final isClosed = state.currentSlot == 'closed';
    final hasAnnouncement = state.unseenAnnouncementsCount > 0;
    final photoUrl = state.student?.photoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22C55E), width: 2.5),
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          // MESS OPEN badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isClosed
                  ? const Color(0xFFF3F4F6)
                  : const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isClosed ? 'MESS' : 'MESS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isClosed ? const Color(0xFF6B7280) : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isClosed ? 'CLOSED' : 'OPEN',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isClosed ? const Color(0xFF6B7280) : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Bell icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF374151),
                  size: 26,
                ),
                onPressed: onBellTap,
              ),
              if (hasAnnouncement)
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${state.unseenAnnouncementsCount}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1,
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

  Widget _defaultAvatar() => Container(
    color: const Color(0xFFDCFCE7),
    child: const Icon(Icons.person, color: Color(0xFF16A34A), size: 32),
  );
}

// ─── Upcoming Meal Card ──────────────────────────────────────────────────────
class _UpcomingMealCard extends StatelessWidget {
  final String slot;
  final MenuModel? menu;
  final StudentHomeState state;
  final VoidCallback onTap;
  final String? label;
  final bool isSkipped;

  const _UpcomingMealCard({
    required this.slot,
    required this.menu,
    required this.state,
    required this.onTap,
    this.label,
    this.isSkipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final slotName = label ?? '${slot[0].toUpperCase()}${slot.substring(1)}';
    final timings = state.mess?.mealTimings[slot];
    final timeRange = timings != null
        ? '${timings['start']} - ${timings['end']}'
        : '';
    final icon = _slotIcons[slot] ?? '🍽';

    final isExplicitlyPosted = menu != null &&
        menu!.isPublished &&
        (menu!.menuType == 'special' || menu!.menuType == 'regular') &&
        menu!.dishes.isNotEmpty;
    final isSpecial = isExplicitlyPosted && menu!.menuType == 'special';
    final dishesStr = isExplicitlyPosted
        ? (isSpecial
            ? '✨ Special: ${menu!.dishes.map((d) => d.name).join(", ")}'
            : 'Today: ${menu!.dishes.map((d) => d.name).join(", ")}')
        : 'Regular Mess Meal';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isSpecial
              ? Border.all(color: const Color(0xFFFDE68A), width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    slotName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: isSkipped ? TextDecoration.lineThrough : null,
                      color: isSkipped
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
                if (isSkipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SKIPPED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                    color: Color(0xFF22C55E),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            if (timeRange.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 12,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeRange,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              dishesStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isExplicitlyPosted ? FontWeight.w600 : FontWeight.normal,
                color: isSpecial
                    ? const Color(0xFFD97706)
                    : (isExplicitlyPosted
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF6B7280)),
                fontStyle: isExplicitlyPosted ? FontStyle.normal : FontStyle.italic,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 48)),
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
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
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
                  'You are On Leave',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF166534),
                  ),
                ),
                Text(
                  'Meals are auto-cancelled.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF15803D),
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
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
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
    return ElevatedButton(
      onPressed: () {
        ref.read(studentHomeProvider.notifier).skipMeal(mealSlot);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal skipped!'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        'Skip This Meal',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Guest Button ─────────────────────────────────────────────────────────────
class _GuestButton extends StatelessWidget {
  final VoidCallback onAddGuest;
  const _GuestButton({
    required this.onAddGuest,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onAddGuest,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF22C55E),
        side: const BorderSide(color: Color(0xFF4ADE80)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        '+1 Guest',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF22C55E),
        ),
      ),
    );
  }
}

// ─── Undo Skip Button ─────────────────────────────────────────────────────────
class _UndoButton extends StatelessWidget {
  final WidgetRef ref;
  const _UndoButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final state = ref.read(studentHomeProvider);
          final todayIso = DateTime.now().toIso8601String().substring(0, 10);
          final recordId =
              state.skippedUpcomingMeals['${todayIso}_${state.currentSlot}'];
          if (recordId != null) {
            ref.read(studentHomeProvider.notifier).undoSkip(recordId);
          }
        },
        icon: const Icon(Icons.undo_rounded, size: 18, color: Colors.white),
        label: Text(
          'Undo Skip',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.white54),
        ),
      ),
    );
  }
}




// ─── Choice Groups Section (Balanced 3D Card) ─────────────────────────────────
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Text(
                ref.watch(localizationProvider) == 'hi' ? 'आज का चुनाव' : "Today's Choice",
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
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
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C0F172A),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Color(0x040F172A),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Group Title & Cutoff Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Builder(
                            builder: (context) {
                              final isHi = ref.watch(localizationProvider) == 'hi';
                              final mealsList = group.availableMeals.map((s) {
                                if (isHi) {
                                  return s == 'morning' ? 'नाश्ता' : (s == 'noon' ? 'दोपहर खाना' : (s == 'evening' ? 'शाम नाश्ता' : 'रात खाना'));
                                } else {
                                  return s == 'morning' ? 'Breakfast' : (s == 'noon' ? 'Lunch' : (s == 'evening' ? 'Snacks' : 'Dinner'));
                                }
                              }).join(isHi ? ' या ' : ' or ');
                              final label = isHi ? '$mealsList (कोई 1)' : 'Choose 1: $mealsList';
                              return Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCutoffPassed ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCutoffPassed ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCutoffPassed ? Icons.lock_outline_rounded : Icons.timer_outlined,
                              size: 13,
                              color: isCutoffPassed ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCutoffPassed
                                  ? (ref.watch(localizationProvider) == 'hi' ? 'समय समाप्त' : 'Locked')
                                  : '${diff.inHours > 0 ? '${diff.inHours}h ' : ''}${diff.inMinutes.remainder(60)}m ' + (ref.watch(localizationProvider) == 'hi' ? 'बाकी' : 'left'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCutoffPassed ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref.watch(localizationProvider) == 'hi'
                        ? 'आज आप नाश्ता लेंगे या दोपहर का खाना?'
                        : 'Which meal would you like today?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Alternative Choice Interactive Tiles (Balanced 3D)
                  Row(
                    children: group.availableMeals.map((slot) {
                      final isSelected = chosenSlot == slot;
                      final isOwnerClosed = state.skippedUpcomingMeals.containsKey('${todayIso}_$slot') ||
                          (state.mess?.temporarilyClosedUntil != null &&
                              DateTime.now().isBefore(state.mess!.temporarilyClosedUntil!));

                      final isHi = ref.watch(localizationProvider) == 'hi';
                      final slotTitle = isHi
                          ? (slot == 'morning' ? '🌅 सुबह नाश्ता' : (slot == 'noon' ? '☀️ दोपहर लंच' : (slot == 'evening' ? '☕ शाम नाश्ता' : '🌙 रात डिनर')))
                          : (slot == 'morning' ? '🌅 Breakfast' : (slot == 'noon' ? '☀️ Lunch' : (slot == 'evening' ? '☕ Snacks' : '🌙 Dinner')));

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () async {
                              if (isCutoffPassed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ref.read(localizationProvider) == 'hi'
                                          ? 'आज का समय समाप्त हो चुका है। आगे के दिनों का डिफ़ॉल्ट बदलने के लिए नीचे "डिफ़ॉल्ट बदलें" पर टैप करें।'
                                          : "Today's cutoff has passed. Tap 'Change default' below to update upcoming days.",
                                    ),
                                    backgroundColor: const Color(0xFFEF4444),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              if (isOwnerClosed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ref.watch(localizationProvider) == 'hi' ? '$slotTitle आज मेस द्वारा बंद है। कृपया दूसरा विकल्प चुनें।' : '$slotTitle is closed by mess today. Please pick another option.'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                                return;
                              }
                              try {
                                await ref.read(studentHomeProvider.notifier).selectChoiceMeal(
                                  group.groupId,
                                  slot,
                                  date: DateTime.now(),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ref.watch(localizationProvider) == 'hi' ? 'आज के लिए $slotTitle चुना गया! ✓' : '$slotTitle selected for today! ✓'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ref.watch(localizationProvider) == 'hi' ? 'चुनाव सुरक्षित नहीं हो सका: $e' : 'Failed to save choice: $e'),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : (isOwnerClosed ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : (isOwnerClosed ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 2 : 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        const BoxShadow(
                                          color: Color(0x3310B981),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    slotTitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isOwnerClosed ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isOwnerClosed)
                                    Text(
                                      isHi ? 'आज बंद है' : 'Closed today',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    )
                                  else if (isSelected)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          isHi ? 'चुना हुआ' : 'Selected',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      isHi ? 'चुनने के लिए टैप करें' : 'Tap to select',
                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Fixed Meals Reminder Pill (Pukka Khana)
                  if (plan.fixedMeals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final isHi = ref.watch(localizationProvider) == 'hi';
                                final mealsText = plan.fixedMeals.map((s) {
                                  if (isHi) {
                                    return s == 'night' ? 'रात का खाना' : (s == 'noon' ? 'दोपहर का खाना' : 'नाश्ता');
                                  } else {
                                    return s == 'night' ? 'Dinner' : (s == 'noon' ? 'Lunch' : 'Breakfast');
                                  }
                                }).join(', ');
                                return Text(
                                  isHi ? 'पक्का खाना: $mealsText रोज़ाना पक्का मिलेगा।' : 'Fixed Meal: $mealsText is served every day.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF065F46),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  // Current Default Display & Change Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) {
                          final studentState = ref.watch(studentHomeProvider);
                          final currentDef = studentState.student?.regularMealPreference[group.groupId] ??
                              group.availableMeals.first;
                          final isHi = ref.watch(localizationProvider) == 'hi';
                          final defName = isHi
                              ? (currentDef == 'morning'
                                  ? 'नाश्ता'
                                  : (currentDef == 'noon'
                                      ? 'लंच'
                                      : (currentDef == 'evening' ? 'शाम नाश्ता' : 'डिनर')))
                              : (currentDef == 'morning'
                                  ? 'Breakfast'
                                  : (currentDef == 'noon'
                                      ? 'Lunch'
                                      : (currentDef == 'evening' ? 'Snacks' : 'Dinner')));
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_added_rounded, size: 13, color: Color(0xFF475569)),
                                const SizedBox(width: 5),
                                Text(
                                  isHi ? 'डिफ़ॉल्ट: $defName' : 'Default: $defName',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: () => _showDefaultPreferenceModal(context, ref, group),
                        icon: const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          ref.watch(localizationProvider) == 'hi' ? 'डिफ़ॉल्ट बदलें' : 'Change default',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDefaultPreferenceModal(
    BuildContext context,
    WidgetRef ref,
    ChoiceGroupModel group,
  ) {
    final studentState = ref.read(studentHomeProvider);
    final currentDefault = studentState.student?.regularMealPreference[group.groupId] ??
        group.availableMeals.first;
    String selectedSlot = currentDefault;
    final isHi = ref.read(localizationProvider) == 'hi';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bookmark_added_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHi ? 'रोज़ का डिफ़ॉल्ट भोजन' : 'Set Daily Default Meal',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isHi
                                    ? 'आगे के सभी दिनों के लिए अपने आप यही भोजन चुना जाएगा'
                                    : 'Automatically selected for you for upcoming days',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ...group.availableMeals.map((slot) {
                      final isSelected = selectedSlot == slot;
                      final isCurrentlySaved = currentDefault == slot;
                      final slotLabel = isHi
                          ? (slot == 'morning'
                              ? '🌅 सुबह का नाश्ता (Breakfast)'
                              : (slot == 'noon'
                                  ? '☀️ दोपहर का खाना (Lunch)'
                                  : (slot == 'evening'
                                      ? '☕ शाम का नाश्ता (Snacks)'
                                      : '🌙 रात का खाना (Dinner)')))
                          : (slot == 'morning'
                              ? '🌅 Breakfast'
                              : (slot == 'noon'
                                  ? '☀️ Lunch'
                                  : (slot == 'evening'
                                      ? '☕ Evening Snacks'
                                      : '🌙 Dinner')));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setModalState(() {
                              selectedSlot = slot;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slotLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight:
                                              isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      if (isCurrentlySaved)
                                        Text(
                                          isHi
                                              ? '✓ वर्तमान में डिफ़ॉल्ट है'
                                              : '✓ Currently your default',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF059669),
                                          ),
                                        ),
                                    ],
                                  ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            await ref
                                .read(studentHomeProvider.notifier)
                                .saveRegularPreference(group.groupId, selectedSlot);
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              final chosenName = isHi
                                  ? (selectedSlot == 'morning'
                                      ? 'सुबह का नाश्ता'
                                      : (selectedSlot == 'noon'
                                          ? 'दोपहर का लंच'
                                          : (selectedSlot == 'evening'
                                              ? 'शाम का नाश्ता'
                                              : 'रात का डिनर')))
                                  : (selectedSlot == 'morning'
                                      ? 'Breakfast'
                                      : (selectedSlot == 'noon'
                                          ? 'Lunch'
                                          : (selectedSlot == 'evening'
                                              ? 'Snacks'
                                              : 'Dinner')));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isHi
                                        ? 'कल से आगे के लिए रोज़ का डिफ़ॉल्ट $chosenName सेट हो गया! ✓'
                                        : '$chosenName set as your daily default from tomorrow! ✓',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isHi
                                        ? 'डिफ़ॉल्ट सेट करने में त्रुटि: $e'
                                        : 'Failed to set default: $e',
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          isHi ? 'डिफ़ॉल्ट के रूप में सेट करें' : 'Save as Daily Default',
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
