import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import 'role_selection_page.dart';
import 'owner_setup_page.dart';
import 'student_setup_page.dart';
import '../owner/owner_main_page.dart';
import '../student/student_main_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final AuthRole? initialRole;
  const LoginPage({super.key, this.initialRole});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to authentication state changes
    ref.listen(authProvider, (prev, next) async {
      if (next.userId != null && prev?.userId == null) {
        final uid = next.userId!;
        final service = ref.read(appServiceProvider);

        if (widget.initialRole == AuthRole.owner) {
          final mess = await service.getMessByOwnerId(uid);
          if (mounted) {
            if (mess == null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OwnerSetupPage()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OwnerMainPage()),
              );
            }
          }
        } else if (widget.initialRole == AuthRole.student) {
          final student = await service.getStudentById(uid);
          if (mounted) {
            if (student == null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StudentSetupPage()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StudentMainPage()),
              );
            }
          }
        } else {
          // Default navigate to role selection
          if (mounted) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),

                  // App Icon / Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                        '100% Free & Secure Authentication',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
