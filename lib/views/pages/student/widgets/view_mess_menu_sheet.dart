import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';

class ViewMessMenuSheet extends ConsumerStatefulWidget {
  final MessModel mess;
  final List<MenuModel>? initialMenus;

  const ViewMessMenuSheet({
    super.key,
    required this.mess,
    this.initialMenus,
  });

  static Future<void> show(
    BuildContext context, {
    required MessModel mess,
    List<MenuModel>? initialMenus,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewMessMenuSheet(
        mess: mess,
        initialMenus: initialMenus,
      ),
    );
  }

  @override
  ConsumerState<ViewMessMenuSheet> createState() => _ViewMessMenuSheetState();
}

class _ViewMessMenuSheetState extends ConsumerState<ViewMessMenuSheet> {
  bool _isLoading = false;
  Map<String, MenuModel> _templatesBySlot = {};
  Map<String, MenuModel> _todayPostedBySlot = {};
  String? _selectedSlot;

  final Map<String, String> _slotDisplayNames = {
    'morning': 'Breakfast',
    'noon': 'Lunch',
    'evening': 'Snacks',
    'night': 'Dinner',
  };

  final Map<String, String> _slotEmojis = {
    'morning': '🌅',
    'noon': '☀️',
    'evening': '🌇',
    'night': '🌙',
  };

  @override
  void initState() {
    super.initState();
    _processMenus(widget.initialMenus ?? []);
    _loadMenus();
  }

  void _processMenus(List<MenuModel> menus) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final templates = <String, MenuModel>{};
    final todayPosted = <String, MenuModel>{};

    for (final m in menus) {
      final slot = m.mealSlot.toLowerCase();
      if (m.menuId == slot || m.menuType == 'template') {
        templates[slot] = m;
      } else if (m.isPublished &&
          (m.menuType == 'regular' || m.menuType == 'special')) {
        if (m.menuId.startsWith(todayStr) || m.menuId == '${todayStr}_$slot') {
          todayPosted[slot] = m;
        }
      }
    }

    setState(() {
      _templatesBySlot = templates;
      _todayPostedBySlot = todayPosted;
    });
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(appServiceProvider);
      final templates = await service.getWeeklyTemplate(widget.mess.messId);
      final todayMenus = await service.getDailyMenus(
        widget.mess.messId,
        DateTime.now(),
      );

