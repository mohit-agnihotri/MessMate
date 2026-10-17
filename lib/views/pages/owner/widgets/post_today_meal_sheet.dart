import 'dart:async';
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
    // Note: If not published for today, keep _chosenDishes empty as requested!
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

  String _categoryEmoji(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('dal')) return '🍲';
    if (c.contains('roti') || c.contains('bread')) return '🫓';
    if (c.contains('rice')) return '🍚';
    if (c.contains('sweet')) return '🍨';
    if (c.contains('snack')) return '🥟';
    if (c.contains('curry') || c.contains('non')) return '🍗';
    return '🥗';
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
                if (_chosenDishes.isNotEmpty)
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
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Empty state or Selected Dishes Chips
            if (_chosenDishes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.soup_kitchen_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No dishes added for today yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add Dish from Catalog" below to search and add dishes cooked today.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
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
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _chosenDishes.map((dish) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFFD1FAE5),
                        child: Text(
                          _categoryEmoji(dish.category),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      label: Text(
                        dish.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      deleteIcon: const Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      onDeleted: () {
                        setState(() {
                          _chosenDishes.removeWhere(
                            (d) =>
                                d.dishId == dish.dishId ||
                                d.name.toLowerCase() == dish.name.toLowerCase(),
                          );
                        });
                      },
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // ── Button: Add Dish from Catalog ──
            GestureDetector(
              onTap: () => _openCatalogSearchBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF86EFAC),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Dish from Catalog',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Step 4: Publish Action ──
            if (_isSaving)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
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
                              content:
                                  Text('Please select at least 1 dish to publish!'),
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
        final results = await ref
            .read(appServiceProvider)
            .searchGlobalDishes(trimmed);
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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Dish',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          // Custom Dish Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF10B981)),
                label: Text(
                  '+ Create Custom Dish for My Mess',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF10B981),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'e.g. Paneer, Dal, Rice...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results / Empty State
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Type to search global dishes\nor tap "+ Create Custom Dish" above'
                                : 'No dishes found for "${_searchController.text.trim()}"\nTap "+ Create Custom Dish" above to create it!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9CA3AF),
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
                              .any((d) => d.dishId == dish.dishId || d.name.toLowerCase() == dish.name.toLowerCase());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: (dish.imageUrl.isNotEmpty &&
                                          !dish.imageUrl.contains('placeholder'))
                                      ? Image.network(
                                          dish.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: const Color(0xFFF3F4F6),
                                            child: const Icon(
                                              Icons.restaurant,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFECFDF5),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.restaurant_menu,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                dish.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                dish.category,
                                style: GoogleFonts.inter(
                                  color: dish.dishFoodType == 'nonveg'
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isAlreadyAdded
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF10B981),
                                        size: 28,
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
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Add'),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
    'dal': 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=800&auto=format&fit=crop',
    'roti': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop',
    'rice': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?q=80&w=800&auto=format&fit=crop',
    'sabzi': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=800&auto=format&fit=crop',
    'sweet': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?q=80&w=800&auto=format&fit=crop',
    'snack': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?q=80&w=800&auto=format&fit=crop',
    'curry': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=800&auto=format&fit=crop',
  };

  bool isSaving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Custom Dish',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dish Name *',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter dish name' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Shahi Paneer, Dal Makhani...',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: ['dal', 'roti', 'rice', 'sabzi', 'sweet', 'snack', 'curry']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat[0].toUpperCase() + cat.substring(1)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Food Type',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  if (foodType == 'pure_veg')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🌱 Pure Veg (Locked by Mess Setting)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                          fontSize: 12,
                        ),
                      ),
                    )
                  else if (foodType == 'non_veg')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🍗 Non-Veg (Locked by Mess Setting)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('🌱 Veg'),
                          selected: selectedDishFoodType == 'veg',
                          selectedColor: const Color(0xFFDCFCE7),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedDishFoodType = 'veg');
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('🍗 Non-Veg'),
                          selected: selectedDishFoodType == 'nonveg',
                          selectedColor: const Color(0xFFFEE2E2),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedDishFoodType = 'nonveg');
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      try {
                        final dishId = 'dish_${DateTime.now().millisecondsSinceEpoch}';
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
                          final updatedMess = mess.copyWith(masterDishNames: names);
                          await appService.updateMess(updatedMess);
                        }

                        // 3. Callback to add to today's meal
                        onDishCreated(newDish);

                        if (context.mounted) {
                          Navigator.pop(ctx); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${newDish.name}" created and added!'),
                              backgroundColor: const Color(0xFF10B981),
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
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create & Add'),
            ),
          ],
        );
      },
    ),
  );
}
