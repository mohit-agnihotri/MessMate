import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'owner_dashboard_page.dart';
import 'owner_menu_planner_v2_page.dart';
import 'owner_absentee_tracker_page.dart';
import 'owner_student_management_page.dart';
import 'owner_settings_page.dart';
import 'owner_analytics_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../viewmodels/all_viewmodels.dart';
import '../auth/owner_setup_page.dart';

class OwnerMainPage extends ConsumerStatefulWidget {
  const OwnerMainPage({super.key});
  @override
  ConsumerState<OwnerMainPage> createState() => _OwnerMainPageState();
}

class _OwnerMainPageState extends ConsumerState<OwnerMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OwnerDashboardPage(),
    const OwnerMenuPlannerV2Page(),
    const OwnerAbsenteeTrackerPage(),
    const OwnerStudentManagementPage(),
    const OwnerAnalyticsPage(),
    const OwnerSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(ownerDashboardProvider, (prev, next) {
      if (!next.isLoading && next.mess == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerSetupPage()),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _buildTab(0, Icons.grid_view_rounded, 'Dashboard'),
                  _buildTab(1, Icons.restaurant_menu_rounded, 'Menu'),
                  _buildTab(2, Icons.how_to_reg_rounded, 'Absentee'),
                  _buildTab(3, Icons.group_rounded, 'Students'),
                  _buildTab(4, Icons.analytics_rounded, 'Analytics'),
                  _buildTab(5, Icons.settings_rounded, 'Settings'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
