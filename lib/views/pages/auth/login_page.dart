import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'role_selection_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Listen to authentication state changes
    ref.listen(authProvider, (prev, next) {
      if (next.userId != null && prev?.userId == null) {
        // Automatically navigate to role selection when login succeeds
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const RoleSelectionPage())
        );
      }
      if (next.error != null && next.error != prev?.error) {
        // Show error snackbar if login fails
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              // App Icon/Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7), 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFF22C55E), size: 32),
              ),
              const SizedBox(height: 32),
              
              // Welcome Text
              Text(
                'Welcome to\nMessMate 👋', 
                style: GoogleFonts.inter(
                  fontSize: 36, 
                  fontWeight: FontWeight.bold, 
                  color: const Color(0xFF111827), 
                  height: 1.2, 
                  letterSpacing: -0.5
                )
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to manage your mess meals easily.', 
                style: GoogleFonts.inter(
                  fontSize: 16, 
                  color: const Color(0xFF6B7280)
                )
              ),
              const SizedBox(height: 60),

              // Google Sign In Button — dark style with real Google G logo
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: authState.isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).signInWithGoogle(),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authState.isLoading)
                              const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            else
                              Image.asset('assets/google_logo.png', width: 22, height: 22),
                            const SizedBox(width: 12),
                            Text(
                              authState.isLoading ? 'Signing in...' : 'Continue with Google',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Feature highlights
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF22C55E)),
                  const SizedBox(width: 8),
                  Text(
                    '100% Free & Secure Authentication',
                    style: GoogleFonts.inter(
                      fontSize: 13, 
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Terms & Privacy
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy', 
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)), 
                    textAlign: TextAlign.center
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
