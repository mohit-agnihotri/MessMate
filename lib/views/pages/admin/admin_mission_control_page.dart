import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../auth/login_page.dart';
import '../owner/owner_main_page.dart';
import '../student/student_main_page.dart';
import 'admin_cyber_theme.dart';
import 'tabs/admin_cockpit_tab.dart';
import 'tabs/admin_messes_tab.dart';
import 'tabs/admin_monetization_tab.dart';
import 'tabs/admin_ops_tab.dart';
import 'tabs/admin_support_tab.dart';

/// Global provider to switch tabs seamlessly from any child component.
final adminActiveTabProvider = StateProvider<int>((ref) => 0);

/// The central Mission Control Dashboard for the Founder / Super Admin.
/// Redesigned with the Executive Dark Luxury Obsidian & Amber aesthetic.
class AdminMissionControlPage extends ConsumerStatefulWidget {
  const AdminMissionControlPage({super.key});

  @override
  ConsumerState<AdminMissionControlPage> createState() =>
      _AdminMissionControlPageState();
}

class _AdminMissionControlPageState
    extends ConsumerState<AdminMissionControlPage> {
  final List<Widget> _tabs = const [
    AdminCockpitTab(),
    AdminMessesTab(),
    AdminSupportTab(),
    AdminMonetizationTab(),
    AdminOpsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(adminActiveTabProvider);

    return Scaffold(
      backgroundColor: AdminCyberTheme.bgObsidian,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AdminCyberTheme.bgObsidian,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  // App Icon Squircle (Sage green with bar chart equalizer glyph)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E654F),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4E654F).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 3.2,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0E9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 2.8),
                          Container(
                            width: 3.2,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0E9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 2.8),
                          Container(
                            width: 3.2,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0E9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Brand Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mission control',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'SUPER ADMIN  •  LIVE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Sandbox Dropdown Pill (Matching Inspired UI)
                  PopupMenuButton<String>(
                    tooltip: 'Sandbox Environment',
                    color: const Color(0xFF221C16),
                    elevation: 12,
                    offset: const Offset(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFF382F25),
                        width: 1.0,
                      ),
                    ),
                    onSelected: (val) {
                      if (val == 'owner') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OwnerMainPage()),
                        );
                      } else if (val == 'student') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentMainPage()),
                        );
                      } else if (val == 'exit_sandbox') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exited sandbox mode. You are in Super Admin Live mode.'),
                            backgroundColor: Color(0xFF221C16),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if (val == 'logout') {
                        ref.read(authProvider.notifier).signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'owner',
                        child: Row(
                          children: [
                            const Icon(Icons.crop_square_rounded,
                                size: 16, color: Color(0xFFFAF7F2)),
                            const SizedBox(width: 12),
                            Text(
                              'View as mess owner',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFAF7F2),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'student',
                        child: Row(
                          children: [
                            const Icon(Icons.diamond_outlined,
                                size: 16, color: Color(0xFFFAF7F2)),
                            const SizedBox(width: 12),
                            Text(
                              'View as student',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFAF7F2),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem(
                        value: 'exit_sandbox',
                        child: Text(
                          'Exit sandbox',
                          style: GoogleFonts.inter(
                            color: AdminCyberTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded,
                                size: 16, color: AdminCyberTheme.neonRose),
                            const SizedBox(width: 12),
                            Text(
                              'Sign out',
                              style: GoogleFonts.inter(
                                color: AdminCyberTheme.neonRose,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2217),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4A3824),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sandbox',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFAF7F2),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Color(0xFFFAF7F2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13100D),
          border: Border(
            top: BorderSide(
              color: Color(0xFF241D17),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.bar_chart_rounded, 'Pulse', currentIndex),
                _buildNavItem(1, Icons.storefront_outlined, 'Messes', currentIndex),
                _buildNavItem(2, Icons.all_inbox_rounded, 'Inbox', currentIndex),
                _buildNavItem(3, Icons.currency_rupee_rounded, 'Money', currentIndex),
                _buildNavItem(4, Icons.tune_rounded, 'Ops', currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final activeColor = AdminCyberTheme.neonAmber;
    final inactiveColor = const Color(0xFF7D7267);

    return InkWell(
      onTap: () {
        ref.read(adminActiveTabProvider.notifier).state = index;
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
