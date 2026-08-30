import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';

class OwnerMenuPlannerV2Page extends ConsumerStatefulWidget {
  const OwnerMenuPlannerV2Page({super.key});

  @override
  ConsumerState<OwnerMenuPlannerV2Page> createState() => _OwnerMenuPlannerV2PageState();
}

class _OwnerMenuPlannerV2PageState extends ConsumerState<OwnerMenuPlannerV2Page> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerMenuProvider);
    final viewModel = ref.read(ownerMenuProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Weekly Planner',
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
            ),
            alignment: Alignment.center,
            child: Text(
              'Auto-repeats',
              style: GoogleFonts.inter(
                color: const Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: state.isLoading && state.weeklyTemplates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                final now = DateTime.now();
                final currentWeekday = now.weekday; // 1=Mon, 7=Sun
                final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
                const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                final monthName = months[startOfWeek.month - 1];
                
                return Column(
                  children: [
                // Days of the week selector
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$monthName ${startOfWeek.year}",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "THIS WEEK",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: _days.map((day) {
                            final isSelected = day == state.selectedDay;
                            final isToday = day == _days[DateTime.now().weekday - 1];
                            final dayIndex = _days.indexOf(day);
                            final currentDayDate = startOfWeek.add(Duration(days: dayIndex));
                            final dateStr = currentDayDate.day.toString().padLeft(2, '0');
                            
                            return GestureDetector(
                          onTap: () => viewModel.selectDay(day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  day,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? (isSelected ? Colors.white : const Color(0xFFF59E0B))
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

                // Meal Slot Tabs
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: (state.mess != null
                            ? ['morning', 'noon', 'evening', 'night']
                                .where((s) => state.mess!.mealTimings[s]?['enabled'] == 'true')
                                .toList()
                            : ['morning', 'noon', 'night'])
                        .map((slot) {
                      final isSelected = slot == state.selectedSlot;
                      final label = slot[0].toUpperCase() + slot.substring(1);
                      return GestureDetector(
                        onTap: () => viewModel.selectSlot(slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Dishes List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '${state.selectedDay} ${state.selectedSlot[0].toUpperCase()}${state.selectedSlot.substring(1)} Menu',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                      
                      ...state.selectedDishes.map((dish) => _buildDishCard(dish, viewModel)),
                      
                      const SizedBox(height: 12),
                      
                      // Add Dish Button
                      GestureDetector(
                        onTap: () => _showGlobalSearchBottomSheet(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF86EFAC), width: 2, style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, color: Color(0xFF16A34A)),
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
                      
                      const SizedBox(height: 100), // Padding for floating button
                    ],
                  ),
                ),
              ],
            );
          },
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
                        const SnackBar(content: Text('Menu saved successfully!')),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  label: Text(
                    'Save ${state.selectedDay} Menu',
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
          )
        ],
      ),
      child: Row(
        children: [
          // Dish Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.network(
                (dish.imageUrl?.isNotEmpty ?? false) ? dish.imageUrl! : 'https://via.placeholder.com/100',
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dish.category == 'Veg' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dish.category,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: dish.category == 'Veg' ? Colors.green[700] : Colors.red[700],
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
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
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
  ConsumerState<_GlobalSearchBottomSheet> createState() => _GlobalSearchBottomSheetState();
}

class _GlobalSearchBottomSheetState extends ConsumerState<_GlobalSearchBottomSheet> {
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
                )
              ],
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
                          final isAlreadyAdded = state.selectedDishes.any((d) => d.dishId == dish.dishId);
                          
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
                                    (dish.imageUrl?.isNotEmpty ?? false) ? dish.imageUrl! : 'https://via.placeholder.com/60',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.restaurant, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                dish.name,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                dish.category,
                                style: GoogleFonts.inter(
                                  color: dish.category == 'Veg' ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isAlreadyAdded
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : ElevatedButton(
                                      onPressed: () {
                                        viewModel.addDish(dish);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
