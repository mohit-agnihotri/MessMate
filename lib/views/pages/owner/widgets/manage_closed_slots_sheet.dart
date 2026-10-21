import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/owner_inspired_theme.dart';
import 'schedule_closure_dialog.dart';

void showManageClosedSlotsSheet(
  BuildContext context, {
  required MessModel mess,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ManageClosedSlotsSheet(mess: mess),
  );
}

class ManageClosedSlotsSheet extends ConsumerStatefulWidget {
  final MessModel mess;

  const ManageClosedSlotsSheet({
    super.key,
    required this.mess,
  });

  @override
  ConsumerState<ManageClosedSlotsSheet> createState() =>
      _ManageClosedSlotsSheetState();
}

class _ManageClosedSlotsSheetState
    extends ConsumerState<ManageClosedSlotsSheet> {
  final Map<String, String> _slotNames = {
    'morning': 'Breakfast',
    'noon': 'Lunch',
    'evening': 'Snacks',
    'night': 'Dinner',
  };

  final Map<String, IconData> _slotIcons = {
    'morning': Icons.wb_twilight_rounded,
    'noon': Icons.wb_sunny_rounded,
    'evening': Icons.coffee_rounded,
    'night': Icons.nightlight_round,
  };

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final diff = d.difference(today).inDays;

        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        final pretty =
            '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
        if (diff == 0) return 'Today · $pretty';
        if (diff == 1) return 'Tomorrow · $pretty';
        return pretty;
      }
    } catch (_) {}
    return dateStr;
  }

  Future<void> _handleReopenSlot(String date, String slot) async {
    final slotTitle = _slotNames[slot] ?? slot.toUpperCase();
    final dateTitle = _formatDate(date);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwnerColors.surfaceWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Re-open $slotTitle?',
          style: OwnerTypography.serifHeading(fontSize: 20),
        ),
        content: Text(
          'This will open $slotTitle on $dateTitle for all students. Refund deduction for this meal will be removed.',
          style: OwnerTypography.body(fontSize: 13, color: OwnerColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: OwnerColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Re-open Meal',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      await ref
          .read(ownerDashboardProvider.notifier)
          .reopenSpecificSlot(date, slot);

      messenger?.showSnackBar(
        SnackBar(
          content: Text('🎉 $slotTitle on $date is now open for service!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _handleReopenAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwnerColors.surfaceWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF16A34A),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Re-open Mess?',
              style: OwnerTypography.serifHeading(fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'This will cancel active schedule closures, open your mess for service immediately, and notify all active students.',
          style: OwnerTypography.body(fontSize: 13, color: OwnerColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: OwnerColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Re-open Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final nav = Navigator.of(context);

      try {
        await ref
            .read(ownerDashboardProvider.notifier)
            .reopenMess(widget.mess.messId);

        if (mounted) nav.pop();

        messenger?.showSnackBar(
          const SnackBar(
            content: Text('🎉 Mess is now open for service! Students notified.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } catch (e) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text('Failed to re-open: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(ownerDashboardProvider);
    final closedSlots = dashboardState.closedSlots;
    final mess = dashboardState.mess ?? widget.mess;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: OwnerColors.surfaceWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Closures',
                      style: OwnerTypography.serifHeading(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active & scheduled meal off slots',
                      style: OwnerTypography.body(
                        fontSize: 12,
                        color: OwnerColors.textMuted,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: OwnerColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content scrollable
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Info Summary Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFC2410C),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mess.isClosureUpcoming
                                  ? 'Upcoming Closure Scheduled'
                                  : 'Mess Currently Closed',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9A3412),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap "Re-open" on any individual meal to start serving that slot. Students will be notified instantly and billing refunds will adjust automatically.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF9A3412),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Closed Slots List
                if (closedSlots.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No closed meal slots!',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your mess is open for all upcoming meals.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: OwnerColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'CLOSED SLOTS (${closedSlots.length})',
                    style: OwnerTypography.overline(
                      fontSize: 11,
                      color: OwnerColors.textOverline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...closedSlots.map((slotData) {
                    final date = slotData['date'] as String? ?? '';
                    final slot = slotData['mealSlot'] as String? ?? '';
                    final slotName = _slotNames[slot] ?? slot.toUpperCase();
                    final icon = _slotIcons[slot] ?? Icons.restaurant_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: OwnerColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      slotName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: OwnerColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Closed',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(date),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: OwnerColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _handleReopenSlot(date, slot),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFDCFCE7),
                              foregroundColor: const Color(0xFF15803D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 15, color: Color(0xFF15803D)),
                                const SizedBox(width: 4),
                                Text(
                                  'Re-open',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showScheduleClosureDialog(context, null, mess: mess);
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 17),
                    label: const Text('Extend / Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OwnerColors.textDark,
                      side: const BorderSide(color: OwnerColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleReopenAll,
                    icon: const Icon(Icons.storefront_rounded, size: 17),
                    label: const Text('Re-open All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
