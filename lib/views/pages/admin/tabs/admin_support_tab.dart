import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Support & User Feedback Inbox Tab.
/// Allows developer to review bug reports, suggestions, view device telemetry,
/// and reply with instant OneSignal push notifications directly to the user's phone.
class AdminSupportTab extends ConsumerStatefulWidget {
  const AdminSupportTab({super.key});

  @override
  ConsumerState<AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends ConsumerState<AdminSupportTab> {
  String _selectedStatus = 'all';
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void dispose() {
    for (final ctrl in _replyControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _getReplyCtrl(String ticketId) {
    return _replyControllers.putIfAbsent(
        ticketId, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);

    return StreamBuilder<List<SupportTicketModel>>(
      stream: adminService.streamSupportTickets(statusFilter: _selectedStatus),
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? [];

        return Column(
          children: [
            // Status Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Tickets', 'all', tickets.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Open Issues',
                      'open',
                      tickets.where((t) => t.status == 'open').length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Resolved',
                      'resolved',
                      tickets.where((t) => t.status == 'resolved').length,
                    ),
                  ],
                ),
              ),
            ),

            // Tickets List or Empty Inbox
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AdminCyberTheme.cardSurface,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AdminCyberTheme.borderSubtle),
                              ),
                              child: const Icon(
                                Icons.mark_email_read_outlined,
                                size: 44,
                                color: AdminCyberTheme.neonEmerald,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Support Inbox Clear',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Zero pending user complaints or suggestions.\nAll live customer tickets are up to date.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AdminCyberTheme.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return _buildTicketCard(ticket, adminService);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AdminCyberTheme.neonViolet.withValues(alpha: 0.15)
              : AdminCyberTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AdminCyberTheme.neonViolet.withValues(alpha: 0.6)
                : AdminCyberTheme.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AdminCyberTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AdminCyberTheme.neonViolet.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AdminCyberTheme.neonViolet
                      : AdminCyberTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
      SupportTicketModel ticket, AdminService adminService) {
    final replyCtrl = _getReplyCtrl(ticket.ticketId);

    Color badgeColor = AdminCyberTheme.neonCyan;
    String categoryName = 'FEEDBACK';
    IconData categoryIcon = Icons.chat_bubble_outline_rounded;

    if (ticket.category == 'bug') {
      badgeColor = AdminCyberTheme.neonRose;
      categoryName = 'BUG REPORT';
      categoryIcon = Icons.bug_report_rounded;
    } else if (ticket.category == 'suggestion') {
      badgeColor = AdminCyberTheme.neonViolet;
      categoryName = 'SUGGESTION';
      categoryIcon = Icons.lightbulb_outline_rounded;
    } else if (ticket.category == 'billing_dispute') {
      badgeColor = AdminCyberTheme.neonAmber;
      categoryName = 'BILLING DISPUTE';
      categoryIcon = Icons.receipt_long_rounded;
    }

    final isResolved = ticket.status == 'resolved';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Squircle + Title + Status Pill
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 12, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        categoryName,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? AdminCyberTheme.neonEmerald.withValues(alpha: 0.12)
                        : AdminCyberTheme.neonAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isResolved
                          ? AdminCyberTheme.neonEmerald.withValues(alpha: 0.35)
                          : AdminCyberTheme.neonAmber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    isResolved ? 'RESOLVED' : 'PENDING',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isResolved
                          ? AdminCyberTheme.neonEmerald
                          : AdminCyberTheme.neonAmber,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User Info & Role Tag
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.userName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticket.userRole.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AdminCyberTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '📞 ${ticket.userPhone}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AdminCyberTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Device Telemetry Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminCyberTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.devices_rounded,
                      size: 13, color: AdminCyberTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${ticket.deviceModel.isNotEmpty ? ticket.deviceModel : 'Unknown Device'} • ${ticket.osVersion} • Build ${ticket.appVersion}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AdminCyberTheme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Ticket Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1322),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminCyberTheme.borderSubtle),
              ),
              child: Text(
                ticket.message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.45,
                ),
              ),
            ),

            // Reply Section
            if (ticket.adminReply != null &&
                ticket.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminCyberTheme.neonEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AdminCyberTheme.neonEmerald.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 13, color: AdminCyberTheme.neonEmerald),
                        const SizedBox(width: 6),
                        Text(
                          'PUSH NOTIFICATION DISPATCHED',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AdminCyberTheme.neonEmerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.adminReply!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Reply Input Field & Push Button
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      style:
                          GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type push reply to user...',
                        hintStyle: GoogleFonts.inter(
                          color: AdminCyberTheme.textMuted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AdminCyberTheme.cardSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AdminCyberTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AdminCyberTheme.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AdminCyberTheme.neonCyan,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminCyberTheme.neonCyan,
                      foregroundColor: const Color(0xFF04202C),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final text = replyCtrl.text.trim();
                      if (text.isEmpty) return;

                      await adminService.replyToTicketAndNotifyUser(
                        ticketId: ticket.ticketId,
                        reply: text,
                        userId: ticket.userId,
                        userRole: ticket.userRole,
                        ticketCategory: ticket.category,
                      );

                      replyCtrl.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF04202C),
                            content: Row(
                              children: [
                                const Icon(Icons.send_rounded,
                                    color: AdminCyberTheme.neonCyan, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Push reply sent to ${ticket.userName} 🚀',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Reply',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
