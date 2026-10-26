import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/localization_service.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../../auth/login_page.dart';
import '../../common/contact_about_page.dart';
import '../owner_about_mess_page.dart';
import '../owner_absentee_tracker_page.dart';
import '../owner_main_page.dart';
import '../owner_plan_builder_page.dart';
import '../owner_settings_page.dart';
import '../owner_expense_ledger_page.dart';
import '../theme/owner_inspired_theme.dart';
import 'owner_launch_partner_sheet.dart';
import 'schedule_closure_dialog.dart';
import 'manage_closed_slots_sheet.dart';
import 'mess_qr_standee_sheet.dart';

class OwnerDrawer extends ConsumerWidget {
  const OwnerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(ownerDashboardProvider);
    final MessModel? mess = dashboardState.mess;
    final isHindi = ref.watch(localizationProvider) == 'hi';

    final isClosedNow = mess?.isClosedNow ?? false;
    final isUpcoming = mess?.isClosureUpcoming ?? false;
    final hasClosure = mess?.hasScheduledClosure ?? false;
    final isOpen = mess?.isOpen ?? true;

    return Drawer(
      backgroundColor: OwnerColors.walnutDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: OwnerColors.amber,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: OwnerColors.amberGlowShadow,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    mess?.name.isNotEmpty == true
                        ? mess!.name[0].toUpperCase()
                        : 'M',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mess?.name ?? 'My Mess',
                        style: GoogleFonts.newsreader(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${mess?.ownerName ?? 'Owner'} · ${mess?.foodType == 'non_veg' ? 'Non-Veg' : mess?.foodType == 'both' ? 'Both' : 'Pure Veg'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFC7BCB3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // VIP pill
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: OwnerColors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: OwnerColors.amber),
                    const SizedBox(width: 6),
                    Text(
                      'VIP · 180 days free',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Open for service card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OwnerColors.walnutSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isClosedNow
                                    ? const Color(0xFFEF4444)
                                    : (isUpcoming
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFF4ADE80)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isClosedNow
                                  ? 'Mess Closed'
                                  : (isUpcoming
                                      ? 'Open (Closure ⏳)'
                                      : 'Open for service'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            final nav = Navigator.of(context);
                            nav.pop();
                            if (hasClosure && mess != null) {
                              showManageClosedSlotsSheet(nav.context, mess: mess);
                            } else {
                              showScheduleClosureDialog(nav.context, ref, mess: mess);
                            }
                          },
                          child: Text(
                            hasClosure
                                ? 'Manage closures ›'
                                : 'Schedule closure ›',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isClosedNow
                                  ? const Color(0xFF4ADE80)
                                  : OwnerColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isOpen,
                    activeTrackColor: OwnerColors.sage,
                    onChanged: (val) {
                      final nav = Navigator.of(context);
                      nav.pop();
                      if (val == false) {
                        showScheduleClosureDialog(nav.context, ref, mess: mess);
                      } else if (mess != null) {
                        showReopenMessDialog(nav.context, ref, messId: mess.messId);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION: OPERATIONS
            _buildSectionHeader('OPERATIONS'),
            _buildDrawerItem(
              title: 'Absentees',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnerAbsenteeTrackerPage()),
                );
              },
            ),
            _buildDrawerItem(
              title: 'Join requests',
              badge: '${ref.watch(ownerStudentsProvider).pending.length}',
              onTap: () {
                Navigator.pop(context);
                ref.read(ownerBottomNavIndexProvider.notifier).state = 3;
              },
            ),
            _buildDrawerItem(
              title: 'Send announcement',
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                _showSendAnnouncementDialog(nav.context, ref);
              },
            ),
            const SizedBox(height: 16),

            // SECTION: MONEY
            _buildSectionHeader('MONEY'),
            _buildDrawerItem(
              title: 'Daily Ration & Kharcha (खाता)',
              badge: 'P&L',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnerExpenseLedgerPage()),
                );
              },
            ),
            _buildDrawerItem(
              title: 'Meal plans builder',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnerPlanBuilderPage()),
                );
              },
            ),
            _buildDrawerItem(
              title: 'Fees & skip rules',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerSettingsPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // SECTION: MY MESS
            _buildSectionHeader('MY MESS'),
            _buildDrawerItem(
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerSettingsPage()),
                );
              },
            ),
            _buildDrawerItem(
              title: 'Meal timings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerSettingsPage()),
                );
              },
            ),
            _buildDrawerItem(
              title: 'About my mess',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnerAboutMessPage()),
                );
              },
            ),
            _buildDrawerItem(
              title: 'Counter QR standee',
              badge: 'NEW',
              onTap: () {
                Navigator.pop(context);
                if (mess != null) {
                  MessQrStandeeSheet.show(context, mess);
                }
              },
            ),
            const SizedBox(height: 16),

            // SECTION: ACCOUNT
            _buildSectionHeader('ACCOUNT'),
            _buildDrawerItem(
              title: 'VIP launch benefits',
              onTap: () {
                Navigator.pop(context);
                if (mess != null) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => OwnerLaunchPartnerSheet(mess: mess),
                  );
                }
              },
            ),
            _buildDrawerItem(
              title:
                  'Language · ${ref.watch(localizationProvider) == 'hi' ? 'हिंदी' : 'English'}',
              onTap: () {
                _showLanguageDialog(context, ref);
              },
            ),
            _buildDrawerItem(
              title: isHindi ? 'सहायता एवं संपर्क (Contact & About)' : 'Contact Us & About',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactAboutPage(
                      userRole: 'owner',
                      messId: mess?.messId ?? '',
                      messName: mess?.name ?? '',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Sign out
            GestureDetector(
              onTap: () => _confirmSignOut(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF87171),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Delete Account & Mess
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteOwnerAccount(context, ref, mess);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHindi ? 'खाता एवं मेस हटाएं' : 'Delete Account & Mess',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: OwnerTypography.overline(
          color: OwnerColors.amber,
          fontSize: 11,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (badge != null && badge != '0') ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: OwnerColors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: OwnerColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localizationProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: OwnerColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose language',
              style: OwnerTypography.serifHeading(fontSize: 22),
            ),
            const SizedBox(height: 16),
            _buildLangTile(
              context: ctx,
              ref: ref,
              title: 'English',
              subtitle: 'Clean & simple English',
              code: 'en',
              selected: currentLang == 'en',
            ),
            const SizedBox(height: 10),
            _buildLangTile(
              context: ctx,
              ref: ref,
              title: 'हिंदी (Hindi)',
              subtitle: 'सरल एवं आसान बोलचाल की हिंदी',
              code: 'hi',
              selected: currentLang == 'hi',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLangTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String code,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(localizationProvider.notifier).toggleLanguage(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? OwnerColors.sageLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? OwnerColors.sage : OwnerColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: OwnerColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: OwnerColors.walnut,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }


  void _showSendAnnouncementDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (dialogCtx, dialogRef, _) => AlertDialog(
          backgroundColor: OwnerColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Send announcement',
            style: OwnerTypography.serifHeading(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goes to every active student instantly.',
                style: OwnerTypography.body(
                    fontSize: 12, color: OwnerColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.inter(
                      color: OwnerColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: OwnerColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: OwnerColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: OwnerColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  dialogRef
                      .read(ownerDashboardProvider.notifier)
                      .sendAnnouncement(textController.text.trim());
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerColors.amber,
                foregroundColor: OwnerColors.textDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (dialogCtx, dialogRef, _) => AlertDialog(
          backgroundColor: OwnerColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              Text('Sign Out', style: OwnerTypography.serifHeading(fontSize: 20)),
          content: Text('Are you sure you want to sign out?',
              style: OwnerTypography.body()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await dialogRef.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOwnerAccount(BuildContext context, WidgetRef ref, MessModel? mess) {
    final isHi = ref.read(localizationProvider) == 'hi';

    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: OwnerColors.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHi ? 'मेस एवं खाता हटाएं?' : 'Delete Account & Mess?',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi
                        ? 'क्या आप वाकई अपना Mezzo खाता और "${mess?.name ?? 'मेस'}" को हमेशा के लिए हटाना चाहते हैं? आपका मेन्यू, बिलिंग, छात्र सूचियां और सारा डेटा हमेशा के लिए नष्ट हो जाएगा। यह प्रक्रिया पूर्ववत नहीं की जा सकती।'
                        : 'Are you sure you want to permanently delete your Mezzo owner account and "${mess?.name ?? 'Mess'}"? All menu schedules, student rosters, billing records, and mess settings will be permanently erased. This action cannot be undone.',
                    style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  if (isDeleting) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFFDC2626)),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDeleting) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      isHi ? 'रद्द करें' : 'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final ownerId = await ref.read(appServiceProvider).getCurrentUserId();
                        final messId = mess?.messId ?? '';
                        if (ownerId != null && ownerId.isNotEmpty) {
                          await ref.read(appServiceProvider).deleteOwnerAccount(ownerId, messId);
                        }
                        await ref.read(authProvider.notifier).signOut();

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isHi
                                    ? 'आपका मेस एवं खाता सफलतापूर्वक हटा दिया गया है।'
                                    : 'Your account and mess have been deleted successfully.',
                              ),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          final errStr = e.toString().toLowerCase();
                          final String errorMsg;
                          if (errStr.contains('cancel') || errStr.contains('cancelled') || errStr.contains('canceled')) {
                            errorMsg = isHi
                                ? 'सुरक्षा सत्यापन रद्द कर दिया गया था।'
                                : 'Security re-authentication was cancelled.';
                          } else {
                            errorMsg = isHi
                                ? 'मेस एवं खाता हटाने में त्रुटि: कृपया पुनः प्रयास करें।'
                                : 'Deletion failed. Please try again.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      isHi ? 'हां, सब हटाएं' : 'Delete Everything',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
