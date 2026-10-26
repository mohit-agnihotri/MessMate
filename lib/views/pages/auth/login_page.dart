import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../admin/admin_mission_control_page.dart';
import '../admin/widgets/admin_stealth_gate_sheet.dart';
import 'role_selection_page.dart';
import 'owner_setup_page.dart';
import 'student_setup_page.dart';
import '../owner/owner_main_page.dart';
import '../student/student_main_page.dart';
import '../student/student_pending_approval_page.dart';
import '../../widgets/mezzo_logo.dart';
import 'widgets/mess_account_chooser_sheet.dart';

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
  bool _isNavigating = false;

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

  Future<void> _handlePostSignIn(String uid) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final service = ref.read(appServiceProvider);

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
        } else if (student.status == 'left' || student.messId.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentSetupPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentPendingApprovalPage(
                initialMessName: student.messId.isNotEmpty
                    ? (ref.read(localizationProvider) == 'hi' ? 'मेस' : 'Mess')
                    : null,
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const RoleSelectionPage(initialStep: 2)),
          );
        }
      }
    } catch (e) {
      debugPrint('[LoginPage] Error in post-sign-in routing: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const RoleSelectionPage(initialStep: 2)),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to authentication state changes
    ref.listen(authProvider, (prev, next) {
      if (next.userId != null &&
          (prev?.userId == null || prev?.userId != next.userId)) {
        _handlePostSignIn(next.userId!);
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

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFF140F0C),
      body: Stack(
        children: [
          // Background Gradient (Deep Espresso to Dark Walnut)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E1712),
                    Color(0xFF120E0B),
                  ],
                ),
              ),
            ),
          ),

          // Ambient Radial Glow 1 (Top Left Warm Amber)
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF09E38).withValues(alpha: 0.16),
              ),
            ),
          ),

          // Ambient Radial Glow 2 (Mid-right Amber)
          Positioned(
            top: screenHeight * 0.45,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
              ),
            ),
          ),

          // Ambient Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: const SizedBox.expand(),
            ),
          ),

          // Bottom Organic Layered Sage Dunes
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: CustomPaint(
              size: const Size(double.infinity, 90),
              painter: _OrganicDunesPainter(),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.paddingOf(context).top - MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Top Bar: Back Button (if canPop) + Language Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (Navigator.canPop(context))
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFFFAF8F3),
                                size: 18,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 36),
                        InkWell(
                          onTap: () {
                            ref
                                .read(localizationProvider.notifier)
                                .toggleLanguage(isHindi ? 'en' : 'hi');
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C221B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              isHindi ? 'English' : 'हिंदी',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFAF8F3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.09),

                    // Logo: Concept 05 Mezzo Logo (5-tap admin stealth gate)
                    GestureDetector(
                      onTap: _onLogoTap,
                      behavior: HitTestBehavior.opaque,
                      child: const MezzoLogo(
                        size: 64,
                        showSquircle: true,
                        showShadow: true,
                        backgroundColor: Color(0xFF281C14),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Serif Headline: "Welcome to Mezzo"
                    Text(
                      isHindi ? 'Mezzo में\nआपका स्वागत है' : 'Welcome to\nMezzo',
                      style: GoogleFonts.newsreader(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF8F3),
                        height: 1.12,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Subtitle
                    Text(
                      isHindi
                          ? 'अपने दैनिक मेस भोजन को आसानी से प्रबंधित करने के लिए साइन इन करें।'
                          : 'Sign in to manage your everyday mess meals, easily.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFFD6CEB8).withValues(alpha: 0.85),
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.08),

                    // Google Sign-In Button: Off-white Cream Pill
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFAF8F3),
                          foregroundColor: const Color(0xFF231A14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(authProvider.notifier)
                                    .signInWithGoogle();
                                final currentUid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (currentUid != null && mounted) {
                                  await _handlePostSignIn(currentUid);
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authState.isLoading)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF09E38),
                                  strokeWidth: 2.5,
                                ),
                              )
                            else
                              Image.asset(
                                'assets/google_logo.png',
                                width: 22,
                                height: 22,
                              ),
                            const SizedBox(width: 14),
                            Text(
                              authState.isLoading
                                  ? (isHindi ? 'साइन इन हो रहा है...' : 'Signing in...')
                                  : (isHindi ? 'Google के साथ जारी रखें' : 'Continue with Google'),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF231A14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footnote: 100% free & secure authentication
                    Center(
                      child: Text(
                        isHindi
                            ? '100% सुरक्षित और निःशुल्क ऑथेंटिकेशन'
                            : '100% free & secure authentication',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFFAF8F3).withValues(alpha: 0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    if (FirebaseAuth.instance.currentUser != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => MessAccountChooserSheet(
                                onAccountSelected: (uid) {
                                  _handlePostSignIn(uid);
                                },
                                onAddAnotherAccount: () async {
                                  await ref
                                      .read(authProvider.notifier)
                                      .signInWithGoogle();
                                  final currentUid =
                                      FirebaseAuth.instance.currentUser?.uid;
                                  if (currentUid != null && mounted) {
                                    await _handlePostSignIn(currentUid);
                                  }
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF241D17),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF382F25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.switch_account_rounded,
                                  size: 15,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isHindi
                                      ? 'खाता चुनें या बदलें'
                                      : 'Choose or switch account',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFAF7F2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Link: New to Mezzo? Choose role
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RoleSelectionPage(initialStep: 2)),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFAF8F3).withValues(alpha: 0.75),
                            ),
                            children: [
                              TextSpan(
                                text: isHindi
                                    ? 'Mezzo में नए हैं? '
                                    : 'New to Mezzo? ',
                              ),
                              TextSpan(
                                text: isHindi ? 'रोल चुनें' : 'Choose role',
                                style: const TextStyle(
                                  color: Color(0xFFF09E38),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
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

/// Custom painter to draw the organic layered sage dunes at the bottom
class _OrganicDunesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back Dune (Darker Sage)
    final backPaint = Paint()
      ..color = const Color(0xFF2E3B30).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h * 0.45)
      ..cubicTo(w * 0.25, h * 0.15, w * 0.65, h * 0.65, w, h * 0.25)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(backPath, backPaint);

    // Front Dune (Lighter Muted Sage)
    final frontPaint = Paint()
      ..color = const Color(0xFF425545).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, h * 0.7)
      ..cubicTo(w * 0.35, h * 0.95, w * 0.7, h * 0.35, w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
