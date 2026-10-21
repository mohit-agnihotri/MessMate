import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/student_inspired_theme.dart';
import 'rate_mess_sheet.dart';

class MessDiscoveryItem {
  final MessModel mess;
  final double? distanceKm;
  final String currentOrNextMealName;
  final String currentOrNextMealDishes;
  final bool isServingNow;
  final String? timeUntilNext;
  final String slotType;
  final MenuModel? activePostedMenu;
  final List<MenuModel> allMenus;

  MessDiscoveryItem({
    required this.mess,
    required this.distanceKm,
    required this.currentOrNextMealName,
    required this.currentOrNextMealDishes,
    required this.isServingNow,
    this.timeUntilNext,
    required this.slotType,
    this.activePostedMenu,
    this.allMenus = const [],
  });
}

class MessDiscoveryDetailsSheet extends ConsumerStatefulWidget {
  final MessDiscoveryItem item;
  final void Function(double lat, double lng) onOpenDirections;
  final void Function(String phone) onCallOwner;
  final void Function(MessModel mess) onShowAbout;
  final void Function(MessModel mess) onJoinRequest;

  const MessDiscoveryDetailsSheet({
    super.key,
    required this.item,
    required this.onOpenDirections,
    required this.onCallOwner,
    required this.onShowAbout,
    required this.onJoinRequest,
  });

  static Future<void> show(
    BuildContext context, {
    required MessDiscoveryItem item,
    required void Function(double lat, double lng) onOpenDirections,
    required void Function(String phone) onCallOwner,
    required void Function(MessModel mess) onShowAbout,
    required void Function(MessModel mess) onJoinRequest,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MessDiscoveryDetailsSheet(
        item: item,
        onOpenDirections: onOpenDirections,
        onCallOwner: onCallOwner,
        onShowAbout: onShowAbout,
        onJoinRequest: onJoinRequest,
      ),
    );
  }

  @override
  ConsumerState<MessDiscoveryDetailsSheet> createState() =>
      _MessDiscoveryDetailsSheetState();
}

