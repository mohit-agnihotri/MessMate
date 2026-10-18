import 'dart:ui';
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

/// The central Mission Control Dashboard for the Founder / Super Admin.
class AdminMissionControlPage extends ConsumerStatefulWidget {
  const AdminMissionControlPage({super.key});

  @override
  ConsumerState<AdminMissionControlPage> createState() =>
      _AdminMissionControlPageState();
}

class _AdminMissionControlPageState
    extends ConsumerState<AdminMissionControlPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    AdminCockpitTab(),
    AdminMessesTab(),
    AdminSupportTab(),
    AdminMonetizationTab(),
    AdminOpsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminCyberTheme.bgObsidian,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF070B14).withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AdminCyberTheme.emeraldCyanGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.terminal_rounded,
                            color: Color(0xFF04202C), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'MISSION CONTROL',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Row(
                            children: [
                              const PulsingBeacon(
                                color: AdminCyberTheme.neonEmerald,
                                size: 6,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SUPER ADMIN • LIVE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AdminCyberTheme.neonEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Actions: Sandbox Switcher & Logout
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_outlined,
                                  size: 13, color: AdminCyberTheme.neonCyan),
                              const SizedBox(width: 5),
                              Text(
                                'Sandbox',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        color: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        onSelected: (val) {
                          if (val == 'owner') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OwnerMainPage()),
                            );
                          } else if (val == 'student') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StudentMainPage()),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'owner',
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_rounded,
                                    size: 16, color: AdminCyberTheme.neonEmerald),
                                const SizedBox(width: 10),
                                Text('View as Mess Owner',
                                    style: GoogleFonts.inter(
                                        color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'student',
                            child: Row(
                              children: [
                                const Icon(Icons.school_rounded,
                                    size: 16, color: AdminCyberTheme.neonCyan),
                                const SizedBox(width: 10),
                                Text('View as Student',
                                    style: GoogleFonts.inter(
                                        color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            size: 20, color: AdminCyberTheme.textMuted),
                        tooltip: 'Exit Mission Control',
                        onPressed: () {
                          ref.read(authProvider.notifier).signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070B14).withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.speed_rounded, 'Pulse'),
                _buildNavItem(1, Icons.storefront_rounded, 'Messes'),
                _buildNavItem(2, Icons.support_agent_rounded, 'Inbox'),
                _buildNavItem(3, Icons.account_balance_wallet_rounded, 'Kamai'),
                _buildNavItem(4, Icons.tune_rounded, 'Ops Deck'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = index == 3
        ? AdminCyberTheme.neonEmerald
        : index == 2
            ? AdminCyberTheme.neonViolet
            : AdminCyberTheme.neonCyan;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : AdminCyberTheme.textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: activeColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
