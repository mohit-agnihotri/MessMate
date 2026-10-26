import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'owner_expense_ledger_page.dart';
import 'theme/owner_inspired_theme.dart';
import 'widgets/owner_drawer.dart';

class OwnerAnalyticsPage extends ConsumerStatefulWidget {
  const OwnerAnalyticsPage({super.key});

  @override
  ConsumerState<OwnerAnalyticsPage> createState() => _OwnerAnalyticsPageState();
}

class _OwnerAnalyticsPageState extends ConsumerState<OwnerAnalyticsPage> {
  int _selectedTabIndex = 0; // 0: Mess, 1: Food

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(ownerDashboardProvider);
    final mess = dashboardState.mess;
    final messId = mess?.messId;
    final messName = mess?.name ?? 'Mahakal';

    if (messId == null) {
      return const Scaffold(
        backgroundColor: OwnerColors.canvasWarm,
        body: Center(
          child: CircularProgressIndicator(color: OwnerColors.sageGreen),
        ),
      );
    }

    final dishRatingsAsync = ref.watch(dishRatingsProvider(messId));
    final messReviewsAsync = ref.watch(messReviewsProvider(messId));
    final feedbacksAsync = ref.watch(ownerFeedbacksProvider(messId));

    final reviewsCount = messReviewsAsync.valueOrNull?.length ?? 0;
    final foodCount = dishRatingsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: OwnerColors.canvasWarm,
      endDrawer: const OwnerDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, messName),
            Expanded(
              child: RefreshIndicator(
                color: OwnerColors.sageGreen,
                backgroundColor: OwnerColors.surfaceLight,
                onRefresh: () async {
                  ref.invalidate(dishRatingsProvider(messId));
                  ref.invalidate(messReviewsProvider(messId));
                  ref.invalidate(ownerFeedbacksProvider(messId));
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    _buildLedgerSnapshotCard(context, ref),
                    const SizedBox(height: 16),
                    _buildSegmentedTabToggle(
                      reviewsCount: reviewsCount,
                      foodCount: foodCount,
                    ),
                    const SizedBox(height: 18),
                    if (_selectedTabIndex == 0)
                      _buildMessTabContent(messReviewsAsync)
                    else
                      _buildFoodTabContent(dishRatingsAsync, feedbacksAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── P&L Khaata Snapshot Card ─────────────────────────────────────────────
  Widget _buildLedgerSnapshotCard(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(ownerExpenseLedgerProvider);
    final isProfitable = ledgerState.netCashProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.walnutDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAA23E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 15,
                      color: OwnerColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'KHAATA · THIS MONTH',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: const Color(0xFFC7BCB3),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OwnerExpenseLedgerPage()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        'Ledger',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEAA23E),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFEAA23E),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fees collected',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFC7BCB3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${ledgerState.totalCollectedFees.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF81C784),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kitchen kharcha',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFC7BCB3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${ledgerState.totalExpenses.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF8A80),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net profit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFC7BCB3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isProfitable ? '+' : ''}₹${ledgerState.netCashProfit.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEAA23E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Header (Screenshot 8) ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String messName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: const BoxDecoration(
        color: OwnerColors.canvasWarm,
        border: Border(
          bottom: BorderSide(color: OwnerColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'RATINGS & FEEDBACK',
                style: OwnerTypography.overline(color: OwnerColors.walnutMuted),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OwnerColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OwnerColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$messName · Settings',
                        style: OwnerTypography.regular(
                          size: 12,
                          color: OwnerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: OwnerColors.walnutMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: OwnerColors.walnutDark,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Insights',
                style: OwnerTypography.editorialSerif(
                  size: 28,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Segmented Tab Toggle: Mess vs Food (Screenshot 8) ────────────────────
  Widget _buildSegmentedTabToggle({
    required int reviewsCount,
    required int foodCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceWarm,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? OwnerColors.walnutDark
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Mess ($reviewsCount)',
                  style: OwnerTypography.bold(
                    size: 13,
                    color: _selectedTabIndex == 0
                        ? OwnerColors.textLight
                        : OwnerColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? OwnerColors.walnutDark
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Food ($foodCount)',
                  style: OwnerTypography.bold(
                    size: 13,
                    color: _selectedTabIndex == 1
                        ? OwnerColors.textLight
                        : OwnerColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mess Tab Content (Screenshot 8) ──────────────────────────────────────
  Widget _buildMessTabContent(
    AsyncValue<List<MessReviewModel>> reviewsAsync,
  ) {
    return reviewsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: OwnerColors.sageGreen),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading reviews: $err',
          style: OwnerTypography.regular(size: 13, color: Colors.red),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return _buildEmptyAnalyticsState(
            title: 'No mess reviews yet',
            subtitle:
                'Students can submit reviews for your mess from their student app.',
            icon: Icons.star_outline_rounded,
          );
        }

        final double totalRating =
            reviews.fold(0.0, (acc, r) => acc + r.rating);
        final double averageRating = totalRating / reviews.length;

        final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (var r in reviews) {
          final rounded = r.rating.round().clamp(1, 5);
          distribution[rounded] = (distribution[rounded] ?? 0) + 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Walnut Hero Card: Overall Mess Rating (Screenshot 8)
            _buildWalnutHeroCard(
              overline: 'OVERALL MESS RATING',
              rating: averageRating,
              subtitle: 'Based on ${reviews.length} student reviews',
            ),
            const SizedBox(height: 18),

            // Rating Breakdown Bars (Screenshot 8)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: OwnerColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OwnerColors.borderSubtle),
                boxShadow: OwnerShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating Breakdown',
                    style: OwnerTypography.editorialSerif(
                      size: 16,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(5, (i) {
                    final star = 5 - i;
                    final count = distribution[star] ?? 0;
                    final pct =
                        reviews.isNotEmpty ? count / reviews.length : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$star★',
                              style: OwnerTypography.bold(
                                size: 12,
                                color: OwnerColors.walnutDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: OwnerColors.surfaceWarm,
                                valueColor: const AlwaysStoppedAnimation(
                                  OwnerColors.amberGlow,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.end,
                              style: OwnerTypography.regular(
                                size: 12,
                                color: OwnerColors.textSecondary,
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
            const SizedBox(height: 22),

            // Student Reviews Section
            Text(
              'Student Reviews (${reviews.length})',
              style: OwnerTypography.editorialSerif(
                size: 20,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            const SizedBox(height: 12),
            ...reviews.map((r) => _buildReviewCard(r)),
          ],
        );
      },
    );
  }

  // ─── Food Tab Content (Screenshot 8) ──────────────────────────────────────
  Widget _buildFoodTabContent(
    AsyncValue<List<DishRatingModel>> dishRatingsAsync,
    AsyncValue<List<FeedbackModel>> feedbacksAsync,
  ) {
    return dishRatingsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: OwnerColors.sageGreen),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading food ratings: $err',
          style: OwnerTypography.regular(size: 13, color: Colors.red),
        ),
      ),
      data: (dishRatings) {
        final feedbacks = feedbacksAsync.valueOrNull ?? [];

        final Map<String, List<DishRatingModel>> ratingsByDish = {};
        for (var dr in dishRatings) {
          ratingsByDish.putIfAbsent(dr.dishName, () => []).add(dr);
        }

        // Fallback to legacy feedbacks if empty
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
          return _buildEmptyAnalyticsState(
            title: 'No dish ratings yet',
            subtitle:
                'Students can rate each dish served from the daily mess menu.',
            icon: Icons.ramen_dining_outlined,
          );
        }

        final List<Map<String, dynamic>> dishStats =
            ratingsByDish.entries.map((e) {
          final list = e.value;
          final avg =
              list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;
          final comments = list
              .where((r) => r.comment != null && r.comment!.isNotEmpty)
              .toList();
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

        final totalRatingsCount = dishStats.fold<int>(
            0, (acc, item) => acc + (item['count'] as int));
        final overallFoodAvg = dishStats.fold<double>(
                0.0, (acc, item) => acc + (item['avg'] as double)) /
            dishStats.length;

        final topRated =
            dishStats.where((d) => (d['avg'] as double) >= 4.0).take(5).toList();
        final needsImprovement =
            dishStats.where((d) => (d['avg'] as double) < 4.0).toList();
        needsImprovement.sort((a, b) =>
            (a['avg'] as double).compareTo(b['avg'] as double));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalnutHeroCard(
              overline: 'OVERALL FOOD SATISFACTION',
              rating: overallFoodAvg,
              subtitle:
                  'Based on $totalRatingsCount dish ratings across ${dishStats.length} items',
            ),
            const SizedBox(height: 20),

            if (topRated.isNotEmpty) ...[
              Text(
                'Top Rated Dishes',
                style: OwnerTypography.editorialSerif(
                  size: 20,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
              const SizedBox(height: 12),
              ...topRated.map((d) => _buildDishDetailCard(d, isLow: false)),
              const SizedBox(height: 20),
            ],

            if (needsImprovement.isNotEmpty) ...[
              Text(
                'Needs Improvement',
                style: OwnerTypography.editorialSerif(
                  size: 20,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
              const SizedBox(height: 12),
              ...needsImprovement
                  .take(5)
                  .map((d) => _buildDishDetailCard(d, isLow: true)),
              const SizedBox(height: 20),
            ],

            Text(
              'All Dish Scores (${dishStats.length})',
              style: OwnerTypography.editorialSerif(
                size: 20,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            const SizedBox(height: 12),
            ...dishStats.map((d) => _buildDishDetailCard(
                  d,
                  isLow: (d['avg'] as double) < 3.0,
                )),
          ],
        );
      },
    );
  }

  // ─── Walnut Hero Card (Screenshot 8) ──────────────────────────────────────
  Widget _buildWalnutHeroCard({
    required String overline,
    required double rating,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: OwnerColors.walnutDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline,
            style: OwnerTypography.overline(color: OwnerColors.amberGlow),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: OwnerTypography.editorialSerif(
                  size: 48,
                  weight: FontWeight.w700,
                  color: OwnerColors.amberGlow,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ 5.0',
                style: OwnerTypography.regular(
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              // 5 Stars indicator
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 22,
                    color: OwnerColors.amberGlow,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: OwnerTypography.regular(
              size: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dish Detail Card (Screenshot 8) ───────────────────────────────────────
  Widget _buildDishDetailCard(Map<String, dynamic> d, {required bool isLow}) {
    final dishName = d['name'] as String;
    final avg = (d['avg'] as double).toStringAsFixed(1);
    final count = d['count'] as int;
    final comments = d['comments'] as List<DishRatingModel>;

    Color ratingColor =
        isLow ? Colors.red : OwnerColors.amberGlow;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
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
                  style: OwnerTypography.bold(
                    size: 15,
                    color: OwnerColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLow
                      ? Colors.red.withValues(alpha: 0.1)
                      : OwnerColors.amberLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avg,
                      style: OwnerTypography.bold(
                        size: 13,
                        color: ratingColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.star_rounded, color: ratingColor, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$count ratings',
            style: OwnerTypography.regular(
              size: 12,
              color: OwnerColors.textSecondary,
            ),
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OwnerColors.surfaceWarm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments.take(2).map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(
                            '"${c.comment}"',
                            style: OwnerTypography.regular(
                              size: 11,
                              color: OwnerColors.textPrimary,
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

  // ─── Student Review Card (Screenshot 8) ───────────────────────────────────
  Widget _buildReviewCard(MessReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: OwnerColors.amberGlow.withValues(alpha: 0.18),
                child: Text(
                  review.studentName.isNotEmpty
                      ? review.studentName[0].toUpperCase()
                      : 'S',
                  style: OwnerTypography.editorialSerif(
                    size: 16,
                    weight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
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
                      style: OwnerTypography.bold(
                        size: 14,
                        color: OwnerColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${review.updatedAt.day}/${review.updatedAt.month}/${review.updatedAt.year}',
                      style: OwnerTypography.regular(
                        size: 11,
                        color: OwnerColors.textSecondary,
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
                    color: OwnerColors.amberGlow,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: OwnerTypography.regular(
                size: 12,
                color: OwnerColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Empty Analytics State ────────────────────────────────────────────────
  Widget _buildEmptyAnalyticsState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: OwnerColors.surfaceWarm,
              shape: BoxShape.circle,
              border: Border.all(color: OwnerColors.borderSubtle),
            ),
            child: Icon(
              icon,
              size: 32,
              color: OwnerColors.walnutMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: OwnerTypography.editorialSerif(
              size: 18,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: OwnerTypography.regular(
              size: 12,
              color: OwnerColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
