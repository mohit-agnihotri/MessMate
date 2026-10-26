import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../auth/login_page.dart';
import '../auth/student_setup_page.dart';
import '../common/contact_about_page.dart';
import 'theme/student_inspired_theme.dart';
import 'widgets/rate_mess_sheet.dart';

/// Formats raw plan IDs into human-readable editorial plan titles
String _formatPlanDisplayName(String? planId, MealPlanModel? plan, bool isHindi) {
  if (plan != null && plan.name.trim().isNotEmpty) {
    final clean = plan.name.trim();
    // If the name is already clean and user-friendly (not a raw database key)
    if (!clean.contains('_') && !RegExp(r'^[a-zA-Z0-9]{8,}$').hasMatch(clean)) {
      return clean;
    }
  }

  if (planId == null || planId.trim().isEmpty) {
    return isHindi ? 'कोई प्लान असाइन नहीं' : 'No Plan Assigned';
  }

  final lower = planId.toLowerCase();
  if (lower.contains('choice_morning_or_noon') ||
      (lower.contains('choice') && (lower.contains('morning') || lower.contains('noon')))) {
    return isHindi
        ? 'फ्लेक्सी चॉइस प्लान (नाश्ता/दोपहर + रात)'
        : 'Flexi Choice (Breakfast/Lunch + Dinner)';
  } else if (lower.contains('full_3') ||
      lower.contains('full_active_3') ||
      lower.contains('3_meal') ||
      lower.contains('3 meal')) {
    return isHindi ? 'फुल 3-मील दैनिक प्लान' : 'Full 3-Meal Daily Plan';
  } else if (lower.contains('core_2') ||
      lower.contains('noon_night') ||
      lower.contains('2_meal') ||
      lower.contains('2 meal')) {
    return isHindi
        ? '2-मील कोर प्लान (दोपहर + रात)'
        : '2-Meal Core Plan (Lunch & Dinner)';
  } else if (lower.contains('single') || lower.contains('single_choice')) {
    return isHindi ? 'सिंगल मील प्लान' : 'Single Meal Choice Plan';
  } else if (lower.contains('flex') || lower.contains('choice')) {
    return isHindi ? 'फ्लेक्सी मील प्लान' : 'Flexible Meal Plan';
  }

  // Strip any raw random hash/alphanumeric IDs like "TYBPp0rk", "8543", etc.
  final tokens = planId
      .split(RegExp(r'[_ \-]+'))
      .where((t) => !RegExp(r'^[a-zA-Z0-9]{6,}$').hasMatch(t) && !RegExp(r'^\d{4,}$').hasMatch(t))
      .toList();
  if (tokens.isNotEmpty) {
    return tokens
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  return isHindi ? 'रेगुलर मील प्लान' : 'Regular Meal Plan';
}

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentProfileProvider);
    final isHindi = ref.watch(localizationProvider) == 'hi';

    return Scaffold(
      backgroundColor: StudentColors.canvas,
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: StudentColors.amber),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header Title & Subtitle with Quick Language Switcher ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi ? 'खाता एवं प्राथमिकताएं' : 'ACCOUNT & PREFERENCES',
                                  style: StudentTypography.overline(
                                    fontSize: 11,
                                    color: StudentColors.sageDark,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isHindi ? 'मेरी प्रोफाइल' : 'My profile',
                                  style: StudentTypography.serifHeading(fontSize: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHindi
                                      ? 'अपनी सदस्यता, प्राथमिकताएं और विवरण प्रबंधित करें'
                                      : 'Manage your membership, preferences, and details',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: StudentColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quick Language Pill
                          InkWell(
                            onTap: () => _showLanguageModal(context, ref),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: StudentColors.borderSubtle),
                                boxShadow: StudentColors.softShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language_rounded,
                                    size: 15,
                                    color: StudentColors.walnut,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isHindi ? 'हिंदी' : 'English',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: StudentColors.walnut,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Student Info Card ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _buildProfileCard(context, ref, state, isHindi),
                    ),
                  ),

                  // ── Active Meal Plan Hero Card ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildActivePlanCard(context, ref, state, isHindi),
                    ),
                  ),

                  // ── Mess Membership Card ──
                  if (state.mess != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildMessCard(context, ref, state, isHindi),
                      ),
                    ),

                  // ── Settings & Notification Preferences ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    sliver: SliverToBoxAdapter(
                      child: _buildSettingsSection(context, ref, state, isHindi),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Student Info Card ──────────────────────────────────────────────────────
  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
    bool isHindi,
  ) {
    final student = state.student;
    final initial = (student?.name.isNotEmpty == true) ? student!.name[0].toUpperCase() : 'M';
    final hasCourse = student?.course != null && student!.course.trim().isNotEmpty;
    final hasCollege = student?.college != null && student!.college.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with Camera Tap
          GestureDetector(
            onTap: () => _pickImage(ref),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: StudentColors.walnut,
                  backgroundImage: student?.photoUrl != null && student!.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(student.photoUrl!)
                      : null,
                  child: student?.photoUrl == null || student!.photoUrl!.isEmpty
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: StudentColors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details & Edit Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        student?.name ?? (isHindi ? 'छात्र' : 'Student'),
                        style: StudentTypography.serifHeading(fontSize: 20),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showEditProfileDialog(context, ref, student),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: StudentColors.walnut),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isHindi ? 'एडिट' : 'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: StudentColors.walnut,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  student?.roomNo != null && student!.roomNo.trim().isNotEmpty
                      ? '${student.phone} • Room ${student.roomNo}'
                      : (student?.phone ?? ''),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: StudentColors.textSecondary,
                  ),
                ),
                if (student != null && (hasCourse || hasCollege)) ...[
                  const SizedBox(height: 2),
                  Text(
                    hasCourse && hasCollege
                        ? '${student.course} • ${student.college}'
                        : (hasCourse ? student.course : student.college),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: StudentColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Meal Plan Dark Walnut Hero Card ─────────────────────────────────
  Widget _buildActivePlanCard(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
    bool isHindi,
  ) {
    final planTitle = _formatPlanDisplayName(state.student?.assignedPlanId, state.plan, isHindi);
    final fee = (state.plan?.monthlyFee ?? state.mess?.monthlyFee ?? 2400).toInt();
    final mealsCount = state.plan?.mealsIncludedPerDay ?? 2;

    return Container(
      decoration: BoxDecoration(
        color: StudentColors.walnut,
        borderRadius: BorderRadius.circular(22),
        boxShadow: StudentColors.elevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StudentColors.amber.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isHindi ? 'सक्रिय मील प्लान' : 'ACTIVE MEAL PLAN',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: StudentColors.amber,
                        ),
                      ),
                    ),
                    if (state.student?.subscriptionEndDate != null)
                      Text(
                        '${isHindi ? 'वैध' : 'Valid till'} ${state.student!.subscriptionEndDate!.day}/${state.student!.subscriptionEndDate!.month}/${state.student!.subscriptionEndDate!.year}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  planTitle,
                  style: StudentTypography.serifHeading(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Clean Specs & Pricing Row
                Row(
                  children: [
                    Text(
                      '₹$fee / ${isHindi ? 'माह' : 'mo'}',
                      style: StudentTypography.bold(
                        fontSize: 14,
                        color: StudentColors.amberLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•   $mealsCount ${isHindi ? 'वक्त का भोजन' : 'meals daily'}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (state.student?.pendingPlanId != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StudentColors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: StudentColors.amber),
                    ),
                    child: Text(
                      '${isHindi ? 'अगले माह से' : 'Next month'}: ${_formatPlanDisplayName(state.student!.pendingPlanId, null, isHindi)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: StudentColors.amberLight,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showChangePlanSheet(context, ref, state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isHindi ? 'प्लान बदलें' : 'Change Plan',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (state.mess != null) {
                            final reviewsAsync =
                                ref.read(messReviewsProvider(state.mess!.messId));
                            final myReview = reviewsAsync.valueOrNull
                                ?.where((r) =>
                                    r.studentId == (state.student?.studentId ?? ''))
                                .firstOrNull;
                            RateMessSheet.show(
                              context,
                              mess: state.mess!,
                              existingReview: myReview,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isHindi ? 'रिव्यू दें' : 'Rate Mess',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mess Membership Card ───────────────────────────────────────────────────
  Widget _buildMessCard(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
    bool isHindi,
  ) {
    final mess = state.mess;
    if (mess == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'मेस सदस्यता' : 'MESS MEMBERSHIP',
                style: StudentTypography.overline(
                  fontSize: 11,
                  color: StudentColors.walnutMuted,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                onPressed: () => _confirmLeaveMess(context, ref, state),
                icon: const Icon(
                  Icons.exit_to_app_rounded,
                  color: StudentColors.brickRed,
                  size: 20,
                ),
                tooltip: isHindi ? 'मेस छोड़ें' : 'Leave Mess',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mess.name,
            style: StudentTypography.serifHeading(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '${isHindi ? 'संचालक' : 'Owner'}: ${mess.ownerName} • ${isHindi ? 'कोड' : 'Code'}: ${mess.messCode}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: StudentColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings & Notification Preferences ───────────────────────────────────
  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
    bool isHindi,
  ) {
    final prefs = state.student?.notificationPrefs ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudentColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudentColors.borderSubtle),
        boxShadow: StudentColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'प्राथमिकताएं एवं सूचनाएं' : 'PREFERENCES & NOTIFICATIONS',
            style: StudentTypography.overline(
              fontSize: 11,
              color: StudentColors.walnutMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),

          // Notification Toggles
          _buildToggleRow(
            isHindi ? 'दैनिक मेन्यू अपडेट' : 'Daily Menu Broadcasts',
            isHindi ? 'आज का मेन्यू पोस्ट होते ही सूचना पाएं' : 'Alerts when today\'s menu is published',
            prefs['menuPublished'] ?? true,
            (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('menuPublished', v),
          ),
          const Divider(height: 18, color: StudentColors.borderSubtle),
          _buildToggleRow(
            isHindi ? '30-मिनट कटऑफ अलर्ट' : '30-min Cutoff Reminders',
            isHindi ? 'मील कैंसलेशन कटऑफ बंद होने से पहले अलर्ट' : 'Alerts before cancellation cutoff closes',
            prefs['cutoffReminder'] ?? true,
            (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('cutoffReminder', v),
          ),
          const Divider(height: 18, color: StudentColors.borderSubtle),
          _buildToggleRow(
            isHindi ? 'मासिक बिल अपडेट' : 'Monthly Bill Generation',
            isHindi ? 'नया बिल तैयार होने पर तुरंत सूचना' : 'Notifications when new bill is ready',
            prefs['billUpdated'] ?? true,
            (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('billUpdated', v),
          ),
          const Divider(height: 18, color: StudentColors.borderSubtle),
          _buildToggleRow(
            isHindi ? 'मेस सूचनाएं' : 'Owner Announcements',
            isHindi ? 'मेस संचालक से महत्वपूर्ण संदेश' : 'Important messages from mess management',
            prefs['announcements'] ?? true,
            (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('announcements', v),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: StudentColors.borderSubtle),
          const SizedBox(height: 14),

          // ── App Language Option ──
          InkWell(
            onTap: () => _showLanguageModal(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: _buildActionLinkWithBadge(
              Icons.language_rounded,
              isHindi ? 'ऐप की भाषा (Language)' : 'App Language',
              isHindi ? '🇮🇳 हिंदी' : '🇬🇧 English',
              StudentColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Contact Us, Support & About Mezzo
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactAboutPage(
                    userRole: 'student',
                    messId: state.student?.messId ?? '',
                    messName: state.mess?.name ?? '',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: _buildActionLink(
              Icons.support_agent_rounded,
              isHindi ? 'सहायता, संपर्क एवं जानकारी (Contact & About)' : 'Contact Us, Support & About',
              StudentColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Sign Out Button
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: _buildActionLink(
              Icons.logout_rounded,
              isHindi ? 'अकाउंट से लॉगआउट करें' : 'Sign Out of Account',
              StudentColors.brickRed,
            ),
          ),
          const SizedBox(height: 10),

          // Delete Account Button (Google Play & DPDP Act Compliant)
          InkWell(
            onTap: () => _confirmDeleteAccount(context, ref, state),
            borderRadius: BorderRadius.circular(12),
            child: _buildActionLink(
              Icons.delete_forever_rounded,
              isHindi ? 'खाता स्थायी रूप से हटाएं (Delete Account)' : 'Delete Account Forever',
              const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: StudentTypography.bold(fontSize: 13.5),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: StudentColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: StudentColors.sage,
          activeTrackColor: StudentColors.sageLight,
        ),
      ],
    );
  }

  Widget _buildActionLink(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _buildActionLinkWithBadge(
    IconData icon,
    String label,
    String badgeText,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: StudentColors.sageLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: StudentColors.sageDark,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 18, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  // ── Language Selector Modal Bottom Sheet ──────────────────────────────────
  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(localizationProvider);
    final isHi = currentLang == 'hi';

    showModalBottomSheet(
      context: context,
      backgroundColor: StudentColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: StudentColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    isHi ? 'ऐप की भाषा चुनें' : 'Choose App Language',
                    style: StudentTypography.serifHeading(
                      fontSize: 20,
                      color: StudentColors.walnut,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                  title: Text(
                    'English',
                    style: StudentTypography.bold(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Use English throughout the app',
                    style: GoogleFonts.inter(fontSize: 11, color: StudentColors.textSecondary),
                  ),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check_circle_rounded, color: StudentColors.sage)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: currentLang == 'en' ? StudentColors.sageLight.withValues(alpha: 0.5) : null,
                  onTap: () {
                    ref.read(localizationProvider.notifier).toggleLanguage('en');
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language switched to English'),
                          backgroundColor: StudentColors.sage,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                  title: Text(
                    'हिंदी (Hindi)',
                    style: StudentTypography.bold(fontSize: 14),
                  ),
                  subtitle: Text(
                    'सरल एवं आसान बोलचाल की हिंदी',
                    style: GoogleFonts.inter(fontSize: 11, color: StudentColors.textSecondary),
                  ),
                  trailing: currentLang == 'hi'
                      ? const Icon(Icons.check_circle_rounded, color: StudentColors.sage)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: currentLang == 'hi' ? StudentColors.sageLight.withValues(alpha: 0.5) : null,
                  onTap: () {
                    ref.read(localizationProvider.notifier).toggleLanguage('hi');
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('भाषा बदलकर हिंदी कर दी गई है'),
                          backgroundColor: StudentColors.sage,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last;
      final path = 'students/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await ref
          .read(studentProfileProvider.notifier)
          .uploadProfilePicture(path, bytes, extension);
    }
  }

  // ── Redesigned Edit Profile Dialog ────────────────────────────────────────
  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    StudentModel? student,
  ) {
    if (student == null) return;
    final isHindi = ref.read(localizationProvider) == 'hi';

    final nameCtrl = TextEditingController(text: student.name);
    final phoneCtrl = TextEditingController(text: student.phone);
    final roomCtrl = TextEditingController(text: student.roomNo);
    final collegeCtrl = TextEditingController(text: student.college);
    final courseCtrl = TextEditingController(text: student.course);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudentColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isHindi ? 'प्रोफाइल एडिट करें' : 'Edit Profile',
          style: StudentTypography.serifHeading(fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameCtrl, isHindi ? 'पूरा नाम' : 'Full Name', Icons.person_outline),
              const SizedBox(height: 12),
              _buildDialogField(phoneCtrl, isHindi ? 'फोन नंबर' : 'Phone Number', Icons.phone_outlined, isPhone: true),
              const SizedBox(height: 12),
              _buildDialogField(roomCtrl, isHindi ? 'कमरा नंबर' : 'Room Number', Icons.meeting_room_outlined),
              const SizedBox(height: 12),
              _buildDialogField(collegeCtrl, isHindi ? 'कॉलेज / हॉस्टल' : 'College / Hostel', Icons.school_outlined),
              const SizedBox(height: 12),
              _buildDialogField(courseCtrl, isHindi ? 'कोर्स / स्ट्रीम' : 'Course / Stream', Icons.book_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isHindi ? 'रद्द करें' : 'Cancel',
              style: StudentTypography.bold(fontSize: 13, color: StudentColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.walnut,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              final updated = student.copyWith(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                roomNo: roomCtrl.text.trim(),
                college: collegeCtrl.text.trim(),
                course: courseCtrl.text.trim(),
              );
              await ref.read(studentProfileProvider.notifier).updateProfile(updated);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(
              isHindi ? 'सेव करें' : 'Save',
              style: StudentTypography.bold(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: StudentTypography.body(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: StudentColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: StudentColors.walnutMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: StudentColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: StudentColors.amber, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: StudentColors.borderSubtle),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _showChangePlanSheet(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
  ) {
    final mess = state.mess;
    if (mess == null) return;
    final isHindi = ref.read(localizationProvider) == 'hi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: StudentColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: FutureBuilder<List<MealPlanModel>>(
            future: ref.read(appServiceProvider).getMealPlans(mess.messId),
            builder: (context, snapshot) {
              final plans = snapshot.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: StudentColors.walnutMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isHindi ? 'अगले माह के लिए प्लान चुनें' : 'Choose Next Month Plan',
                    style: StudentTypography.serifHeading(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHindi
                        ? 'नया प्लान अगले महीने की पहली तारीख से अपने आप लागू हो जाएगा।'
                        : 'The new plan will take effect automatically on the 1st of next month.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: StudentColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: StudentColors.amber),
                      ),
                    )
                  else if (plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(isHindi ? 'इस मेस के लिए कोई अन्य प्लान उपलब्ध नहीं है।' : 'No other plans available for this mess.'),
                    )
                  else
                    ...plans.map((p) {
                      final isCurrent = state.student?.assignedPlanId == p.planId;
                      final isPending = state.student?.pendingPlanId == p.planId;
                      final cleanName = _formatPlanDisplayName(p.planId, p, isHindi);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? StudentColors.sage
                                : (isPending
                                    ? StudentColors.amber
                                    : StudentColors.borderSubtle),
                            width: (isCurrent || isPending) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cleanName,
                                    style: StudentTypography.bold(fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${p.monthlyFee.toInt()}/${isHindi ? 'माह' : 'month'} • ${p.mealsIncludedPerDay} ${isHindi ? 'वक्त का खाना' : 'meals daily'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: StudentColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: StudentColors.sageLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isHindi ? 'वर्तमान' : 'Current',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: StudentColors.sageDark,
                                  ),
                                ),
                              )
                            else if (isPending)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: StudentColors.amberLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isHindi ? 'शेड्यूल्ड' : 'Scheduled',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: StudentColors.amberDark,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () async {
                                  await ref
                                      .read(studentProfileProvider.notifier)
                                      .changeMealPlan(p.planId);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isHindi
                                              ? 'प्लान बदल दिया गया! यह अगले माह से लागू होगा।'
                                              : 'Plan updated! It will take effect on the 1st of next month.',
                                        ),
                                        backgroundColor: StudentColors.sage,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: StudentColors.walnut,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  elevation: 0,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  isHindi ? 'चुनें' : 'Select',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmLeaveMess(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
  ) {
    final isHindi = ref.read(localizationProvider) == 'hi';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudentColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isHindi ? 'मेस छोड़ें?' : 'Leave Mess?',
          style: StudentTypography.serifHeading(fontSize: 20),
        ),
        content: Text(
          isHindi
              ? 'क्या आप वाकई ${state.mess?.name ?? 'इस मेस'} को छोड़ना चाहते हैं? आपकी सदस्यता रद्द हो जाएगी।'
              : 'Are you sure you want to leave ${state.mess?.name ?? 'this mess'}? Your active subscription will be terminated.',
          style: StudentTypography.body(fontSize: 14, color: StudentColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isHindi ? 'रद्द करें' : 'Cancel',
              style: StudentTypography.bold(fontSize: 13, color: StudentColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.brickRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              await ref.read(studentProfileProvider.notifier).leaveMess();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isHindi ? 'आपने सफलतापूर्वक मेस छोड़ दिया।' : 'You have left the mess successfully.'),
                    backgroundColor: StudentColors.brickRed,
                  ),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const StudentSetupPage()),
                  (route) => false,
                );
              }
            },
            child: Text(
              isHindi ? 'मेस छोड़ें' : 'Leave',
              style: StudentTypography.bold(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
  ) {
    final isHindi = ref.read(localizationProvider) == 'hi';

    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: StudentColors.surfaceLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHindi ? 'खाता स्थायी रूप से हटाएं?' : 'Delete Account Forever?',
                      style: StudentTypography.serifHeading(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi
                        ? 'क्या आप वाकई अपना Mezzo अकाउंट हमेशा के लिए हटाना चाहते हैं? आपकी प्रोफ़ाइल, उपस्थिति इतिहास और भोजन प्राथमिकताएं हमेशा के लिए मिटा दी जाएंगी। यह प्रक्रिया वापस नहीं ली जा सकती।'
                        : 'Are you sure you want to delete your Mezzo account? All your personal profile data, meal preferences, and attendance history will be permanently erased. This action cannot be undone.',
                    style: StudentTypography.body(fontSize: 13.5, color: StudentColors.textDark),
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
                      isHindi ? 'रद्द करें' : 'Cancel',
                      style: StudentTypography.bold(fontSize: 13, color: StudentColors.textMuted),
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
                        final studentId = state.student?.studentId ??
                            await ref.read(appServiceProvider).getCurrentUserId();
                        if (studentId != null && studentId.isNotEmpty) {
                          await ref.read(appServiceProvider).deleteStudentAccount(studentId);
                        }
                        await ref.read(authProvider.notifier).signOut();

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isHindi
                                    ? 'आपका अकाउंट सफलतापूर्वक हटा दिया गया है।'
                                    : 'Your account has been deleted successfully.',
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
                            errorMsg = isHindi
                                ? 'सुरक्षा सत्यापन रद्द कर दिया गया था।'
                                : 'Security re-authentication was cancelled.';
                          } else {
                            errorMsg = isHindi
                                ? 'अकाउंट हटाने में त्रुटि: कृपया पुनः प्रयास करें।'
                                : 'Account deletion failed. Please try again.';
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
                      isHindi ? 'हां, हटाएं' : 'Delete Forever',
                      style: StudentTypography.bold(fontSize: 13, color: Colors.white),
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
