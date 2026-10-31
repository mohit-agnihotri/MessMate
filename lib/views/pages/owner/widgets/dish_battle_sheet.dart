import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/owner_inspired_theme.dart';

/// Redesigned Food Vote Sheet matching user screenshots:
/// - WhatsApp Image 2026-10-31 at 03.42.39.jpeg (Creation: 4 steps, quick presets, pick dishes)
/// - WhatsApp Image 2026-10-31 at 03.42.52.jpeg (Add Dishes Catalog Sheet)
/// - WhatsApp Image 2026-10-31 at 03.43.03.jpeg (Active Battle Monitor: Countdown, +1h, Close now)
/// - WhatsApp Image 2026-10-31 at 03.41.42.jpeg (Closed Battle / Winner: 1-tap Post to Menu)
class DishBattleSheet extends ConsumerStatefulWidget {
  final MessModel mess;

  const DishBattleSheet({super.key, required this.mess});

  static Future<void> show(BuildContext context, {required MessModel mess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DishBattleSheet(mess: mess),
    );
  }

  @override
  ConsumerState<DishBattleSheet> createState() => _DishBattleSheetState();
}

class _DishBattleSheetState extends ConsumerState<DishBattleSheet> {
  // Form State
  final TextEditingController _titleController =
      TextEditingController(text: 'Sunday Feast Clash');
  String _selectedSlot = 'noon'; // 'morning', 'noon', 'night'
  int _durationHours = 4;
  bool _forceCreateMode = false;
  bool _isSaving = false;

