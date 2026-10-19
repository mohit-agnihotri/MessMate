import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import 'view_mess_menu_sheet.dart';

class MessDiscoveryItem {
  final MessModel mess;
  final double? distanceKm;
  final String currentOrNextMealName;
  final String currentOrNextMealDishes;
  final bool isServingNow;
  final String? timeUntilNext;
  final String slotType; // 'Morning', 'Noon', 'Night'
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
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Segmented Bar: [ 📋 Mess Details ] | [ ⭐ Ratings & Reviews ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
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
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: _selectedTabIndex == 0
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Mess Details',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedTabIndex == 0
                                      ? const Color(0xFF111827)
                                      : const Color(0xFF6B7280),
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
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: _selectedTabIndex == 1
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                reviewCount > 0
                                    ? 'Reviews ($reviewCount)'
                                    : 'Ratings & Reviews',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedTabIndex == 1
                                      ? const Color(0xFF111827)
                                      : const Color(0xFF6B7280),
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
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // View Content
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
          // Hero / Photo Carousel
          if (mess.messPhotos.isNotEmpty)
            _buildPhotoCarousel(mess.messPhotos, widget.item, isClosed)
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=1000&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isClosed
                            ? 'CLOSED TILL ${mess.temporarilyClosedUntil!.day}/${mess.temporarilyClosedUntil!.month}'
                            : (widget.item.currentOrNextMealName == 'No meal set'
                                ? '🍽️ DAILY FRESH MEALS'
                                : '${widget.item.slotType == 'Night' ? '🌙' : '☀️'} SERVING ${widget.item.slotType.toUpperCase()} ${widget.item.isServingNow ? 'NOW' : 'NEXT'}'),
                        style: GoogleFonts.inter(
                          color: isClosed
                              ? const Color(0xFFFCA5A5)
                              : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Mess Name & Code
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mess.name,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mess Code: ${mess.messCode}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Rating Badge (Clickable to switch to Ratings Tab)
              InkWell(
                onTap: () => setState(() => _selectedTabIndex = 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        displayRating > 0
                            ? '${displayRating.toStringAsFixed(1)} ($reviewCount)'
                            : 'New',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Specs chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                Icons.location_on,
                '${widget.item.distanceKm?.toStringAsFixed(1) ?? '--'} km',
              ),
              _buildChip(Icons.people, '${mess.capacity} seats'),
              _buildChip(
                mess.foodType == 'pure_veg'
                    ? Icons.eco_rounded
                    : mess.foodType == 'non_veg'
                        ? Icons.restaurant_rounded
                        : Icons.lunch_dining_rounded,
                mess.foodType == 'pure_veg'
                    ? '🌱 Pure Veg'
                    : mess.foodType == 'non_veg'
                        ? '🍗 Non-Veg'
                        : '🍃 Veg & Non-Veg',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Closed message or Menu Button
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mess is Temporarily Closed',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Closed until ${mess.temporarilyClosedUntil!.day}/${mess.temporarilyClosedUntil!.month}/${mess.temporarilyClosedUntil!.year}. You can still contact the owner.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () {
                ViewMessMenuSheet.show(
                  context,
                  mess: mess,
                  initialMenus: widget.item.allMenus,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('📋', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Mess Menu (मेन्यू देखें)',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ALL SLOTS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view standard breakfast, lunch & dinner offerings',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Pricing Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Monthly Plan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${mess.monthlyFee.toStringAsFixed(0)}/mo',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Per Meal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${mess.perMealRate.toStringAsFixed(0)}/meal',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Includes ${mess.mealsIncludedPerDay} meals daily',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
            ),
          ),

          // More about mess button
          if (mess.aboutContent != null && mess.aboutContent!.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => widget.onShowAbout(mess),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More About This Mess',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        Text(
                          'Rules, specials, food details & more',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Contact Row
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF6B7280), size: 20),
              const SizedBox(width: 8),
              Text(
                mess.ownerName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                mess.ownerPhone,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons: Call Now & Open in Maps
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => widget.onCallOwner(mess.ownerPhone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Call Now',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => widget.onOpenDirections(mess.gpsLat, mess.gpsLng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Open in Maps',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Request to Join Mess button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: Text(
                'Request to Join Mess',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
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

    final Map<String, List<double>> dishMap = {};
    for (var dr in dishRatings) {
      dishMap.putIfAbsent(dr.dishName, () => []).add(dr.rating);
    }
    final topDishes = dishMap.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'name': e.key, 'avg': avg, 'count': e.value.length};
    }).where((d) => (d['avg'] as double) >= 3.5).toList();
    topDishes.sort((a, b) => (b['avg'] as double).compareTo(a['avg'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mess Score Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2522C55E),
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
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayRating > 0 ? displayRating.toStringAsFixed(1) : 'New',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (displayRating > 0) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '/ 5.0',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reviewCount > 0
                          ? 'Based on $reviewCount student reviews'
                          : 'No reviews yet',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Icon(Icons.stars_rounded, color: Colors.white, size: 52),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rating Breakdown bars
          if (reviews.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(5, (i) {
                  final star = 5 - i;
                  final count = distribution[star] ?? 0;
                  final pct = reviews.isNotEmpty ? count / reviews.length : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
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
                              minHeight: 7,
                              backgroundColor: const Color(0xFFF3F4F6),
                              valueColor:
                                  const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Student Review Liability Section (Create / Edit / Delete)
          if (myReview != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Your Review',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF15803D),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _openMessReviewDialog(context, mess, myReview),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _confirmDeleteReview(context, mess, myReview),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < myReview.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${myReview.rating.toStringAsFixed(1)} • ${myReview.updatedAt.day}/${myReview.updatedAt.month}/${myReview.updatedAt.year}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  if (myReview.comment != null &&
                      myReview.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      myReview.comment!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF374151),
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
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 18),
                label: Text(
                  'Rate & Review This Mess',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _openMessReviewDialog(context, mess, null),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Top Rated Food Items
          if (topDishes.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Rated Dishes',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ViewMessMenuSheet.show(
                      context,
                      mess: mess,
                      initialMenus: widget.item.allMenus,
                    );
                  },
                  child: Text(
                    'View Menu >',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topDishes.take(6).map((d) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      Text(
                        (d['avg'] as double).toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // All Reviews List
          Text(
            'Student Reviews (${reviews.length})',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),

          if (reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 36,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first student to review ${mess.name}!',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            )
          else
            ...reviews.map((r) {
              final isMe = r.studentId == currentUid;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMe ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: Text(
                            r.studentName.isNotEmpty
                                ? r.studentName[0].toUpperCase()
                                : 'S',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.studentName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'YOU',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${r.updatedAt.day}/${r.updatedAt.month}/${r.updatedAt.year}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < r.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 15,
                              color: const Color(0xFFF59E0B),
                            );
                          }),
                        ),
                      ],
                    ),
                    if (r.comment != null && r.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        r.comment!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── REVIEW DIALOG ─────────────────────────────────────────────────────────
  void _openMessReviewDialog(
    BuildContext context,
    MessModel mess,
    MessReviewModel? existingReview,
  ) {
    final currentStudent = ref.read(studentHomeProvider).student;
    final currentUid =
        currentStudent?.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final studentName = currentStudent?.name ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Student';
    final studentPhoto = currentStudent?.photoUrl;

    if (currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to write a review.')),
      );
      return;
    }

    double selectedRating = existingReview?.rating ?? 5.0;
    final commentCtrl = TextEditingController(text: existingReview?.comment ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isEditing = existingReview != null;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEditing ? 'Edit Your Review' : 'Rate ${mess.name}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your overall experience with food quality, cleanliness & service',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = (index + 1).toDouble();
                        final isSelected = starValue <= selectedRating;
                        return IconButton(
                          iconSize: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          icon: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  Center(
                    child: Text(
                      selectedRating == 5
                          ? '⭐ 5.0 - Exceptional Mess'
                          : selectedRating == 4
                              ? '⭐ 4.0 - Very Good Mess'
                              : selectedRating == 3
                                  ? '⭐ 3.0 - Average Mess'
                                  : selectedRating == 2
                                      ? '⭐ 2.0 - Below Expectations'
                                      : '⭐ 1.0 - Poor Experience',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Describe how the meals taste, seating, hygiene, timings, etc. (optional)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF22C55E)),
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
                                  setDialogState(() => isSubmitting = true);
                                  try {
                                    await ref
                                        .read(appServiceProvider)
                                        .deleteMessReview(
                                          mess.messId,
                                          existingReview.reviewId,
                                        );
                                    if (dialogCtx.mounted) {
                                      Navigator.pop(dialogCtx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Review deleted successfully.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSubmitting = false);
                                    if (dialogCtx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setDialogState(() => isSubmitting = true);
                                  try {
                                    final review = MessReviewModel(
                                      reviewId: existingReview?.reviewId ?? currentUid,
                                      messId: mess.messId,
                                      studentId: currentUid,
                                      studentName: studentName,
                                      studentPhotoUrl: studentPhoto,
                                      rating: selectedRating,
                                      comment: commentCtrl.text.trim().isEmpty
                                          ? null
                                          : commentCtrl.text.trim(),
                                    );
                                    await ref
                                        .read(appServiceProvider)
                                        .submitOrUpdateMessReview(review);
                                    if (dialogCtx.mounted) {
                                      Navigator.pop(dialogCtx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing
                                                ? 'Review updated!'
                                                : 'Thanks for reviewing this mess!',
                                          ),
                                          backgroundColor: const Color(0xFF22C55E),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSubmitting = false);
                                    if (dialogCtx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to save: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Update Review' : 'Submit Review',
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

  void _confirmDeleteReview(
    BuildContext context,
    MessModel mess,
    MessReviewModel review,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Review?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove your review for ${mess.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(appServiceProvider)
                    .deleteMessReview(mess.messId, review.reviewId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review deleted successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(
    List<String> photos,
    MessDiscoveryItem item,
    bool isClosed,
  ) {
    final pageController = PageController();
    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  controller: pageController,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _carouselPage = i),
                  itemBuilder: (ctx, i) => Container(
                    color: const Color(0xFFF9FAFB),
                    child: Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isClosed
                      ? 'CLOSED TILL ${item.mess.temporarilyClosedUntil!.day}/${item.mess.temporarilyClosedUntil!.month}'
                      : (item.currentOrNextMealName == 'No meal set'
                          ? '🍽️ DAILY FRESH MEALS'
                          : '${item.slotType == 'Night' ? '🌙' : '☀️'} SERVING ${item.slotType.toUpperCase()} ${item.isServingNow ? 'NOW' : 'NEXT'}'),
                  style: GoogleFonts.inter(
                    color: isClosed ? const Color(0xFFFCA5A5) : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_carouselPage + 1}/${photos.length}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              photos.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _carouselPage == i ? 16 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _carouselPage == i
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
