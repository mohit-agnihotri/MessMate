import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'owner_dashboard_page.dart';
import 'owner_menu_planner_v2_page.dart';
import 'owner_absentee_tracker_page.dart';
import 'owner_student_management_page.dart';
import 'owner_settings_page.dart';
import 'owner_analytics_page.dart';
import 'widgets/owner_drawer.dart';
import 'widgets/post_today_meal_sheet.dart';
import 'theme/owner_inspired_theme.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../auth/owner_setup_page.dart';
import '../../widgets/app_update_dialog.dart';

final ownerBottomNavIndexProvider = StateProvider<int>((ref) => 0);

class OwnerMainPage extends ConsumerStatefulWidget {
  const OwnerMainPage({super.key});
  @override
  ConsumerState<OwnerMainPage> createState() => _OwnerMainPageState();
}

class _OwnerMainPageState extends ConsumerState<OwnerMainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateDialog.checkAndShow(context, ref);
    });
  }

  final List<Widget> _pages = [
    const OwnerDashboardPage(),        // 0: Today
    const OwnerMenuPlannerV2Page(),     // 1: Menu
    const OwnerAbsenteeTrackerPage(),   // 2: Absentee
    const OwnerStudentManagementPage(), // 3: People
    const OwnerAnalyticsPage(),         // 4: Insights
    const OwnerSettingsPage(),          // 5: Settings
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(ownerBottomNavIndexProvider);

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
        backgroundColor: OwnerColors.canvas,
        endDrawer: const OwnerDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: OwnerColors.canvasGradient,
          ),
          child: IndexedStack(index: currentIndex, children: _pages),
        ),
        bottomNavigationBar: _buildFloatingDock(context, currentIndex),
      ),
    );
  }

  Widget _buildFloatingDock(BuildContext context, int currentIndex) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: OwnerColors.walnut,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockTab(
                currentIndex: currentIndex,
                pageIndex: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Today',
              ),
              _buildDockTab(
                currentIndex: currentIndex,
                pageIndex: 1,
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu_rounded,
                label: 'Menu',
              ),
              _buildCenterPlusButton(context),
              _buildDockTab(
                currentIndex: currentIndex,
                pageIndex: 3,
                icon: Icons.group_outlined,
                activeIcon: Icons.group_rounded,
                label: 'People',
              ),
              _buildDockTab(
                currentIndex: currentIndex,
                pageIndex: 4,
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Insights',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockTab({
    required int currentIndex,
    required int pageIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == pageIndex;
    final color = isActive ? OwnerColors.amber : const Color(0xFFC7BCB3);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(ownerBottomNavIndexProvider.notifier).state = pageIndex;
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlusButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        final mess = ref.read(ownerDashboardProvider).mess;
        if (mess != null) {
          PostTodayMealSheet.show(context, mess: mess);
        }
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: OwnerColors.amber,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: OwnerColors.amber.withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add_rounded,
          size: 28,
          color: OwnerColors.textDark,
        ),
      ),
    );
  }
}