  // Selected dishes (starts with 2 popular defaults)
  final List<String> _selectedDishes = ['Chole Bhature', 'Pav Bhaji'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applyQuickPreset(String title, String slot, List<String> dishes) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = title;
      _selectedSlot = slot;
      _selectedDishes.clear();
      _selectedDishes.addAll(dishes);
    });
  }

  void _removeDish(int index) {
    if (_selectedDishes.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 dishes are required for a voting clash'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDishes.removeAt(index);
    });
  }

  void _openAddDishesSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDishesCatalogSheet(
        mess: widget.mess,
        selectedDishes: List.from(_selectedDishes),
        onSelectedDishesChanged: (updated) {
          setState(() {
            _selectedDishes.clear();
            _selectedDishes.addAll(updated);
          });
        },
      ),
    );
  }

  Future<void> _launchBattle() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your food vote a title')),
      );
      return;
    }

    if (_selectedDishes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 dishes to vote on')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final now = DateTime.now();
      final closesAt = now.add(Duration(hours: _durationHours));
      final options = <DishBattleOption>[];

      final defaultIcons = ['🍛', '🥘', '🍲', '🍚'];
      for (int i = 0; i < _selectedDishes.length; i++) {
        options.add(
          DishBattleOption(
            id: 'dish_${i + 1}_${now.millisecondsSinceEpoch}',
            name: _selectedDishes[i],
            icon: defaultIcons[i % defaultIcons.length],
            votes: 0,
          ),
        );
      }

      final battle = DishBattleModel(
        battleId: 'battle_${now.millisecondsSinceEpoch}',
        messId: widget.mess.messId,
        title: title,
        targetSlot: _selectedSlot,
        targetDate: now,
        options: options,
        voterSelections: {},
        createdAt: now,
        closesAt: closesAt,
      );

      await ref.read(appServiceProvider).createDishBattle(battle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚔️ Food vote "$title" is now live for all students!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch battle: $e'),
            backgroundColor: const Color(0xFFC75D4D),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _extendBattle(DishBattleModel battle) async {
    HapticFeedback.selectionClick();
    await ref.read(appServiceProvider).extendDishBattle(
          widget.mess.messId,
          battle.battleId,
          const Duration(hours: 1),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Voting window extended by +1 hour!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _closeBattleNow(DishBattleModel battle) async {
    HapticFeedback.mediumImpact();
    // Winner with highest votes
    DishBattleOption? winner;
    int maxV = -1;
    for (final opt in battle.options) {
      if (opt.votes > maxV) {
        maxV = opt.votes;
        winner = opt;
      }
    }
    final winningName = winner?.name ?? battle.options.first.name;

    await ref.read(appServiceProvider).closeDishBattle(
          widget.mess.messId,
          battle.battleId,
          winningName,
        );
  }

  Future<void> _postWinnerToMenu(DishBattleModel battle, String winningDishName) async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final dishObj = DishModel(
        dishId: 'dish_${DateTime.now().millisecondsSinceEpoch}',
        name: winningDishName,
        category: 'main',
      );

      await ref.read(ownerMenuProvider.notifier).publishTodayMenu(
            slot: battle.targetSlot,
            menuType: 'special',
            dishes: [dishObj],
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "$winningDishName" posted as today\'s ${_slotLabel(battle.targetSlot)}!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post winner to menu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _slotLabel(String slot) {
    switch (slot.toLowerCase()) {
      case 'morning':
        return 'Breakfast';
      case 'noon':
        return 'Lunch';
      case 'night':
        return 'Dinner';
      default:
        return slot[0].toUpperCase() + slot.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBattleAsync = ref.watch(activeDishBattleProvider(widget.mess.messId));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CEC5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              activeBattleAsync.when(
                data: (battle) {
                  if (battle != null && !_forceCreateMode) {
                    final isClosedOrExpired =
                        battle.isClosed || DateTime.now().isAfter(battle.closesAt);
                    if (isClosedOrExpired) {
                      return _buildClosedWinnerView(battle);
                    }
                    return _buildActiveMonitorView(battle);
                  }
                  return _buildCreateBattleView();
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: OwnerColors.amber),
                  ),
                ),
                error: (e, st) => _buildCreateBattleView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. CREATION VIEW (Matching Screenshot 03.42.39.jpeg)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCreateBattleView() {
    final slot = _slotLabel(_selectedSlot);
    final summaryTitle = _selectedDishes.join(' vs ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE8DE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: OwnerColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Food vote',
              style: GoogleFonts.newsreader(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: OwnerColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Let students vote on what to cook next. The most-voted dish wins.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: OwnerColors.textMuted,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── STEP 1: Give it a title ──
        _buildStepHeader(1, 'Give it a title'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: OwnerColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Sunday Feast Clash',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8DFD3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8DFD3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: OwnerColors.amber, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Quick start presets row
        Row(
          children: [
            Text(
              'Quick start:',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: OwnerColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPresetChip(
                      'Chole vs Pav Bhaji',
                      () => _applyQuickPreset(
                        'Sunday Feast Clash',
                        'noon',
                        ['Chole Bhature', 'Pav Bhaji'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      'Paneer vs Dal Makhani',
                      () => _applyQuickPreset(
                        'Royal Dinner Faceoff',
                        'night',
                        ['Paneer Butter Masala', 'Dal Makhani'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      'Biryani vs Pulao',
                      () => _applyQuickPreset(
                        'Rice Royale',
                        'noon',
                        ['Hyderabadi Biryani', 'Veg Pulao'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── STEP 2: Which meal is it for? ──
        _buildStepHeader(2, 'Which meal is it for?'),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildMealSlotButton('morning', 'Breakfast'),
            const SizedBox(width: 10),
            _buildMealSlotButton('noon', 'Lunch'),
            const SizedBox(width: 10),
            _buildMealSlotButton('night', 'Dinner'),
          ],
        ),
        const SizedBox(height: 22),

        // ── STEP 3: Pick the dishes ──
        _buildStepHeader(
          3,
          'Pick the dishes',
          subtitle: 'Choose 2 to 4. Students pick one.',
        ),
        const SizedBox(height: 10),

        // Selected dishes list
        for (int i = 0; i < _selectedDishes.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8DFD3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFFE89025) : const Color(0xFF86A386),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    i == 0 ? '🍛' : (i == 1 ? '🥘' : (i == 2 ? '🍲' : '🍚')),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDishes[i],
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeDish(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF9E9284),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Dashed border: + Search & add a dish
        if (_selectedDishes.length < 4)
          GestureDetector(
            onTap: _openAddDishesSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE1).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF86A386),
                  width: 1.4,
                  style: BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+ Search & add a dish · ${_selectedDishes.length} of 4',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A6B4A),
                ),
              ),
            ),
          ),
        const SizedBox(height: 22),

        // ── STEP 4: When should voting close? ──
        _buildStepHeader(4, 'When should voting close?'),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDurationChip(2, '2 h'),
            const SizedBox(width: 8),
            _buildDurationChip(4, '4 h'),
            const SizedBox(width: 8),
            _buildDurationChip(8, '8 h'),
            const SizedBox(width: 8),
            _buildDurationChip(24, '24 h'),
          ],
        ),
        const SizedBox(height: 24),

        // ── Sticky Bottom Launch Box ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8DFD3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summaryTitle.isNotEmpty ? summaryTitle : 'Food Battle',
                style: GoogleFonts.newsreader(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: OwnerColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$slot · closes in $_durationHours hours',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: OwnerColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _launchBattle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFE89025),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Launch Food Vote',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. ACTIVE BATTLE LIVE MONITOR VIEW (Matching Screenshot 03.43.03.jpeg)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActiveMonitorView(DishBattleModel battle) {
    final now = DateTime.now();
    final remaining = battle.closesAt.difference(now);
    final hours = math.max(0, remaining.inHours);
    final mins = math.max(0, remaining.inMinutes % 60);
    final timeStr = '${hours}h ${mins}m';

    int totalVotes = battle.totalVotes;
    if (totalVotes == 0) {
      totalVotes = battle.options.fold<int>(0, (s, o) => s + o.votes);
    }

    final elapsed = now.difference(battle.createdAt);
    final totalSpan = battle.closesAt.difference(battle.createdAt);
    final timePct = totalSpan.inSeconds > 0
        ? (elapsed.inSeconds / totalSpan.inSeconds).clamp(0.0, 1.0)
        : 0.5;

    final slotName = _slotLabel(battle.targetSlot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFE8DE),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: OwnerColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  battle.title,
                  style: GoogleFonts.newsreader(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chips Row: • Live, Slot, Votes
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF231A14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE89025),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EDE3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                slotName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A6B4A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8CD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalVotes votes so far',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9E5327),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dark Hero Card (Voting Closes in 3h 12m)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2119),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOTING CLOSES IN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFFD4A373),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timeStr,
                style: GoogleFonts.newsreader(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFDF7E7),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: timePct,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE89025)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$totalVotes votes so far · results update live',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result Cards for each dish
        for (int i = 0; i < battle.options.length; i++) ...[
          Builder(builder: (ctx) {
            final opt = battle.options[i];
            final pct = totalVotes > 0 ? (opt.votes / totalVotes) : 0.0;
            final pctInt = (pct * 100).round();
            final isAmber = i % 2 == 0;
            final themeColor = isAmber ? const Color(0xFFE89025) : const Color(0xFF86A386);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          opt.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OwnerColors.textDark,
                              ),
                            ),
                            Text(
                              '${opt.votes} votes',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: OwnerColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$pctInt%',
                        style: GoogleFonts.newsreader(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEDE5D8),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 8),

        // Action Buttons Row: [ + 1 hour ] and [ Close now ]
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _extendBattle(battle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5EDE3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '+ 1 hour',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A6B4A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _closeBattleNow(battle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDECE7),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Close now',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB84A39),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'When voting ends, you can post the winner as the meal with 1 tap.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: OwnerColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. CLOSED / WINNER VIEW (Matching Screenshot 03.41.42.jpeg)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildClosedWinnerView(DishBattleModel battle) {
    int totalVotes = battle.totalVotes;
    if (totalVotes == 0) {
      totalVotes = battle.options.fold<int>(0, (s, o) => s + o.votes);
    }

    // Determine winner
    DishBattleOption winner = battle.options.first;
    int maxV = -1;
    for (final opt in battle.options) {
      if (opt.votes > maxV) {
        maxV = opt.votes;
        winner = opt;
      }
    }
    final winningName = battle.winningDishName ?? winner.name;
    final winnerPct = totalVotes > 0 ? ((maxV / totalVotes) * 100).round() : 100;
    final slotName = _slotLabel(battle.targetSlot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE8DE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: OwnerColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              battle.title,
              style: GoogleFonts.newsreader(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: OwnerColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chips Row: Voting closed, Slot, Total votes
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EDE3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Voting closed',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A6B4A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                slotName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: OwnerColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8CD),
                borderRadius: BorderRadius.circular(12),
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
          ],
        ),
        const SizedBox(height: 16),

        // Dark Hero Winner Card (🏆 WINNER Pav Bhaji)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2119),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                'WINNER',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: const Color(0xFFD4A373),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                winningName,
                textAlign: TextAlign.center,
                style: GoogleFonts.newsreader(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFDF7E7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$winnerPct% · $maxV of $totalVotes votes',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dish breakdown cards
        for (int i = 0; i < battle.options.length; i++) ...[
          Builder(builder: (ctx) {
            final opt = battle.options[i];
            final pct = totalVotes > 0 ? (opt.votes / totalVotes) : 0.0;
            final pctInt = (pct * 100).round();
            final isAmber = i % 2 == 0;
            final themeColor = isAmber ? const Color(0xFFE89025) : const Color(0xFF86A386);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          opt.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OwnerColors.textDark,
                              ),
                            ),
                            Text(
                              '${opt.votes} votes',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: OwnerColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$pctInt%',
                        style: GoogleFonts.newsreader(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEDE5D8),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 8),

        // Big Primary CTA: Post Winner as today's lunch!
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _postWinnerToMenu(battle, winningName),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFE89025),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Post $winningName as today\'s ${slotName.toLowerCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Actions: [ Choose another ] and [ Start new vote ]
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Show picker to choose runner-up
                  showModalBottomSheet(
                    context: context,
                    builder: (sheetCtx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Choose alternative dish',
                              style: GoogleFonts.newsreader(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...battle.options.map((o) => ListTile(
                                leading: Text(o.icon, style: const TextStyle(fontSize: 24)),
                                title: Text(o.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                subtitle: Text('${o.votes} votes'),
                                onTap: () {
                                  Navigator.pop(sheetCtx);
                                  _postWinnerToMenu(battle, o.name);
                                },
                              )),
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5EDE3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Choose another',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A6B4A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _forceCreateMode = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5EDE3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Start new vote',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A6B4A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStepHeader(int stepNumber, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF2B2119),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stepNumber',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: OwnerColors.textDark,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: OwnerColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EDE3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A6B4A),
          ),
        ),
      ),
    );
  }

  Widget _buildMealSlotButton(String slotKey, String label) {
    final isSelected = _selectedSlot == slotKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSlot = slotKey);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFDE8CD) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFE89025) : const Color(0xFFE8DFD3),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF9E5327) : OwnerColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(int hours, String label) {
    final isSelected = _durationHours == hours;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _durationHours = hours);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2B2119) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF2B2119) : const Color(0xFFE8DFD3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : OwnerColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. ADD DISHES CATALOG MODAL SHEET (Matching Screenshot 03.42.52.jpeg)
// ═══════════════════════════════════════════════════════════════════════════
class _AddDishesCatalogSheet extends StatefulWidget {
  final MessModel mess;
  final List<String> selectedDishes;
  final ValueChanged<List<String>> onSelectedDishesChanged;

  const _AddDishesCatalogSheet({
    required this.mess,
    required this.selectedDishes,
    required this.onSelectedDishesChanged,
  });

  @override
  State<_AddDishesCatalogSheet> createState() => _AddDishesCatalogSheetState();
}

class _AddDishesCatalogSheetState extends State<_AddDishesCatalogSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _currentSelected;
  String _searchQuery = '';

  // Preset popular catalog
  static const List<String> _catalogPresets = [
    'Chole Bhature',
    'Pav Bhaji',
    'Paneer Butter Masala',
    'Dal Makhani',
    'Aloo Paratha',
    'Puri Bhaji',
    'Hyderabadi Veg Biryani',
    'Veg Pulao',
    'Rajma Chawal',
    'Kadai Paneer',
  ];

  @override
  void initState() {
    super.initState();
    _currentSelected = List.from(widget.selectedDishes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDish(String dishName) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentSelected.contains(dishName)) {
        if (_currentSelected.length > 2) {
          _currentSelected.remove(dishName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least 2 dishes must be chosen'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (_currentSelected.length < 4) {
          _currentSelected.add(dishName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 4 dishes allowed for voting'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  void _promptCustomDish() {
    final customController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add custom dish',
          style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: customController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Masala Dosa, Matar Paneer',
            filled: true,
            fillColor: const Color(0xFFF9F6F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8DFD3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = customController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _toggleDish(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE89025),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Dish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _catalogPresets.where((d) {
      if (_searchQuery.isEmpty) return true;
      return d.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CEC5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              'Add dishes',
              style: GoogleFonts.newsreader(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: OwnerColors.textDark,
              ),
            ),
            const SizedBox(height: 10),

            // Search Header row: Search your catalog & 2 of 4 chosen pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search your catalog',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: OwnerColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2119),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentSelected.length} of 4 chosen',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search Field
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search dishes, e.g. paneer, dal, paratha',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: OwnerColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8DFD3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8DFD3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OwnerColors.amber, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dish List (Expanded to absorb all remaining space with zero overflow)
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (ctx, i) => const Divider(
                  color: Color(0xFFEFE8DE),
                  height: 1,
                ),
                itemBuilder: (ctx, index) {
                  final dishName = filtered[index];
                  final isAdded = _currentSelected.contains(dishName);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF86A386),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🍲', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dishName,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: OwnerColors.textDark,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleDish(dishName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isAdded
                                  ? const Color(0xFF2B2119)
                                  : const Color(0xFFE5EDE3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAdded ? '✓ Added' : '+ Add',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isAdded ? Colors.white : const Color(0xFF4A6B4A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Can't find it? Create custom dish
            Center(
              child: TextButton(
                onPressed: _promptCustomDish,
                child: Text(
                  'Can\'t find it? Create a custom dish',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A6B4A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Done Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelectedDishesChanged(_currentSelected);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE89025),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
