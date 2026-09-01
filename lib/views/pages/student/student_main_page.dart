import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_home_page.dart';
import 'student_history_page.dart';
import 'student_bill_page.dart';
import 'student_profile_page.dart';
import 'student_discovery_page.dart';

class StudentMainPage extends StatefulWidget {
  const StudentMainPage({super.key});
  @override
  State<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StudentHomePage(),
    const StudentDiscoveryPage(),
    const StudentHistoryPage(),
    const StudentBillPage(),
    const StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _buildTab(0, Icons.home_rounded, 'Home'),
                  _buildTab(1, Icons.explore_rounded, 'Discover'),
                  _buildTab(2, Icons.history_rounded, 'History'),
                  _buildTab(3, Icons.currency_rupee_rounded, 'Bill'),
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
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isActive ? const Color(0xFF22C55E) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF)),
              const SizedBox(height: 3),
              Text(label, style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
