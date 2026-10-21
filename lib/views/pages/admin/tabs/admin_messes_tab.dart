import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Messes Directory & Operations Tab.
/// Redesigned with the exact Executive Dark Luxury Obsidian & Warm Gold aesthetic
/// from Inspired UI (Screenshots 2, 8, 9, 11).
class AdminMessesTab extends ConsumerStatefulWidget {
  const AdminMessesTab({super.key});

  @override
  ConsumerState<AdminMessesTab> createState() => _AdminMessesTabState();
}

class _AdminMessesTabState extends ConsumerState<AdminMessesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'all'; // 'all' | 'trial' | 'verified' | 'frozen'
  String _sortBy = 'name'; // 'name' | 'newest' | 'expiring'
  bool _isSeeding = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showExtendTrialDialog(BuildContext context, MessModel mess, AdminService adminService) {
    final noteCtrl = TextEditingController();
    int currentDays = 0;
    if (mess.trialExpiresAt != null) {
      currentDays = mess.trialExpiresAt!.difference(DateTime.now()).inDays;
      if (currentDays < 0) currentDays = 0;
    }
    final int newDays = currentDays + 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B1612),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF382F25), width: 1.5),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '+30 days trial',
              style: AdminCyberTheme.serifTitle(fontSize: 24),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminCyberTheme.textSecondary,
                ),
                children: [
                  TextSpan(text: '${mess.name} has '),
                  TextSpan(
                    text: '$currentDays days',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFAF7F2)),
                  ),
                  const TextSpan(text: ' left. After this: '),
                  TextSpan(
                    text: '$newDays days.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: noteCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                hintStyle: GoogleFonts.inter(
                  color: AdminCyberTheme.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFF14110E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E261E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E261E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFAF7F2),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF140F09),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await adminService.extendMessTrial(mess.messId, 30);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added 30 days trial to ${mess.name}! ⏳'),
                          backgroundColor: const Color(0xFF1B1612),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Add 30 days',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  void _showFreezeDialog(BuildContext context, MessModel mess, AdminService adminService) {
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B1612),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF382F25), width: 1.5),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              mess.isFrozen ? 'Unfreeze ${mess.name}?' : 'Freeze ${mess.name}?',
              style: AdminCyberTheme.serifTitle(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              mess.isFrozen
                  ? 'Mess operations and student skipping will be fully restored.'
                  : 'Students lose menu access and skipping until you unfreeze. Reversible anytime.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AdminCyberTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'REASON • LOGGED IN AUDIT',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AdminCyberTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: GoogleFonts.inter(
                  color: AdminCyberTheme.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFF14110E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E261E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E261E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFAF7F2),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mess.isFrozen
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFB91C1C),
                    foregroundColor: mess.isFrozen
                        ? const Color(0xFF140F09)
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (mess.isFrozen) {
                      await adminService.unfreezeMess(
                        mess.messId,
                        reason: reasonCtrl.text.trim().isEmpty
                            ? 'Admin unfreeze'
                            : reasonCtrl.text.trim(),
                      );
                    } else {
                      await adminService.freezeMess(
                        mess.messId,
                        reason: reasonCtrl.text.trim().isEmpty
                            ? 'Admin freeze'
                            : reasonCtrl.text.trim(),
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mess.isFrozen
                              ? '${mess.name} has been unfrozen! 🔥'
                              : '${mess.name} is now frozen ❄️'),
                          backgroundColor: const Color(0xFF1B1612),
                        ),
                      );
                    }
                  },
                  child: Text(
                    mess.isFrozen ? 'Unfreeze mess' : 'Freeze mess',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  void _showMessStudentsSheet(
      BuildContext context, MessModel mess, List<StudentModel> allStudents) {
    final messStudents =
        allStudents.where((s) => s.messId == mess.messId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF16120E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF382F25), width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrolled students • ${mess.name}',
                      style: AdminCyberTheme.serifTitle(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${messStudents.length} registered students • Cap ${mess.capacity}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AdminCyberTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF261F18), height: 1),
              Expanded(
                child: messStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 40, color: AdminCyberTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No students enrolled yet',
                            style: GoogleFonts.inter(
                              color: AdminCyberTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share code #${mess.messCode} with students to join.',
                            style: GoogleFonts.inter(
                              color: AdminCyberTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      itemCount: messStudents.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF241C16), height: 16),
                      itemBuilder: (context, index) {
                        final student = messStudents[index];
                        final isActive =
                            student.status == 'active' || student.status == 'approved';
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF2C2217),
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : 'S',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AdminCyberTheme.neonAmber,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFAF7F2),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    student.phone.isNotEmpty
                                        ? student.phone
                                        : 'No phone',
                                    style: GoogleFonts.inter(
                                      color: AdminCyberTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1E2F22)
                                    : const Color(0xFF2E1715),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF33573A)
                                      : const Color(0xFF4C211D),
                                ),
                              ),
                              child: Text(
                                isActive ? 'Active' : student.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? const Color(0xFF6EAE7A)
                                      : const Color(0xFFF87171),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);
    final studentsAsync = ref.watch(adminStudentsStreamProvider);
    final allStudents = studentsAsync.value ?? [];

    return StreamBuilder<List<MessModel>>(
      stream: adminService.streamAllMesses(),
      builder: (context, snapshot) {
        final allMesses = snapshot.data ?? [];

        // Apply Search & Filters
        final query = _searchCtrl.text.trim().toLowerCase();
        var filteredMesses = allMesses.where((mess) {
          final matchesQuery = query.isEmpty ||
              mess.name.toLowerCase().contains(query) ||
              mess.messCode.toLowerCase().contains(query) ||
              mess.ownerName.toLowerCase().contains(query) ||
              mess.ownerPhone.toLowerCase().contains(query);

          if (!matchesQuery) return false;

          if (_selectedFilter == 'trial') {
            return mess.subscriptionStatus == 'trial_active';
          } else if (_selectedFilter == 'verified') {
            return mess.isVerified;
          } else if (_selectedFilter == 'frozen') {
            return mess.isFrozen;
          }
          return true;
        }).toList();

        // Apply Sorting
        if (_sortBy == 'name') {
          filteredMesses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        } else if (_sortBy == 'newest') {
          filteredMesses.sort((a, b) => (b.trialStartDate ?? DateTime(2020)).compareTo(a.trialStartDate ?? DateTime(2020)));
        } else if (_sortBy == 'expiring') {
          filteredMesses.sort((a, b) => (a.trialExpiresAt ?? DateTime(2099)).compareTo(b.trialExpiresAt ?? DateTime(2099)));
        }

        return Column(
          children: [
            // Search Input & Filter Pills Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search mess name, #code, owner phone...',
                      hintStyle: GoogleFonts.inter(
                        color: AdminCyberTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7A7067),
                        size: 20,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Color(0xFF7A7067), size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1B1612),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2E251D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2E251D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Filter Pills Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('All messes', 'all', allMesses.length),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          'In trial (180D)',
                          'trial',
                          allMesses.where((m) => m.subscriptionStatus == 'trial_active').length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          'Verified',
                          'verified',
                          allMesses.where((m) => m.isVerified).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          'Frozen',
                          'frozen',
                          allMesses.where((m) => m.isFrozen).length,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sort Menu Dropdown Pill
                  PopupMenuButton<String>(
                    tooltip: 'Sort messes',
                    color: const Color(0xFF221C16),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFF382F25)),
                    ),
                    onSelected: (val) => setState(() => _sortBy = val),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'name',
                        child: Text(
                          'Name A-Z',
                          style: GoogleFonts.inter(
                            color: _sortBy == 'name'
                                ? AdminCyberTheme.neonAmber
                                : const Color(0xFFFAF7F2),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'newest',
                        child: Text(
                          'Newest first',
                          style: GoogleFonts.inter(
                            color: _sortBy == 'newest'
                                ? AdminCyberTheme.neonAmber
                                : const Color(0xFFFAF7F2),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'expiring',
                        child: Text(
                          'Trial expiring soon',
                          style: GoogleFonts.inter(
                            color: _sortBy == 'expiring'
                                ? AdminCyberTheme.neonAmber
                                : const Color(0xFFFAF7F2),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221C16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF382F25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sortBy == 'name'
                                ? 'Sort ▼'
                                : _sortBy == 'newest'
                                    ? 'Newest ▼'
                                    : 'Expiring ▼',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFAF7F2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messes List or Inspired UI Empty State
            Expanded(
              child: filteredMesses.isEmpty
                  ? _buildEmptyState(allMesses.isEmpty, adminService)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      itemCount: filteredMesses.length,
                      itemBuilder: (context, index) {
                        final mess = filteredMesses[index];
                        return _buildMessCard(mess, adminService, allStudents);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterPill(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF221C16),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF382F25), width: 1.0),
        ),
        child: Text(
          '$label $count',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF140F09) : const Color(0xFFFAF7F2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty, AdminService adminService) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF221C16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 32,
                color: Color(0xFFFAF7F2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isCompletelyEmpty
                  ? 'No messes onboarded yet'
                  : 'No messes match this filter',
              textAlign: TextAlign.center,
              style: AdminCyberTheme.serifTitle(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletelyEmpty
                  ? 'Your database is fresh. You can seed a realistic demo mess with 1-click.'
                  : 'Reset filters or clear the search.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AdminCyberTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isCompletelyEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF140F09),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSeeding
                    ? null
                    : () async {
                        setState(() => _isSeeding = true);
                        try {
                          await adminService.seedSampleMess();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Demo Mess seeded with 180-day trial!'),
                                backgroundColor: Color(0xFF1B1612),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSeeding = false);
                        }
                      },
                icon: _isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF140F09),
                        ),
                      )
                    : const Icon(Icons.add_business_rounded, size: 18),
                label: Text(
                  _isSeeding ? 'Seeding Demo...' : 'Seed Sample Mess (1-Click)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF140F09),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _selectedFilter = 'all');
                },
                child: Text(
                  'Reset all filters',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessCard(
    MessModel mess,
    AdminService adminService,
    List<StudentModel> allStudents,
  ) {
    final messStudents =
        allStudents.where((s) => s.messId == mess.messId).toList();
    final activeStudentsCount = messStudents
        .where((s) => s.status == 'active' || s.status == 'approved')
        .length;

    int daysLeft = 0;
    double progress = 1.0;
    if (mess.trialExpiresAt != null) {
      daysLeft = mess.trialExpiresAt!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) daysLeft = 0;
      progress = (daysLeft / 180.0).clamp(0.0, 1.0);
    }

    final isVip = mess.subscriptionStatus == 'lifetime_vip';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CyberCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Title + Code Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Avatar in Sage Green
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: mess.isFrozen
                        ? const Color(0xFF381B18)
                        : const Color(0xFF4E654F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      mess.name.isNotEmpty ? mess.name[0].toUpperCase() : 'M',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF7F2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Mess Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mess.name,
                        style: AdminCyberTheme.serifTitle(fontSize: 19),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mess.ownerName.isNotEmpty ? mess.ownerName : 'Owner'} • ${mess.ownerPhone.isNotEmpty ? mess.ownerPhone : 'No phone'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AdminCyberTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Code Badge (#125061)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF332516),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4D371F)),
                  ),
                  child: Text(
                    '#${mess.messCode}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Capacity & Active students line
            Text(
              '$activeStudentsCount active students • cap ${mess.capacity}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AdminCyberTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Inner Trial Progress Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14110E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF261F18)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            isVip
                                ? '👑 Lifetime VIP Active'
                                : '⏳ $daysLeft days left in 180D trial',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFAF7F2),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: mess.isFrozen
                              ? const Color(0xFF331614)
                              : isVip
                                  ? const Color(0xFF382B1C)
                                  : const Color(0xFF1E2F22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: mess.isFrozen
                                ? const Color(0xFF4C211D)
                                : isVip
                                    ? const Color(0xFF5A442A)
                                    : const Color(0xFF33573A),
                          ),
                        ),
                        child: Text(
                          mess.isFrozen
                              ? 'FROZEN'
                              : isVip
                                  ? 'VIP'
                                  : 'ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: mess.isFrozen
                                ? const Color(0xFFF87171)
                                : isVip
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF6EAE7A),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isVip ? 1.0 : progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF261F18),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        mess.isFrozen
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF6EAE7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons Wrap (Zero Overflow Guarantee)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Students Button (Amber Filled)
                InkWell(
                  onTap: () => _showMessStudentsSheet(context, mess, allStudents),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Students ($activeStudentsCount)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF140F09),
                      ),
                    ),
                  ),
                ),

                // +30 Days Trial
                InkWell(
                  onTap: () => _showExtendTrialDialog(context, mess, adminService),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF241D17),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF382F25)),
                    ),
                    child: Text(
                      '+30 days trial',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFAF7F2),
                      ),
                    ),
                  ),
                ),

                // Grant VIP 👑
                InkWell(
                  onTap: () async {
                    await adminService.grantLifetimeVip(
                      mess.messId,
                      reason: 'Granted by Super Admin',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Granted Lifetime VIP to ${mess.name}! 👑'),
                          backgroundColor: const Color(0xFF1B1612),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2217),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4A3723)),
                    ),
                    child: Text(
                      isVip ? 'VIP Active 👑' : 'Grant VIP 👑',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),

                // Verify Badge ✓
                InkWell(
                  onTap: () async {
                    await adminService.toggleMessVerification(
                      mess.messId,
                      !mess.isVerified,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mess.isVerified
                              ? 'Removed verified badge from ${mess.name}'
                              : 'Verified badge granted to ${mess.name}! ✓'),
                          backgroundColor: const Color(0xFF1B1612),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2F22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF33573A)),
                    ),
                    child: Text(
                      mess.isVerified ? 'Verified ✓' : 'Verify badge ✓',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6EAE7A),
                      ),
                    ),
                  ),
                ),

                // Freeze ❄
                InkWell(
                  onTap: () => _showFreezeDialog(context, mess, adminService),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E1715),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4C211D)),
                    ),
                    child: Text(
                      mess.isFrozen ? 'Unfreeze 🔥' : 'Freeze ❄',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF87171),
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
  }
}
