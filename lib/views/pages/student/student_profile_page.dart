import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/all_viewmodels.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildProfileCard(state)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildMessCard(context, ref, state)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverToBoxAdapter(child: _buildSettingsSection()),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildProfileCard(StudentProfileState state) {
    final student = state.student;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.person, size: 40, color: Color(0xFF16A34A)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(
              student?.name ?? 'Student',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Edit Profile',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6))),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${student?.studentId.substring(0, 8).toUpperCase() ?? ''} | Room ${student?.roomNo ?? ''}',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
          Text('${student?.course ?? ''} - ${student?.college ?? ''}',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
        ])),
      ]),
    );
  }

  Widget _buildMessCard(BuildContext context, WidgetRef ref, StudentProfileState state) {
    final mess = state.mess;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Mess', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Text(mess?.name ?? '',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 4),
        Text('Owner: ${mess?.ownerName ?? ''}',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
        Text('Joined via Code: ${mess?.messCode ?? ''}',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLeaveDialog(context, ref),
            icon: const Icon(Icons.exit_to_app_rounded, size: 18, color: Color(0xFFEF4444)),
            label: Text('Leave This Mess',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Text('Notifications', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        _ToggleTile('Menu Published'),
        _ToggleTile('30 min Cut-off Reminder'),
        _ToggleTile('Bill Updated'),
        _ToggleTile('Owner Announcements'),
        const Divider(height: 24, color: Color(0xFFF3F4F6)),
        _buildArrowTile(Icons.language_outlined, 'Language', 'English'),
        _buildArrowTile(Icons.help_outline_rounded, 'Help & Support', ''),
      ]),
    );
  }

  Widget _buildArrowTile(IconData icon, String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151)))),
        if (trailing.isNotEmpty)
          Text(trailing, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
      ]),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Leave this mess?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: Text('You will lose access to all mess data. This cannot be undone.',
        style: GoogleFonts.inter()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter())),
        ElevatedButton(
          onPressed: () {
            ref.read(studentProfileProvider.notifier).leaveMess();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left Mess Successfully!')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          child: Text('Leave', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ],
    ));
  }
}

class _ToggleTile extends StatefulWidget {
  final String title;
  const _ToggleTile(this.title);

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(widget.title, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151)))),
        CupertinoSwitch(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          activeTrackColor: const Color(0xFF22C55E),
        ),
      ]),
    );
  }
}

