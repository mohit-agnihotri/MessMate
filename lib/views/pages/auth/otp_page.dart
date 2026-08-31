import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'role_selection_page.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  
  bool _isResending = false;
  int _resendTimer = 30;
  late final _ticker = Stream.periodic(const Duration(seconds: 1));
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() async {
    await for (final _ in _ticker) {
      if (!mounted) break;
      if (_resendTimer <= 0) break;
      setState(() => _resendTimer--);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.userId != null && prev?.userId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        );
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    });

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: GoogleFonts.inter(fontSize: 22, color: const Color(0xFF111827), fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Phone icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.sms_rounded, color: Color(0xFF22C55E), size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter OTP 🔐',
              style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.bold,
                color: const Color(0xFF111827), letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF6B7280)),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to '),
                  TextSpan(
                    text: '+91 ${widget.phone}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text(
                  'Auto-detects OTP on Android',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF22C55E), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 40),

            Center(
              child: Pinput(
                length: 6,
                controller: _pinController,
                focusNode: _focusNode,
                autofillHints: const [AutofillHints.oneTimeCode],
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: const Color(0xFF22C55E), width: 2),
                  ),
                ),
                onCompleted: (pin) {
                  ref.read(authProvider.notifier).verifyOtp(pin);
                },
              ),
            ),

            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        final otp = _pinController.text;
                        if (otp.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Please enter all 6 digits'),
                            backgroundColor: Color(0xFFEF4444),
                          ));
                          return;
                        }
                        ref.read(authProvider.notifier).verifyOtp(otp);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Verify OTP', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 20),

            // Resend OTP
            Center(
              child: _isResending
                  ? const CircularProgressIndicator(color: Color(0xFF22C55E), strokeWidth: 2)
                  : _resendTimer > 0
                      ? RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                            children: [
                              const TextSpan(text: 'Resend OTP in '),
                              TextSpan(
                                text: '${_resendTimer}s',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF22C55E)),
                              ),
                            ],
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            setState(() { _isResending = true; _resendTimer = 30; });
                            await ref.read(authProvider.notifier).sendOtp(widget.phone);
                            if (mounted) {
                              setState(() => _isResending = false);
                              _startResendTimer();
                            }
                          },
                          child: Text(
                            'Resend OTP',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF22C55E),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Didn\'t receive? Check spam folder or wait 30 seconds',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
