import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/admin_config.dart';
import '../../../services/admin_service.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../admin/admin_mission_control_page.dart';
import '../admin/widgets/admin_pin_verification_sheet.dart';
import '../admin/widgets/admin_stealth_gate_sheet.dart';
import 'role_selection_page.dart';
import 'owner_setup_page.dart';
import 'student_setup_page.dart';
import '../owner/owner_main_page.dart';
import '../student/student_main_page.dart';
import '../student/student_pending_approval_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final AuthRole? initialRole;
  const LoginPage({super.key, this.initialRole});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool get isHindi => ref.watch(localizationProvider) == 'hi';

  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastLogoTap == null ||
        now.difference(_lastLogoTap!) > const Duration(seconds: 2)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    _lastLogoTap = now;

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      HapticFeedback.heavyImpact();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => AdminStealthGateSheet(
          onSuccess: () {
            ref.read(authProvider.notifier).setRole(AuthRole.admin);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminMissionControlPage()),
            );
          },
        ),
      );
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to authentication state changes
    ref.listen(authProvider, (prev, next) async {
      if (next.userId != null && prev?.userId == null) {
        final uid = next.userId!;
        final service = ref.read(appServiceProvider);

        // 0. Super Admin Auto-Detection & Whitelist Check:
        final currentUser = FirebaseAuth.instance.currentUser;
        final adminService = ref.read(adminServiceProvider);
        final config = await adminService.getGlobalConfig();
        if (AdminConfig.isSuperAdminEmail(
            currentUser?.email, config.adminEmails)) {
          if (mounted) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              builder: (_) => AdminPinVerificationSheet(
                onSuccess: () {
                  ref.read(authProvider.notifier).setRole(AuthRole.admin);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminMissionControlPage()),
                  );
                },
              ),
            );
            return;
          }
        }

        // Smart Universal Account Auto-Detection:
        // 1. Check if user already exists as an Owner
        final mess = await service.getMessByOwnerId(uid);
        if (mess != null && mounted) {
          ref.read(authProvider.notifier).setRole(AuthRole.owner);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OwnerMainPage()),
          );
          return;
        }

        // 2. Check if user already exists as a Student
        final student = await service.getStudentById(uid);
        if (student != null && mounted) {
          ref.read(authProvider.notifier).setRole(AuthRole.student);
          if (student.status == 'active' || student.status == 'approved') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentMainPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StudentPendingApprovalPage(
                  initialMessName: student.messId.isNotEmpty ? (ref.read(localizationProvider) == 'hi' ? 'मेस' : 'Mess') : null,
                ),
              ),
            );
          }
          return;
        }

        // 3. New User without account:
        if (mounted) {
          if (widget.initialRole == AuthRole.owner) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OwnerSetupPage()),
            );
          } else if (widget.initialRole == AuthRole.student) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentSetupPage()),
            );
          } else {
            // Take to Role Selection to choose Owner or Student
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
            );
          }
        }
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // Ambient Radial Glow 1 (Emerald top-left)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
            ),
          ),
          // Ambient Radial Glow 2 (Amber bottom-right)
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.expand(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Back button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 40),
                      InkWell(
                        onTap: () {
                          ref.read(localizationProvider.notifier).toggleLanguage(isHindi ? 'en' : 'hi');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 15, color: Color(0xFF34D399)),
                              const SizedBox(width: 6),
                              Text(
                                isHindi ? 'English' : 'हिंदी',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // App Icon / Logo (with 5-tap stealth easter egg)
                  GestureDetector(
                    onTap: _onLogoTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Welcome Text
                  Text(
                    'Welcome to\nMessMate',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.initialRole == AuthRole.owner
                        ? 'Sign in to manage your mess, live kitchen headcount & billing.'
                        : widget.initialRole == AuthRole.student
                            ? 'Sign in to track meals, choose daily timings & view passbook.'
                            : 'Sign in to manage your everyday mess meals easily.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF94A3B8),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: authState.isLoading
                          ? null
                          : () => ref.read(authProvider.notifier).signInWithGoogle(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (authState.isLoading)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFF10B981),
                                strokeWidth: 2.5,
                              ),
                            )
                          else
                            Image.asset(
                              'assets/google_logo.png',
                              width: 22,
                              height: 22,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            authState.isLoading ? 'Signing in...' : 'Continue with Google',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF34D399)),
                      const SizedBox(width: 8),
                      Text(
                        isHindi ? '100% सुरक्षित और निःशुल्क' : '100% Free & Secure Authentication',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                        );
                      },
                      child: Text(
                        isHindi ? 'नया खाता बनाना चाहते हैं? रोल चुनें' : 'New to MessMate? Choose Role',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
