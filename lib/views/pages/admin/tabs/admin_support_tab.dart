import 'package:flutter/material.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

            // Tickets List
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mark_email_read_outlined,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            'Support inbox clear! Zero pending complaints 🚀',
                            style: GoogleFonts.inter(
                              color: AdminCyberTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AdminCyberTheme.neonViolet.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AdminCyberTheme.neonViolet
                : Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.1),
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
    String categoryName = 'Feedback';
    IconData categoryIcon = Icons.chat_bubble_outline_rounded;

    if (ticket.category == 'bug') {
      badgeColor = AdminCyberTheme.neonRose;
      categoryName = '🐛 BUG REPORT';
      categoryIcon = Icons.bug_report_rounded;
    } else if (ticket.category == 'suggestion') {
      badgeColor = AdminCyberTheme.neonViolet;
      categoryName = '💡 FEATURE SUGGESTION';
      categoryIcon = Icons.lightbulb_outline_rounded;
    } else if (ticket.category == 'billing_dispute') {
      badgeColor = AdminCyberTheme.neonAmber;
      categoryName = '💰 BILLING DISPUTE';
      categoryIcon = Icons.receipt_long_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CyberCard(
        glowColor: badgeColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(categoryIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      categoryName,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ticket.status == 'resolved'
                        ? AdminCyberTheme.neonEmerald.withValues(alpha: 0.15)
                        : AdminCyberTheme.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ticket.status == 'resolved'
                          ? AdminCyberTheme.neonEmerald.withValues(alpha: 0.4)
                          : AdminCyberTheme.neonAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ticket.status == 'resolved'
                          ? AdminCyberTheme.neonEmerald
                          : AdminCyberTheme.neonAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // User Info & Device Telemetry
            Text(
              '${ticket.userName} (${ticket.userRole.toUpperCase()}) • 📞 ${ticket.userPhone}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '📱 ${ticket.deviceModel.isNotEmpty ? ticket.deviceModel : 'Unknown Device'} • ${ticket.osVersion} • Build ${ticket.appVersion}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AdminCyberTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // Ticket Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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

            // If already replied, show reply
            if (ticket.adminReply != null &&
                ticket.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AdminCyberTheme.neonEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AdminCyberTheme.neonEmerald.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            size: 14, color: AdminCyberTheme.neonEmerald),
                        const SizedBox(width: 6),
                        Text(
                          'YOUR DISPATCHED PUSH REPLY',
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
              const SizedBox(height: 14),
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
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                                    color: AdminCyberTheme.neonCyan, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Push reply sent to ${ticket.userName} 🚀',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.send_rounded, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'REPLY',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
