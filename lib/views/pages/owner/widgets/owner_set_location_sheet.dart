import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';

/// Redesigned Set Mess Location Bottom Sheet matching exact Mezzo inspired UI.
/// Features a map preview placeholder with amber radius indicator,
/// walking-distance explainability card, 1-tap GPS pin action, and 'set later' fallback.
class OwnerSetLocationSheet extends ConsumerStatefulWidget {
  final MessModel mess;
  const OwnerSetLocationSheet({super.key, required this.mess});

  static Future<bool?> show(BuildContext context, WidgetRef ref, MessModel mess) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => OwnerSetLocationSheet(mess: mess),
    );
  }

  @override
  ConsumerState<OwnerSetLocationSheet> createState() => _OwnerSetLocationSheetState();
}

class _OwnerSetLocationSheetState extends ConsumerState<OwnerSetLocationSheet> {
  bool _isLocating = false;
  String? _errorMessage;

  Future<void> _fetchAndSaveLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocating = false;
            _errorMessage = 'Phone location service (GPS) is turned off. Please turn it on in your phone settings.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLocating = false;
              _errorMessage = 'Location permission was denied. Please allow location to pin your mess.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocating = false;
            _errorMessage = 'Location permission is permanently denied. Please enable it in App Settings.';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final updatedMess = widget.mess.copyWith(
        gpsLat: position.latitude,
        gpsLng: position.longitude,
      );

      await ref.read(appServiceProvider).updateMess(updatedMess);
      ref.read(ownerDashboardProvider.notifier).reload();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mess location pinned successfully! Nearby students can now see your mess distance.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF38573D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _errorMessage = 'Could not get location: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8D1C5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Subtitle
              Text(
                'Set mess location',
                style: GoogleFonts.newsreader(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF241A14),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Help nearby students discover your mess.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B6662),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),

              // Map Preview Box (Placeholder matching Screenshot 4)
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE7DC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCD7CA)),
                ),
                child: Stack(
                  children: [
                    // Horizontal subtle map grid lines
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) => Container(
                            height: 1,
                            color: const Color(0xFFCFDAC9).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    // Label at top-left
                    Positioned(
                      top: 12,
                      left: 14,
                      child: Text(
                        'Map preview · placeholder',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A5F4C),
                        ),
                      ),
                    ),
                    // Center dotted circle and map pin
                    Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF9EED4).withValues(alpha: 0.8),
                          border: Border.all(
                            color: const Color(0xFFEAA23E),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF241A14),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFFFAF8F5),
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDFE6DB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you at your mess right now?',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241A14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Students see messes sorted by walking distance. Pinning your location puts your mess on top for nearby hostelers and students.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        color: const Color(0xFF6B6662),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          widget.mess.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF241A14),
                          ),
                        ),
                        if (widget.mess.messCode.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '(${widget.mess.messCode})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8A8480),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Primary Action: Yes, pin current location
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAA23E),
                    foregroundColor: const Color(0xFF241A14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLocating ? null : _fetchAndSaveLocation,
                  child: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF241A14),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF241A14), width: 2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF241A14),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Yes, pin current location',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF241A14),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary action: I'm not at the mess now · set later
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No worries! You can pin location anytime from the Dashboard banner or Settings.',
                          style: GoogleFonts.inter(fontSize: 12.5),
                        ),
                        backgroundColor: const Color(0xFF241A14),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      'I\'m not at the mess now · set later',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A7571),
                      ),
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
}
