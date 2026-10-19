import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class OwnerAnalyticsPage extends ConsumerStatefulWidget {
  const OwnerAnalyticsPage({super.key});

  @override
  ConsumerState<OwnerAnalyticsPage> createState() => _OwnerAnalyticsPageState();
}

class _OwnerAnalyticsPageState extends ConsumerState<OwnerAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(ownerDashboardProvider);
    final messId = dashboardState.mess?.messId;

    if (messId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dishRatingsAsync = ref.watch(dishRatingsProvider(messId));
    final messReviewsAsync = ref.watch(messReviewsProvider(messId));
    final feedbacksAsync = ref.watch(ownerFeedbacksProvider(messId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(
          'Rating & Analytics',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF22C55E),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF22C55E),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(
                  icon: Icon(Icons.restaurant_menu_rounded, size: 18),
                  text: 'Food Ratings',
                ),
                Tab(
                  icon: Icon(Icons.star_rate_rounded, size: 18),
                  text: 'Mess Ratings',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Food Ratings
            _buildFoodRatingsTab(dishRatingsAsync, feedbacksAsync),

            // Tab 2: Mess Ratings & Reviews
            _buildMessReviewsTab(messReviewsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodRatingsTab(
    AsyncValue<List<DishRatingModel>> dishRatingsAsync,
    AsyncValue<List<FeedbackModel>> feedbacksAsync,
  ) {
    return dishRatingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      ),
      error: (err, _) => Center(child: Text('Error loading food ratings: $err')),
      data: (dishRatings) {
        // Fallback / combine with legacy feedbacks if needed
        final feedbacks = feedbacksAsync.valueOrNull ?? [];

        // Build Map of Dish Name -> Ratings & comments
        final Map<String, List<DishRatingModel>> ratingsByDish = {};
        for (var dr in dishRatings) {
          ratingsByDish.putIfAbsent(dr.dishName, () => []).add(dr);
        }

        // If no dish_ratings yet, check legacy feedbacks
        if (ratingsByDish.isEmpty && feedbacks.isNotEmpty) {
          for (var f in feedbacks) {
            for (var dish in f.dishes) {
              ratingsByDish.putIfAbsent(dish, () => []).add(
                DishRatingModel(
                  ratingId: f.feedbackId,
                  messId: f.messId,
                  studentId: f.studentId,
                  studentName: 'Student',
                  dishName: dish,
                  rating: f.rating,
                  comment: f.comment,
                  updatedAt: f.date,
                ),
              );
            }
          }
        }

        if (ratingsByDish.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.ramen_dining_outlined, size: 56, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 12),
                Text(
                  'No food ratings yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Students can rate dishes individually from the mess menu.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        }

        final List<Map<String, dynamic>> dishStats = ratingsByDish.entries.map((e) {
          final list = e.value;
          final avg = list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;
          final comments = list.where((r) => r.comment != null && r.comment!.isNotEmpty).toList();
          return {
            'name': e.key,
            'avg': avg,
            'count': list.length,
            'ratings': list,
            'comments': comments,
          };
        }).toList();

        dishStats.sort(
          (a, b) => (b['avg'] as double).compareTo(a['avg'] as double),
        );

        final totalRatingsCount = dishStats.fold<int>(0, (acc, item) => acc + (item['count'] as int));
        final overallFoodAvg = dishStats.fold<double>(0.0, (acc, item) => acc + (item['avg'] as double)) / dishStats.length;

        final topRated = dishStats.where((d) => (d['avg'] as double) >= 4.0).take(5).toList();
        final needsImprovement = dishStats.where((d) => (d['avg'] as double) < 4.0).toList();
        needsImprovement.sort((a, b) => (a['avg'] as double).compareTo(b['avg'] as double));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallCard(
                title: 'Overall Food Satisfaction',
                average: overallFoodAvg,
                subtitle: 'Based on $totalRatingsCount individual dish ratings across ${dishStats.length} dishes',
                icon: Icons.fastfood_rounded,
              ),
              const SizedBox(height: 24),

              if (topRated.isNotEmpty) ...[
                Text(
                  'Top Rated Dishes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ...topRated.map((d) => _buildDishDetailItem(d, isLow: false)),
                const SizedBox(height: 24),
              ],

              if (needsImprovement.isNotEmpty) ...[
                Text(
                  'Needs Improvement',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ...needsImprovement.take(5).map((d) => _buildDishDetailItem(d, isLow: true)),
                const SizedBox(height: 24),
              ],

              // All Rated Dishes section
              Text(
                'All Dish Scores (${dishStats.length})',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              ...dishStats.map((d) => _buildDishDetailItem(d, isLow: (d['avg'] as double) < 3.0)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessReviewsTab(AsyncValue<List<MessReviewModel>> reviewsAsync) {
    return reviewsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      ),
      error: (err, _) => Center(child: Text('Error loading reviews: $err')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border_rounded, size: 56, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 12),
                Text(
                  'No mess reviews yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Students can write overall mess reviews from the Discover section.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        }

        final double totalRating = reviews.fold(0.0, (acc, r) => acc + r.rating);
        final double averageRating = totalRating / reviews.length;

        // Rating distribution counts
        final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (var r in reviews) {
          final rounded = r.rating.round().clamp(1, 5);
          distribution[rounded] = (distribution[rounded] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallCard(
                title: 'Overall Mess Rating',
                average: averageRating,
                subtitle: 'Based on ${reviews.length} student reviews',
                icon: Icons.stars_rounded,
              ),
              const SizedBox(height: 20),

              // Breakdown distribution
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Breakdown',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(5, (i) {
                      final star = 5 - i;
                      final count = distribution[star] ?? 0;
                      final pct = reviews.isNotEmpty ? count / reviews.length : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              '$star★',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$count',
                                textAlign: TextAlign.end,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Student Reviews (${reviews.length})',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),

              ...reviews.map((r) => _buildReviewCard(r)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallCard({
    required String title,
    required double average,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322C55E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      average.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ 5.0',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white, size: 56),
        ],
      ),
    );
  }

  Widget _buildDishDetailItem(Map<String, dynamic> d, {required bool isLow}) {
    final dishName = d['name'] as String;
    final avg = (d['avg'] as double).toStringAsFixed(1);
    final count = d['count'] as int;
    final comments = d['comments'] as List<DishRatingModel>;

    Color ratingColor = isLow ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dishName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    avg,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ratingColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, color: ratingColor, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count ratings',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments.take(3).map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬 ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            '"${c.comment}"',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(MessReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFDCFCE7),
                child: Text(
                  review.studentName.isNotEmpty ? review.studentName[0].toUpperCase() : 'S',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.studentName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '${review.updatedAt.day}/${review.updatedAt.month}/${review.updatedAt.year}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
