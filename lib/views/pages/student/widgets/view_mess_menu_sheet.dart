import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';

class ViewMessMenuSheet extends ConsumerStatefulWidget {
  final MessModel mess;
  final List<MenuModel>? initialMenus;

  const ViewMessMenuSheet({
    super.key,
    required this.mess,
    this.initialMenus,
  });

  static Future<void> show(
    BuildContext context, {
    required MessModel mess,
    List<MenuModel>? initialMenus,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewMessMenuSheet(
        mess: mess,
        initialMenus: initialMenus,
      ),
    );
  }

  @override
  ConsumerState<ViewMessMenuSheet> createState() => _ViewMessMenuSheetState();
}

class _ViewMessMenuSheetState extends ConsumerState<ViewMessMenuSheet> {
  bool _isLoading = false;
  Map<String, MenuModel> _templatesBySlot = {};
  Map<String, MenuModel> _todayPostedBySlot = {};

  final Map<String, String> _slotDisplayNames = {
    'morning': 'Breakfast (Morning)',
    'noon': 'Lunch (Noon)',
    'evening': 'Snacks (Evening)',
    'night': 'Dinner (Night)',
  };

  final Map<String, String> _slotEmojis = {
    'morning': '🌅',
    'noon': '☀️',
    'evening': '🌇',
    'night': '🌙',
  };

  @override
  void initState() {
    super.initState();
    _processMenus(widget.initialMenus ?? []);
    _loadMenus();
  }

  void _processMenus(List<MenuModel> menus) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final templates = <String, MenuModel>{};
    final todayPosted = <String, MenuModel>{};

    for (final m in menus) {
      final slot = m.mealSlot.toLowerCase();
      if (m.menuId == slot || m.menuType == 'template') {
        templates[slot] = m;
      } else if (m.isPublished && (m.menuType == 'regular' || m.menuType == 'special')) {
        if (m.menuId.startsWith(todayStr) || m.menuId == '${todayStr}_$slot') {
          todayPosted[slot] = m;
        }
      }
    }

    setState(() {
      _templatesBySlot = templates;
      _todayPostedBySlot = todayPosted;
    });
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(appServiceProvider);
      // Fetch both weekly templates (standard offerings) and today's menus
      final templates = await service.getWeeklyTemplate(widget.mess.messId);
      final todayMenus = await service.getDailyMenus(
        widget.mess.messId,
        DateTime.now(),
      );

      final combined = <MenuModel>[...templates, ...todayMenus];
      _processMenus(combined);
    } catch (e) {
      debugPrint('Error loading mess menu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabledSlots = ['morning', 'noon', 'evening', 'night'].where((slot) {
      final timing = widget.mess.mealTimings[slot];
      return timing != null && timing['enabled'] == 'true';
    }).toList();

    final activeSlots = enabledSlots.isNotEmpty
        ? enabledSlots
        : ['morning', 'noon', 'night'];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🍽️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.mess.name} Menu',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Regular offerings & timings (मेन्यू सूची)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: _isLoading && _templatesBySlot.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // Subheading banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This is what this mess regularly serves. When the mess cooks something specific today, it is highlighted below.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF15803D),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Slot cards
                      for (final slot in activeSlots) ...[
                        _buildSlotCard(slot),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(String slot) {
    final emoji = _slotEmojis[slot] ?? '🍽️';
    final displayName = _slotDisplayNames[slot] ?? slot.toUpperCase();
    final timing = widget.mess.mealTimings[slot];
    final startStr = timing?['start'] ?? '';
    final endStr = timing?['end'] ?? '';
    final timingStr = (startStr.isNotEmpty && endStr.isNotEmpty)
        ? '$startStr - $endStr'
        : '';

    final template = _templatesBySlot[slot];
    final todayPosted = _todayPostedBySlot[slot];
    final templateDishes = template?.dishes ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: todayPosted != null
              ? (todayPosted.menuType == 'special'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF22C55E))
              : const Color(0xFFE5E7EB),
          width: todayPosted != null ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Header Row
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (timingStr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 11,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timingStr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // If Today's meal is specifically posted
          if (todayPosted != null && todayPosted.dishes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: todayPosted.menuType == 'special'
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: todayPosted.menuType == 'special'
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFA7F3D0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        todayPosted.menuType == 'special'
                            ? '✨ TODAY\'S SPECIAL MEAL'
                            : 'TODAY\'S COOKED MEAL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: todayPosted.menuType == 'special'
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayPosted.dishes.map((d) => d.name).join(', '),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Standard Regular Offerings
          Text(
            'Regular Offerings (आम तौर पर बनने वाली डिशेस):',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),

          if (templateDishes.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: templateDishes.map((d) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    d.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'Homestyle fresh meals prepared daily.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
