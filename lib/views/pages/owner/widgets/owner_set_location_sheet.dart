import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/owner_inspired_theme.dart';

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
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mess location pinned successfully! Nearby students can now see your mess distance.',
                  ),
                ),
              ],
            ),
            backgroundColor: OwnerColors.sage,
            behavior: SnackBarBehavior.floating,
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
        color: OwnerColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: OwnerColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OwnerColors.sageLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OwnerColors.sageBorder),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: OwnerColors.sageDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Mess Location 📍',
                        style: OwnerTypography.serifHeading(fontSize: 19, color: OwnerColors.walnutDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Help nearby students discover your mess',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: OwnerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OwnerColors.borderSubtle),
                boxShadow: OwnerColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you at your mess location right now?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When students open the Mezzo app, they see mess recommendations sorted by walking distance. Pinning your GPS location puts your mess on top for nearby hostelers and students.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.45,
                      color: OwnerColors.walnut,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: OwnerColors.walnutMuted),
                      const SizedBox(width: 6),
                      Text(
                        widget.mess.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                      if (widget.mess.messCode.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${widget.mess.messCode})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: OwnerColors.textSecondary,
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
                  borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.sageDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isLocating ? null : _fetchAndSaveLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(
                  _isLocating ? 'Pinning GPS Location...' : '📍 Yes, Pin Current Location',
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No worries! You can pin location anytime from the Dashboard banner or Settings.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'I\'m not at the mess right now (Set later)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OwnerColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
