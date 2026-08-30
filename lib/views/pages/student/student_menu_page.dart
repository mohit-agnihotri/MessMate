import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/dish_catalog_service.dart';
import '../../../models/app_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../viewmodels/all_viewmodels.dart';

class StudentMenuPage extends ConsumerStatefulWidget {
  const StudentMenuPage({super.key});
  @override
  ConsumerState<StudentMenuPage> createState() => _StudentMenuPageState();
}

class _StudentMenuPageState extends ConsumerState<StudentMenuPage> {
  int _selectedDay = DateTime.now().weekday - 1;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late Future<List<DishModel>> _morningDishes;
  late Future<List<DishModel>> _lunchDishes;
  late Future<List<DishModel>> _dinnerDishes;

  @override
  void initState() {
    super.initState();
    _morningDishes = DishCatalogService.searchDishes('poha', limit: 2);
    _lunchDishes = DishCatalogService.getByCategory('veg', limit: 4);
    _dinnerDishes = DishCatalogService.getByCategory('nonveg', limit: 2);
  }

  @override 
  Widget build(BuildContext context) {
    final state = ref.watch(studentHomeProvider);
    final mess = state.mess;
    
    // Fallback if no mess loaded yet
    final isMorningEnabled = mess?.mealTimings['morning']?['enabled'] == 'true';
    final isNoonEnabled = mess?.mealTimings['noon']?['enabled'] == 'true';
    final isEveningEnabled = mess?.mealTimings['evening']?['enabled'] == 'true';
    final isNightEnabled = mess?.mealTimings['night']?['enabled'] == 'true';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildDaySelector()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (isMorningEnabled) _buildMealSection(context, 'Morning', 'morning', _morningDishes, null),
                if (isMorningEnabled) const SizedBox(height: 24),
                if (isNoonEnabled) _buildMealSection(context, 'Noon', 'noon', _lunchDishes, null),
                if (isNoonEnabled) const SizedBox(height: 24),
                if (isEveningEnabled) _buildMealSection(context, 'Evening', 'evening', _lunchDishes, null), // Reusing lunch dishes mock
                if (isEveningEnabled) const SizedBox(height: 24),
                if (isNightEnabled) _buildMealSection(context, 'Night', 'night', _dinnerDishes, '⚠️ Skipping counts as a full day deduction'),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text("This Week's Menu",
        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = _selectedDay == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF22C55E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                  ? [const BoxShadow(color: Color(0x3322C55E), blurRadius: 8, offset: Offset(0, 3))]
                  : [],
              ),
              child: Text(_days[i], style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String title, String slot, Future<List<DishModel>> dishesFuture, String? warning) {
    final icons = {'morning': Icons.wb_twilight, 'noon': Icons.wb_sunny, 'evening': Icons.wb_iridescent, 'night': Icons.nights_stay};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icons[slot], color: const Color(0xFFF59E0B), size: 20),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800,
            color: const Color(0xFF111827), letterSpacing: 0.5)),
      ]),
      const SizedBox(height: 10),
      if (warning != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(warning,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E), fontWeight: FontWeight.w500))),
          ]),
        ),
      ],
      FutureBuilder<List<DishModel>>(
        future: dishesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)));
          final dishes = snapshot.data!;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
            ),
            itemCount: dishes.length,
            itemBuilder: (_, i) => _buildDishCard(dishes[i]),
          );
        }
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _buildRateButton(context, title, 'mock_id', slot)),
      ]),
    ]);
  }

  Widget _buildDishCard(DishModel dish) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.hardEdge,
          child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: dish.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.restaurant, size: 36, color: Color(0xFF9CA3AF))),
                )
              : const Center(child: Icon(Icons.restaurant, size: 36, color: Color(0xFF9CA3AF))),
        ),
        Positioned(
          top: 8, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: dish.category == 'nonveg' ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(dish.category.toUpperCase(),
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            ),
            child: Text(dish.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
          ),
        ),
      ]),
    );
  }

  Widget _buildRateButton(BuildContext context, String mealName, String menuId, String slot) {
    return GestureDetector(
      onTap: () => _showRatingBottomSheet(context, mealName, menuId, slot),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 4),
          Text('Rate This Meal', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
        ]),
      ),
    );
  }

  void _showRatingBottomSheet(BuildContext context, String mealName, String menuId, String slot) {
    int rating = 5;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Rate $mealName', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('How was the food?', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(index < rating ? Icons.star_rounded : Icons.star_border_rounded, size: 40, color: const Color(0xFFF59E0B)),
                  onPressed: () => setModalState(() => rating = index + 1),
                );
              })),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: rating > 0 ? () async {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted to Database!'), backgroundColor: Color(0xFF22C55E)));
                    }
                  } : null,
                  child: Text('Submit Rating', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          );
        },
      ),
    );
  }
}
