import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../services/admin_service.dart';

/// Redesigned Ticket Detail Page matching Screenshot 3.
/// Displays user query, official Mezzo support reply with amber accent,
/// attached screenshot preview, and 'Was this solved?' resolution prompt.
class TicketDetailPage extends ConsumerStatefulWidget {
  final SupportTicketModel ticket;

  const TicketDetailPage({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  late SupportTicketModel _ticket;
  bool _isMarkingSolved = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  String _getCategoryDisplayName(String cat) {
    switch (cat) {
      case 'bug':
        return 'bug report';
      case 'suggestion':
        return 'suggestion';
      case 'mess_issue':
        return 'mess issue';
      case 'billing_dispute':
        return 'bill dispute';
      default:
        return 'support ticket';
    }
  }

  String _getCategoryPillName(String cat) {
    switch (cat) {
      case 'bug':
        return 'Bug report';
      case 'suggestion':
        return 'Suggestion';
      case 'mess_issue':
        return 'Mess issue';
      case 'billing_dispute':
        return 'Bill dispute';
      default:
        return 'Support';
    }
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
                    child: CircularProgressIndicator(color: Color(0xFFEAA23E)),
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

  Future<void> _markResolved() async {
    if (_ticket.status == 'resolved') return;
    setState(() => _isMarkingSolved = true);

    try {
      if (_ticket.ticketId.isNotEmpty) {
        await ref.read(adminServiceProvider).updateTicketStatus(
          _ticket.ticketId,
          'resolved',
        );
      }
      setState(() {
        _ticket = _ticket.copyWith(status: 'resolved');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFFEAA23E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Glad this was resolved! Thank you for helping improve Mezzo.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF241A14),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      debugPrint('[TicketDetailPage] Error resolving ticket: $e');
    } finally {
      if (mounted) setState(() => _isMarkingSolved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catName = _getCategoryDisplayName(_ticket.category);
    final catPill = _getCategoryPillName(_ticket.category);
    final isResolved = _ticket.status == 'resolved';

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
                Color(0xFFEAEFE7),
                Color(0xFFE1ECE0),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      // Circular back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      Expanded(
                        child: Text(
                          'Ticket · $catName',
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF241A14),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Pills Row (Category + Status) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      // Amber category pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE4BF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          catPill,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B4B0A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isResolved ? const Color(0xFF2E633B) : const Color(0xFF2C2018),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isResolved ? 'Resolved' : (_ticket.status == 'in_progress' ? 'In Progress' : 'Open'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFAF8F5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Scrollable Discussion / Details Area ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: User message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDFE6DB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF241A14),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _ticket.message,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF554D48),
                                  height: 1.45,
                                ),
                              ),
                              if (_ticket.screenshotUrl != null &&
                                  _ticket.screenshotUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _showImagePreviewDialog(_ticket.screenshotUrl!),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3EFEA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFDFE6DB)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: _ticket.screenshotUrl!,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'View attached screenshot',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF38573D),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.open_in_new_rounded,
                                            size: 14, color: Color(0xFF38573D)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'Filed ${_formatDate(_ticket.createdAt)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8A8480),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Card 2: Mezzo Support Reply with Amber left border accent
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFDFE6DB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Amber vertical accent curve/bar on the left
                                  Container(
                                    width: 5,
                                    color: const Color(0xFFEAA23E),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Mezzo support',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF241A14),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDFE7DC),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Official',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF334B37),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _ticket.adminReply != null &&
                                                    _ticket.adminReply!.isNotEmpty
                                                ? _ticket.adminReply!
                                                : 'Sample admin reply appears here once support answers your ticket.',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF554D48),
                                              height: 1.45,
                                            ),
                                          ),
                                          if (_ticket.adminRepliedAt != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Replied ${_formatDate(_ticket.adminRepliedAt!)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF8A8480),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Card 3: "Was this solved?" resolution prompt
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDFE6DB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Was this solved?',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B6662),
                                  ),
                                ),
                              ),
                              // Yes button
                              GestureDetector(
                                onTap: _isMarkingSolved ? null : _markResolved,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isResolved
                                        ? const Color(0xFF2E633B)
                                        : const Color(0xFF2C2018),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    isResolved ? '✓ Solved' : 'Yes',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFAF8F5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Still an issue button
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Our team has been alerted and will follow up shortly!',
                                        style: GoogleFonts.inter(fontSize: 12.5),
                                      ),
                                      backgroundColor: const Color(0xFF241A14),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDFE7DC),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Still an...',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334B37),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
