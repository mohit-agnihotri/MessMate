import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/owner_inspired_theme.dart';

/// Post Today's Meal Bottom Sheet:
/// Allows the mess owner to post cooked dishes for a slot for today.
/// Designed according to inspired screenshots:
/// - WhatsApp Image 2026-10-20 at 03.10.23.jpeg (Post today's menu)
/// - WhatsApp Image 2026-10-20 at 03.10.25 (3).jpeg (Add dish & Create custom dish)
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

    final existingToday = menuState.weeklyTemplates.where(
      (m) =>
          m.menuId == todayMenuId ||
          (m.date.toIso8601String().startsWith(todayIso) &&
              m.mealSlot == _selectedSlot),
    ).firstOrNull;

    _chosenDishes.clear();
    if (existingToday != null && existingToday.isPublished) {
      _chosenDishes.addAll(existingToday.dishes);
      _selectedMenuType = existingToday.menuType;
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

  void _openCatalogSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TodayMealCatalogSearchSheet(
        mess: widget.mess,
        alreadySelectedDishes: _chosenDishes,
        onDishAdded: (dish) {
          setState(() {
            if (!_chosenDishes.any(
              (d) =>
                  d.dishId == dish.dishId ||
                  d.name.toLowerCase() == dish.name.toLowerCase(),
            )) {
              _chosenDishes.add(dish);
            }
          });
        },
        onDishRemoved: (dish) {
          setState(() {
            _chosenDishes.removeWhere(
              (d) =>
                  d.dishId == dish.dishId ||
                  d.name.toLowerCase() == dish.name.toLowerCase(),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(ownerMenuProvider);
    final enabledSlots = ['morning', 'noon', 'evening', 'night']
        .where((s) => widget.mess.mealTimings[s]?['enabled'] == 'true')
        .toList();

    final now = DateTime.now();
    final todayIso = now.toIso8601String().substring(0, 10);
    final todayMenuId = '${todayIso}_$_selectedSlot';
    final existingToday = menuState.weeklyTemplates.where(
      (m) => m.menuId == todayMenuId,
    ).firstOrNull;
    final isAlreadyPublished = existingToday != null && existingToday.isPublished;

    return Container(
      decoration: const BoxDecoration(
        color: OwnerColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: OwnerColors.walnutMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title & Subtitle (Newsreader Serif)
                Text(
                  "Post today's menu",
                  style: OwnerTypography.editorialSerif(
                    size: 26,
                    weight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires automatically tonight',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: OwnerColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── 1 · MEAL ──
                Text(
                  '1 · MEAL',
                  style: OwnerTypography.overline(
                    size: 11,
                    spacing: 1.2,
                    color: OwnerColors.sageGreen,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: enabledSlots.map((slot) {
                      final isSelected = slot == _selectedSlot;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSlot = slot;
                              _loadExistingDishesForSlot();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? OwnerColors.walnutDark
                                  : OwnerColors.sageLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _slotName(slot),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? OwnerColors.amberGlow
                                    : OwnerColors.walnutDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),

                // ── 2 · TYPE ──
                Text(
                  '2 · TYPE',
                  style: OwnerTypography.overline(
                    size: 11,
                    spacing: 1.2,
                    color: OwnerColors.sageGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Regular card
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMenuType = 'regular'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedMenuType == 'regular'
                                  ? OwnerColors.walnutDark
                                  : OwnerColors.borderSubtle,
                              width: _selectedMenuType == 'regular' ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Regular',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: OwnerColors.walnutDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Today's ${_slotName(_selectedSlot)} Meal",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: OwnerColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Special card
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMenuType = 'special'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedMenuType == 'special'
                                ? const Color(0xFFFDF8EE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedMenuType == 'special'
                                  ? OwnerColors.amberGlow
                                  : OwnerColors.borderSubtle,
                              width: _selectedMenuType == 'special' ? 2 : 1,
                            ),
                            boxShadow: _selectedMenuType == 'special'
                                ? [
                                    BoxShadow(
                                      color: OwnerColors.amberGlow
                                          .withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: OwnerColors.amberGlow,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Special',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: OwnerColors.walnutDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Special ${_slotName(_selectedSlot)} Meal",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: OwnerColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── 3 · DISHES COOKED TODAY ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3 · DISHES COOKED TODAY · ${_chosenDishes.length}',
                      style: OwnerTypography.overline(
                        size: 11,
                        spacing: 1.2,
                        color: OwnerColors.sageGreen,
                      ),
                    ),
                    if (_chosenDishes.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _chosenDishes.clear()),
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dashed container if empty, or chips list if dishes added
                if (_chosenDishes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: OwnerColors.borderSubtle,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Nothing added yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: OwnerColors.walnutDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search the catalog or create a custom dish',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: OwnerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OwnerColors.borderSubtle),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _chosenDishes.map((dish) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: OwnerColors.canvas,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: OwnerColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dish.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: OwnerColors.walnutDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _chosenDishes.removeWhere(
                                      (d) =>
                                          d.dishId == dish.dishId ||
                                          d.name.toLowerCase() ==
                                              dish.name.toLowerCase(),
                                    );
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: OwnerColors.walnutMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 12),

                // Button: + Add dish from catalog
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openCatalogSearchBottomSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.sageLight,
                      foregroundColor: OwnerColors.walnutDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      '+ Add dish from catalog',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Publish Button
                if (_isSaving)
                  const Center(
                    child: CircularProgressIndicator(
                      color: OwnerColors.walnutDark,
                    ),
                  )
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
                                    backgroundColor: OwnerColors.walnutDark,
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(
                                color: Color(0xFFFCA5A5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_chosenDishes.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select at least 1 dish to publish!',
                                    ),
                                    backgroundColor: Color(0xFFEF4444),
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
                                          ? "Special ${_slotName(_selectedSlot)} posted for today!"
                                          : "Today's ${_slotName(_selectedSlot)} meal posted successfully!",
                                    ),
                                    backgroundColor: OwnerColors.walnutDark,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OwnerColors.amberGlow,
                              foregroundColor: OwnerColors.walnutDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              isAlreadyPublished
                                  ? "Update today's ${_slotName(_selectedSlot)}"
                                  : _selectedMenuType == 'special'
                                      ? "Publish special for today"
                                      : "Publish for today",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: OwnerColors.walnutDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATALOG SEARCH BOTTOM SHEET FOR TODAY'S MEAL
// ─────────────────────────────────────────────────────────────────────────────
class _TodayMealCatalogSearchSheet extends ConsumerStatefulWidget {
  final MessModel mess;
  final List<DishModel> alreadySelectedDishes;
  final Function(DishModel) onDishAdded;
  final Function(DishModel) onDishRemoved;

  const _TodayMealCatalogSearchSheet({
    required this.mess,
    required this.alreadySelectedDishes,
    required this.onDishAdded,
    required this.onDishRemoved,
  });

  @override
  ConsumerState<_TodayMealCatalogSearchSheet> createState() =>
      _TodayMealCatalogSearchSheetState();
}

class _TodayMealCatalogSearchSheetState
    extends ConsumerState<_TodayMealCatalogSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<DishModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isSearching = true);
      try {
        final results =
            await ref.read(appServiceProvider).searchGlobalDishes(trimmed);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: OwnerColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: OwnerColors.walnutMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add dish',
                    style: OwnerTypography.editorialSerif(
                      size: 24,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: OwnerColors.walnutMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Custom Dish Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    _showCreateCustomDishDialog(
                      context,
                      ref,
                      widget.mess,
                      (newDish) {
                        widget.onDishAdded(newDish);
                        setState(() {});
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: OwnerColors.sageGreen,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    '+ Create custom dish for my mess',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: OwnerColors.sageGreen,
                    ),
                  ),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: OwnerColors.walnutDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search e.g. Paneer, Dal, Rice...',
                  hintStyle: GoogleFonts.inter(
                    color: OwnerColors.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: OwnerColors.walnutMuted,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: OwnerColors.walnutMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: OwnerColors.borderSubtle,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: OwnerColors.borderSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: OwnerColors.amberGlow,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Results / Empty State
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: OwnerColors.walnutDark,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Type to search global dishes\nor create a custom dish'
                                  : 'No dishes found for "${_searchController.text.trim()}"\nTap "+ Create custom dish for my mess" above!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: OwnerColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final dish = _searchResults[index];
                            final isAlreadyAdded = widget.alreadySelectedDishes
                                .any(
                              (d) =>
                                  d.dishId == dish.dishId ||
                                  d.name.toLowerCase() ==
                                      dish.name.toLowerCase(),
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: OwnerColors.borderSubtle,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: (dish.imageUrl.isNotEmpty &&
                                            !dish.imageUrl.contains('placeholder'))
                                        ? Image.network(
                                            dish.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (ctx, err, stack) =>
                                                    Container(
                                              color: OwnerColors.sageLight,
                                              child: const Icon(
                                                Icons.restaurant,
                                                color: OwnerColors.walnutDark,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: OwnerColors.sageLight,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.restaurant_menu,
                                              color: OwnerColors.walnutDark,
                                            ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  dish.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: OwnerColors.walnutDark,
                                  ),
                                ),
                                subtitle: Text(
                                  dish.category,
                                  style: GoogleFonts.inter(
                                    color: OwnerColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: isAlreadyAdded
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: OwnerColors.sageGreen,
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        widget.onDishRemoved(dish);
                                        setState(() {});
                                      },
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        widget.onDishAdded(dish);
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: OwnerColors.amberGlow,
                                        foregroundColor: OwnerColors.walnutDark,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE CUSTOM DISH DIALOG FOR OWNER MESS
// ─────────────────────────────────────────────────────────────────────────────
void _showCreateCustomDishDialog(
  BuildContext context,
  WidgetRef ref,
  MessModel mess,
  Function(DishModel) onDishCreated,
) {
  final nameCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final foodType = mess.foodType;

  String selectedCategory = 'sabzi';
  String selectedDishFoodType = foodType == 'pure_veg'
      ? 'veg'
      : (foodType == 'non_veg' ? 'nonveg' : 'veg');

  const defaultCategoryImages = {
    'dal':
        'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=800&auto=format&fit=crop',
    'roti':
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop',
    'rice':
        'https://images.unsplash.com/photo-1516684732162-798a0062be99?q=80&w=800&auto=format&fit=crop',
    'sabzi':
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=800&auto=format&fit=crop',
    'sweet':
        'https://images.unsplash.com/photo-1551024709-8f23befc6f87?q=80&w=800&auto=format&fit=crop',
    'snack':
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?q=80&w=800&auto=format&fit=crop',
    'curry':
        'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=800&auto=format&fit=crop',
  };

  bool isSaving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        return AlertDialog(
          backgroundColor: OwnerColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Create custom dish',
            style: OwnerTypography.editorialSerif(
              size: 22,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISH NAME *',
                    style: OwnerTypography.overline(
                      size: 11,
                      spacing: 1.2,
                      color: OwnerColors.sageGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter dish name' : null,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: OwnerColors.walnutDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Shahi Paneer',
                      hintStyle: GoogleFonts.inter(
                        color: OwnerColors.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: OwnerColors.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: OwnerColors.borderSubtle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'CATEGORY',
                    style: OwnerTypography.overline(
                      size: 11,
                      spacing: 1.2,
                      color: OwnerColors.sageGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: OwnerColors.walnutDark,
                    ),
                    items: [
                      'dal',
                      'roti',
                      'rice',
                      'sabzi',
                      'sweet',
                      'snack',
                      'curry'
                    ]
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat[0].toUpperCase() + cat.substring(1),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: OwnerColors.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: OwnerColors.borderSubtle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'FOOD TYPE',
                    style: OwnerTypography.overline(
                      size: 11,
                      spacing: 1.2,
                      color: OwnerColors.sageGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (foodType == 'pure_veg')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: OwnerColors.borderSubtle),
                      ),
                      child: Text(
                        'Pure Veg · locked by mess setting',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: OwnerColors.walnutDark,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else if (foodType == 'non_veg')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: OwnerColors.borderSubtle),
                      ),
                      child: Text(
                        'Non-Veg · locked by mess setting',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Veg'),
                          selected: selectedDishFoodType == 'veg',
                          selectedColor: OwnerColors.sageLight,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => selectedDishFoodType = 'veg');
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Non-Veg'),
                          selected: selectedDishFoodType == 'nonveg',
                          selectedColor: const Color(0xFFFEE2E2),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(
                                () => selectedDishFoodType = 'nonveg',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 16),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      try {
                        final dishId =
                            'dish_${DateTime.now().millisecondsSinceEpoch}';
                        final newDish = DishModel(
                          dishId: dishId,
                          name: nameCtrl.text.trim(),
                          category: selectedCategory,
                          imageUrl: defaultCategoryImages[selectedCategory] ??
                              'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=800',
                          dishFoodType: selectedDishFoodType,
                          isCustom: true,
                        );

                        final appService = ref.read(appServiceProvider);
                        final messId = mess.messId;

                        // 1. Add to mess subcollection /messes/{messId}/dishes/{dishId}
                        await appService.addDishToMess(messId, newDish);

                        // 2. Update masterDishNames cache on MessModel
                        final names = List<String>.from(mess.masterDishNames);
                        if (!names.contains(newDish.name)) {
                          names.add(newDish.name);
                          final updatedMess =
                              mess.copyWith(masterDishNames: names);
                          await appService.updateMess(updatedMess);
                        }

                        // 3. Callback to add to today's meal
                        onDishCreated(newDish);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${newDish.name}" created and added!',
                              ),
                              backgroundColor: OwnerColors.walnutDark,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving dish: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerColors.amberGlow,
                foregroundColor: OwnerColors.walnutDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: OwnerColors.walnutDark,
                      ),
                    )
                  : const Text(
                      'Create & add',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        );
      },
    ),
  );
}
