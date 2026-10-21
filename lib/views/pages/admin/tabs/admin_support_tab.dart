import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Support & User Feedback Inbox Tab.
/// Redesigned with the exact Executive Dark Luxury Obsidian & Warm Gold aesthetic
/// from Inspired UI (Screenshots 3 & 13).
class AdminSupportTab extends ConsumerStatefulWidget {
  const AdminSupportTab({super.key});

  @override
  ConsumerState<AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends ConsumerState<AdminSupportTab> {
  String _selectedStatus = 'all'; // 'all' | 'open' | 'resolved'
  String _selectedCategory = 'all'; // 'all' | 'bug' | 'suggestion' | 'mess' | 'billing_dispute'
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void dispose() {
    for (final ctrl in _replyControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _getReplyCtrl(String ticketId) {
    return _replyControllers.putIfAbsent(ticketId, () => TextEditingController());
  }

  void _showTicketDetailSheet(
      BuildContext context, SupportTicketModel ticket, AdminService adminService) {
    final replyCtrl = _getReplyCtrl(ticket.ticketId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isResolved = ticket.status == 'resolved';

          String categoryLabel = 'Suggestion';
          if (ticket.category == 'bug') categoryLabel = 'Bug report';
          if (ticket.category == 'mess') categoryLabel = 'Mess issue';
          if (ticket.category == 'billing_dispute') categoryLabel = 'Bill dispute';

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFF16120E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0xFF382F25), width: 1.5),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Top Bar Tags
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2217),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF4A3824)),
                          ),
                          child: Text(
                            categoryLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdminCyberTheme.neonAmber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFF1E2F22)
                                : const Color(0xFF382B1C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isResolved
                                  ? const Color(0xFF33573A)
                                  : const Color(0xFF5A442A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? const Color(0xFF6EAE7A)
                                      : const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isResolved ? 'Resolved' : 'Open',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isResolved
                                      ? const Color(0xFF6EAE7A)
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User & Message Card
                    CyberCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${ticket.userRole == 'owner' ? 'Mess owner' : 'Student'} • ${ticket.userName}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFAF7F2),
                                ),
                              ),
                              Text(
                                '${ticket.createdAt.day}/${ticket.createdAt.month}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AdminCyberTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ticket.message,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AdminCyberTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildPillAction('Assign to me', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ticket assigned to you')),
                                );
                              }),
                              if (ticket.userPhone.isNotEmpty)
                                _buildPillAction(ticket.userPhone, () {
                                  Clipboard.setData(ClipboardData(text: ticket.userPhone));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied user phone')),
                                  );
                                }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reply Text Field
                    TextField(
                      controller: replyCtrl,
                      maxLines: 4,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Reply...',
                        hintStyle: GoogleFonts.inter(
                          color: AdminCyberTheme.textMuted,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF14110E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2E261E)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2E261E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Templates + Send Reply Row
                    Row(
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Reply Templates',
                          color: const Color(0xFF221C16),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFF382F25)),
                          ),
                          onSelected: (template) {
                            replyCtrl.text = template;
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'Thank you for reaching out! We are currently looking into this.',
                              child: Text('Under Investigation', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                            const PopupMenuItem(
                              value: 'We have applied the resolution to your account. Please restart the app.',
                              child: Text('Issue Resolved', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                            const PopupMenuItem(
                              value: 'Could you please provide your registered phone number and mess code?',
                              child: Text('Need More Info', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF221C16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF382F25)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Templates ▼',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFAF7F2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF140F09),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              final text = replyCtrl.text.trim();
                              if (text.isEmpty) return;
                              await adminService.replyToTicket(
                                ticketId: ticket.ticketId,
                                replyMessage: text,
                              );
                              replyCtrl.clear();
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reply sent directly to user! 📨'),
                                    backgroundColor: Color(0xFF1B1612),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Send reply',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mark Resolved / Reopen Full Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isResolved
                              ? const Color(0xFF241D17)
                              : const Color(0xFF324B36),
                          foregroundColor: const Color(0xFFFAF7F2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isResolved
                                  ? const Color(0xFF382F25)
                                  : const Color(0xFF456B4A),
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final nextStatus = isResolved ? 'open' : 'resolved';
                          await adminService.updateTicketStatus(
                            ticket.ticketId,
                            nextStatus,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isResolved
                                    ? 'Ticket re-opened'
                                    : 'Ticket marked resolved! ✓'),
                                backgroundColor: const Color(0xFF1B1612),
                              ),
                            );
                          }
                        },
                        child: Text(
                          isResolved ? 'Re-open ticket' : 'Mark resolved',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillAction(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF221C16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF382F25)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AdminCyberTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);

    return StreamBuilder<List<SupportTicketModel>>(
      stream: adminService.streamSupportTickets(
        statusFilter: _selectedStatus == 'all' ? null : _selectedStatus,
      ),
      builder: (context, snapshot) {
        final allTickets = snapshot.data ?? [];

        // Category filter
        final tickets = allTickets.where((t) {
          if (_selectedCategory == 'all') return true;
          return t.category == _selectedCategory;
        }).toList();

        final openCount = allTickets.where((t) => t.status == 'open').length;
        final resolvedCount = allTickets.where((t) => t.status == 'resolved').length;

        return Column(
          children: [
            // Top Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                children: [
                  // Row 1: Status Chips
                  Row(
                    children: [
                      _buildStatusPill('All tickets', 'all', allTickets.length),
                      const SizedBox(width: 8),
                      _buildStatusPill('Open', 'open', openCount),
                      const SizedBox(width: 8),
                      _buildStatusPill('Resolved', 'resolved', resolvedCount),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryPill('Bug report', 'bug'),
                        const SizedBox(width: 8),
                        _buildCategoryPill('Suggestion', 'suggestion'),
                        const SizedBox(width: 8),
                        _buildCategoryPill('Mess issue', 'mess'),
                        const SizedBox(width: 8),
                        _buildCategoryPill('Bill dispute', 'billing_dispute'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tickets List or Empty Inbox
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                color: Color(0xFF384D3B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.all_inbox_rounded,
                                size: 38,
                                color: Color(0xFFE8F0E9),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Support inbox clear',
                              textAlign: TextAlign.center,
                              style: AdminCyberTheme.serifTitle(fontSize: 25),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Zero pending complaints or suggestions.\nAll live tickets are up to date.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AdminCyberTheme.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return _buildTicketSummaryCard(ticket, adminService);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusPill(String label, String value, int count) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF221C16),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF382F25), width: 1.0),
        ),
        child: Text(
          '$label $count',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF140F09) : const Color(0xFFFAF7F2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label, String value) {
    final isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? 'all' : value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF382B1C) : const Color(0xFF221C16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF382F25),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AdminCyberTheme.neonAmber : const Color(0xFFFAF7F2),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketSummaryCard(
      SupportTicketModel ticket, AdminService adminService) {
    final isResolved = ticket.status == 'resolved';

    String categoryLabel = 'Suggestion';
    if (ticket.category == 'bug') categoryLabel = 'Bug report';
    if (ticket.category == 'mess') categoryLabel = 'Mess issue';
    if (ticket.category == 'billing_dispute') categoryLabel = 'Bill dispute';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        onTap: () => _showTicketDetailSheet(context, ticket, adminService),
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2217),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AdminCyberTheme.neonAmber,
                    ),
                  ),
                ),
                Text(
                  isResolved ? '✓ Resolved' : '• Open',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isResolved ? const Color(0xFF6EAE7A) : AdminCyberTheme.neonAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${ticket.userRole == 'owner' ? 'Mess owner' : 'Student'} • ${ticket.userName}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAF7F2),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AdminCyberTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ticket.createdAt.day}/${ticket.createdAt.month} • Tap to view & reply',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AdminCyberTheme.textMuted,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF7A7067),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
