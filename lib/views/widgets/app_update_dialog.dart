import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/admin_service.dart';
import '../pages/owner/theme/owner_inspired_theme.dart';

/// App-wide Current Version Constant (Keep in sync with pubspec.yaml)
const String kCurrentAppVersion = '1.0.6';

/// Highly polished, executive In-App Update Dialog.
/// Automatically matches Mezzo's Warm Walnut & Cream aesthetic.
class AppUpdateDialog extends StatelessWidget {
  final String newVersion;
  final String currentVersion;
  final String apkDownloadUrl;
  final String changelog;
  final bool isForced;

  const AppUpdateDialog({
    super.key,
    required this.newVersion,
    required this.currentVersion,
    required this.apkDownloadUrl,
    required this.changelog,
    this.isForced = false,
  });

  /// Static helper to check Firestore config and show update dialog if a newer version is live.
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref) async {
    try {
      final config = await ref.read(adminServiceProvider).getPublicAppInfo();

      final serverVersion = config.latestAppVersion;
      final minRequired = config.minSupportedVersion;

      final isUpdateAvailable = _isVersionHigher(serverVersion, kCurrentAppVersion);
      final isForced = _isVersionHigher(minRequired, kCurrentAppVersion) || config.forceUpdate;

      if ((isUpdateAvailable || isForced) && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: !isForced,
          builder: (ctx) => PopScope(
            canPop: !isForced,
            child: AppUpdateDialog(
              newVersion: serverVersion,
              currentVersion: kCurrentAppVersion,
              apkDownloadUrl: config.apkDownloadUrl,
              changelog: config.updateChangelog,
              isForced: isForced,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateDialog] Version check skipped safely: $e');
    }
  }

  /// SemVer comparator: returns true if v1 > v2
  static bool _isVersionHigher(String v1, String v2) {
    try {
      final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final val1 = i < p1.length ? p1[i] : 0;
        final val2 = i < p2.length ? p2[i] : 0;
        if (val1 > val2) return true;
        if (val1 < val2) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startDownload(BuildContext context) async {
    final cleanUrl = apkDownloadUrl.trim();
    if (cleanUrl.isEmpty) return;

    final uri = Uri.parse(cleanUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open download link: $e',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFFAF8F5)),
            ),
            backgroundColor: OwnerColors.walnutDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFE8DE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Top Rocket Icon Squircle
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAA23E).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFEAA23E).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFFEAA23E),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'New Update Available!',
              style: GoogleFonts.newsreader(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF241A14),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Version Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2EBE2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v$newVersion • Latest Release',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A6B53),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Subtitle Description
            Text(
              'A newer version of Mezzo is ready. Update now to enjoy the latest kitchen kharcha ledger, live cutoff rules, and performance enhancements.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF5C4E44),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Changelog Box
            if (changelog.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFE8DE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHAT\'S NEW:',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF8E7F75),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      changelog,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF241A14),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _startDownload(context),
                icon: const Icon(Icons.download_rounded, size: 20, color: Color(0xFF241A14)),
                label: Text(
                  'Update Now',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241A14),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA23E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            if (!isForced) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Remind Me Later',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E7F75),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}
