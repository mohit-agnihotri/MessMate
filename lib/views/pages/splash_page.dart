import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/phone_login_page.dart';
import 'auth/role_selection_page.dart';
import 'owner/owner_main_page.dart';
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // If logged in, send to Role Selection to decide where to go
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneLoginPage()));
        }
      }
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text('MessMate', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF111827), letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Smart Mess Management', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}
