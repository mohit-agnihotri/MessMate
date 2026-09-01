import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

// ─── Background images per slot ─────────────────────────────────────────────
const _bgImages = {
  'morning': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000&auto=format&fit=crop',
  'noon': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=1000&auto=format&fit=crop',
  'evening': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?q=80&w=1000&auto=format&fit=crop',
  'night': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000&auto=format&fit=crop',
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
                  onBellTap: () => _showAnnouncementDialog(context, state),
                ),
              ),

              // ── On-leave banner ──
              if (state.activeLeave != null)
                SliverToBoxAdapter(
                  child: _OnLeaveBanner(state: state, ref: ref),
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
                          height: 140,
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

    final menu = state.currentMeal;
    if (menu == null) return _NoMenuCard(state: state);

    final dishesStr = menu.dishes.map((d) => d.name).join(', ');
    final cutoff = state.timeLeftToCutoff ?? Duration.zero;
    final cutoffStr = _formatDuration(cutoff);
    final hasCutoff = cutoff != Duration.zero;
    final bgUrl = _bgImages[menu.mealSlot] ?? _bgImages['noon']!;
    final icon = _slotIcons[menu.mealSlot] ?? '🍽';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 340,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Food background image ──
            Image.network(
              bgUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF2C2C2E)),
            ),

            // ── Top glassmorphism strip ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Text('$icon ', style: const TextStyle(fontSize: 18)),
                        Text(
                          menu.mealSlot.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dishesStr.isNotEmpty ? dishesStr : 'No dishes set',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom dark overlay ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.92),
                    ],
                    stops: const [0, 0.3, 1],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: hasCutoff
                              ? const Color(0xFFFFB347)
                              : const Color(0xFFF87171),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Action buttons
                    if (!hasCutoff)
                      _RateMealButton(
                        context: context,
                        ref: ref,
                        state: state,
                        menu: menu,
                      )
                    else if (state.hasSelfSkipped)
                      _UndoButton(ref: ref)
                    else
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _SkipButton(
                              ref: ref,
                              mealSlot: menu.mealSlot,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _GuestButton(
                              ref: ref,
                              mealSlot: menu.mealSlot,
                              perMealRate: state.mess?.perMealRate ?? 0.0,
                            ),
                          ),
                        ],
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

  // ── Announcement dialog ──────────────────────────────────────────────────
  void _showAnnouncementDialog(BuildContext context, StudentHomeState state) {
    final msg = state.announcement?.message;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📢', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Announcement',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          msg ?? 'No new announcements from your mess owner.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: const Color(0xFF22C55E)),
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
            if (menu != null) ...[
              Text(
                menu.dishes.map((d) => d.name).join(', '),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ] else ...[
              Text(
                'Menu not set yet.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
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
                  Expanded(
                    flex: 2,
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

  const _Header({
    required this.state,
    required this.greeting,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = state.student?.name.split(' ').first ?? 'Student';
    final isClosed = state.currentSlot == 'closed';
    final hasAnnouncement = state.announcement != null;
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
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
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
    final dishesStr =
        menu?.dishes.map((d) => d.name).join(', ') ?? 'Menu not set';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            const Spacer(),
            Text(
              dishesStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: menu != null
                    ? const Color(0xFF374151)
                    : const Color(0xFF9CA3AF),
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

// ─── No Menu Card ─────────────────────────────────────────────────────────────
class _NoMenuCard extends StatelessWidget {
  final StudentHomeState state;
  const _NoMenuCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
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
          const Text('🍽', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Menu Not Set',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Owner has not set the menu for ${state.currentSlot} yet.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
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
  final WidgetRef ref;
  final String mealSlot;
  final double perMealRate;
  const _GuestButton({
    required this.ref,
    required this.mealSlot,
    required this.perMealRate,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        ref.read(studentHomeProvider.notifier).addGuest(mealSlot, perMealRate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest added!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      },
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

// ─── Rate Meal Button ─────────────────────────────────────────────────────────
class _RateMealButton extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;
  final StudentHomeState state;
  final MenuModel menu;
  const _RateMealButton({
    required this.context,
    required this.ref,
    required this.state,
    required this.menu,
  });

  @override
  Widget build(BuildContext _) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showRatingDialog(context, ref, state, menu),
        icon: const Icon(
          Icons.star_outline_rounded,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          'Rate This Meal',
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

  void _showRatingDialog(
    BuildContext context,
    WidgetRef ref,
    StudentHomeState state,
    MenuModel menu,
  ) {
    if (state.student == null) return;
    int selectedRating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Rate ${menu.mealSlot[0].toUpperCase()}${menu.mealSlot.substring(1)} Meal',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 36,
                    ),
                    onPressed: () => setState(() => selectedRating = i + 1),
                  ),
                ),
              ),
              TextField(
                controller: commentCtrl,
                decoration: InputDecoration(
                  hintText: 'Feedback? (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        final fb = FeedbackModel(
                          feedbackId: '',
                          messId: menu.messId,
                          studentId: state.student!.studentId,
                          date: DateTime.now(),
                          mealSlot: menu.mealSlot,
                          rating: selectedRating.toDouble(),
                          comment: commentCtrl.text,
                          dishes: menu.dishes.map((d) => d.name).toList(),
                        );
                        await ref.read(appServiceProvider).submitFeedback(fb);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thanks for your feedback!'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
