import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../services/admin_service.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../../widgets/mezzo_logo.dart';
import '../owner/theme/owner_inspired_theme.dart';
import 'user_feedback_sheet.dart';

/// Complete, Executive "Contact Us & About Mezzo" Page.
/// Features:
/// 1. Tab 1: 📞 Support & Complaints: Direct WhatsApp/Email channels,
///    Complaint/Feedback generator with screenshot upload, and Real-time Ticket/Response Tracker.
/// 2. Tab 2: ℹ️ About Mezzo: Brand story, app version, developer contact, and legal/privacy guarantees.
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

class _ContactAboutPageState extends ConsumerState<ContactAboutPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const String _supportPhone = '+9190117365771';
  static const String _supportEmail = 'support@mezzo.app';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
          const SnackBar(
            content: Text('Support email: support@mezzo.app'),
            backgroundColor: OwnerColors.walnutDark,
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

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: OwnerColors.amberGlow),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHi = ref.watch(localizationProvider) == 'hi';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: OwnerColors.canvas,
        appBar: AppBar(
          backgroundColor: OwnerColors.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: OwnerColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isHi ? 'सहायता एवं संपर्क' : 'Contact & About',
            style: OwnerTypography.editorialSerif(
              size: 20,
              weight: FontWeight.w700,
              color: OwnerColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: OwnerColors.sageGreen,
            indicatorWeight: 3,
            labelColor: OwnerColors.walnutDark,
            unselectedLabelColor: OwnerColors.textMuted,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: [
              Tab(
                icon: const Icon(Icons.headset_mic_rounded, size: 18),
                text: isHi ? 'संपर्क एवं शिकायत' : 'Contact & Support',
              ),
              Tab(
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                text: isHi ? 'मेज़ो के बारे में' : 'About Mezzo',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildContactSupportTab(context, isHi),
            _buildAboutMezzoTab(context, isHi),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: 📞 CONTACT & SUPPORT + REAL-TIME TICKET TRACKER
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildContactSupportTab(BuildContext context, bool isHi) {
    final userId = ref.watch(authProvider).userId ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fast Help Action Cards (WhatsApp, Call, Email) ──
          Text(
            isHi ? 'सीधे संपर्क करें' : 'DIRECT SUPPORT CHANNELS',
            style: OwnerTypography.overline(
              size: 11,
              color: OwnerColors.walnutMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // WhatsApp Direct
              Expanded(
                child: _buildChannelCard(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF25D366),
                  bgColor: const Color(0xFFE8F9EE),
                  title: 'WhatsApp',
                  subtitle: isHi ? 'तुरंत चैट करें' : 'Chat Instantly',
                  onTap: _launchWhatsApp,
                ),
              ),
              const SizedBox(width: 10),

              // Official Email
              Expanded(
                child: _buildChannelCard(
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                  title: isHi ? 'ईमेल' : 'Email Us',
                  subtitle: 'support@mezzo.app',
                  onTap: _launchEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Helpline Card
          InkWell(
            onTap: _launchCall,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OwnerColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OwnerColors.amberLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded,
                        color: OwnerColors.amberText, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHi ? 'कॉल सहायता (Mon-Sat, 9AM-8PM)' : 'Call Support Helpline',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.textPrimary,
                          ),
                        ),
                        Text(
                          '+91 90117 36577',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: OwnerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: OwnerColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Raise Complaint / Bug / Suggestion CTA Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D231C), Color(0xFF1E1611)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D231C).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OwnerColors.amberGlow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        color: OwnerColors.amberGlow,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHi ? 'कोई समस्या या सुझाव है?' : 'Got an Issue or Bug?',
                        style: GoogleFonts.newsreader(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFAF8F3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isHi
                      ? 'बग रिपोर्ट करें, स्क्रीनशॉट संलग्न करें या बिलिंग विवाद उठाएं। हमारी टीम सीधे ऐप में समाधान देगी।'
                      : 'File a complaint, attach screenshots of the issue, or propose feature ideas. You\'ll receive direct responses right here.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFFD6C8BC),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.amberGlow,
                      foregroundColor: OwnerColors.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _openComplaintSheet,
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                    label: Text(
                      isHi ? 'शिकायत / सुझाव दर्ज करें' : 'Raise Ticket with Screenshot',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── User Ticket History & Admin Response Tracker ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHi ? 'मेरी शिकायतें एवं स्टेटस' : 'MY COMPLAINTS & REPLIES',
                style: OwnerTypography.overline(
                  size: 11,
                  color: OwnerColors.walnutMuted,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: OwnerColors.textMuted),
                onPressed: () => setState(() {}),
                tooltip: isHi ? 'रिफ्रेश करें' : 'Refresh',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          StreamBuilder<List<SupportTicketModel>>(
            stream: ref.watch(adminServiceProvider).streamUserTickets(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: OwnerColors.sageGreen),
                  ),
                );
              }

              final tickets = snapshot.data ?? [];
              if (tickets.isEmpty) {
                return _buildEmptyTicketState(isHi);
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildTicketCard(tickets[index], isHi);
                },
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OwnerColors.borderSubtle),
          boxShadow: OwnerColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: OwnerColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: OwnerColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTicketState(bool isHi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwnerColors.sageLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: OwnerColors.sageGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isHi ? 'कोई सक्रिय शिकायत नहीं है' : 'No Complaints on Record',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: OwnerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHi
                ? 'यदि आपको कोई बग, असुविधा या बिलिंग समस्या आती है, तो ऊपर दिए गए बटन से टिकट दर्ज करें।'
                : 'Whenever you report an issue or suggest a feature, your ticket and official admin response will show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: OwnerColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket, bool isHi) {
    final isResolved = ticket.status == 'resolved';
    final isInProgress = ticket.status == 'in_progress';

    final Color statusColor = isResolved
        ? const Color(0xFF16A34A)
        : isInProgress
            ? const Color(0xFFD97706)
            : const Color(0xFFEA580C);

    final String statusLabel = isResolved
        ? (isHi ? 'समाधान हुआ (Resolved)' : 'Resolved')
        : isInProgress
            ? (isHi ? 'समीक्षाधीन (In Progress)' : 'In Progress')
            : (isHi ? 'दर्ज की गई (Open)' : 'Open');

    String categoryLabel = 'Suggestion';
    if (ticket.category == 'bug') categoryLabel = isHi ? '🐛 बग रिपोर्ट' : 'Bug report';
    if (ticket.category == 'mess_issue') categoryLabel = isHi ? '🍽️ मेस समस्या' : 'Mess issue';
    if (ticket.category == 'billing_dispute') categoryLabel = isHi ? '💳 बिल विवाद' : 'Bill dispute';
    if (ticket.category == 'suggestion') categoryLabel = isHi ? '💡 सुझाव' : 'Suggestion';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isResolved ? const Color(0xFFCBD6C7) : OwnerColors.borderSubtle,
        ),
        boxShadow: OwnerColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Pill & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8DE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  categoryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E2D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // User's Complaint Message
          Text(
            ticket.message,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: OwnerColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Attached Screenshot Thumbnail (if present)
          if (ticket.screenshotUrl != null && ticket.screenshotUrl!.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showImagePreviewDialog(ticket.screenshotUrl!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwnerColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ticket.screenshotUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHi ? 'संलग्न स्क्रीनशॉट देखें' : 'View Attached Screenshot',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OwnerColors.sageGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 14, color: OwnerColors.sageGreen),
                  ],
                ),
              ),
            ),
          ],

          // Timestamp & Device info
          Text(
            '${isHi ? 'दर्ज' : 'Filed'}: ${_formatDate(ticket.createdAt)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: OwnerColors.textMuted,
            ),
          ),

          // ── Admin Reply Box (if responded) ──
          if (ticket.adminReply != null && ticket.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD6C7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: OwnerColors.sageGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHi ? 'मेज़ो सपोर्ट टीम का उत्तर' : 'Official Mezzo Team Response',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.sageText,
                        ),
                      ),
                      const Spacer(),
                      if (ticket.adminRepliedAt != null)
                        Text(
                          _formatDate(ticket.adminRepliedAt!),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: OwnerColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.adminReply!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: OwnerColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: ℹ️ ABOUT MEZZO (STORY, VISION & LEGAL COMPLIANCE)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildAboutMezzoTab(BuildContext context, bool isHi) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Central Brand Squircle Logo
          const Center(
            child: MezzoLogo(
              size: 80,
              showSquircle: true,
              showShadow: true,
              backgroundColor: Color(0xFF2B1D14),
            ),
          ),
          const SizedBox(height: 16),

          // Brand Title: Mezzo
          Text(
            'Mezzo',
            style: GoogleFonts.newsreader(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: OwnerColors.walnutDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle / Tagline
          Text(
            isHi
                ? 'स्मार्ट मेस मैनेजमेंट • स्वाद भी, हिसाब भी'
                : 'SMART MESS MANAGEMENT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: OwnerColors.amberDark,
            ),
          ),
          const SizedBox(height: 10),

          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OwnerColors.borderSubtle),
            ),
            child: Text(
              'v1.0.4 • Build 2026 (Production)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: OwnerColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Story & Mission Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: OwnerColors.borderSubtle),
              boxShadow: OwnerColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu_rounded,
                        color: OwnerColors.amberGlow, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isHi ? 'हमारा उद्देश्य (Our Mission)' : 'About Mezzo',
                      style: OwnerTypography.editorialSerif(
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isHi
                      ? 'Mezzo को मेस संचालकों और छात्रों के बीच रोज़मर्रा के मैन्युअल रजिस्टर और बिलिंग विवादों को खत्म करने के लिए बनाया गया है।\n\n'
                        'हम हॉस्टल और प्राइवेट मेस को पूरी तरह डिजिटल बनाते हैं — लाइव मेन्यू ब्रॉडकास्ट, ऑटोमैटिक 30-मिनट कटऑफ कैंसलेशन, पारदर्शी मासिक बिल, और क्लाउड लेज़र हिसाब-किताब।'
                      : 'Mezzo was engineered to eliminate paper meal registers, missed cancellation deadlines, and end-of-month fee disputes for hostels and independent messes across India.\n\n'
                        'With real-time menu broadcasts, automated cancellation cutoffs, accurate per-meal & monthly billing, and an integrated kitchen expense ledger, Mezzo brings trust and transparency to daily dining.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: OwnerColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Trust & Security Pillars
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: OwnerColors.borderSubtle),
              boxShadow: OwnerColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHi ? 'सुरक्षा एवं तकनीक' : 'SECURITY & PRIVACY GUARANTEES',
                  style: OwnerTypography.overline(
                    size: 11,
                    color: OwnerColors.walnutMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTrustRow(
                  Icons.shield_outlined,
                  isHi ? '100% डेटा सुरक्षा' : 'Data Isolation & Privacy',
                  isHi
                      ? 'DPDP Act 2023 और Google Play नियमों के पूर्णतः अनुकूल।'
                      : 'Compliant with India DPDP Act 2023 and Google Play privacy policies.',
                ),
                const Divider(height: 18, color: OwnerColors.borderSubtle),
                _buildTrustRow(
                  Icons.cloud_done_outlined,
                  isHi ? 'सुरक्षित मीडिया क्लाउड' : 'Optimized Media Cloud',
                  isHi
                      ? 'Cloudinary CDN के साथ तेज और सुरक्षित फोटो स्टोरेज।'
                      : 'Powered by Cloudinary CDN with auto-optimized WebP image delivery.',
                ),
                const Divider(height: 18, color: OwnerColors.borderSubtle),
                _buildTrustRow(
                  Icons.delete_outline_rounded,
                  isHi ? 'खाता हटाने का पूर्ण अधिकार' : 'Right to Erasure',
                  isHi
                      ? 'छात्र एवं संचालक कभी भी एक क्लिक में अपना खाता और डेटा हटा सकते हैं।'
                      : 'Both students and owners can delete accounts and wipe personal data anytime.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Made with Pride footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with ',
                style: GoogleFonts.inter(fontSize: 12, color: OwnerColors.textMuted),
              ),
              const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 14),
              Text(
                ' in India for Students & Mess Owners',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OwnerColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '© 2026 Mezzo Technologies. All rights reserved.',
            style: GoogleFonts.inter(fontSize: 11, color: OwnerColors.textMuted),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrustRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: OwnerColors.sageLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: OwnerColors.sageGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: OwnerColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: OwnerColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
  }
}
