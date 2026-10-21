import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'widgets/post_today_meal_sheet.dart';
import 'theme/owner_inspired_theme.dart';

class OwnerMenuPlannerV2Page extends ConsumerStatefulWidget {
  const OwnerMenuPlannerV2Page({super.key});

  @override
  ConsumerState<OwnerMenuPlannerV2Page> createState() =>
      _OwnerMenuPlannerV2PageState();
}

class _OwnerMenuPlannerV2PageState
    extends ConsumerState<OwnerMenuPlannerV2Page> {

  String _slotShortLabel(String slot) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerMenuProvider);
    final viewModel = ref.read(ownerMenuProvider.notifier);

    final enabledSlots = (state.mess != null
            ? ['morning', 'noon', 'evening', 'night']
                .where((s) => state.mess!.mealTimings[s]?['enabled'] == 'true')
                .toList()
            : ['morning', 'noon', 'night']);

    final activeSlot = enabledSlots.contains(state.selectedSlot)
        ? state.selectedSlot
        : (enabledSlots.isNotEmpty ? enabledSlots.first : 'morning');

    final slotName = _slotShortLabel(activeSlot);
    final messName = state.mess?.name ?? 'Mahakal';
    final dishes = state.selectedDishes;
    final slotAsset = 'assets/images/slot_$activeSlot.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: state.isLoading && state.weeklyTemplates.isEmpty
            ? const Center(child: CircularProgressIndicator(color: OwnerColors.sage))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // ── Top Header (Screenshot 2) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STANDARD DAILY MENU',
                            style: OwnerTypography.overline(
                              color: OwnerColors.textOverline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Menu',
                            style: OwnerTypography.serifHeading(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: OwnerColors.textDark,
                            ),
                          ),
                        ],
                      ),

                      // Mahakal · Settings pill (opens Drawer)
                      GestureDetector(
                        onTap: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: OwnerColors.sageLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: OwnerColors.sageBorder.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '$messName · Settings',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: OwnerColors.sageText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Standard vs Today's special Pill Toggle (Screenshot 2) ──
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: OwnerColors.sageLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        // Standard (Active)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: OwnerColors.walnut,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Standard',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFDE8CD),
                              ),
                            ),
                          ),
                        ),

                        // Today's special (opens sheet)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (state.mess != null) {
                                PostTodayMealSheet.show(
                                  context,
                                  mess: state.mess!,
                                  initialSlot: activeSlot,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              child: Text(
                                "Today's special",
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: OwnerColors.sageText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Slot Selector Cards: Morning / Noon / Night (Screenshot 2) ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: enabledSlots.map((s) {
                        final isSelected = s == activeSlot;
                        final timings = state.mess?.mealTimings[s];
                        final start = timings?['start'] ?? '';
                        final end = timings?['end'] ?? '';
                        final timeRange = (start.isNotEmpty && end.isNotEmpty) ? '$start-$end' : (start.isNotEmpty ? start : '');

                        // Distinct colors matching screenshot
                        Color cardBg;
                        Color textC;
                        Color timeC;
                        if (isSelected) {
                          if (s == 'morning') {
                            cardBg = OwnerColors.amber;
                            textC = OwnerColors.textDark;
                            timeC = OwnerColors.textDark.withValues(alpha: 0.7);
                          } else if (s == 'noon') {
                            cardBg = const Color(0xFF869E87);
                            textC = Colors.white;
                            timeC = Colors.white70;
                          } else {
                            cardBg = OwnerColors.walnut;
                            textC = Colors.white;
                            timeC = Colors.white70;
                          }
                        } else {
                          cardBg = OwnerColors.cardPure;
                          textC = OwnerColors.textDark;
                          timeC = OwnerColors.textMuted;
                        }

                        return GestureDetector(
                          onTap: () => viewModel.selectSlot(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 115,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : OwnerColors.cardBorder,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: cardBg.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : OwnerColors.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _slotShortLabel(s),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textC,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeRange.isNotEmpty ? timeRange : '12:30',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: timeC,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Hero Slot Banner Image (Screenshot 2) ──
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: OwnerColors.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            slotAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: OwnerColors.amber,
                              alignment: Alignment.center,
                              child: Text(
                                'Your existing $slotName image',
                                style: GoogleFonts.inter(
                                  color: OwnerColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Standard $slotName Banner',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section Title: Breakfast · X dishes & Repeats daily (Screenshot 2) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$slotName · ${dishes.length} dishes',
                        style: OwnerTypography.serifHeading(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: OwnerColors.sageLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: OwnerColors.sageBorder.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Repeats daily',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.sageText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Dish Cards ──
                  if (dishes.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: OwnerColors.cardPure,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: OwnerColors.cardBorder),
                        boxShadow: OwnerColors.softShadow,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 38,
                              color: OwnerColors.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No dishes added for $slotName yet',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: OwnerColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add dishes from the catalog so students see the menu.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: OwnerColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...dishes.map((dish) => _buildDishCard(dish, viewModel)),

                  const SizedBox(height: 8),

                  // ── Dashed "+ Add dish from catalog" Button (Screenshot 2) ──
                  GestureDetector(
                    onTap: () => _showGlobalSearchBottomSheet(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: OwnerColors.sageLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: OwnerColors.sage.withValues(alpha: 0.6),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+ Add dish from catalog',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.sageText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Solid "Save breakfast menu" Button (Screenshot 2) ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await viewModel.saveTemplate();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$slotName menu saved and active for all days!'),
                              backgroundColor: OwnerColors.sage,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OwnerColors.sage,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save ${slotName.toLowerCase()} menu',
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
    );
  }

  // ── Dish Card matching Screenshot 2 ──
  Widget _buildDishCard(DishModel dish, OwnerMenuViewModel viewModel) {
    final isVeg = dish.category.toLowerCase().contains('veg');
    final thumbColor = isVeg ? OwnerColors.amber : const Color(0xFF869E87);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OwnerColors.cardPure,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OwnerColors.cardBorder),
        boxShadow: OwnerColors.softShadow,
      ),
      child: Row(
        children: [
          // Left rounded square thumbnail (Screenshot 2)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: thumbColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
              color: OwnerColors.textDark.withValues(alpha: 0.8),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Dish Name & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dish.category.toLowerCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: OwnerColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Rating pill (4.0 ★) or Remove text (Screenshot 2)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OwnerColors.amberLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '4.0',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.amberText,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: OwnerColors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => viewModel.removeDish(dish),
                child: Text(
                  'Remove',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OwnerColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGlobalSearchBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GlobalSearchBottomSheet(),
    );
  }
}

// ── Global Search & Add Dish Bottom Sheet (Screenshot 12) ──
class _GlobalSearchBottomSheet extends ConsumerStatefulWidget {
  const _GlobalSearchBottomSheet();

  @override
  ConsumerState<_GlobalSearchBottomSheet> createState() =>
      _GlobalSearchBottomSheetState();
}

class _GlobalSearchBottomSheetState
    extends ConsumerState<_GlobalSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerMenuProvider);
    final viewModel = ref.read(ownerMenuProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: OwnerColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: "Add dish"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add dish',
                  style: OwnerTypography.serifHeading(fontSize: 24),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: OwnerColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Custom Dish Action Button (Screenshot 12)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                _showCreateCustomDishDialog(context, ref);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: OwnerColors.sageLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: OwnerColors.sage.withValues(alpha: 0.5)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+ Create custom dish for my mess',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: OwnerColors.sageText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search Field (Screenshot 12)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => viewModel.searchGlobalDishes(val),
              decoration: InputDecoration(
                hintText: 'Search e.g. Paneer, Dal, Rice...',
                hintStyle: GoogleFonts.inter(color: OwnerColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OwnerColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OwnerColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OwnerColors.sage),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Results / Empty state
          Expanded(
            child: state.searchResults.isEmpty && _searchController.text.isEmpty
                ? Center(
                    child: Text(
                      'Type to search global dishes\nor create a custom dish',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: OwnerColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: state.searchResults.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dish = state.searchResults[index];
                      final isSelected = state.selectedDishes.any((d) => d.dishId == dish.dishId);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: OwnerColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dish.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: OwnerColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    dish.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: OwnerColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isSelected ? null : () => viewModel.addDish(dish),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.grey[200] : OwnerColors.amber,
                                foregroundColor: isSelected ? Colors.grey : OwnerColors.textDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text(isSelected ? 'Added' : 'Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomDishDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String category = 'Sabzi';
    final categories = ['Sabzi', 'Dal', 'Roti', 'Rice', 'Snacks', 'Dessert'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: OwnerColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Create custom dish',
            style: OwnerTypography.serifHeading(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DISH NAME *', style: OwnerTypography.overline(color: OwnerColors.textOverline)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Shahi Paneer',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: OwnerColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('CATEGORY', style: OwnerTypography.overline(color: OwnerColors.textOverline)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OwnerColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('FOOD TYPE', style: OwnerTypography.overline(color: OwnerColors.textOverline)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OwnerColors.cardBorder),
                ),
                child: Text(
                  'Pure Veg · locked by mess setting',
                  style: GoogleFonts.inter(fontSize: 13, color: OwnerColors.textMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: OwnerColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final newDish = DishModel(
                    dishId: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    category: category,
                  );
                  ref.read(ownerMenuProvider.notifier).addDish(newDish);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerColors.amber,
                foregroundColor: OwnerColors.textDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Create & add'),
            ),
          ],
        ),
      ),
    );
  }
}
