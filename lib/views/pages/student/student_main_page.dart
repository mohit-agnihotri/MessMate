import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/student_inspired_theme.dart';
import 'student_home_page.dart';
import 'student_history_page.dart';
import 'student_bill_page.dart';
import 'student_profile_page.dart';
import 'student_discovery_page.dart';
import '../../widgets/app_update_dialog.dart';

class StudentMainPage extends ConsumerStatefulWidget {
  const StudentMainPage({super.key});
  @override
  ConsumerState<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends ConsumerState<StudentMainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateDialog.checkAndShow(context, ref);
      }
    });
  }

  final List<Widget> _pages = const [
    StudentHomePage(),
    StudentDiscoveryPage(),
    StudentHistoryPage(),
    StudentBillPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: StudentColors.canvas,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: StudentColors.walnut,
                borderRadius: BorderRadius.circular(34),
                boxShadow: StudentColors.dockShadow,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildTab(0, Icons.home_rounded, 'Home'),
                  _buildTab(1, Icons.explore_rounded, 'Discover'),
                  _buildTab(2, Icons.history_rounded, 'History'),
                  _buildTab(3, Icons.receipt_long_rounded, 'Bill'),
                  _buildTab(4, Icons.person_rounded, 'Profile'),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? StudentColors.amber.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? StudentColors.amber
                      : const Color(0xFFB5A99D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? StudentColors.amber
                      : const Color(0xFF9E9287),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
