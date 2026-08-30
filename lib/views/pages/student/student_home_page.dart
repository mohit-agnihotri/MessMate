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
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF22C55E),
          onRefresh: () => ref.read(studentHomeProvider.notifier).load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(state, greeting)),
              if (state.activeLeave != null) SliverToBoxAdapter(child: _buildOnLeaveBanner(context, ref, state)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildMessStatusPill(state)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _buildCurrentMealCard(context, ref, state)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverToBoxAdapter(child: _buildNextMealCard(state)),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: state.announcement != null ? _buildAnnouncementBanner(state.announcement!.message) : null,
    );
  }

  Widget _buildHeader(StudentHomeState state, String greeting) {
    final name = state.student?.name.split(' ')[0] ?? 'Student';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(child: Text(
          '$greeting, $name!',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
        )),
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF374151)), onPressed: () {}),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.person, color: Color(0xFF16A34A), size: 20),
        ),
      ]),
    );
  }

  Widget _buildMessStatusPill(StudentHomeState state) {
    bool isClosed = state.currentSlot == 'closed';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isClosed ? const Color(0xFF9CA3AF) : const Color(0xFF22C55E), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(color: isClosed ? const Color(0xFF9CA3AF) : const Color(0xFF22C55E), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(isClosed ? 'MESS CLOSED FOR TODAY' : 'MESS OPEN TODAY',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
              color: isClosed ? const Color(0xFF6B7280) : const Color(0xFF16A34A), letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  Widget _buildCurrentMealCard(BuildContext context, WidgetRef ref, StudentHomeState state) {
    if (state.currentSlot == 'closed') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
    
    final menu = state.currentMeal;
    if (menu == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        ),
        child: Text('No menu set for the current meal.', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
      );
    }
    final dishesStr = menu.dishes.map((d) => d.name).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text('${menu.mealSlot[0].toUpperCase()}${menu.mealSlot.substring(1)} Menu',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ),
        Container(
          height: 170,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1C1C2E),
          ),
          child: const Center(child: Icon(Icons.restaurant, size: 60, color: Color(0xFF374151))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            dishesStr.isNotEmpty ? dishesStr : 'No dishes added',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151)),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 16),
            const SizedBox(width: 6),
            Builder(builder: (_) {
              final cutoff = state.timeLeftToCutoff;
              String label;
              if (cutoff == null || cutoff == Duration.zero) {
                label = 'Cutoff passed';
              } else {
                final h = cutoff.inHours;
                final m = cutoff.inMinutes.remainder(60);
                label = h > 0 ? '$h h $m min left to cancel' : '$m min left to cancel';
              }
              return Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w500));
            }),
          ]),
        ),
        const SizedBox(height: 12),
        Builder(builder: (ctx) {
          final cutoff = state.timeLeftToCutoff;
          final hasCutoff = cutoff != null && cutoff != Duration.zero;
          return hasCutoff
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: state.hasSelfSkipped
                  ? _buildUndoButton(ref)
                  : Column(children: [
                      _buildSkipButton(ref, menu.mealSlot),
                      const SizedBox(height: 8),
                      _buildGuestButton(ref, menu.mealSlot, state.mess?.perMealRate ?? 0.0),
                    ]),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRateMealButton(context, ref, state, menu),
              );
        }),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildRateMealButton(BuildContext context, WidgetRef ref, StudentHomeState state, MenuModel menu) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showRatingDialog(context, ref, state, menu),
        icon: const Icon(Icons.star_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
        label: Text('Rate This Meal', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B))),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFF59E0B)),
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

  Widget _buildSkipButton(WidgetRef ref, String mealSlot) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => ref.read(studentHomeProvider.notifier).skipMeal(mealSlot),
        icon: const Icon(Icons.block_rounded, size: 18),
        label: Text('Skip This Meal', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildGuestButton(WidgetRef ref, String mealSlot, double perMealRate) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => ref.read(studentHomeProvider.notifier).addGuest(mealSlot, perMealRate),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          foregroundColor: const Color(0xFF374151),
        ),
        child: Text('+1 Guest (Add Guest Meal)',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
      ),
    );
  }

  Widget _buildUndoButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(studentHomeProvider.notifier).undoSkip(''),
        icon: const Icon(Icons.undo_rounded, size: 18, color: Color(0xFF22C55E)),
        label: Text('Undo Skip',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E))),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF22C55E)),
        ),
      ),
    );
  }

  Widget _buildNextMealCard(StudentHomeState state) {
    final nextMeal = state.nextMeal;
    if (nextMeal == null) return const SizedBox.shrink();
    
    final dishesStr = nextMeal.dishes.map((d) => d.name).join(', ');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFF3F4F6),
          ),
          child: const Icon(Icons.restaurant, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(state.isNextMealTomorrow ? "Tomorrow's ${nextMeal.mealSlot[0].toUpperCase()}${nextMeal.mealSlot.substring(1)}" : "Upcoming: ${nextMeal.mealSlot[0].toUpperCase()}${nextMeal.mealSlot.substring(1)}",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(dishesStr.isNotEmpty ? dishesStr : "No dishes added yet",
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
        ])),
      ]),
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
