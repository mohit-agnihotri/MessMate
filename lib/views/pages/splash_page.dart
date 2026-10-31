import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../services/localization_service.dart';
import '../widgets/mezzo_logo.dart';
import 'auth/login_page.dart';
import 'auth/role_selection_page.dart';
import 'auth/student_setup_page.dart';
import 'owner/owner_main_page.dart';
import 'student/student_main_page.dart';
import 'student/student_pending_approval_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fade;
  late Animation<double> _scale;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();

    // Safety guard: Never hang on splash indefinitely on weak network
    Future.delayed(const Duration(seconds: 6), () async {
      if (mounted && !_hasNavigated) {
        debugPrint('[SplashPage] Safety fallback triggered');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _navigateTo(const RoleSelectionPage(initialStep: 2));
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            final hasSeen = prefs.getBool('has_completed_onboarding') ?? false;
            _navigateTo(hasSeen ? const LoginPage() : const RoleSelectionPage(initialStep: 0));
          } catch (_) {
            _navigateTo(const LoginPage());
          }
        }
      }
    });

    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    try {
      // 400ms buffer so user sees the premium Mezzo branding smoothly
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || _hasNavigated) return;

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Give Firebase Auth state a moment to restore cached session if cold starting
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(milliseconds: 1000), onTimeout: () => null);
        } catch (_) {}
      }

      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
        if (!hasCompletedOnboarding) {
          _navigateTo(const RoleSelectionPage(initialStep: 0));
        } else {
          _navigateTo(const LoginPage());
        }
        return;
      }

      final service = ref.read(appServiceProvider);

      // 1. Check if user is an owner with realistic network timeout
      try {
        final mess = await service
            .getMessByOwnerId(user.uid)
            .timeout(const Duration(milliseconds: 4500), onTimeout: () => null);

        if (mess != null && mounted && !_hasNavigated) {
          ref.read(authProvider.notifier).setRole(AuthRole.owner);
          _navigateTo(const OwnerMainPage());
          return;
        }
      } catch (e) {
        debugPrint('[SplashPage] Error checking owner: $e');
      }

      if (!mounted || _hasNavigated) return;

      // 2. Check if user is a student with realistic network timeout
      try {
        final student = await service
            .getStudentById(user.uid)
            .timeout(const Duration(milliseconds: 4500), onTimeout: () => null);

        if (student != null && mounted && !_hasNavigated) {
          if (student.status == 'removed' || student.isDeletedByOwner) {
            try {
              await service.updateStudent(student.copyWith(
                isDeletedByOwner: false,
                status: 'left',
                messId: '',
              ));
            } catch (_) {}
            await ref.read(authProvider.notifier).signOut();
            _navigateTo(const LoginPage(removalNotice: true));
            return;
          }
          ref.read(authProvider.notifier).setRole(AuthRole.student);
          if (student.status == 'active' || student.status == 'approved') {
            _navigateTo(const StudentMainPage());
          } else if (student.status == 'left' || student.messId.isEmpty) {
            _navigateTo(const StudentSetupPage());
          } else {
            _navigateTo(
              StudentPendingApprovalPage(
                initialMessName: student.messId.isNotEmpty
                    ? (ref.read(localizationProvider) == 'hi' ? 'मेस' : 'Mess')
                    : null,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('[SplashPage] Error checking student: $e');
      }

      // If user is authenticated in Firebase but has neither profile, take directly to Role Selection
      if (mounted && !_hasNavigated) {
        _navigateTo(const RoleSelectionPage(initialStep: 2));
      }
    } catch (e) {
      debugPrint('[SplashPage] Routing exception: $e');
      if (mounted && !_hasNavigated) {
        _navigateTo(const RoleSelectionPage(initialStep: 2));
      }
    }
  }

  void _navigateTo(Widget target) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1510),
      body: Stack(
        children: [
          // Background Gradient with subtle warm ambiance
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.1,
                colors: [
                  Color(0xFF2E1E14),
                  Color(0xFF221710),
                  Color(0xFF170F0A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Gentle ambient warm glow at bottom center
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.8),
                  radius: 0.9,
                  colors: [
                    const Color(0xFFF09E38).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Wavy rolling landscape dunes in sage greens (as in reference screenshot)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.14,
            child: CustomPaint(
              size: Size(size.width, size.height * 0.14),
              painter: _BottomWavesPainter(),
            ),
          ),

          // Central Brand Content
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Squircle Logo (Concept 05: Fork and spoon forming M in a plate)
                    const MezzoLogo(
                      size: 96,
                      showSquircle: true,
                      showShadow: true,
                      backgroundColor: Color(0xFF2B1D14),
                    ),

                    const SizedBox(height: 28),

                    // Brand Headline: "Mezzo" in Newsreader Serif
                    Text(
                      'Mezzo',
                      style: GoogleFonts.newsreader(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF8F3),
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle: "SMART MESS MANAGEMENT"
                    Text(
                      'SMART MESS MANAGEMENT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.8,
                        color: const Color(0xFFD6A269),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Animated Progress Bar Pill
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38271C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment(
                              -1.0 +
                                  (1.0 +
                                          math.sin(
                                              _progressController.value *
                                                  2 *
                                                  math.pi)) *
                                      1.0,
                              0,
                            ),
                            child: Container(
                              width: 36,
                              height: 3.5,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF09E38),
                                    Color(0xFFFFBF6B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF09E38)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the organic sage green undulating bottom dunes
class _BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back Dune: softer muted sage green
    final backPaint = Paint()
      ..color = const Color(0xFF5A725C).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, h * 0.45);
    backPath.cubicTo(
      w * 0.28,
      h * 0.15,
      w * 0.62,
      h * 0.60,
      w,
      h * 0.28,
    );
    backPath.lineTo(w, h);
    backPath.lineTo(0, h);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Front Dune: richer sage green
    final frontPaint = Paint()
      ..color = const Color(0xFF7E977F).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, h * 0.62);
    frontPath.cubicTo(
      w * 0.32,
      h * 0.78,
      w * 0.68,
      h * 0.32,
      w,
      h * 0.52,
    );
    frontPath.lineTo(w, h);
    frontPath.lineTo(0, h);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
