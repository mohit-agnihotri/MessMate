import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Layer 2: Secret Stealth Gate Sheet.
/// Redesigned with the exact Executive Dark Luxury Obsidian & Warm Gold PIN Terminal
/// from Inspired UI (Screenshot 12).
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
  String _enteredPin = '';
  bool _isLoading = false;
  String? _error;

  void _onDigitTap(String digit) {
    if (_enteredPin.length < 6) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin += digit;
        _error = null;
      });
      if (_enteredPin.length == 6) {
        _submitPin();
      }
    }
  }

  void _onBackspaceTap() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _submitPin() async {
    if (_enteredPin.length < 4) {
      setState(() => _error = 'Enter at least 4 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isValid =
          await ref.read(adminServiceProvider).verifyMasterPin(_enteredPin);
      if (!mounted) return;

      if (isValid) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isLoading = false;
          _error = 'ACCESS DENIED: Invalid Security Key';
          _enteredPin = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16120E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF382F25), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              const SizedBox(height: 20),

              // Title: Enter admin PIN
              Text(
                'Enter admin PIN',
                style: AdminCyberTheme.serifTitle(fontSize: 26),
              ),
              const SizedBox(height: 4),

              // Subtitle: • STEALTH ACCESS TERMINAL
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STEALTH ACCESS TERMINAL',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminCyberTheme.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the master security PIN to proceed.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminCyberTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 6 PIN Dots Indicator (Amber filled, Dark empty)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF241D17),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFilled
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF382F25),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF87171),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // On-Screen Keypad Grid (Tiles 1..9, Backspace, 0, Checkmark)
              _buildKeypad(),
              const SizedBox(height: 18),

              // Submit Button (Amber Filled)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF140F09),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitPin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF140F09),
                          ),
                        )
                      : Text(
                          'Enter admin panel',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: [
            _buildKeypadTile('1'),
            const SizedBox(width: 12),
            _buildKeypadTile('2'),
            const SizedBox(width: 12),
            _buildKeypadTile('3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeypadTile('4'),
            const SizedBox(width: 12),
            _buildKeypadTile('5'),
            const SizedBox(width: 12),
            _buildKeypadTile('6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeypadTile('7'),
            const SizedBox(width: 12),
            _buildKeypadTile('8'),
            const SizedBox(width: 12),
            _buildKeypadTile('9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeypadActionTile(
              icon: Icons.backspace_outlined,
              onTap: _onBackspaceTap,
            ),
            const SizedBox(width: 12),
            _buildKeypadTile('0'),
            const SizedBox(width: 12),
            _buildKeypadActionTile(
              icon: Icons.check_rounded,
              onTap: _submitPin,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadTile(String digit) {
    return Expanded(
      child: Material(
        color: const Color(0xFF241D17),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _onDigitTap(digit),
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF382F25), width: 1.0),
            ),
            child: Text(
              digit,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAF7F2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadActionTile({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: const Color(0xFF241D17),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF382F25), width: 1.0),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFFAF7F2),
            ),
          ),
        ),
      ),
    );
  }
}
