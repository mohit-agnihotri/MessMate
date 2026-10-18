import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);

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
              mess.ownerName.toLowerCase().contains(query);

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search mess name, code (#MESS-...), owner...',
                      hintStyle: GoogleFonts.inter(
                          color: AdminCyberTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AdminCyberTheme.neonCyan, size: 20),
                      filled: true,
                      fillColor: const Color(0xFF101626),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AdminCyberTheme.neonCyan,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                              .where((m) =>
                                  m.subscriptionStatus == 'trial_active')
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

            // Messes List
            Expanded(
              child: filteredMesses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_outlined,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'No messes found matching query',
                            style: GoogleFonts.inter(
                              color: AdminCyberTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: filteredMesses.length,
                      itemBuilder: (context, index) {
                        final mess = filteredMesses[index];
                        return _buildMessCard(mess, adminService);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AdminCyberTheme.neonCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AdminCyberTheme.neonCyan
                : Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.1),
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

  Widget _buildMessCard(MessModel mess, AdminService adminService) {
    int daysLeft = 0;
    if (mess.trialExpiresAt != null) {
      daysLeft = mess.trialExpiresAt!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CyberCard(
        glowColor: mess.isFrozen
            ? AdminCyberTheme.neonRose
            : mess.isVerified
                ? AdminCyberTheme.neonEmerald
                : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name, Status & Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      PulsingBeacon(
                        color: mess.isFrozen
                            ? AdminCyberTheme.neonRose
                            : AdminCyberTheme.neonEmerald,
                        size: 7,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          mess.name,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mess.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 16, color: AdminCyberTheme.neonEmerald),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 6),
            Text(
              'Owner: ${mess.ownerName} • 📞 ${mess.ownerPhone}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AdminCyberTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Plan & Trial Telemetry Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AdminCyberTheme.neonAmber),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            mess.subscriptionStatus == 'lifetime_vip'
                                ? 'LIFETIME FREE VIP'
                                : '$daysLeft Days Trial Remaining',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: mess.subscriptionStatus == 'lifetime_vip'
                                  ? AdminCyberTheme.neonCyan
                                  : AdminCyberTheme.neonAmber,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mess.isFrozen ? 'STATUS: FROZEN' : 'STATUS: ACTIVE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: mess.isFrozen
                          ? AdminCyberTheme.neonRose
                          : AdminCyberTheme.neonEmerald,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
                  label: mess.isVerified ? 'Remove Badge' : 'Verify Badge ✓',
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

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
