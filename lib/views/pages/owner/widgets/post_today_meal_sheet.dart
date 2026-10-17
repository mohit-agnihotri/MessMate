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

  final TextEditingController _searchController = TextEditingController();
  List<DishModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
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

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isSearching = true);
      try {
        final results = await ref.read(appServiceProvider).searchGlobalDishes(trimmed);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _addCustomDish(String dishName) {
    final trimmed = dishName.trim();
    if (trimmed.isEmpty) return;

    if (_chosenDishes.any((d) => d.name.toLowerCase() == trimmed.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$trimmed" is already in today\'s menu.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final match = _searchResults.where((d) => d.name.toLowerCase() == trimmed.toLowerCase()).firstOrNull;
    final dishToAdd = match ??
        DishModel(
          dishId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmed,
          category: _detectCategory(trimmed),
          dishFoodType: _detectFoodType(trimmed),
          isCustom: true,
        );

    setState(() {
      _chosenDishes.add(dishToAdd);
      _searchController.clear();
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _toggleDish(DishModel dish) {
    setState(() {
      final idx = _chosenDishes.indexWhere(
        (d) => d.dishId == dish.dishId || d.name.toLowerCase() == dish.name.toLowerCase(),
      );
      if (idx >= 0) {
        _chosenDishes.removeAt(idx);
      } else {
        _chosenDishes.add(dish);
      }
    });
  }

  String _detectCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('roti') || n.contains('chapati') || n.contains('naan') || n.contains('paratha') || n.contains('puri') || n.contains('poori') || n.contains('kulcha') || n.contains('bread')) {
      return 'roti';
    }
    if (n.contains('rice') || n.contains('chawal') || n.contains('pulao') || n.contains('pulav') || n.contains('biryani') || n.contains('khichdi') || n.contains('fried rice')) {
      return 'rice';
    }
    if (n.contains('dal') || n.contains('daal') || n.contains('sambar') || n.contains('rasam') || n.contains('kadhi') || n.contains('rajma') || n.contains('chole') || n.contains('chhole')) {
      return 'dal';
    }
    if (n.contains('sweet') || n.contains('kheer') || n.contains('halwa') || n.contains('gulab') || n.contains('laddu') || n.contains('jalebi') || n.contains('custard') || n.contains('ice cream') || n.contains('rasgulla')) {
      return 'sweet';
    }
    if (n.contains('snack') || n.contains('samosa') || n.contains('pakora') || n.contains('kachori') || n.contains('poha') || n.contains('upma') || n.contains('sandwich')) {
      return 'snack';
    }
    if (n.contains('chicken') || n.contains('egg') || n.contains('mutton') || n.contains('fish') || n.contains('curry')) {
      return 'curry';
    }
    return 'sabzi';
  }

  String _detectFoodType(String name) {
    final n = name.toLowerCase();
    if (n.contains('chicken') || n.contains('egg') || n.contains('mutton') || n.contains('fish') || n.contains('meat') || n.contains('prawn')) {
      return 'nonveg';
    }
    return 'veg';
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
            const SizedBox(height: 6),

            // Search Bar & Instant Add
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (val) => _addCustomDish(val),
              decoration: InputDecoration(
                hintText: 'Search or type dish name (e.g. Biryani, Kheer)...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
              ),
            ),

            // Instant "+ Add '[search]' as dish" button
            if (_searchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _addCustomDish(_searchController.text),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '+ Add "${_searchController.text.trim()}" to Today\'s Menu',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF065F46),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Text(
                          'Add Now',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Search results from database
            if (_isSearching) ...[
              const SizedBox(height: 10),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ] else if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Matching dishes in library:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _searchResults.map((dish) {
                  final isChosen = _chosenDishes.any(
                    (d) => d.dishId == dish.dishId || d.name.toLowerCase() == dish.name.toLowerCase(),
                  );
                  return FilterChip(
                    avatar: Text(_categoryEmoji(dish.category), style: const TextStyle(fontSize: 12)),
                    label: Text(dish.name),
                    selected: isChosen,
                    selectedColor: const Color(0xFFDCFCE7),
                    checkmarkColor: const Color(0xFF16A34A),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isChosen ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isChosen ? FontWeight.w600 : FontWeight.w500,
                      color: isChosen ? const Color(0xFF15803D) : const Color(0xFF374151),
                    ),
                    onSelected: (_) => _toggleDish(dish),
                  );
                }).toList(),
              ),
            ],

            // Quick pick from template dishes
            if (availableDishes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Quick select from saved ${_slotName(_selectedSlot)} offerings:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: availableDishes.map((dish) {
                  final isChosen = _chosenDishes.any(
                    (d) => d.dishId == dish.dishId || d.name.toLowerCase() == dish.name.toLowerCase(),
                  );
                  return FilterChip(
                    avatar: Text(_categoryEmoji(dish.category), style: const TextStyle(fontSize: 12)),
                    label: Text(dish.name),
                    selected: isChosen,
                    selectedColor: const Color(0xFFDCFCE7),
                    checkmarkColor: const Color(0xFF16A34A),
                    backgroundColor: const Color(0xFFF9FAFB),
                    side: BorderSide(
                      color: isChosen ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isChosen ? FontWeight.w600 : FontWeight.w500,
                      color: isChosen ? const Color(0xFF15803D) : const Color(0xFF374151),
                    ),
                    onSelected: (_) => _toggleDish(dish),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Selected dishes container
            Text(
              'Selected for Today\'s ${_slotName(_selectedSlot)} (${_chosenDishes.length}):',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),

            if (_chosenDishes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.soup_kitchen_outlined, color: Color(0xFF9CA3AF), size: 26),
                    const SizedBox(height: 6),
                    Text(
                      'No dishes selected yet.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type any dish name above to add, or tap items from your saved menu.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _chosenDishes.map((dish) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFFD1FAE5),
                        child: Text(_categoryEmoji(dish.category), style: const TextStyle(fontSize: 12)),
                      ),
                      label: Text(
                        dish.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
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
                            (d) => d.dishId == dish.dishId || d.name.toLowerCase() == dish.name.toLowerCase(),
                          );
                        });
                      },
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
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
