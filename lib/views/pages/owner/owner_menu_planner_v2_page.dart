import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';

class OwnerMenuPlannerV2Page extends ConsumerStatefulWidget {
  const OwnerMenuPlannerV2Page({super.key});

  @override
  ConsumerState<OwnerMenuPlannerV2Page> createState() =>
      _OwnerMenuPlannerV2PageState();
}

class _OwnerMenuPlannerV2PageState
    extends ConsumerState<OwnerMenuPlannerV2Page> {

  String _slotLabel(String slot) {
    switch (slot) {
      case 'morning':
        return 'Morning (Breakfast)';
      case 'noon':
        return 'Noon (Lunch)';
      case 'evening':
        return 'Evening (Snacks)';
      case 'night':
        return 'Night (Dinner)';
      default:
        return slot[0].toUpperCase() + slot.substring(1);
    }
  }

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
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerMenuProvider);
    final viewModel = ref.read(ownerMenuProvider.notifier);

    final enabledSlots = (state.mess != null
            ? ['morning', 'noon', 'evening', 'night']
                .where(
                  (s) => state.mess!.mealTimings[s]?['enabled'] == 'true',
                )
                .toList()
            : ['morning', 'noon', 'night']);

    final activeSlot = enabledSlots.contains(state.selectedSlot)
        ? state.selectedSlot
        : (enabledSlots.isNotEmpty ? enabledSlots.first : 'noon');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Regular Mess Menu',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.all_inclusive_rounded,
                  size: 15,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  'Auto-repeats',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF059669),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isLoading && state.weeklyTemplates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Banner ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard Daily Mess Menu',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set standard dishes once for each meal. They repeat every day so students always see their menu!',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF047857),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Meal Slot Tabs (Derived Dynamically from Enabled Timings) ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: enabledSlots.map((slot) {
                        final isSelected = slot == activeSlot;
                        final timings = state.mess?.mealTimings[slot];
                        final timeStr = (timings != null &&
                                timings['start'] != null &&
                                timings['end'] != null)
                            ? '${timings['start']} - ${timings['end']}'
                            : '';

                        return GestureDetector(
                          onTap: () => viewModel.selectSlot(slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _slotIcon(slot),
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _slotShortLabel(slot),
                                      style: GoogleFonts.inter(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1F2937),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (timeStr.isNotEmpty)
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.85)
                                              : const Color(0xFF9CA3AF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Dishes List ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_slotLabel(activeSlot)} Dishes (${state.selectedDishes.length})',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            if (state.selectedDishes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Active Daily',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (state.selectedDishes.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.restaurant_menu_outlined,
                                size: 40,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No dishes added for ${_slotShortLabel(activeSlot)} yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add dishes below so students can see today’s ${_slotShortLabel(activeSlot)} menu.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      ...state.selectedDishes.map(
                        (dish) => _buildDishCard(dish, viewModel),
                      ),

                      const SizedBox(height: 8),

                      // Add Dish Button
                      GestureDetector(
                        onTap: () =>
                            _showGlobalSearchBottomSheet(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                              width: 1.5,
                              style: BorderStyle.solid,
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
                                'Add Dish from Global Catalog',
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

                      const SizedBox(
                        height: 100,
                      ), // Padding for floating button
                    ],
                  ),
                ),
              ],
            ),
      // Save Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: state.isLoading
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await viewModel.saveTemplate();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_slotShortLabel(activeSlot)} menu saved and active for all days!',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Save ${_slotShortLabel(activeSlot)} Menu',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDishCard(DishModel dish, OwnerMenuViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dish Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.network(
                (dish.imageUrl?.isNotEmpty ?? false)
                    ? dish.imageUrl!
                    : 'https://via.placeholder.com/100',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Dish Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: dish.category == 'Veg'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dish.category,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: dish.category == 'Veg'
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove Button
          GestureDetector(
            onTap: () => viewModel.removeDish(dish),
            child: Container(
              width: 48,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
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
      builder: (context) {
        return const _GlobalSearchBottomSheet();
      },
    );
  }
}

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
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
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
                  _showCreateCustomDishDialog(context, ref);
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
              onChanged: (val) {
                if (val.length >= 2) {
                  viewModel.searchGlobalDishes(val);
                }
              },
              decoration: InputDecoration(
                hintText: 'e.g. Paneer, Dal, Rice...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: state.isSearching
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Type to search global dishes'
                          : 'No dishes found',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final dish = state.searchResults[index];
                      final isAlreadyAdded = state.selectedDishes.any(
                        (d) => d.dishId == dish.dishId,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: Image.network(
                                (dish.imageUrl?.isNotEmpty ?? false)
                                    ? dish.imageUrl!
                                    : 'https://via.placeholder.com/60',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          title: Text(
                            dish.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            dish.category,
                            style: GoogleFonts.inter(
                              color: dish.category == 'Veg'
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isAlreadyAdded
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    viewModel.addDish(dish);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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


// ─── Create Custom Dish Dialog ────────────────────────────────────────────────
void _showCreateCustomDishDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final state = ref.read(ownerMenuProvider);
  final mess = state.mess;
  final foodType = mess?.foodType ?? 'both';

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
      builder: (context, setDialogState) {
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter dish name' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Shahi Paneer, Dal Makhani...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                          imageUrl: defaultCategoryImages[selectedCategory] ?? 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=800',
                          dishFoodType: selectedDishFoodType,
                        );

                        final appService = ref.read(appServiceProvider);
                        final messId = state.messId;

                        // 1. Add to mess subcollection /messes/{messId}/dishes/{dishId}
                        await appService.addDishToMess(messId, newDish);

                        // 2. Update masterDishNames cache on MessModel
                        if (mess != null) {
                          final names = List<String>.from(mess.masterDishNames);
                          if (!names.contains(newDish.name)) {
                            names.add(newDish.name);
                            final updatedMess = mess.copyWith(masterDishNames: names);
                            await appService.updateMess(updatedMess);
                          }
                        }

                        // 3. Add to current day's selected template
                        ref.read(ownerMenuProvider.notifier).addDish(newDish);

                        if (context.mounted) {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close search sheet
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save & Add'),
            ),
          ],
        );
      },
    ),
  );
}