      final combined = <MenuModel>[...templates, ...todayMenus];
      _processMenus(combined);
    } catch (e) {
      debugPrint('Error loading mess menu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabledSlots = ['morning', 'noon', 'evening', 'night'].where((slot) {
      final timing = widget.mess.mealTimings[slot];
      return timing != null && timing['enabled'] == 'true';
    }).toList();

    final activeSlots = enabledSlots.isNotEmpty
        ? enabledSlots
        : ['morning', 'noon', 'night'];

    if (_selectedSlot == null || !activeSlots.contains(_selectedSlot)) {
      _selectedSlot = activeSlots.first;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🍽️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.mess.name} Menu',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Regular offerings & meal timings (मेन्यू सूची)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          // Meal Slot Tabs (Breakfast, Lunch, Dinner)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: activeSlots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  final emoji = _slotEmojis[slot] ?? '🍽️';
                  final name = _slotDisplayNames[slot] ?? slot;
                  final timing = widget.mess.mealTimings[slot];
                  final start = timing?['start'] ?? '';
                  final end = timing?['end'] ?? '';
                  final hasTime = start.isNotEmpty && end.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSlot = slot),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x2010B981),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                            if (hasTime) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$start - $end',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Body for Selected Slot
          Expanded(
            child: _isLoading && _templatesBySlot.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                  )
                : _buildSelectedSlotContent(_selectedSlot!),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSlotContent(String slot) {
    final template = _templatesBySlot[slot];
    final todayPosted = _todayPostedBySlot[slot];
    final templateDishes = template?.dishes ?? [];
    final slotTitle = _slotDisplayNames[slot] ?? slot;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // If Today's meal is specifically posted for this slot
        if (todayPosted != null && todayPosted.dishes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: todayPosted.menuType == 'special'
                  ? const LinearGradient(
                      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: todayPosted.menuType == 'special'
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFA7F3D0),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  todayPosted.menuType == 'special' ? '✨' : '🔥',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayPosted.menuType == 'special'
                            ? 'TODAY\'S SPECIAL $slotTitle'.toUpperCase()
                            : 'COOKED TODAY FOR $slotTitle'.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: todayPosted.menuType == 'special'
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Freshly announced by the mess owner for today',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${todayPosted.dishes.length} items',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: todayPosted.menuType == 'special'
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dishes cooked today
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayPosted.dishes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final dish = todayPosted.dishes[i];
              return _buildDishCard(
                dish,
                isTodayActive: true,
                menuType: todayPosted.menuType,
              );
            },
          ),
          const SizedBox(height: 20),
        ],

        // Section Title: Standard / Regular Offerings
        Row(
          children: [
            Text(
              todayPosted != null && todayPosted.dishes.isNotEmpty
                  ? 'Standard $slotTitle Repertoire'
                  : 'Standard $slotTitle Offerings',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${templateDishes.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Dishes regularly cooked by this mess for $slotTitle',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),

        // List of Visual Dish Cards with Images
        if (templateDishes.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templateDishes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final dish = templateDishes[i];
              return _buildDishCard(dish);
            },
          ),
        ] else if (todayPosted == null || todayPosted.dishes.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 10),
                Text(
                  'Standard Homestyle Food',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fresh nutritious meals cooked daily with authentic ingredients.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Footer note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Standard offerings are regular repertoire items. Active meals cooked today are highlighted above.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackFoodIcon(DishModel dish) {
    Color bg;
    final cat = dish.category.toLowerCase();
    final name = dish.name.toLowerCase();

    if (cat.contains('dal') || name.contains('dal') || name.contains('sambar')) {
      bg = const Color(0xFFFEF3C7);
    } else if (cat.contains('roti') || name.contains('roti') || name.contains('paratha')) {
      bg = const Color(0xFFFFF1F2);
    } else if (cat.contains('rice') || name.contains('rice') || name.contains('biryani')) {
      bg = const Color(0xFFEFF6FF);
    } else if (cat.contains('sweet') || name.contains('kheer') || name.contains('halwa')) {
      bg = const Color(0xFFFCE7F3);
    } else if (cat.contains('non') || dish.dishFoodType == 'nonveg') {
      bg = const Color(0xFFFEE2E2);
    } else {
      bg = const Color(0xFFDCFCE7);
    }

    String emoji = '🥗';
    if (cat.contains('dal') || name.contains('dal')) emoji = '🍲';
    else if (cat.contains('roti') || name.contains('roti') || name.contains('naan')) emoji = '🫓';
    else if (cat.contains('rice') || name.contains('rice') || name.contains('biryani')) emoji = '🍚';
    else if (cat.contains('sweet') || name.contains('kheer')) emoji = '🍨';
    else if (cat.contains('snack')) emoji = '🥟';
    else if (dish.dishFoodType == 'nonveg' || cat.contains('non')) emoji = '🍗';

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 26),
      ),
    );
  }

  Widget _buildDishCard(
    DishModel dish, {
    bool isTodayActive = false,
    String? menuType,
  }) {
    Color badgeBg;
    Color badgeText;
    final cat = dish.category.toLowerCase();

    if (cat.contains('veg') && !cat.contains('non')) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
    } else if (cat.contains('non') || dish.dishFoodType == 'nonveg') {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFB91C1C);
    } else if (cat.contains('roti') || cat.contains('bread')) {
      badgeBg = const Color(0xFFFFF1F2);
      badgeText = const Color(0xFFBE123C);
    } else if (cat.contains('dal')) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
    } else if (cat.contains('rice')) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF1D4ED8);
    } else if (cat.contains('sweet')) {
      badgeBg = const Color(0xFFFCE7F3);
      badgeText = const Color(0xFF9D174D);
    } else {
      badgeBg = const Color(0xFFF3F4F6);
      badgeText = const Color(0xFF4B5563);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTodayActive
              ? (menuType == 'special' ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
              : const Color(0xFFE5E7EB),
          width: isTodayActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isTodayActive
                ? (menuType == 'special' ? const Color(0x15F59E0B) : const Color(0x1510B981))
                : const Color(0x06000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Dish Image with appetizing fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 58,
              height: 58,
              child: (dish.imageUrl.isNotEmpty && !dish.imageUrl.contains('placeholder'))
                  ? Image.network(
                      dish.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackFoodIcon(dish),
                    )
                  : _buildFallbackFoodIcon(dish),
            ),
          ),
          const SizedBox(width: 14),

          // Dish Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dish.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTodayActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: menuType == 'special'
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          menuType == 'special' ? '✨ Special' : 'Today',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: menuType == 'special'
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dish.category,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Homestyle Prepared',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isTodayActive
                  ? (menuType == 'special' ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5))
                  : const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTodayActive
                    ? (menuType == 'special' ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0))
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Icon(
              isTodayActive ? Icons.local_fire_department_rounded : Icons.check,
              size: 14,
              color: isTodayActive
                  ? (menuType == 'special' ? const Color(0xFFD97706) : const Color(0xFF059669))
                  : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
