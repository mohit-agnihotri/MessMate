import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../owner/owner_main_page.dart';
import 'student_setup_page.dart';
import 'owner_setup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('Who are you? 🤔', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827), letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Select your role to get started', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B7280))),
              const SizedBox(height: 48),
              _RoleCard(
                emoji: '🏠',
                title: 'Mess Owner',
                subtitle: 'Manage your mess, menu, students & billing',
                color: const Color(0xFF22C55E),
                bgColor: const Color(0xFFDCFCE7),
                onTap: () async {
                  ref.read(authProvider.notifier).setRole(AuthRole.owner);
                  
                  // Show loading dialog
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) throw Exception('Not logged in');
                    final mess = await ref.read(appServiceProvider).getMessByOwnerId(uid);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // hide loading
                      if (mess == null) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerSetupPage()));
                      } else {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerMainPage()));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                emoji: '🎓',
                title: 'Student',
                subtitle: 'Track meals, view menu, manage your bill',
                color: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
                onTap: () {
                  ref.read(authProvider.notifier).setRole(AuthRole.student);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentSetupPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _RoleCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
          ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ]),
      ),
    );
  }
}
