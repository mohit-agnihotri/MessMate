import '../../../services/localization_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../common/user_feedback_sheet.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/app_models.dart';

String _formatPlanName(String? planId) {
  if (planId == null || planId.isEmpty) return 'Koi plan nahi (No plan)';
  final parts = planId.split('_');
  final name = parts.length > 1 ? parts.sublist(1).join(' ') : planId;
  return name
      .split('_')
      .map((w) => w.isNotEmpty ? '' : w)
      .join(' ');
}
class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildProfileCard(context, ref, state),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildMessCard(context, ref, state),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    sliver: SliverToBoxAdapter(
                      child: _buildSettingsSection(context, ref, state),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
  ) {
    final student = state.student;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _pickImage(ref),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFDCFCE7),
                  backgroundImage:
                      student?.photoUrl != null && student!.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(student.photoUrl!)
                      : null,
                  child: student?.photoUrl == null || student!.photoUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF16A34A),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student?.name ?? 'Student',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          _showEditProfileDialog(context, ref, student),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF3B82F6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${student?.studentId.substring(0, 8).toUpperCase() ?? ''} | Room ${student?.roomNo ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '${student?.course ?? ''} - ${student?.college ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last;
      final path =
          'students/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await ref
          .read(studentProfileProvider.notifier)
          .uploadProfilePicture(path, bytes, extension);
    }
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    StudentModel? student,
  ) {
    if (student == null) return;

    final nameCtrl = TextEditingController(text: student.name);
    final phoneCtrl = TextEditingController(text: student.phone);
    final roomCtrl = TextEditingController(text: student.roomNo);
    final collegeCtrl = TextEditingController(text: student.college);
    final courseCtrl = TextEditingController(text: student.course);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'Room No'),
              ),
              TextField(
                controller: collegeCtrl,
                decoration: const InputDecoration(labelText: 'College'),
              ),
              TextField(
                controller: courseCtrl,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
            ),
            onPressed: () {
              final updated = StudentModel(
                studentId: student.studentId,
                name: nameCtrl.text,
                phone: phoneCtrl.text,
                roomNo: roomCtrl.text,
                college: collegeCtrl.text,
                course: courseCtrl.text,
                email: student.email,
                photoUrl: student.photoUrl,
                joinDate: student.joinDate,
                messId: student.messId,
                status: student.status,
              );
              ref.read(studentProfileProvider.notifier).updateProfile(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile Updated!'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessCard(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
  ) {
    final mess = state.mess;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Mess',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mess?.name ?? '',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Owner: ${mess?.ownerName ?? ''}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            'Joined via Code: ${mess?.messCode ?? ''}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          if (state.student?.subscriptionEndDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Valid Till: ${state.student!.subscriptionEndDate!.toIso8601String().substring(0, 10)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Plan Status Banner (Balanced 3D Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C10B981),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.card_membership_rounded, color: Color(0xFF059669), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ref.watch(localizationProvider) == 'hi' ? 'सक्रिय मील प्लान' : 'Active Meal Plan',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPlanName(state.student?.assignedPlanId),
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                if (state.student?.pendingPlanId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ref.watch(localizationProvider) == 'hi' ? 'अगले माह से लागू: ${_formatPlanName(state.student!.pendingPlanId)}' : 'Effective next month: ${_formatPlanName(state.student!.pendingPlanId)}',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showChangePlanSheet(context, ref, state),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                ref.watch(localizationProvider) == 'hi' ? 'अगले महीने का प्लान बदलें' : 'Change Next Month Plan',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLeaveDialog(context, ref),
              icon: const Icon(
                Icons.exit_to_app_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              label: Text(
                'Leave This Mess',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    StudentProfileState state,
  ) {
    final prefs = state.student?.notificationPrefs ?? {};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _RealToggleTile(
            title: 'Menu Published',
            subtitle: 'Notified when daily menu is posted',
            value: prefs['menuPublished'] ?? true,
            onChanged: (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('menuPublished', v),
          ),
          _RealToggleTile(
            title: '30 min Cut-off Reminder',
            subtitle: 'Reminder before meal cut-off time',
            value: prefs['cutoffReminder'] ?? true,
            onChanged: (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('cutoffReminder', v),
          ),
          _RealToggleTile(
            title: 'Bill Updated',
            subtitle: 'Alert when your monthly bill is ready',
            value: prefs['billUpdated'] ?? true,
            onChanged: (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('billUpdated', v),
          ),
          _RealToggleTile(
            title: 'Owner Announcements',
            subtitle: 'Important messages from mess owner',
            value: prefs['announcements'] ?? true,
            onChanged: (v) => ref
                .read(studentProfileProvider.notifier)
                .toggleNotification('announcements', v),
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          InkWell(
            onTap: () => _showLanguageModal(context, ref),
            child: _buildArrowTile(
              Icons.language_outlined,
              ref.watch(localizationProvider) == 'hi' ? 'भाषा (Language)' : 'Language',
              ref.watch(localizationProvider) == 'hi' ? 'हिंदी (Hindi)' : 'English',
            ),
          ),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => UserFeedbackSheet(
                  userRole: 'student',
                  messId: state.student?.messId ?? '',
                  messName: state.mess?.name ?? '',
                ),
              );
            },
            child: _buildArrowTile(
              Icons.support_agent_rounded,
              ref.watch(localizationProvider) == 'hi'
                  ? 'सहायता और शिकायत (Help & Complaints)'
                  : 'Help & Complaints',
              '',
            ),
          ),

          const Divider(height: 24, color: Color(0xFFF3F4F6)),
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
            child: _buildArrowTile(
              Icons.logout_rounded,
              'Sign Out',
              '',
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowTile(
    IconData icon,
    String title,
    String trailing, {
    Color? color,
  }) {
    final textColor = color ?? const Color(0xFF374151);
    final iconColor = color ?? const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, color: textColor),
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
        ],
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ref.watch(localizationProvider) == 'hi' ? 'अगले महीने के लिए प्लान चुनें' : 'Choose Plan for Next Month',
                    style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ref.watch(localizationProvider) == 'hi' ? 'नया प्लान अगले महीने की 1 तारीख से अपने आप लागू हो जाएगा।' : 'The new plan will take effect automatically on the 1st of next month.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF10B981))))
                  else if (plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(ref.watch(localizationProvider) == 'hi' ? 'कोई अन्य प्लान उपलब्ध नहीं है' : 'No other plans available', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
                    )
                  else
                    ...plans.map((p) {
                      final isCurrent = state.student?.assignedPlanId == p.planId;
                      final isPending = state.student?.pendingPlanId == p.planId;
                      final hasChoice = p.choiceGroups.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF10B981)
                                : (isPending ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
                            width: (isCurrent || isPending) ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isCurrent
                                  ? const Color(0x0C10B981)
                                  : (isPending ? const Color(0x0CF59E0B) : const Color(0x060F172A)),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (hasChoice)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ref.watch(localizationProvider) == 'hi' ? '🎯 पसंद का खाना' : '🎯 Meal Choice',
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                                          ),
                                        ),
                                      Text(
                                        p.name,
                                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ref.watch(localizationProvider) == 'hi' ? '₹${p.monthlyFee.toInt()} / महीना • ₹${p.deductionPolicy.flatRate?.toInt() ?? 50} वापसी/छुट्टी' : '₹${p.monthlyFee.toInt()} / month • ₹${p.deductionPolicy.flatRate?.toInt() ?? 50} rebate per skip',
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(ref.watch(localizationProvider) == 'hi' ? 'वर्तमान प्लान' : 'Current Plan', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                                  )
                                else if (isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(ref.watch(localizationProvider) == 'hi' ? 'अनुरोधित ✓' : 'Requested ✓', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                                  )
                                else
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      await ref.read(studentProfileProvider.notifier).requestPlanChange(p.planId);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(ref.read(localizationProvider) == 'hi' ? 'अनुरोध दर्ज हो गया! अगले माह की 1 तारीख से लागू होगा।' : 'Plan change requested! Takes effect on 1st of next month.')),
                                        );
                                      }
                                    },
                                    child: Text(ref.watch(localizationProvider) == 'hi' ? 'चुनें' : 'Select', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave this mess?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will lose access to all mess data. This cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(studentProfileProvider.notifier).leaveMess();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Left Mess Successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text('Leave', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(localizationProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    currentLang == 'hi' ? 'भाषा चुनें' : 'Choose Language',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'English',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  subtitle: Text(
                    'Clean & simple English',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    ref.read(localizationProvider.notifier).toggleLanguage('en');
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language switched to English'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'हिंदी (Hindi)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  subtitle: Text(
                    'सरल एवं आसान बोलचाल की हिंदी',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: currentLang == 'hi'
                      ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    ref.read(localizationProvider.notifier).toggleLanguage('hi');
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('भाषा बदलकर हिंदी कर दी गई है'),
                          backgroundColor: Color(0xFF10B981),
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
}

class _RealToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RealToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}
