import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../services/admin_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'ticket_detail_page.dart';
import 'user_feedback_sheet.dart';

/// Complete, Executive Contact & About Page matching Mezzo Inspired UI.
/// Features custom segmented toggle bar between "Contact & support" (Screenshot 1)
/// and "About Mezzo" (Screenshot 5), direct communication channels,
/// ticket creation bottom sheet, and comprehensive support tracker.
class ContactAboutPage extends ConsumerStatefulWidget {
  final String userRole; // 'student' | 'owner'
  final String messId;
  final String messName;
  final int initialTabIndex;

  const ContactAboutPage({
    super.key,
    required this.userRole,
    this.messId = '',
    this.messName = '',
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<ContactAboutPage> createState() => _ContactAboutPageState();
}

class _ContactAboutPageState extends ConsumerState<ContactAboutPage> {
  late int _selectedTab;

  static const String _supportPhone = '+917974220107';
  static const String _supportEmail = 'agnihotrimohit185@gmail.com';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 1);
  }

  Future<void> _launchWhatsApp() async {
    final message = Uri.encodeComponent(
      'Hi Mezzo Support Team, I need assistance with my ${widget.userRole == 'owner' ? 'Mess Owner' : 'Student'} account on Mezzo.',
    );
    final whatsappUri = Uri.parse('whatsapp://send?phone=$_supportPhone&text=$message');
    final webUri = Uri.parse('https://wa.me/$_supportPhone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Mezzo%20Support%20Request%20(${widget.userRole.toUpperCase()})',
    );
    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Support email: agnihotrimohit185@gmail.com'),
            backgroundColor: const Color(0xFF241A14),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _launchCall() async {
    final callUri = Uri(scheme: 'tel', path: _supportPhone);
    try {
      await launchUrl(callUri);
    } catch (_) {}
  }

  void _openComplaintSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => UserFeedbackSheet(
        userRole: widget.userRole,
        messId: widget.messId,
        messName: widget.messName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFE8EFE5),
                Color(0xFFDFE8DD),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDFE8DD),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: Color(0xFF241A14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Contact & About',
                        style: GoogleFonts.newsreader(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF241A14),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Segmented Toggle Tabs (Contact & support vs About Mezzo) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFE7DC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? const Color(0xFF2C2018)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  'Contact & support',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: _selectedTab == 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _selectedTab == 0
                                        ? const Color(0xFFFAF8F5)
                                        : const Color(0xFF3A4B3D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? const Color(0xFF2C2018)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  'About Mezzo',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _selectedTab == 1
                                        ? const Color(0xFFFAF8F5)
                                        : const Color(0xFF3A4B3D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Tab Body ──
                Expanded(
                  child: _selectedTab == 0
                      ? _ContactSupportView(
                          userRole: widget.userRole,
                          messId: widget.messId,
                          messName: widget.messName,
                          onWhatsApp: _launchWhatsApp,
                          onEmail: _launchEmail,
                          onCall: _launchCall,
                          onOpenComplaint: _openComplaintSheet,
                        )
                      : const _AboutMezzoView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1: CONTACT & SUPPORT VIEW (MATCHING SCREENSHOT 1)
// ═════════════════════════════════════════════════════════════════════════════

class _ContactSupportView extends ConsumerWidget {
  final String userRole;
  final String messId;
  final String messName;
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;
  final VoidCallback onCall;
  final VoidCallback onOpenComplaint;

  const _ContactSupportView({
    required this.userRole,
    required this.messId,
    required this.messName,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onCall,
    required this.onOpenComplaint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid ??
        ref.watch(authProvider).userId ??
        '';
    final ticketsAsync = ref.watch(userTicketsStreamProvider(userId));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: TALK TO US DIRECTLY ──
          Text(
            'TALK TO US DIRECTLY',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: const Color(0xFF5C6B5E),
            ),
          ),
          const SizedBox(height: 10),

          // Row with WhatsApp and Email Cards
          Row(
            children: [
              // WhatsApp Card
              Expanded(
                child: _buildContactChannelCard(
                  iconBgColor: const Color(0xFF7E9D84),
                  icon: Icons.chat_bubble_rounded,
                  title: 'WhatsApp',
                  subtitle: 'Chat instantly',
                  onTap: onWhatsApp,
                ),
              ),
              const SizedBox(width: 10),
              // Email us Card
              Expanded(
                child: _buildContactChannelCard(
                  iconBgColor: const Color(0xFFEAA23E),
                  icon: Icons.mail_rounded,
                  title: 'Email us',
                  subtitle: 'agnihotrimohit185@gmail.com',
                  onTap: onEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Call support helpline Card
          InkWell(
            onTap: onCall,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDFE6DB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF5633),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Color(0xFFFAF8F5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call support helpline',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF241A14),
                          ),
                        ),
                        Text(
                          '+91 79742 20107',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF7A7571),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8A8480),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Section 2: ISSUE, BUG OR IDEA? Banner Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C2018),
                  Color(0xFF423022),
                  Color(0xFF201610),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF241A14).withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ISSUE, BUG OR IDEA?',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: const Color(0xFFEAA23E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Raise a ticket',
                  style: GoogleFonts.newsreader(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAF8F5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'File a complaint, attach screenshots or suggest a feature. The reply comes back right here.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFFD6C8BC),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAA23E),
                      foregroundColor: const Color(0xFF241A14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onOpenComplaint,
                    child: Text(
                      'Raise ticket with screenshot',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241A14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section 3: MY COMPLAINTS & REPLIES ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY COMPLAINTS & REPLIES',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: const Color(0xFF5C6B5E),
                ),
              ),
              InkWell(
                onTap: () => ref.invalidate(userTicketsStreamProvider(userId)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFE7DC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF304333)),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF304333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tickets Stream List / Empty State
          ticketsAsync.when(
            data: (tickets) {
              if (tickets.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return _buildTicketSummaryCard(context, ticket);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF38573D)),
              ),
            ),
            error: (err, stack) => _buildEmptyState(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactChannelCard({
    required Color iconBgColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDFE6DB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFFAF8F5), size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF241A14),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF7A7571),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDFE6DB)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFDFE8DD),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF2E633B),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No complaints on record',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF241A14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your tickets and the official reply will show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF7A7571),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketSummaryCard(BuildContext context, SupportTicketModel ticket) {
    final isResolved = ticket.status == 'resolved';
    final hasReply = ticket.adminReply != null && ticket.adminReply!.isNotEmpty;

    String catDisplay = 'Bug report';
    if (ticket.category == 'suggestion') catDisplay = 'Suggestion';
    if (ticket.category == 'mess_issue') catDisplay = 'Mess issue';
    if (ticket.category == 'billing_dispute') catDisplay = 'Bill dispute';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailPage(ticket: ticket),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isResolved ? const Color(0xFFCCD7CA) : const Color(0xFFDFE6DB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE4BF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    catDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B4B0A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? const Color(0xFF2E633B)
                        : (ticket.status == 'in_progress'
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2C2018)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isResolved ? 'Resolved' : (ticket.status == 'in_progress' ? 'In Progress' : 'Open'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFAF8F5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ticket.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF241A14),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasReply) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE8DD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF2E633B)),
                    const SizedBox(width: 4),
                    Text(
                      'Mezzo support replied · Tap to view',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E633B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2: ABOUT MEZZO VIEW (MATCHING SCREENSHOT 5)
// ═════════════════════════════════════════════════════════════════════════════

class _AboutMezzoView extends StatelessWidget {
  const _AboutMezzoView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hero Card with Dark Walnut Gradient ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C2018),
                  Color(0xFF423023),
                  Color(0xFF1F1610),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF241A14).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Squircle steaming bowl badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38291F),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFEAA23E).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Steam lines
                        Positioned(
                          top: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.rotate(
                                angle: -0.15,
                                child: Container(
                                  width: 3.5,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAA23E),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Transform.rotate(
                                angle: 0.15,
                                child: Container(
                                  width: 3.5,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAA23E),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bowl
                        Positioned(
                          bottom: 15,
                          child: Container(
                            width: 34,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8FB098),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                topLeft: Radius.circular(3),
                                topRight: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Brand Name
                Text(
                  'Mezzo',
                  style: GoogleFonts.newsreader(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAF8F5),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),

                // Tagline
                Text(
                  'SMART MESS MANAGEMENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: const Color(0xFFEAA23E),
                  ),
                ),
                const SizedBox(height: 12),

                // Version Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EBE0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v1.0.6 · Build 2026 (Production)',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E4231),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Section 1: WHY MEZZO EXISTS Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDFE6DB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY MEZZO EXISTS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: const Color(0xFF5C6B5E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Built for hostels and independent messes across India, to end:',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF4A433E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Checkmark Pills
                _buildBulletPill('Paper meal registers'),
                const SizedBox(height: 8),
                _buildBulletPill('Missed cancellation deadlines'),
                const SizedBox(height: 8),
                _buildBulletPill('End-of-month fee disputes'),
                const SizedBox(height: 16),

                // Sub-heading: WHAT YOU GET
                Text(
                  'WHAT YOU GET',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: const Color(0xFF5C6B5E),
                  ),
                ),
                const SizedBox(height: 10),

                // 4 Soft Sage Feature Pills (Screenshot 5)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureTag('Real-time menu broadcasts'),
                    _buildFeatureTag('Automated cancellation cut-offs'),
                    _buildFeatureTag('Per-meal and monthly billing'),
                    _buildFeatureTag('Kitchen expense ledger'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Section 2: SECURITY & PRIVACY Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDFE6DB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY & PRIVACY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: const Color(0xFF5C6B5E),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSecurityRow(
                  title: 'Data isolation & privacy',
                  subtitle:
                      'Compliant with India DPDP Act 2023 and Google Play privacy policies.',
                ),
                const SizedBox(height: 14),
                _buildSecurityRow(
                  title: 'Optimized media cloud',
                  subtitle:
                      'Cloudinary CDN with auto-optimized WebP image delivery.',
                ),
                const SizedBox(height: 14),
                _buildSecurityRow(
                  title: 'Right to erasure',
                  subtitle:
                      'Students and owners can delete their account and wipe personal data anytime.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Footer ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with ',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7571)),
              ),
              const Icon(Icons.favorite_rounded, color: Color(0xFFDC2626), size: 14),
              Text(
                ' in India for students & mess owners',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF241A14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 Mezzo Technologies. All rights reserved.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8A8480)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBulletPill(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECE2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF2E633B), size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF241A14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE8DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D3E30),
        ),
      ),
    );
  }

  Widget _buildSecurityRow({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF241A14),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF6B6662),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
