import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentHomeProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning,' : hour < 17 ? 'Good Afternoon,' : 'Good Evening,';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF22C55E),
          onRefresh: () => ref.read(studentHomeProvider.notifier).load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, state, greeting)),
              if (state.activeLeave != null) SliverToBoxAdapter(child: _buildOnLeaveBanner(context, ref, state)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Current Meal', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _buildCurrentMealCard(context, ref, state)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              if (state.upcomingSlots.isNotEmpty)
                SliverToBoxAdapter(child: _buildUpcomingMealsSection(context, ref, state)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomSheet: state.announcement != null ? _buildAnnouncementBanner(state.announcement!.message) : null,
    );
  }

  Widget _buildHeader(BuildContext context, StudentHomeState state, String greeting) {
    final name = state.student?.name.split(' ')[0] ?? 'Student';
    bool isClosed = state.currentSlot == 'closed';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.person, color: Color(0xFF16A34A), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
              Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isClosed ? const Color(0xFFF3F4F6) : const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isClosed ? const Color(0xFF9CA3AF) : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isClosed ? 'CLOSED' : 'MESS OPEN',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: isClosed ? const Color(0xFF6B7280) : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF374151)),
          onPressed: () {},
        ),
      ]),
    );
  }

  Widget _buildCurrentMealCard(BuildContext context, WidgetRef ref, StudentHomeState state) {
    if (state.currentSlot == 'closed') {
      return _buildClosedCard();
    }
    
    final menu = state.currentMeal;
    if (menu == null) {
      return _buildNoMenuCard();
    }
    final dishesStr = menu.dishes.map((d) => d.name).join(', ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8))],
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  menu.mealSlot.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
            child: Text(
              dishesStr.isNotEmpty ? dishesStr : 'No dishes added',
              style: GoogleFonts.inter(fontSize: 15, color: Colors.white70, height: 1.4),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Cancellation closes in: ',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Builder(builder: (_) {
                      final cutoff = state.timeLeftToCutoff;
                      String timeStr;
                      if (cutoff == null || cutoff == Duration.zero) {
                        timeStr = 'Closed';
                      } else {
                        final h = cutoff.inHours;
                        final m = cutoff.inMinutes.remainder(60);
                        timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
                      }
                      return Row(
                        children: [
                          Text(timeStr, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFF87171))),
                          const SizedBox(width: 4),
                          const Icon(Icons.access_time, size: 14, color: Color(0xFFF87171)),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (_) {
                  final cutoff = state.timeLeftToCutoff;
                  final hasCutoff = cutoff != null && cutoff != Duration.zero;
                  if (!hasCutoff) {
                    return _buildRateMealButton(context, ref, state, menu);
                  }
                  if (state.hasSelfSkipped) {
                    return _buildUndoButton(ref);
                  }
                  return Row(
                    children: [
                      Expanded(flex: 2, child: _buildSkipButton(ref, menu.mealSlot)),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: _buildGuestButton(ref, menu.mealSlot, state.mess?.perMealRate ?? 0.0)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
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

  Widget _buildNoMenuCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu, color: Color(0xFF22C55E), size: 48),
          const SizedBox(height: 12),
          Text('Menu Not Set', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('Owner has not set the menu yet.', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUpcomingMealsSection(BuildContext context, WidgetRef ref, StudentHomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Upcoming Meals', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: state.upcomingSlots.length,
            itemBuilder: (context, index) {
              final slot = state.upcomingSlots[index];
              final menu = state.todayMenus[slot];
              return _buildUpcomingMealCard(context, ref, state, slot, menu);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMealCard(BuildContext context, WidgetRef ref, StudentHomeState state, String slot, MenuModel? menu) {
    final timings = state.mess?.mealTimings[slot];
    final timeRange = timings != null ? '${timings['start']} - ${timings['end']}' : '';
    
    return GestureDetector(
      onTap: () {
        if (menu != null) {
          _showUpcomingMealBottomSheet(context, ref, state, menu);
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  slot == 'morning' ? Icons.wb_sunny_outlined : slot == 'night' ? Icons.nightlight_outlined : Icons.restaurant,
                  color: const Color(0xFF111827),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${slot[0].toUpperCase()}${slot.substring(1)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827)),
                  ),
                ),
                const Icon(Icons.notifications_active, color: Color(0xFF10B981), size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(timeRange, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
              ],
            ),
            const Spacer(),
            Text(
              menu != null ? menu.dishes.map((d) => d.name).join(', ') : 'Menu is not set yet',
              style: GoogleFonts.inter(fontSize: 13, color: menu != null ? const Color(0xFF374151) : const Color(0xFF9CA3AF)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showUpcomingMealBottomSheet(BuildContext context, WidgetRef ref, StudentHomeState state, MenuModel menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Color(0xFF111827)),
                const SizedBox(width: 8),
                Text(
                  'Upcoming: ${menu.mealSlot[0].toUpperCase()}${menu.mealSlot.substring(1)}',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              menu.dishes.map((d) => d.name).join(', '),
              style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF4B5563), height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cancellation closes in: ',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B)),
                      ),
                      Builder(builder: (_) {
                        final timings = state.mess!.mealTimings[menu.mealSlot];
                        final startStr = timings?['start'] ?? '00:00';
                        final parts = startStr.split(':');
                        final h = int.tryParse(parts[0]) ?? 0;
                        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
                        final now = DateTime.now();
                        DateTime cutoffTime = DateTime(now.year, now.month, now.day, h, m).subtract(Duration(hours: state.mess!.cutoffHours));
                        Duration timeLeft = cutoffTime.difference(now);
                        if (timeLeft.isNegative) timeLeft = Duration.zero;

                        String timeStr;
                        if (timeLeft == Duration.zero) {
                          timeStr = 'Closed';
                        } else {
                          final lh = timeLeft.inHours;
                          final lm = timeLeft.inMinutes.remainder(60);
                          timeStr = lh > 0 ? '${lh}h ${lm}m' : '${lm}m';
                        }
                        return Text(timeStr, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)));
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildSkipButton(ref, menu.mealSlot)),
                      const SizedBox(width: 8),
                      Expanded(flex: 1, child: _buildGuestButton(ref, menu.mealSlot, state.mess?.perMealRate ?? 0.0)),
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

  Widget _buildSkipButton(WidgetRef ref, String mealSlot) {
    return ElevatedButton(
      onPressed: () {
        ref.read(studentHomeProvider.notifier).skipMeal(mealSlot);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444), // Bright red
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text('Skip This Meal', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildGuestButton(WidgetRef ref, String mealSlot, double perMealRate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(studentHomeProvider.notifier).addGuest(mealSlot, perMealRate),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text('+1 Guest', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(studentHomeProvider.notifier).undoSkip(''),
        icon: const Icon(Icons.undo_rounded, size: 18, color: Colors.white),
        label: Text('Undo Skip',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildRateMealButton(BuildContext context, WidgetRef ref, StudentHomeState state, MenuModel menu) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showRatingDialog(context, ref, state, menu),
        icon: const Icon(Icons.star_outline_rounded, size: 18, color: Colors.white),
        label: Text('Rate This Meal', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, StudentHomeState state, MenuModel menu) {
    if (state.student == null) return;
    int selectedRating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Rate ${menu.mealSlot[0].toUpperCase()}${menu.mealSlot.substring(1)} Meal', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 36,
                      ),
                      onPressed: () => setState(() => selectedRating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Any specific feedback? (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  setState(() => isSubmitting = true);
                  try {
                    final feedback = FeedbackModel(
                      feedbackId: '',
                      messId: menu.messId,
                      studentId: state.student!.studentId,
                      date: DateTime.now(),
                      mealSlot: menu.mealSlot,
                      rating: selectedRating.toDouble(),
                      comment: commentCtrl.text,
                      dishes: menu.dishes.map((d) => d.name).toList(),
                    );
                    await ref.read(appServiceProvider).submitFeedback(feedback);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your feedback!'), backgroundColor: Color(0xFF22C55E)));
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      setState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        border: Border(top: BorderSide(color: Color(0xFFFCD34D))),
      ),
      child: Row(children: [
        const Icon(Icons.campaign_rounded, color: Color(0xFF92400E), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF92400E)))),
      ]),
    );
  }

  Widget _buildOnLeaveBanner(BuildContext context, WidgetRef ref, StudentHomeState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌴', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You are On Leave', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF166534))),
                    Text('Meals are automatically cancelled.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF15803D))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(studentHomeProvider.notifier).cancelLeave();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave cancelled early!'), backgroundColor: Color(0xFF22C55E)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Cancel Leave Early', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
