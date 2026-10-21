import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/app_models.dart';
import '../../../../services/localization_service.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/student_inspired_theme.dart';

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
    final isHindi = ref.watch(localizationProvider) == 'hi';
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

    final dishRatingsAsync = ref.watch(dishRatingsProvider(widget.mess.messId));
    final allDishRatings = dishRatingsAsync.valueOrNull ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: StudentColors.canvasWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: StudentColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: StudentColors.sageLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudentColors.sageBorder),
                  ),
                  child: const Text('🍽️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.mess.name} ${isHindi ? 'मेन्यू' : 'Menu'}',
                        style: StudentTypography.serifHeading(
                          fontSize: 20,
                          color: StudentColors.walnut,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHindi
                            ? 'नियमित भोजन सूची एवं समय'
                            : 'Regular offerings & meal timings',
                        style: StudentTypography.body(
                          fontSize: 12,
                          color: StudentColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: StudentColors.walnutMuted),
                ),
              ],
            ),
          ),

          // Meal Slot Tabs (Breakfast, Lunch, Dinner)
          Container(
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
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? StudentColors.walnut : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? StudentColors.walnut : StudentColors.borderSubtle,
                          ),
                          boxShadow: isSelected ? StudentColors.softShadow : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : StudentColors.textDark,
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
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : StudentColors.textMuted,
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

          const Divider(height: 1, color: StudentColors.borderSubtle),

          // Body for Selected Slot
          Expanded(
            child: _isLoading && _templatesBySlot.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: StudentColors.sage),
                  )
                : _buildSelectedSlotContent(_selectedSlot!, allDishRatings, isHindi),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSlotContent(
    String slot,
    List<DishRatingModel> allDishRatings,
    bool isHindi,
  ) {
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
              color: todayPosted.menuType == 'special'
                  ? StudentColors.amberLight
                  : StudentColors.sageLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: todayPosted.menuType == 'special'
                    ? StudentColors.amberPill
                    : StudentColors.sageBorder,
                width: 1.5,
              ),
              boxShadow: StudentColors.softShadow,
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
                            ? (isHindi ? 'आज का विशेष $slotTitle' : 'TODAY\'S SPECIAL $slotTitle').toUpperCase()
                            : (isHindi ? 'आज तैयार $slotTitle' : 'COOKED TODAY FOR $slotTitle').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: todayPosted.menuType == 'special'
                              ? StudentColors.amberDark
                              : StudentColors.sageDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isHindi
                            ? 'मेस संचालक द्वारा आज के लिए घोषित'
                            : 'Freshly announced by the mess owner for today',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: StudentColors.textDark.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${todayPosted.dishes.length} items',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: todayPosted.menuType == 'special'
                          ? StudentColors.amberDark
                          : StudentColors.sageDark,
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
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final dish = todayPosted.dishes[i];
              return _buildDishCard(
                dish,
                isTodayActive: true,
                menuType: todayPosted.menuType,
                allDishRatings: allDishRatings,
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
                  ? (isHindi ? 'मानक $slotTitle मेन्यू' : 'Standard $slotTitle Repertoire')
                  : (isHindi ? 'मानक $slotTitle मेन्यू' : 'Standard $slotTitle Offerings'),
              style: StudentTypography.serifHeading(
                fontSize: 16,
                color: StudentColors.walnut,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StudentColors.borderSubtle),
              ),
              child: Text(
                '${templateDishes.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: StudentColors.walnut,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isHindi
              ? '$slotTitle के लिए इस मेस के नियमित व्यंजन'
              : 'Dishes regularly cooked by this mess for $slotTitle',
          style: StudentTypography.body(
            fontSize: 12,
            color: StudentColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),

        // List of Visual Dish Cards with Images
        if (templateDishes.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templateDishes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final dish = templateDishes[i];
              return _buildDishCard(
                dish,
                allDishRatings: allDishRatings,
              );
            },
          ),
        ] else if (todayPosted == null || todayPosted.dishes.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StudentColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: StudentColors.walnutMuted,
                ),
                const SizedBox(height: 10),
                Text(
                  isHindi ? 'घर जैसा शुद्ध भोजन' : 'Standard Homestyle Food',
                  style: StudentTypography.bold(
                    fontSize: 14,
                    color: StudentColors.walnut,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHindi
                      ? 'ताजा और पौष्टिक भोजन प्रतिदिन प्रामाणिक मसालों के साथ पकाया जाता है।'
                      : 'Fresh nutritious meals cooked daily with authentic ingredients.',
                  textAlign: TextAlign.center,
                  style: StudentTypography.body(
                    fontSize: 12,
                    color: StudentColors.textMuted,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StudentColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: StudentColors.amberDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHindi
                      ? 'मानक व्यंजन नियमित मेन्यू सूची हैं। आज पकाए जा रहे विशेष व्यंजन ऊपर हाइलाइट किए गए हैं।'
                      : 'Standard offerings are regular repertoire items. Active meals cooked today are highlighted above.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: StudentColors.textMuted,
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
      bg = StudentColors.amberLight;
    } else if (cat.contains('roti') || name.contains('roti') || name.contains('paratha')) {
      bg = const Color(0xFFF9EAE1);
    } else if (cat.contains('rice') || name.contains('rice') || name.contains('biryani')) {
      bg = const Color(0xFFEFF3F8);
    } else if (cat.contains('sweet') || name.contains('kheer') || name.contains('halwa')) {
      bg = const Color(0xFFFCE7F3);
    } else if (cat.contains('non') || dish.dishFoodType == 'nonveg') {
      bg = StudentColors.brickRedLight;
    } else {
      bg = StudentColors.sageLight;
    }

    String emoji = '🥗';
    if (cat.contains('dal') || name.contains('dal')) {
      emoji = '🍲';
    } else if (cat.contains('roti') || name.contains('roti') || name.contains('naan')) {
      emoji = '🫓';
    } else if (cat.contains('rice') || name.contains('rice') || name.contains('biryani')) {
      emoji = '🍚';
    } else if (cat.contains('sweet') || name.contains('kheer')) {
      emoji = '🍨';
    } else if (cat.contains('snack')) {
      emoji = '🥟';
    } else if (dish.dishFoodType == 'nonveg' || cat.contains('non')) {
      emoji = '🍗';
    }

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
    required List<DishRatingModel> allDishRatings,
  }) {
    Color badgeBg;
    Color badgeText;
    final cat = dish.category.toLowerCase();

    if (cat.contains('veg') && !cat.contains('non')) {
      badgeBg = StudentColors.sageLight;
      badgeText = StudentColors.sageDark;
    } else if (cat.contains('non') || dish.dishFoodType == 'nonveg') {
      badgeBg = StudentColors.brickRedLight;
      badgeText = StudentColors.brickRed;
    } else if (cat.contains('roti') || cat.contains('bread')) {
      badgeBg = const Color(0xFFFFF1F2);
      badgeText = const Color(0xFFBE123C);
    } else if (cat.contains('dal')) {
      badgeBg = StudentColors.amberLight;
      badgeText = StudentColors.amberDark;
    } else if (cat.contains('rice')) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF1D4ED8);
    } else if (cat.contains('sweet')) {
      badgeBg = const Color(0xFFFCE7F3);
      badgeText = const Color(0xFF9D174D);
    } else {
      badgeBg = StudentColors.surfaceWarm;
      badgeText = StudentColors.textDark;
    }

    final currentStudent = ref.watch(studentHomeProvider).student;
    final currentUid = currentStudent?.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final dishRatings = allDishRatings
        .where((r) => r.dishName.trim().toLowerCase() == dish.name.trim().toLowerCase())
        .toList();
    final myRating = dishRatings.where((r) => r.studentId == currentUid).firstOrNull;
    final double avgDishRating = dishRatings.isNotEmpty
        ? dishRatings.map((r) => r.rating).reduce((a, b) => a + b) / dishRatings.length
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTodayActive
              ? (menuType == 'special' ? StudentColors.amber : StudentColors.sage)
              : StudentColors.borderSubtle,
          width: isTodayActive ? 1.5 : 1.0,
        ),
        boxShadow: StudentColors.softShadow,
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
                      errorBuilder: (context, error, stackTrace) => _buildFallbackFoodIcon(dish),
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
                          color: StudentColors.walnut,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTodayActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: menuType == 'special'
                              ? StudentColors.amberLight
                              : StudentColors.sageLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: menuType == 'special'
                                ? StudentColors.amberPill
                                : StudentColors.sageBorder,
                          ),
                        ),
                        child: Text(
                          menuType == 'special' ? '✨ Special' : 'Today',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: menuType == 'special'
                                ? StudentColors.amberDark
                                : StudentColors.sageDark,
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
                        color: StudentColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Interactive Dish Rating Action
          InkWell(
            onTap: () => _openDishRatingDialog(dish, myRating, allDishRatings),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: myRating != null
                    ? StudentColors.amberLight
                    : (dishRatings.isNotEmpty ? StudentColors.canvasWarm : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: myRating != null
                      ? StudentColors.amber
                      : StudentColors.borderSubtle,
                  width: myRating != null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    myRating != null ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: myRating != null ? StudentColors.amberDark : StudentColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    myRating != null
                        ? myRating.rating.toStringAsFixed(1)
                        : (dishRatings.isNotEmpty ? avgDishRating.toStringAsFixed(1) : 'Rate'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: myRating != null ? FontWeight.bold : FontWeight.w600,
                      color: myRating != null
                          ? StudentColors.amberDark
                          : StudentColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDishRatingDialog(
    DishModel dish,
    DishRatingModel? existingRating,
    List<DishRatingModel> allDishRatings,
  ) {
    final currentStudent = ref.read(studentHomeProvider).student;
    final currentUid = currentStudent?.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final studentName = currentStudent?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Student';

    if (currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to rate dishes.')),
      );
      return;
    }

    final dishRatings = allDishRatings
        .where((r) => r.dishName.trim().toLowerCase() == dish.name.trim().toLowerCase())
        .toList();
    final double avgRating = dishRatings.isNotEmpty
        ? dishRatings.map((r) => r.rating).reduce((a, b) => a + b) / dishRatings.length
        : 0.0;

    double selectedRating = existingRating?.rating ?? 5.0;
    final commentCtrl = TextEditingController(text: existingRating?.comment ?? '');
    bool isSubmitting = false;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final isEditing = existingRating != null;
          return Container(
            decoration: const BoxDecoration(
              color: StudentColors.canvasWarm,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StudentColors.borderSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: (dish.imageUrl.isNotEmpty && !dish.imageUrl.contains('placeholder'))
                              ? Image.network(
                                  dish.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackFoodIcon(dish),
                                )
                              : _buildFallbackFoodIcon(dish),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.name,
                              style: StudentTypography.serifHeading(
                                fontSize: 18,
                                color: StudentColors.walnut,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dishRatings.isNotEmpty
                                  ? '⭐ ${avgRating.toStringAsFixed(1)} (${dishRatings.length} ratings)'
                                  : 'No ratings yet • Be the first to rate!',
                              style: StudentTypography.body(
                                fontSize: 12,
                                color: StudentColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      isEditing ? 'Update Your Rating' : 'Rate This Dish',
                      style: StudentTypography.bold(
                        fontSize: 15,
                        color: StudentColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = (index + 1).toDouble();
                      final isSelected = starValue <= selectedRating;
                      return IconButton(
                        iconSize: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: StudentColors.amber,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedRating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: StudentColors.amberLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedRating == 5
                            ? '🤩 Delicious!'
                            : selectedRating == 4
                                ? '😋 Very Good'
                                : selectedRating == 3
                                    ? '😐 Average'
                                    : selectedRating == 2
                                        ? '🙁 Needs Improvement'
                                        : '😞 Poor',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: StudentColors.amberDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 2,
                    style: StudentTypography.body(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Share feedback or note about taste, oil, salt... (optional)',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: StudentColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: StudentColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: StudentColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: StudentColors.amber, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (isEditing) ...[
                        OutlinedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    await ref.read(appServiceProvider).deleteDishRating(
                                          widget.mess.messId,
                                          existingRating.ratingId,
                                        );
                                    if (!mounted) return;
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Rating removed for ${dish.name}'),
                                          backgroundColor: StudentColors.brickRed,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    if (sheetContext.mounted) {
                                      setModalState(() => isSubmitting = false);
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to delete: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.delete_outline, size: 18, color: StudentColors.brickRed),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.inter(color: StudentColors.brickRed, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: StudentColors.brickRedBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    final ratingModel = DishRatingModel(
                                      ratingId: existingRating?.ratingId ?? '',
                                      messId: widget.mess.messId,
                                      studentId: currentUid,
                                      studentName: studentName,
                                      dishName: dish.name,
                                      rating: selectedRating,
                                      comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                                    );
                                    await ref.read(appServiceProvider).submitOrUpdateDishRating(ratingModel);
                                    if (!mounted) return;
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing
                                                ? 'Updated rating for ${dish.name}!'
                                                : 'Rating saved for ${dish.name}!',
                                          ),
                                          backgroundColor: StudentColors.sage,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    if (sheetContext.mounted) {
                                      setModalState(() => isSubmitting = false);
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to save rating: $e')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StudentColors.amber,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEditing ? 'Update Rating' : 'Save Rating',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
        },
      ),
    );
  }
}
