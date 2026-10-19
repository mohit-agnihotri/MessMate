import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';
import 'widgets/mess_discovery_details_sheet.dart';

class _MessItem {
  final MessModel mess;
  final double? distanceKm;
  final String currentOrNextMealName;
  final String currentOrNextMealDishes;
  final bool isServingNow;
  final String? timeUntilNext;
  final String slotType; // 'Morning', 'Noon', 'Night'
  final MenuModel? activePostedMenu;
  final List<MenuModel> allMenus;

  _MessItem({
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

class StudentDiscoveryPage extends ConsumerStatefulWidget {
  const StudentDiscoveryPage({super.key});

  @override
  ConsumerState<StudentDiscoveryPage> createState() =>
      _StudentDiscoveryPageState();
}

class _StudentDiscoveryPageState extends ConsumerState<StudentDiscoveryPage> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _lastMessId;
  List<_MessItem> _allItems = [];
  List<_MessItem> _messes = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final pos = await _getUserLocation();
      final newMesses = await ref.read(appServiceProvider).getAllListedMesses(lastMessId: _lastMessId, limit: 10);
      
      if (newMesses.isEmpty || newMesses.length < 10) {
        _hasMore = false;
      }
      if (newMesses.isNotEmpty) {
        _lastMessId = newMesses.last.messId;
        
        final items = await _processMesses(newMesses, pos);
        
        setState(() {
          _allItems.addAll(items);
        });
        _filterItems();
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<List<_MessItem>> _processMesses(List<MessModel> messesList, Position? pos) async {
    final items = await Future.wait(
      messesList.map((m) async {
        double? dist;
        if (pos != null && m.gpsLat != 0.0 && m.gpsLng != 0.0) {
          dist =
              Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                m.gpsLat,
                m.gpsLng,
              ) /
              1000.0;
        }

        final menus = await ref
            .read(appServiceProvider)
            .getDailyMenus(m.messId, DateTime.now());

        bool isServingNow = false;
        String mealName = 'No meal set';
        String dishes = '';
        String? timeUntilNext;
        String slotType = 'Noon';
        MenuModel? activePosted;

        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;

        if (menus.isNotEmpty) {
          bool found = false;
          final slotOrder = ['morning', 'noon', 'evening', 'night'];

          for (var slot in slotOrder) {
            final timing = m.mealTimings[slot];
            if (timing != null && timing['enabled'] == 'true') {
              final startStr = timing['start'] ?? '00:00';
              final endStr = timing['end'] ?? '00:00';
              final startMin = _parseTime(startStr);
              final endMin = _parseTime(endStr);

              if (currentMinutes <= endMin) {
                final matchingMenu = menus
                    .where((menu) => menu.mealSlot.toLowerCase() == slot)
                    .firstOrNull;

                slotType = slot == 'morning'
                    ? 'Morning'
                    : slot == 'noon'
                    ? 'Noon'
                    : slot == 'evening'
                    ? 'Evening'
                    : 'Night';
                mealName = slot == 'morning'
                    ? 'Breakfast'
                    : slot == 'noon'
                    ? 'Lunch'
                    : slot == 'evening'
                    ? 'Snacks'
                    : 'Dinner';

                final isPosted = matchingMenu != null &&
                    matchingMenu.isPublished &&
                    (matchingMenu.menuType == 'special' ||
                        matchingMenu.menuType == 'regular') &&
                    matchingMenu.dishes.isNotEmpty;

                if (isPosted) {
                  activePosted = matchingMenu;
                  dishes = matchingMenu.dishes.map((d) => d.name).join(' • ');
                  if (matchingMenu.menuType == 'special') {
                    mealName = '✨ Special $mealName';
                  } else {
                    mealName = "Today's $mealName";
                  }
                } else {
                  dishes = '';
                }

                if (currentMinutes >= startMin && currentMinutes <= endMin) {
                  isServingNow = true;
                } else {
                  isServingNow = false;
                }

                found = true;
                break;
              }
            }
          }

          if (!found) {
            for (var slot in slotOrder) {
              final timing = m.mealTimings[slot];
              if (timing != null && timing['enabled'] == 'true') {
                slotType = slot == 'morning'
                    ? 'Morning'
                    : slot == 'noon'
                    ? 'Noon'
                    : slot == 'evening'
                    ? 'Evening'
                    : 'Night';
                mealName = 'Tomorrow $slotType';
                dishes = '';
                isServingNow = false;
                break;
              }
            }
          }
        }

        return _MessItem(
          mess: m,
          distanceKm: dist,
          currentOrNextMealName: mealName,
          currentOrNextMealDishes: dishes,
          isServingNow: isServingNow,
          timeUntilNext: timeUntilNext,
          slotType: slotType,
          activePostedMenu: activePosted,
          allMenus: menus,
        );
      }),
    );
    return items;
  }

  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _getUserLocation();
      final allMesses = await ref.read(appServiceProvider).getAllListedMesses(limit: 10);

      if (allMesses.length < 10) _hasMore = false;
      if (allMesses.isNotEmpty) _lastMessId = allMesses.last.messId;

      final items = await _processMesses(allMesses, pos);

      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );

      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
        _filterItems();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  void _filterItems() {
    List<_MessItem> filtered = _allItems.where((item) {
      final matchesSearch = item.mess.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Open Now') {
        return item.isServingNow;
      }
      return true; // Expand logic for Veg/Non-Veg when data exists
    }).toList();

    if (_selectedFilter == 'Best Rated') {
      filtered.sort((a, b) {
        final cmp = b.mess.rating.compareTo(a.mess.rating);
        if (cmp != 0) return cmp;
        return (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999);
      });
    } else {
      filtered.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );
    }

