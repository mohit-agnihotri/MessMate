import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class _MessItem {
  final MessModel mess;
  final double? distanceKm;
  final String currentOrNextMealName;
  final String currentOrNextMealDishes;
  final bool isServingNow;
  final String? timeUntilNext;
  final String slotType; // 'Morning', 'Noon', 'Night'

  _MessItem({
    required this.mess,
    required this.distanceKm,
    required this.currentOrNextMealName,
    required this.currentOrNextMealDishes,
    required this.isServingNow,
    this.timeUntilNext,
    required this.slotType,
  });
}

class StudentDiscoveryPage extends ConsumerStatefulWidget {
  const StudentDiscoveryPage({super.key});

  @override
  ConsumerState<StudentDiscoveryPage> createState() => _StudentDiscoveryPageState();
}

class _StudentDiscoveryPageState extends ConsumerState<StudentDiscoveryPage> {
  bool _isLoading = true;
  List<_MessItem> _messes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _getUserLocation();
      final allMesses = await ref.read(appServiceProvider).getAllListedMesses();
      
      final items = await Future.wait(allMesses.map((m) async {
        double? dist;
        if (pos != null) {
          dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, m.gpsLat, m.gpsLng) / 1000.0;
        }
        
        final menus = await ref.read(appServiceProvider).getDailyMenus(m.messId, DateTime.now());
        
        bool isServingNow = false;
        String mealName = 'No meal set';
        String dishes = 'Menu not updated';
        String? timeUntilNext;
        String slotType = 'Noon';
        
        final now = DateTime.now();
        // currentMinutes used for future time-based serving logic
        // final currentMinutes = now.hour * 60 + now.minute;
        
        // Simple logic for UI purpose
        if (menus.isNotEmpty) {
           final upcoming = menus.where((m) => true).toList(); // simplfied
           
           if (upcoming.isNotEmpty) {
             final m = upcoming.first;
             slotType = m.mealSlot;
             mealName = m.mealSlot == 'Morning' ? 'Breakfast' : m.mealSlot == 'Noon' ? 'Lunch' : 'Dinner';
             dishes = m.dishes.map((d) => d.name).join(' • ');
             isServingNow = true; 
           } else {
             slotType = menus.first.mealSlot;
             mealName = 'Tomorrow ${menus.first.mealSlot}';
             dishes = menus.first.dishes.map((d) => d.name).join(' • ');
             isServingNow = false;
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
        );
      }));

      items.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      
      if (mounted) {
        setState(() {
          _messes = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openNativeDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheet(context, item);
      },
    );
  }

  Widget _buildBottomSheet(BuildContext context, _MessItem item) {
    final mess = item.mess;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFC), // Warm white
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Hero Image / Photo Carousel
              if (mess.messPhotos.isNotEmpty)
                _buildPhotoCarousel(mess.messPhotos, item)
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=1000&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
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
                            item.currentOrNextMealName == 'No meal set'
                              ? 'MENU NOT UPDATED'
                              : '${item.slotType == 'Night' ? '🌙' : '☀️'} SERVING ${item.slotType.toUpperCase()} ${item.isServingNow ? 'NOW' : 'NEXT'}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(mess.name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Text('Mess Code: ${mess.messCode}', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.location_on, '${item.distanceKm?.toStringAsFixed(1) ?? '--'} km'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.people, '${mess.capacity} seats'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.eco, 'Veg & Non-Veg'), // Static for now
                ],
              ),
              const SizedBox(height: 24),
              // Meal highlight box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.currentOrNextMealName == 'No meal set'
                          ? 'No Upcoming Meal Scheduled'
                          : '${item.slotType == 'Night' ? '🌙' : '☀️'} ${item.isServingNow ? "Today's" : "Upcoming"} ${item.currentOrNextMealName}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFC2410C)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.currentOrNextMealDishes,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check mess for timings', 
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9A3412)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Pricing
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text('Monthly Plan', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF166534))),
                          const SizedBox(height: 4),
                          Text('₹${mess.monthlyFee.toStringAsFixed(0)}/mo', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text('Per Meal', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E40AF))),
                          const SizedBox(height: 4),
                          Text('₹${mess.perMealRate.toStringAsFixed(0)}/meal', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: Text('Includes all 3 meals daily', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)))),
              const SizedBox(height: 24),
              // Contact info
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF6B7280), size: 20),
                  const SizedBox(width: 8),
                  Text(mess.ownerName, style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF111827))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _callOwner(mess.ownerPhone),
                    child: Text(mess.ownerPhone, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E))),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _callOwner(mess.ownerPhone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.call, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Call Now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openNativeDirections(mess.gpsLat, mess.gpsLng),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Open in Maps', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(List<String> photos, _MessItem item) {
    final PageController controller = PageController();
    int _currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: PageView.builder(
                      controller: controller,
                      itemCount: photos.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (ctx, i) => Image.network(
                        photos[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF9CA3AF), size: 48),
                        ),
                      ),
                    ),
                  ),
                  // Meal status badge
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.currentOrNextMealName == 'No meal set'
                          ? 'MENU NOT UPDATED'
                          : '${item.slotType == 'Night' ? '🌙' : '☀️'} SERVING ${item.slotType.toUpperCase()} ${item.isServingNow ? 'NOW' : 'NEXT'}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Photo count badge
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${photos.length}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Page indicator dots
            if (photos.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563))),
        ],
      ),
    );
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
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterChips(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
                      : _messes.isEmpty
                          ? Center(child: Text("No messes found nearby.", style: GoogleFonts.inter(color: Colors.white70)))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _messes.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Mess Near Me', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Text('📍', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Showing ${_messes.length} messes · Updated just now', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB4A8E0))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x3322C55E),
              border: Border.all(color: const Color(0xFF22C55E)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Within 5 km', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF), // frosted glass
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Color(0xFFB4A8E0)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search mess by name...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF8B82B5)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All', false),
          _buildFilterChip('Veg Only', false),
          _buildFilterChip('Non-Veg', false),
          _buildFilterChip('Open Now', true),
          _buildFilterChip('Best Rated', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0x3322C55E) : const Color(0x1AFFFFFF),
        border: Border.all(color: isSelected ? const Color(0xFF22C55E) : const Color(0x33FFFFFF)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.white : const Color(0xFFB4A8E0),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildGlassCard(_MessItem item, bool isTopPick) {
    return GestureDetector(
      onTap: () => _showMessDetails(context, item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF), // 10% white opacity for glassmorphism
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTopPick ? const Color(0xFF22C55E).withValues(alpha: 0.5) : const Color(0x33FFFFFF),
            width: isTopPick ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
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
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTopPick)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAB308),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('★ TOP PICK', style: GoogleFonts.inter(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x3322C55E),
                    border: Border.all(color: const Color(0xFF22C55E)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${item.distanceKm?.toStringAsFixed(1) ?? '--'} km', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status row
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(item.isServingNow ? 'SERVING NOW' : 'NEXT UP', style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            // Meal Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.currentOrNextMealName == 'No meal set'
                    ? 'MENU NOT UPDATED'
                    : '${item.slotType == 'Night' ? '🌙' : '☀️'} ${item.currentOrNextMealName} • ${item.currentOrNextMealDishes}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
                Text('₹${item.mess.monthlyFee.toStringAsFixed(0)}/mo', style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                InkWell(
                  onTap: () => _callOwner(item.mess.ownerPhone),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.call, color: Color(0xFF0F0C29), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _openNativeDirections(item.mess.gpsLat, item.mess.gpsLng),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                    child: const Icon(Icons.directions, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