class _MessDiscoveryDetailsSheetState
    extends ConsumerState<MessDiscoveryDetailsSheet> {
  int _selectedTabIndex = 0; // 0 = Mess Details, 1 = Ratings & Reviews
  int _carouselPage = 0;

  @override
  Widget build(BuildContext context) {
    final mess = widget.item.mess;
    final reviewsAsync = ref.watch(messReviewsProvider(mess.messId));
    final dishRatingsAsync = ref.watch(dishRatingsProvider(mess.messId));
    final reviews = reviewsAsync.valueOrNull ?? [];
    final dishRatings = dishRatingsAsync.valueOrNull ?? [];

    final currentStudent = ref.watch(studentHomeProvider).student;
    final currentUid =
        currentStudent?.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final myReview = reviews.where((r) => r.studentId == currentUid).firstOrNull;

    final reviewCount = reviews.isNotEmpty ? reviews.length : mess.reviewCount;
    final double displayRating = reviews.isNotEmpty
        ? (reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length)
        : mess.rating;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: StudentColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: StudentColors.walnutMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Top Segmented Pill Bar: [ 📋 Details ] | [ ⭐ Reviews ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: StudentColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: StudentColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? StudentColors.walnut
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : StudentColors.textDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Details',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedTabIndex == 0
                                      ? Colors.white
                                      : StudentColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? StudentColors.walnut
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: _selectedTabIndex == 1
                                    ? StudentColors.amber
                                    : StudentColors.amberDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                reviewCount > 0
                                    ? 'Reviews ($reviewCount)'
                                    : 'Reviews',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedTabIndex == 1
                                      ? Colors.white
                                      : StudentColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: StudentColors.borderSubtle),

            // Tab View Content
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildDetailsTab(mess, displayRating, reviewCount)
                  : _buildRatingsTab(
                      mess,
                      reviews,
                      dishRatings,
                      myReview,
                      displayRating,
                      reviewCount,
                      currentUid,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: MESS DETAILS ───────────────────────────────────────────────────
  Widget _buildDetailsTab(
    MessModel mess,
    double displayRating,
    int reviewCount,
  ) {
    bool isClosed = mess.temporarilyClosedUntil != null &&
        mess.temporarilyClosedUntil!.isAfter(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Carousel Banner
          if (mess.messPhotos.isNotEmpty)
            _buildPhotoCarousel(mess.messPhotos, widget.item, isClosed),
          const SizedBox(height: 16),

          // Mess Name & Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mess.name,
                      style: StudentTypography.serifHeading(fontSize: 26),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: StudentColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mess.ownerName.isNotEmpty
                                ? 'Managed by ${mess.ownerName}'
                                : 'Verified Mess Partner',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: StudentColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Rating Pill Badge (Clickable to switch to Ratings Tab)
              InkWell(
                onTap: () => setState(() => _selectedTabIndex = 1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: StudentColors.amberLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudentColors.amberPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: StudentColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayRating > 0
                            ? '${displayRating.toStringAsFixed(1)} ($reviewCount)'
                            : 'New',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: StudentColors.amberText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Specs Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                Icons.location_searching_rounded,
                '${widget.item.distanceKm?.toStringAsFixed(1) ?? '--'} km away',
                StudentColors.walnut,
                StudentColors.canvas,
              ),
              _buildBadge(
                Icons.people_outline_rounded,
                '${mess.capacity} seats',
                StudentColors.sageDark,
                StudentColors.sageLight,
              ),
              _buildBadge(
                mess.foodType == 'pure_veg' ? Icons.eco_rounded : Icons.restaurant_rounded,
                mess.foodType == 'pure_veg' ? 'Pure Veg' : 'Veg & Non-Veg',
                StudentColors.sageDark,
                StudentColors.sageLight,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Cards (Call, Directions, About)
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.phone_outlined,
                  label: 'Call Owner',
                  onTap: () => widget.onCallOwner(mess.ownerPhone),
                  bgColor: StudentColors.surfaceLight,
                  iconColor: StudentColors.walnut,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.navigation_outlined,
                  label: 'Directions',
                  onTap: () => widget.onOpenDirections(mess.gpsLat, mess.gpsLng),
                  bgColor: StudentColors.sageLight,
                  iconColor: StudentColors.sageDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About Mess',
                  onTap: () => widget.onShowAbout(mess),
                  bgColor: StudentColors.amberLight,
                  iconColor: StudentColors.amberDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Monthly Plans Section
          Text(
            'MONTHLY PLANS',
            style: StudentTypography.overline(fontSize: 11),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<MealPlanModel>>(
            future: ref.read(appServiceProvider).getMealPlans(mess.messId),
            builder: (context, snapshot) {
              final plans = snapshot.data?.where((p) => p.isActive).toList() ?? [];
              if (plans.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StudentColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StudentColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: StudentColors.walnut,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard Plan',
                              style: StudentTypography.bold(fontSize: 14),
                            ),
                            Text(
                              'All daily meals included',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: StudentColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${mess.monthlyFee.toInt()}/mo',
                        style: StudentTypography.serifNumeral(
                          fontSize: 20,
                          color: StudentColors.walnut,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: plans.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StudentColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: StudentColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: StudentTypography.bold(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.mealsIncludedPerDay} meals daily • Fixed & Flexible',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: StudentColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${p.monthlyFee.toInt()}/mo',
                          style: StudentTypography.serifNumeral(
                            fontSize: 18,
                            color: StudentColors.walnut,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Meal Timings Section
          Text(
            'MEAL TIMINGS',
            style: StudentTypography.overline(fontSize: 11),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StudentColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: StudentColors.borderSubtle),
            ),
            child: Column(
              children: ['morning', 'noon', 'evening', 'night'].map((slot) {
                final timing = mess.mealTimings[slot];
                final isEnabled = timing?['enabled'] == 'true';
                final start = timing?['start'] ?? '--:--';
                final end = timing?['end'] ?? '--:--';
                final label = '${slot[0].toUpperCase()}${slot.substring(1)}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isEnabled
                              ? StudentColors.textDark
                              : StudentColors.textMuted,
                        ),
                      ),
                      Text(
                        isEnabled ? '$start - $end' : 'Closed',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: isEnabled
                              ? StudentColors.sageDark
                              : StudentColors.textMuted,
                          fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 26),

          // Primary Join CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: StudentColors.amber,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.group_add_rounded, size: 20),
              label: Text(
                'Request to Join Mess',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: () => widget.onJoinRequest(mess),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── TAB 2: RATINGS & REVIEWS ──────────────────────────────────────────────
  Widget _buildRatingsTab(
    MessModel mess,
    List<MessReviewModel> reviews,
    List<DishRatingModel> dishRatings,
    MessReviewModel? myReview,
    double displayRating,
    int reviewCount,
    String currentUid,
  ) {
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in reviews) {
      final rounded = r.rating.round().clamp(1, 5);
      distribution[rounded] = (distribution[rounded] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating Card in Dark Walnut
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StudentColors.walnut,
              borderRadius: BorderRadius.circular(20),
              boxShadow: StudentColors.elevated,
            ),
            child: Row(
              children: [
                // Left Numeral & Stars
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayRating > 0 ? displayRating.toStringAsFixed(1) : 'New',
                      style: StudentTypography.serifNumeral(
                        fontSize: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: StudentColors.amber,
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reviewCount > 0
                          ? 'Based on $reviewCount reviews'
                          : 'No reviews yet',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Right 5★ to 1★ Distribution Bars
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final star = 5 - i;
                      final count = distribution[star] ?? 0;
                      final pct = reviews.isNotEmpty ? count / reviews.length : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$star★',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  valueColor: const AlwaysStoppedAnimation(
                                    StudentColors.amber,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // User's Own Review Banner (if already reviewed)
          if (myReview != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: StudentColors.amberPill),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Review',
                        style: StudentTypography.bold(fontSize: 14),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: StudentColors.walnut,
                            ),
                            onPressed: () =>
                                RateMessSheet.show(context, mess: mess, existingReview: myReview),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: StudentColors.brickRed,
                            ),
                            onPressed: () =>
                                _confirmDeleteReview(context, mess, myReview),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < myReview.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: StudentColors.amber,
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        myReview.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: StudentColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (myReview.comment != null && myReview.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      myReview.comment!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: StudentColors.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: StudentColors.walnut),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined, size: 18, color: StudentColors.walnut),
                label: Text(
                  'Write a Review',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: StudentColors.walnut,
                  ),
                ),
                onPressed: () => RateMessSheet.show(context, mess: mess, existingReview: null),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // All Student Reviews List
          Text(
            'STUDENT REVIEWS',
            style: StudentTypography.overline(fontSize: 11),
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: StudentColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StudentColors.borderSubtle),
              ),
              child: Center(
                child: Text(
                  'No reviews posted yet. Be the first to review!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: StudentColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = reviews[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudentColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StudentColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: StudentColors.walnut,
                                child: Text(
                                  r.studentName.isNotEmpty
                                      ? r.studentName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.studentName,
                                style: StudentTypography.bold(fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: StudentColors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                r.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          r.comment!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: StudentColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(
    List<String> photos,
    MessDiscoveryItem item,
    bool isClosed,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _carouselPage = i),
            itemBuilder: (context, i) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  photos[i],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: StudentColors.surfaceWarm,
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: StudentColors.walnutMuted,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.length, (i) {
              return Container(
                width: _carouselPage == i ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: _carouselPage == i
                      ? StudentColors.walnut
                      : StudentColors.walnutMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StudentColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: StudentColors.walnut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReview(
    BuildContext context,
    MessModel mess,
    MessReviewModel review,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudentColors.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Review?',
          style: StudentTypography.serifHeading(fontSize: 20),
        ),
        content: Text(
          'Are you sure you want to remove your rating and feedback for this mess?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: StudentColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: StudentColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(appServiceProvider)
                  .deleteMessReview(mess.messId, review.reviewId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.brickRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
