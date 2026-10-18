import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Layer 2: Secret Stealth Gate Sheet.
/// Triggered by 5 rapid taps on the MessMate logo.
class AdminStealthGateSheet extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const AdminStealthGateSheet({
    super.key,
    required this.onSuccess,
  });

  @override
  ConsumerState<AdminStealthGateSheet> createState() =>
      _AdminStealthGateSheetState();
}

class _AdminStealthGateSheetState extends ConsumerState<AdminStealthGateSheet> {
  final TextEditingController _pinCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _unlockStealth() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isValid = await ref.read(adminServiceProvider).verifyMasterPin(pin);
      if (!mounted) return;

      if (isValid) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context); // Dismiss sheet
        widget.onSuccess();     // Trigger transition in parent LoginPage context
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isLoading = false;
          _error = 'ACCESS DENIED: Invalid Master Security Key';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error during bypass: $e';
      });
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF05080E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF06B6D4), width: 2.0),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const PulsingBeacon(
                    color: AdminCyberTheme.neonCyan,
                    size: 8,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STEALTH ACCESS TERMINAL',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminCyberTheme.neonCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enter Master Key',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Developer bypass active. Provide the master encryption key to proceed.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminCyberTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AdminCyberTheme.neonCyan,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AdminCyberTheme.neonCyan,
                      width: 1.8,
                    ),
                  ),
                ),
                onSubmitted: (_) => _unlockStealth(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AdminCyberTheme.neonRose,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminCyberTheme.neonCyan,
                    foregroundColor: const Color(0xFF04202C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _unlockStealth,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF04202C),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'AUTHENTICATE DEVELOPER ⚡',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
