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
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: AdminCyberTheme.bgObsidian,
            border: Border(
              bottom: BorderSide(
                color: AdminCyberTheme.borderSubtle,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Brand & Status (Expanded to prevent any overflow)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: AdminCyberTheme.emeraldCyanGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dashboard_customize_rounded,
                              color: Color(0xFF04202C), size: 17),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
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
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const PulsingBeacon(
                                    color: AdminCyberTheme.neonEmerald,
                                    size: 6,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'SUPER ADMIN • LIVE',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AdminCyberTheme.neonEmerald,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Sandbox Switcher & Logout
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AdminCyberTheme.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: AdminCyberTheme.borderSubtle),
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
                                    size: 16,
                                    color: AdminCyberTheme.neonEmerald),
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
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            size: 19, color: AdminCyberTheme.textMuted),
                        tooltip: 'Exit Mission Control',
                        onPressed: () {
                          ref.read(authProvider.notifier).signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
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
          color: AdminCyberTheme.bgObsidian,
          border: Border(
            top: BorderSide(
              color: AdminCyberTheme.borderSubtle,
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(
                  color: activeColor.withValues(alpha: 0.35), width: 1.0)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? activeColor : AdminCyberTheme.textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
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
