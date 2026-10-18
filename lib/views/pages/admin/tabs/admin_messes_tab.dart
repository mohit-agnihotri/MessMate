import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Messes Directory & Operations Tab.
/// Allows developer to search messes, extend trials, grant VIP, freeze accounts, and inspect.
class AdminMessesTab extends ConsumerStatefulWidget {
  const AdminMessesTab({super.key});

  @override
  ConsumerState<AdminMessesTab> createState() => _AdminMessesTabState();
}

class _AdminMessesTabState extends ConsumerState<AdminMessesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'all';
  bool _isSeeding = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

        // Filter messes
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredMesses = allMesses.where((mess) {
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

        return Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search mess name, #code, owner phone...',
                      hintStyle: GoogleFonts.inter(
                        color: AdminCyberTheme.textMuted,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AdminCyberTheme.neonCyan, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AdminCyberTheme.textMuted, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AdminCyberTheme.cardSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AdminCyberTheme.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AdminCyberTheme.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AdminCyberTheme.neonCyan,
                          width: 1.5,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Messes', 'all', allMesses.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'In Trial (180D)',
                          'trial',
                          allMesses
                              .where((m) => m.subscriptionStatus == 'trial_active')
                              .length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Verified',
                          'verified',
                          allMesses.where((m) => m.isVerified).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Frozen',
                          'frozen',
                          allMesses.where((m) => m.isFrozen).length,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Messes List or Rich Empty State
            Expanded(
              child: filteredMesses.isEmpty
                  ? _buildEmptyState(allMesses.isEmpty, adminService)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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

  Widget _buildEmptyState(bool isCompletelyEmpty, AdminService adminService) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminCyberTheme.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AdminCyberTheme.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                isCompletelyEmpty
                    ? Icons.storefront_outlined
                    : Icons.filter_alt_off_rounded,
                size: 44,
                color: AdminCyberTheme.neonCyan.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isCompletelyEmpty
                  ? 'No Messes Onboarded Yet'
                  : 'No Messes Match Current Filter',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletelyEmpty
                  ? 'Your database is fresh. You can seed a realistic demo mess with 1-click to test the entire ecosystem.'
                  : 'Try resetting the filters or clearing the search query to see all registered messes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AdminCyberTheme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isCompletelyEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminCyberTheme.neonCyan,
                  foregroundColor: const Color(0xFF04202C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                content: Text(
                                    '🎉 Demo Mess successfully onboarded with 180-day trial!'),
                                backgroundColor: Color(0xFF04202C),
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
                          color: Color(0xFF04202C),
                        ),
                      )
                    : const Icon(Icons.add_business_rounded, size: 18),
                label: Text(
                  _isSeeding ? 'Onboarding Demo...' : 'Seed Sample Mess (1-Click)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminCyberTheme.neonCyan,
                  side: const BorderSide(color: AdminCyberTheme.neonCyan),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _selectedFilter = 'all');
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: Text(
                  'Reset All Filters',
                  style: GoogleFonts.outfit(
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

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AdminCyberTheme.neonCyan.withValues(alpha: 0.14)
              : AdminCyberTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AdminCyberTheme.neonCyan.withValues(alpha: 0.6)
                : AdminCyberTheme.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AdminCyberTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AdminCyberTheme.neonCyan.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AdminCyberTheme.neonCyan
                      : AdminCyberTheme.textMuted,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Title + Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Avatar Squircle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: mess.isFrozen
                          ? [
                              AdminCyberTheme.neonRose.withValues(alpha: 0.25),
                              const Color(0xFF1E1122),
                            ]
                          : [
                              AdminCyberTheme.neonCyan.withValues(alpha: 0.25),
                              const Color(0xFF0D1B2A),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mess.isFrozen
                          ? AdminCyberTheme.neonRose.withValues(alpha: 0.4)
                          : AdminCyberTheme.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mess.name.isNotEmpty ? mess.name[0].toUpperCase() : 'M',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: mess.isFrozen
                            ? AdminCyberTheme.neonRose
                            : AdminCyberTheme.neonCyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Mess Info (Expanded to prevent overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mess.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mess.isVerified) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.verified_rounded,
                                size: 15, color: AdminCyberTheme.neonEmerald),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13, color: AdminCyberTheme.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${mess.ownerName} • ${mess.ownerPhone}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AdminCyberTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.copy_rounded,
                                size: 13, color: AdminCyberTheme.textMuted),
                            tooltip: 'Copy Phone',
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: mess.ownerPhone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Copied ${mess.ownerPhone} to clipboard'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Real Live Enrolled Students Counter
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              size: 13, color: AdminCyberTheme.neonCyan),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$activeStudentsCount Active Students • Cap: ${mess.capacity}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AdminCyberTheme.neonCyan,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Code Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminCyberTheme.borderSubtle),
                  ),
                  child: Text(
                    '#${mess.messCode}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminCyberTheme.neonCyan,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Plan & Trial Telemetry Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminCyberTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isVip
                                ? Icons.workspace_premium_rounded
                                : Icons.hourglass_top_rounded,
                            size: 14,
                            color: isVip
                                ? AdminCyberTheme.neonCyan
                                : (daysLeft > 30
                                    ? AdminCyberTheme.neonEmerald
                                    : AdminCyberTheme.neonAmber),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isVip
                                ? 'LIFETIME FREE VIP'
                                : '$daysLeft Days Remaining in 180D Trial',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isVip
                                  ? AdminCyberTheme.neonCyan
                                  : (daysLeft > 30
                                      ? AdminCyberTheme.neonEmerald
                                      : AdminCyberTheme.neonAmber),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: mess.isFrozen
                              ? AdminCyberTheme.neonRose.withValues(alpha: 0.15)
                              : AdminCyberTheme.neonEmerald
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mess.isFrozen ? 'FROZEN' : 'ACTIVE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: mess.isFrozen
                                ? AdminCyberTheme.neonRose
                                : AdminCyberTheme.neonEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isVip) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          daysLeft > 30
                              ? AdminCyberTheme.neonEmerald
                              : AdminCyberTheme.neonAmber,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionPill(
                  label: 'Students ($activeStudentsCount)',
                  icon: Icons.people_outline_rounded,
                  color: AdminCyberTheme.neonCyan,
                  onTap: () =>
                      _showMessStudentsSheet(context, mess, messStudents),
                ),
                _buildActionPill(
                  label: '+30 Days Trial',
                  icon: Icons.add_circle_outline_rounded,
                  color: AdminCyberTheme.neonCyan,
                  onTap: () async {
                    await adminService.extendMessTrial(mess.messId, 30);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Extended 30 days trial for ${mess.name} 🚀'),
                          backgroundColor: const Color(0xFF04202C),
                        ),
                      );
                    }
                  },
                ),
                _buildActionPill(
                  label: isVip ? 'Revoke VIP' : 'Grant VIP 👑',
                  icon: Icons.workspace_premium_rounded,
                  color: AdminCyberTheme.neonViolet,
                  onTap: () async {
                    await adminService.setMessLifetimeVip(mess.messId, !isVip);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isVip
                              ? 'VIP revoked for ${mess.name}'
                              : '👑 Lifetime VIP granted to ${mess.name}!'),
                          backgroundColor: const Color(0xFF04202C),
                        ),
                      );
                    }
                  },
                ),
                _buildActionPill(
                  label: mess.isVerified ? 'Remove Tick' : 'Verify Badge ✓',
                  icon: Icons.verified_rounded,
                  color: AdminCyberTheme.neonEmerald,
                  onTap: () async {
                    await adminService.toggleMessVerification(
                        mess.messId, !mess.isVerified);
                  },
                ),
                _buildActionPill(
                  label: mess.isFrozen ? 'Unfreeze' : 'Freeze ❄️',
                  icon: Icons.ac_unit_rounded,
                  color: AdminCyberTheme.neonRose,
                  onTap: () async {
                    await adminService.toggleMessFreeze(
                        mess.messId, !mess.isFrozen);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessStudentsSheet(
    BuildContext context,
    MessModel mess,
    List<StudentModel> students,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF070B14),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ENROLLED STUDENTS DIRECTORY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AdminCyberTheme.neonCyan,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mess.name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AdminCyberTheme.neonCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AdminCyberTheme.neonCyan
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${students.length} Total',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.neonCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 10),
                  if (students.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_off_outlined,
                                size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              'No Students Enrolled Yet',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'When students join using code #${mess.messCode}, they will appear here live.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AdminCyberTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: students.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10, height: 16),
                        itemBuilder: (context, idx) {
                          final st = students[idx];
                          final isActive =
                              st.status == 'active' || st.status == 'approved';

                          return Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AdminCyberTheme.neonCyan
                                          .withValues(alpha: 0.15)
                                      : AdminCyberTheme.neonAmber
                                          .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isActive
                                        ? AdminCyberTheme.neonCyan
                                            .withValues(alpha: 0.4)
                                        : AdminCyberTheme.neonAmber
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    st.name.isNotEmpty
                                        ? st.name[0].toUpperCase()
                                        : 'S',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isActive
                                          ? AdminCyberTheme.neonCyan
                                          : AdminCyberTheme.neonAmber,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      st.name.isNotEmpty
                                          ? st.name
                                          : 'Unknown Student',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          st.phone.isNotEmpty
                                              ? st.phone
                                              : 'No Phone',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            color: AdminCyberTheme.textMuted,
                                          ),
                                        ),
                                        if (st.phone.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: st.phone));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Copied ${st.phone}'),
                                                  duration: const Duration(
                                                      seconds: 1),
                                                ),
                                              );
                                            },
                                            child: const Icon(Icons.copy_rounded,
                                                size: 11,
                                                color:
                                                    AdminCyberTheme.textMuted),
                                          ),
                                        ],
                                        if (st.roomNo.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '• Room ${st.roomNo}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AdminCyberTheme
                                                  .textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AdminCyberTheme.neonEmerald
                                          .withValues(alpha: 0.15)
                                      : AdminCyberTheme.neonAmber
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isActive
                                        ? AdminCyberTheme.neonEmerald
                                            .withValues(alpha: 0.3)
                                        : AdminCyberTheme.neonAmber
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  st.status.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isActive
                                        ? AdminCyberTheme.neonEmerald
                                        : AdminCyberTheme.neonAmber,
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
            );
          },
        );
      },
    );
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
