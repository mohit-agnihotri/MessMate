import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../services/notification_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/student_inspired_theme.dart';
import 'widgets/mess_discovery_details_sheet.dart';
import 'student_pending_approval_page.dart';

class _MessItem {
  final MessModel mess;
  final double? distanceKm;
  final String currentOrNextMealName;
  final String currentOrNextMealDishes;
  final bool isServingNow;
  final String? timeUntilNext;
  final String slotType;
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
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const ['All', 'Open Now', 'Best Rated', 'Veg Only'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final pos = await _getUserLocation();
      final newMesses = await ref
          .read(appServiceProvider)
          .getAllListedMesses(lastMessId: _lastMessId, limit: 10);

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

  Future<List<_MessItem>> _processMesses(
    List<MessModel> messesList,
    Position? pos,
  ) async {
    final items = await Future.wait(
      messesList.map((m) async {
        double? dist;
        if (pos != null && m.gpsLat != 0.0 && m.gpsLng != 0.0) {
          dist = Geolocator.distanceBetween(
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

        bool found = false;
        final slotOrder = ['morning', 'noon', 'evening', 'night'];

        for (var slot in slotOrder) {
          Map<String, String>? timing;
          for (final entry in m.mealTimings.entries) {
            if (entry.key.toLowerCase().trim() == slot) {
              timing = entry.value;
              break;
            }
          }
          timing ??= m.mealTimings[slot];

          final rawEnabled = timing?['enabled']?.toString().toLowerCase().trim();
          final isEnabled = timing != null &&
              (rawEnabled == 'true' || rawEnabled == '1' || rawEnabled == 'yes');

          if (isEnabled) {
            final startStr = timing['start'] ?? '00:00';
            final endStr = timing['end'] ?? '00:00';
            final startMin = _parseTime(startStr);
            final endMin = _parseTime(endStr);

            final bool isWithinTime = endMin >= startMin
                ? (currentMinutes >= startMin && currentMinutes <= endMin)
                : (currentMinutes >= startMin || currentMinutes <= endMin);

            final bool isCurrentOrUpcoming = endMin >= startMin
                ? (currentMinutes <= endMin)
                : (currentMinutes <= endMin || currentMinutes >= startMin);

            if (isCurrentOrUpcoming) {
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

              isServingNow = isWithinTime;
              found = true;
              break;
            }
          }
        }

        if (!found) {
          for (var slot in slotOrder) {
            Map<String, String>? timing;
            for (final entry in m.mealTimings.entries) {
              if (entry.key.toLowerCase().trim() == slot) {
                timing = entry.value;
                break;
              }
            }
            timing ??= m.mealTimings[slot];

            final rawEnabled = timing?['enabled']?.toString().toLowerCase().trim();
            final isEnabled = timing != null &&
                (rawEnabled == 'true' || rawEnabled == '1' || rawEnabled == 'yes');

            if (isEnabled) {
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

        final isClosed = !m.isOpen;
        if (isClosed) {
          isServingNow = false;
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _getUserLocation();
      final allMesses =
          await ref.read(appServiceProvider).getAllListedMesses(limit: 10);

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
    if (timeStr.isEmpty) return 0;
    final clean = timeStr.trim().toLowerCase();
    final isPm = clean.contains('pm');
    final isAm = clean.contains('am');
    final digitsOnly = clean.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = digitsOnly.split(':');
    if (parts.isEmpty || parts[0].isEmpty) return 0;
    int h = int.tryParse(parts[0]) ?? 0;
    int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    return h * 60 + m;
  }

  void _filterItems() {
    final anyServingNow =
        _allItems.any((it) => it.isServingNow && it.mess.isOpen);

    List<_MessItem> filtered = _allItems.where((item) {
      final matchesSearch = item.mess.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item.mess.ownerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Open Now') {
        if (anyServingNow) {
          return item.isServingNow && item.mess.isOpen;
        } else {
          // If no mess is in active meal serving window right now (e.g. between lunch & dinner),
          // show all operational messes that are open today (exclude temporarily closed)
          return item.mess.isOpen;
        }
      }
      if (_selectedFilter == 'Veg Only') {
        return item.mess.foodType == 'pure_veg';
      }
      return true;
    }).toList();

    if (_selectedFilter == 'Best Rated') {
      filtered.sort((a, b) {
        final cmp = b.mess.rating.compareTo(a.mess.rating);
        if (cmp != 0) return cmp;
        return (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999);
      });
    } else if (_selectedFilter == 'Open Now') {
      filtered.sort((a, b) {
        if (a.isServingNow != b.isServingNow) {
          return a.isServingNow ? -1 : 1;
        }
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

  // ── Sanitized Native Directions intent ──
  void _openNativeDirections(double lat, double lng) async {
    if (!lat.isFinite || !lng.isFinite || (lat == 0.0 && lng == 0.0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid GPS location for this mess.')),
        );
      }
      return;
    }
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

  // ── Sanitized Call intent ──
  void _callOwner(String phone) async {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner phone number is not available for this mess.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$sanitized');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final launched = await launchUrl(uri);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open phone dialer for $sanitized'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  Future<void> _openMessByCodePrompt() async {
    final codeController = TextEditingController();
    bool isSearching = false;
    String? errorText;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: StudentColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: StudentColors.walnutMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudentColors.sageLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: StudentColors.sageDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Mess Code',
                          style: StudentTypography.serifHeading(fontSize: 20),
                        ),
                        Text(
                          'From counter standee or shared link',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: StudentColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: StudentColors.walnut,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 102938 or mezzo.app link',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    letterSpacing: 0,
                    color: StudentColors.textMuted,
                  ),
                  filled: true,
                  fillColor: StudentColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: StudentColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: StudentColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: StudentColors.sageDark, width: 1.5),
                  ),
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSearching
                      ? null
                      : () async {
                          final input = codeController.text.trim();
                          if (input.isEmpty) return;
                          setModalState(() {
                            isSearching = true;
                            errorText = null;
                          });

                          String cleanCode = input;
                          if (input.contains('code=')) {
                            cleanCode = Uri.tryParse(input)?.queryParameters['code'] ?? input;
                          }

                          final mess = await ref.read(appServiceProvider).getMessByCode(cleanCode);
                          if (!mounted) return;

                          if (mess == null) {
                            setModalState(() {
                              isSearching = false;
                              errorText = 'No mess found with code "$cleanCode"';
                            });
                            return;
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          final pos = await _getUserLocation();
                          final items = await _processMesses([mess], pos);
                          if (!mounted) return;
                          if (items.isNotEmpty) {
                            _showMessDetails(context, items.first);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.walnut,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'View Mess Details',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                color: StudentColors.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StudentColors.walnutMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: StudentColors.sageLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: StudentColors.sageDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About This Mess',
                                style: StudentTypography.serifHeading(fontSize: 18),
                              ),
                              Text(
                                mess.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: StudentColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: StudentColors.walnut,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: StudentColors.borderSubtle),
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
                                fontSize: 14.5,
                                color: StudentColors.textDark,
                                height: 1.6,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(0, 4),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h1: DefaultTextBlockStyle(
                              StudentTypography.serifHeading(fontSize: 20),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(10, 4),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h2: DefaultTextBlockStyle(
                              StudentTypography.serifHeading(fontSize: 17),
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
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: StudentColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Title & Subtitle ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPLORE MESSES',
                      style: StudentTypography.overline(
                        fontSize: 11,
                        color: StudentColors.sageDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mess near me',
                      style: StudentTypography.serifHeading(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing verified messes around your location',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: StudentColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search Input Box + QR Action ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: StudentColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: StudentColors.borderSubtle),
                          boxShadow: StudentColors.softShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            _searchQuery = val;
                            _filterItems();
                          },
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: StudentColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by mess name, area...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: StudentColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: StudentColors.walnutMuted,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _filterItems();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: StudentColors.walnut,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: StudentColors.softShadow,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        tooltip: 'Enter Mess Code / QR',
                        onPressed: _openMessByCodePrompt,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Filter Chips ──
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    final anyServing = _allItems.any((it) => it.isServingNow && it.mess.isOpen);
                    final isOpenNowFilter = filter == 'Open Now';

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        _filterItems();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? StudentColors.walnut
                              : StudentColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? StudentColors.walnut
                                : StudentColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isOpenNowFilter) ...[
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: anyServing
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Text(
                              filter,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : StudentColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Status Banner for Open Now ──
              if (_selectedFilter == 'Open Now') ...[
                Builder(
                  builder: (context) {
                    final anyServing =
                        _allItems.any((it) => it.isServingNow && it.mess.isOpen);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: anyServing
                              ? StudentColors.sageLight
                              : StudentColors.amberLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: anyServing
                                ? StudentColors.sageBorder
                                : StudentColors.amberPill,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: anyServing
                                    ? StudentColors.sage
                                    : StudentColors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                anyServing
                                    ? 'Messes actively serving meals right now'
                                    : 'Currently between meal hours • Showing messes open today',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: anyServing
                                      ? StudentColors.sageText
                                      : StudentColors.amberText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              // ── Mess List / Empty State / Loading ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: StudentColors.amber,
                        ),
                      )
                    : _messes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🍽️', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 10),
                                Text(
                                  'No messes found nearby',
                                  style: StudentTypography.serifHeading(
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adjusting your search or filters.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: StudentColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: StudentColors.amber,
                            onRefresh: _loadData,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                              itemCount: _messes.length + (_hasMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                if (index == _messes.length) {
                                  return Center(
                                    child: _isLoadingMore
                                        ? const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(
                                              color: StudentColors.amber,
                                            ),
                                          )
                                        : TextButton(
                                            onPressed: _loadMore,
                                            child: Text(
                                              'Load More Messes',
                                              style: GoogleFonts.inter(
                                                color: StudentColors.sageDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  );
                                }
                                return _buildMessCard(_messes[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mess Card with Left Accent Strip & Editorial Hierarchy ─────────────────
  Widget _buildMessCard(_MessItem item) {
    bool isClosed = !item.mess.isOpen;

    final accentColor = isClosed
        ? StudentColors.brickRed
        : (item.isServingNow ? StudentColors.sage : StudentColors.amber);

    return GestureDetector(
      onTap: () => _showMessDetails(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: StudentColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StudentColors.borderSubtle),
          boxShadow: StudentColors.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Colored Vertical Strip
              Container(
                width: 5,
                color: accentColor,
              ),

              // Card Main Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Mess Name, Rating, Distance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.mess.name,
                                  style: StudentTypography.itemTitle(fontSize: 17),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.mess.ownerName.isNotEmpty
                                      ? 'Managed by ${item.mess.ownerName}'
                                      : 'Verified Mess Partner',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: StudentColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Rating Badge
                          if (item.mess.reviewCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: StudentColors.amberLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: StudentColors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.mess.rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      color: StudentColors.amberText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: StudentColors.sageLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.inter(
                                  color: StudentColors.sageText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),

                          // Distance Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: StudentColors.canvas,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: StudentColors.borderSubtle),
                            ),
                            child: Text(
                              '${item.distanceKm?.toStringAsFixed(1) ?? '--'} km',
                              style: GoogleFonts.inter(
                                color: StudentColors.walnut,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Current / Next Meal Banner Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? StudentColors.brickRedLight
                              : (item.isServingNow
                                  ? StudentColors.sageLight
                                  : StudentColors.amberLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isClosed
                                ? StudentColors.brickRedBorder
                                : (item.isServingNow
                                    ? StudentColors.sageBorder
                                    : StudentColors.amberPill),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isClosed
                                    ? StudentColors.brickRed
                                    : (item.isServingNow
                                        ? StudentColors.sage
                                        : StudentColors.amber),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isClosed
                                    ? (item.mess.temporarilyClosedUntil != null
                                        ? 'CLOSED TILL ${item.mess.temporarilyClosedUntil!.day}/${item.mess.temporarilyClosedUntil!.month}'
                                        : 'TEMPORARILY CLOSED')
                                    : (item.activePostedMenu != null &&
                                            item.currentOrNextMealDishes.isNotEmpty
                                        ? '${item.currentOrNextMealName} • ${item.currentOrNextMealDishes}'
                                        : (item.isServingNow
                                            ? 'Serving ${item.currentOrNextMealName}'
                                            : 'Next up: ${item.currentOrNextMealName} • Open Today')),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isClosed
                                      ? StudentColors.brickRed
                                      : (item.isServingNow
                                          ? StudentColors.sageText
                                          : StudentColors.amberText),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bottom Row: Price & Action Buttons (Wrap for responsive safety)
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${item.mess.monthlyFee.toStringAsFixed(0)}',
                                style: StudentTypography.serifNumeral(
                                  fontSize: 22,
                                  color: StudentColors.walnut,
                                ),
                              ),
                              Text(
                                'per month',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: StudentColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _callOwner(item.mess.ownerPhone),
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                  color: StudentColors.walnut,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: StudentColors.canvas,
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () => _openNativeDirections(
                                  item.mess.gpsLat,
                                  item.mess.gpsLng,
                                ),
                                icon: const Icon(
                                  Icons.navigation_outlined,
                                  size: 18,
                                  color: StudentColors.sageDark,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: StudentColors.sageLight,
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _showMessDetails(context, item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: StudentColors.walnut,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Details',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: StudentColors.amber),
      ),
    );

    try {
      final plans = await ref.read(appServiceProvider).getMealPlans(mess.messId);
      final activePlans = plans.where((p) => p.isActive).toList();

      if (!context.mounted) return;
      Navigator.pop(context);

      String? selectedPlanId;
      if (activePlans.isNotEmpty) {
        selectedPlanId = activePlans.first.planId;
      }

      if (activePlans.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: StudentColors.canvas,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  'Select Meal Plan',
                  style: StudentTypography.serifHeading(fontSize: 22),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a plan for ${mess.name}:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: StudentColors.textSecondary,
                      ),
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
                            color: isSelected ? StudentColors.walnut : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? StudentColors.walnut
                                  : StudentColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? StudentColors.amber
                                    : StudentColors.walnutMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: StudentTypography.bold(
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : StudentColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      '₹${p.monthlyFee.toInt()}/mo • ${p.mealsIncludedPerDay} meals daily',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: isSelected
                                            ? Colors.white70
                                            : StudentColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Future<void> _executeJoin(
    BuildContext context,
    String uid,
    MessModel mess,
    String? planId,
  ) async {
    BuildContext? dialogCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        dialogCtx = dCtx;
        return const Center(
          child: CircularProgressIndicator(color: StudentColors.amber),
        );
      },
    );

    try {
      final appService = ref.read(appServiceProvider);
      final student = await appService.getStudentById(uid);

      if (student != null) {
        final updated = student.copyWith(
          messId: mess.messId,
          status: 'pending',
          assignedPlanId: planId,
          isDeletedByOwner: false,
          joinDate: DateTime.now(),
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
          isDeletedByOwner: false,
        );
        await appService.updateStudent(newStudent);
      }

      String planName = 'Standard Mess Plan';
      if (planId != null && planId.isNotEmpty) {
        try {
          final plans = await appService.getMealPlans(mess.messId);
          final matched = plans.where((p) => p.planId == planId);
          if (matched.isNotEmpty) planName = matched.first.name;
        } catch (_) {}
      }

      if (mess.ownerNotificationPrefs['joinRequest'] != false) {
        final applicantName = student?.name ??
            FirebaseAuth.instance.currentUser?.displayName ??
            'A student';
        // Non-blocking fire-and-forget in background so notification never holds up navigation
        NotificationService.sendOwnerNotification(
          ownerId: mess.ownerId,
          title: '👋 New Join Request',
          message: '$applicantName requested to join ${mess.name}',
          data: {
            'type': 'join_request',
            'messId': mess.messId,
            'studentId': uid,
          },
        ).catchError((e) {
          debugPrint('[OneSignal] Error sending join request to owner: $e');
          return false;
        });
      }

      if (dialogCtx != null && dialogCtx!.mounted) {
        Navigator.of(dialogCtx!).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Join request sent to ${mess.name}! Waiting for owner approval.',
            ),
            backgroundColor: StudentColors.sage,
          ),
        );

        // Cleanly pop modal sheets and redirect to StudentPendingApprovalPage
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => StudentPendingApprovalPage(
              initialMessName: mess.name,
              initialPlanName: planName,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (dialogCtx != null && dialogCtx!.mounted) {
        Navigator.of(dialogCtx!).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit request: $e'),
            backgroundColor: StudentColors.brickRed,
          ),
        );
      }
    }
  }
}