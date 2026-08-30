import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'otp_page.dart';

class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() { _phoneController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen(authProvider, (prev, next) {
      if (next.otpSent && !(prev?.otpSent ?? false)) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpPage(phone: _phoneController.text)));
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
              const SizedBox(height: 60),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.restaurant, color: Color(0xFF22C55E), size: 28),
              ),
              const SizedBox(height: 32),
              Text('Welcome to\nMessMate 👋', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF111827), height: 1.2, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text('Enter your phone number to continue', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B7280))),
              const SizedBox(height: 40),
              Text('Phone Number', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                decoration: InputDecoration(
                  prefixText: '+91  ',
                  prefixStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF3F4F6))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF3F4F6))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2)),
                  hintText: '98765 43210',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : () => ref.read(authProvider.notifier).sendOtp(_phoneController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Send OTP', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const Spacer(),
              Center(child: Text('By continuing, you agree to our Terms & Privacy Policy', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)), textAlign: TextAlign.center)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
