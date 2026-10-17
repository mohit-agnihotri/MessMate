import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';

class PostTodayMealSheet extends ConsumerStatefulWidget {
  final MessModel mess;
  final String? initialSlot;

  const PostTodayMealSheet({
    super.key,
    required this.mess,
    this.initialSlot,
  });

  static Future<void> show(
    BuildContext context, {
    required MessModel mess,
    String? initialSlot,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostTodayMealSheet(
        mess: mess,
        initialSlot: initialSlot,
      ),
    );
  }

  @override
  ConsumerState<PostTodayMealSheet> createState() => _PostTodayMealSheetState();
}

class _PostTodayMealSheetState extends ConsumerState<PostTodayMealSheet> {
  late String _selectedSlot;
  String _selectedMenuType = 'regular'; // 'regular' or 'special'
  final List<DishModel> _chosenDishes = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final enabledSlots = ['morning', 'noon', 'evening', 'night']
        .where((s) => widget.mess.mealTimings[s]?['enabled'] == 'true')
        .toList();

    if (widget.initialSlot != null && enabledSlots.contains(widget.initialSlot)) {
      _selectedSlot = widget.initialSlot!;
    } else if (enabledSlots.isNotEmpty) {
      _selectedSlot = enabledSlots.first;
    } else {
      _selectedSlot = 'noon';
    }

    _loadExistingDishesForSlot();
  }

  void _loadExistingDishesForSlot() {
    final menuState = ref.read(ownerMenuProvider);
    final now = DateTime.now();
    final todayIso = now.toIso8601String().substring(0, 10);
    final todayMenuId = '${todayIso}_$_selectedSlot';

    // Check if already published for today
    final existingToday = menuState.weeklyTemplates.where(
      (m) => m.menuId == todayMenuId || (m.date.toIso8601String().startsWith(todayIso) && m.mealSlot == _selectedSlot),
    ).firstOrNull;

    _chosenDishes.clear();
    if (existingToday != null && existingToday.isPublished) {
      _chosenDishes.addAll(existingToday.dishes);
      _selectedMenuType = existingToday.menuType;
    } else {
      // Default to regular menu template dishes for easy 1-tap selection
      final template = menuState.weeklyTemplates.where(
        (m) => m.mealSlot == _selectedSlot && (m.menuId == _selectedSlot || !m.menuId.contains('_')),
      ).firstOrNull;

      if (template != null) {
        _chosenDishes.addAll(template.dishes);
      }
    }
  }

  String _slotName(String slot) {
    switch (slot) {
      case 'morning':
        return 'Breakfast';
      case 'noon':
        return 'Lunch';
      case 'evening':
        return 'Snacks';
      case 'night':
        return 'Dinner';
      default:
        return slot[0].toUpperCase() + slot.substring(1);
    }
  }

  IconData _slotIcon(String slot) {
    switch (slot) {
      case 'morning':
        return Icons.wb_twilight_rounded;
      case 'noon':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.coffee_rounded;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(ownerMenuProvider);
    final enabledSlots = ['morning', 'noon', 'evening', 'night']
        .where((s) => widget.mess.mealTimings[s]?['enabled'] == 'true')
        .toList();

    // Template dishes available for this slot to pick from
    final template = menuState.weeklyTemplates.where(
      (m) => m.mealSlot == _selectedSlot && (m.menuId == _selectedSlot || !m.menuId.contains('_')),
    ).firstOrNull;
    final availableDishes = template?.dishes ?? [];

    final now = DateTime.now();
    final todayIso = now.toIso8601String().substring(0, 10);
    final todayMenuId = '${todayIso}_$_selectedSlot';
    final existingToday = menuState.weeklyTemplates.where(
      (m) => m.menuId == todayMenuId,
    ).firstOrNull;
    final isAlreadyPublished = existingToday != null && existingToday.isPublished;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Post Today's Menu",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        "Publish cooked dishes for today. Expires automatically!",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Step 1: Select Slot ──
            Text(
              '1. Select Meal Slot',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: enabledSlots.map((slot) {
                  final isSelected = slot == _selectedSlot;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _slotIcon(slot),
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 6),
                          Text(_slotName(slot)),
                        ],
                      ),
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedSlot = slot;
                            _loadExistingDishesForSlot();
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Step 2: Choose Menu Type (Regular vs Special) ──
            Text(
              '2. What kind of meal is it?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Option 1: Regular
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMenuType = 'regular'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedMenuType == 'regular'
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedMenuType == 'regular'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5E7EB),
                          width: _selectedMenuType == 'regular' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant_rounded,
                                size: 18,
                                color: _selectedMenuType == 'regular'
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Regular Meal',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedMenuType == 'regular'
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Shows as "Today\'s ${_slotName(_selectedSlot)} Meal"',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Option 2: Special
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMenuType = 'special'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedMenuType == 'special'
                            ? const Color(0xFFFFFBEB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedMenuType == 'special'
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE5E7EB),
                          width: _selectedMenuType == 'special' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                size: 18,
                                color: _selectedMenuType == 'special'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '✨ Special Meal',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedMenuType == 'special'
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Shows as "✨ Special ${_slotName(_selectedSlot)} Meal"',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Step 3: Select Today's Dishes ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '3. Dishes Cooked Today (${_chosenDishes.length})',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _chosenDishes.clear();
                    });
                  },
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),

            // Chips from template
            if (availableDishes.isNotEmpty) ...[
              Text(
                'Tap to select from your ${_slotName(_selectedSlot)} items:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: availableDishes.map((dish) {
                  final isChosen = _chosenDishes.any((d) => d.dishId == dish.dishId);
                  return FilterChip(
                    label: Text(dish.name),
                    selected: isChosen,
                    selectedColor: const Color(0xFFDCFCE7),
                    checkmarkColor: const Color(0xFF16A34A),
                    backgroundColor: const Color(0xFFF9FAFB),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isChosen ? FontWeight.w600 : FontWeight.w500,
                      color: isChosen ? const Color(0xFF15803D) : const Color(0xFF374151),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _chosenDishes.add(dish);
                        } else {
                          _chosenDishes.removeWhere((d) => d.dishId == dish.dishId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Selected dishes display
            if (_chosenDishes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'No dishes selected yet. Tap items above to add.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // ── Step 4: Publish Action ──
            if (_isSaving)
              const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            else
              Row(
                children: [
                  if (isAlreadyPublished) ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isSaving = true);
                          await ref
                              .read(ownerMenuProvider.notifier)
                              .removeTodayMenu(_selectedSlot);
                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Today's ${_slotName(_selectedSlot)} post removed.",
                                ),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_chosenDishes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least 1 dish to publish!'),
                            ),
                          );
                          return;
                        }

                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSaving = true);
                        await ref
                            .read(ownerMenuProvider.notifier)
                            .publishTodayMenu(
                              slot: _selectedSlot,
                              menuType: _selectedMenuType,
                              dishes: _chosenDishes,
                            );

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                _selectedMenuType == 'special'
                                    ? "✨ Special ${_slotName(_selectedSlot)} posted for today!"
                                    : "Today's ${_slotName(_selectedSlot)} meal posted successfully!",
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedMenuType == 'special'
                            ? const Color(0xFFD97706)
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isAlreadyPublished
                            ? "Update Today's ${_slotName(_selectedSlot)}"
                            : "Publish for Today",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
}