    setState(() {
      _messes = filtered;
    });
  }

  void _openNativeDirections(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  void _callOwner(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showMessDetails(BuildContext context, _MessItem item) {
    MessDiscoveryDetailsSheet.show(
      context,
      item: MessDiscoveryItem(
        mess: item.mess,
        distanceKm: item.distanceKm,
        currentOrNextMealName: item.currentOrNextMealName,
        currentOrNextMealDishes: item.currentOrNextMealDishes,
        isServingNow: item.isServingNow,
        timeUntilNext: item.timeUntilNext,
        slotType: item.slotType,
        activePostedMenu: item.activePostedMenu,
        allMenus: item.allMenus,
      ),
      onOpenDirections: (lat, lng) => _openNativeDirections(lat, lng),
      onCallOwner: (phone) => _callOwner(phone),
      onShowAbout: (mess) => _showAboutMessSheet(context, mess),
      onJoinRequest: (mess) => _handleJoinMessRequest(context, mess),
    );
  }


  void _showAboutMessSheet(BuildContext context, MessModel mess) {
    QuillController? controller;
    try {
      final doc = Document.fromJson(
        jsonDecode(mess.aboutContent!) as List<dynamic>,
      );
      controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      controller = QuillController.basic();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'More About This Mess',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              Text(
                                mess.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  // Content - read only quill editor
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: QuillEditor(
                        controller: controller!,
                        scrollController: ScrollController(),
                        config: QuillEditorConfig(
                          padding: EdgeInsets.zero,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          scrollable: false,
                          expands: false,
                          autoFocus: false,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF111827),
                                height: 1.65,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(0, 4),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h1: DefaultTextBlockStyle(
                              GoogleFonts.inter(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(10, 4),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h2: DefaultTextBlockStyle(
                              GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(8, 2),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                        focusNode: FocusNode(canRequestFocus: false),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => controller?.dispose());
  }



  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Mess Near Me 📍',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22C55E),
                          ),
                        )
                      : _messes.isEmpty
                      ? Center(
                          child: Text(
                            "No messes found nearby.",
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _messes.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == _messes.length) {
                              return Center(
                                child: _isLoadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(
                                            color: Color(0xFF22C55E)),
                                      )
                                    : TextButton(
                                        onPressed: _loadMore,
                                        child: Text(
                                          'Load More',
                                          style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              );
                            }
                            return _buildGlassCard(_messes[index], index == 0);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(_MessItem item, bool isTopPick) {
    bool isClosed =
        item.mess.temporarilyClosedUntil != null &&
        item.mess.temporarilyClosedUntil!.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () => _showMessDetails(context, item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF), // 10% white opacity for glassmorphism
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTopPick
                ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                : const Color(0x33FFFFFF),
            width: isTopPick ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.mess.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Mess Rating Badge on Discover Card
                if (item.mess.reviewCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                        const SizedBox(width: 2),
                        Text(
                          '${item.mess.rating.toStringAsFixed(1)} (${item.mess.reviewCount})',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded, size: 12, color: Colors.white70),
                        const SizedBox(width: 2),
                        Text(
                          'New',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isTopPick)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAB308),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '★ TOP PICK',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x3322C55E),
                    border: Border.all(color: const Color(0xFF22C55E)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.distanceKm?.toStringAsFixed(1) ?? '--'} km',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status row
            if (!isClosed)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.isServingNow ? 'SERVING NOW' : 'NEXT UP',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF22C55E),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (isClosed)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CLOSED',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // Meal Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isClosed
                    ? const Color(0x33EF4444)
                    : (item.activePostedMenu?.menuType == 'special'
                        ? const Color(0xFFD97706)
                        : const Color(0xFF16A34A)),
                border: isClosed
                    ? Border.all(color: const Color(0xFFEF4444))
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isClosed
                    ? 'CLOSED TILL ${item.mess.temporarilyClosedUntil!.day}/${item.mess.temporarilyClosedUntil!.month}'
                    : (item.activePostedMenu != null &&
                            item.currentOrNextMealDishes.isNotEmpty
                        ? '${item.slotType == 'Night' ? '🌙' : '☀️'} ${item.currentOrNextMealName} • ${item.currentOrNextMealDishes}'
                        : (item.isServingNow
                            ? '${item.slotType == 'Night' ? '🌙' : '☀️'} Serving ${item.currentOrNextMealName}'
                            : (item.currentOrNextMealName != 'No meal set'
                                ? '${item.slotType == 'Night' ? '🌙' : '☀️'} Next: ${item.currentOrNextMealName}'
                                : '🍽️ Daily Fresh Homestyle Food'))),
                style: GoogleFonts.inter(
                  color: isClosed ? const Color(0xFFFCA5A5) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            // Bottom Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${item.mess.monthlyFee.toStringAsFixed(0)}/mo',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _callOwner(item.mess.ownerPhone),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Color(0xFF0F0C29),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () =>
                      _openNativeDirections(item.mess.gpsLat, item.mess.gpsLng),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleJoinMessRequest(BuildContext context, MessModel mess) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to join a mess')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      final plans = await ref.read(appServiceProvider).getMealPlans(mess.messId);
      final activePlans = plans.where((p) => p.isActive).toList();

      if (!context.mounted) return;
      Navigator.pop(context); // hide loading

      String? selectedPlanId;
      if (activePlans.isNotEmpty) {
        selectedPlanId = activePlans.first.planId;
      }

      // If active custom plans exist, prompt student to select one
      if (activePlans.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  'Select Meal Plan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a plan for ${mess.name}:',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    ...activePlans.map((p) {
                      final isSelected = selectedPlanId == p.planId;
                      return GestureDetector(
                        onTap: () => setState(() => selectedPlanId = p.planId),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      '₹${p.monthlyFee.toInt()}/mo • ${p.mealsIncludedPerDay} meals daily',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _executeJoin(context, user.uid, mess, selectedPlanId);
                    },
                    child: const Text('Submit Request'),
                  ),
                ],
              );
            },
          ),
        );
      } else {
        // No custom plans, join with default mess plan
        await _executeJoin(context, user.uid, mess, null);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _executeJoin(BuildContext context, String uid, MessModel mess, String? planId) async {
    final appService = ref.read(appServiceProvider);
    final student = await appService.getStudentById(uid);

    if (student != null) {
      final updated = student.copyWith(
        messId: mess.messId,
        status: 'pending',
        assignedPlanId: planId,
      );
      await appService.updateStudent(updated);
    } else {
      final newStudent = StudentModel(
        studentId: uid,
        name: FirebaseAuth.instance.currentUser?.displayName ?? 'Student',
        phone: FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        status: 'pending',
        messId: mess.messId,
        joinDate: DateTime.now(),
        roomNo: '',
        college: '',
        course: '',
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        assignedPlanId: planId,
      );
      await appService.updateStudent(newStudent);
    }

    if (context.mounted) {
      Navigator.pop(context); // close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request sent to ${mess.name}! The owner will activate your membership.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

}