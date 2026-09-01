import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class OwnerAnalyticsPage extends ConsumerWidget {
  const OwnerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(ownerDashboardProvider);
    final messId = dashboardState.mess?.messId;

    if (messId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final feedbacksAsync = ref.watch(ownerFeedbacksProvider(messId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(
          'Food Rating & Analytics',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: feedbacksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF22C55E)),
          ),
          error: (err, stack) =>
              Center(child: Text('Error loading analytics: $err')),
          data: (feedbacks) {
            if (feedbacks.isEmpty) {
              return Center(
                child: Text(
                  'No ratings yet.',
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                ),
              );
            }

            final totalRatings = feedbacks.length;
            final averageRating =
                feedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
                totalRatings;

            // Calculate per dish ratings
            final Map<String, List<double>> dishRatingsMap = {};
            for (var f in feedbacks) {
              for (var dish in f.dishes) {
                dishRatingsMap.putIfAbsent(dish, () => []).add(f.rating);
              }
            }

            final List<Map<String, dynamic>> dishStats = dishRatingsMap.entries
                .map((e) {
                  final avg = e.value.reduce((a, b) => a + b) / e.value.length;
                  return {'name': e.key, 'avg': avg, 'count': e.value.length};
                })
                .toList();

            dishStats.sort(
              (a, b) => (b['avg'] as double).compareTo(a['avg'] as double),
            );

            final topRated = dishStats
                .where((d) => (d['avg'] as double) >= 4.0)
                .take(5)
                .toList();
            final needsImprovement = dishStats
                .where((d) => (d['avg'] as double) < 4.0)
                .toList();
            // Sort needs improvement ascending so lowest is first
            needsImprovement.sort(
              (a, b) => (a['avg'] as double).compareTo(b['avg'] as double),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallRatingCard(averageRating, totalRatings),
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
                    ...topRated.map(
                      (d) => _buildDishRatingItem(
                        d['name'],
                        (d['avg'] as double).toStringAsFixed(1),
                        d['count'],
                      ),
                    ),
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
                    ...needsImprovement
                        .take(5)
                        .map(
                          (d) => _buildDishRatingItem(
                            d['name'],
                            (d['avg'] as double).toStringAsFixed(1),
                            d['count'],
                            isLow: true,
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverallRatingCard(double average, int count) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Mess Rating',
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
                'Based on $count student ratings',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Icon(Icons.star_rounded, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  Widget _buildDishRatingItem(
    String dishName,
    String rating,
    int count, {
    bool isLow = false,
  }) {
    Color ratingColor = isLow
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dishName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  '$count ratings',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                rating,
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
    );
  }
}
