import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/owner_inspired_theme.dart';

void showScheduleClosureDialog(
  BuildContext context,
  WidgetRef? ref, {
  MessModel? mess,
}) {
  showDialog(
    context: context,
    builder: (_) => ScheduleClosureDialog(mess: mess),
  );
}

void showReopenMessDialog(
  BuildContext context,
  WidgetRef? ref, {
  required String messId,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Consumer(
      builder: (dialogCtx, dialogRef, _) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: OwnerColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              final activeRef = ref ?? dialogRef;
              Navigator.pop(ctx);
              try {
                await activeRef.read(ownerDashboardProvider.notifier).reopenMess(messId);
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Mess is now open for service! Students notified.'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              } catch (e) {
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text('Failed to re-open mess: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
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
    ),
  );
}

class ScheduleClosureDialog extends ConsumerStatefulWidget {
  final WidgetRef? ref;
  final MessModel? mess;

  const ScheduleClosureDialog({
    super.key,
    this.ref,
    this.mess,
  });

  @override
  ConsumerState<ScheduleClosureDialog> createState() => _ScheduleClosureDialogState();
}

class _ScheduleClosureDialogState extends ConsumerState<ScheduleClosureDialog> {
  late DateTime _startDate;
  late String _startSlot;
  late DateTime _endDate;
  late String _endSlot;
  bool _isLoading = false;

  final List<String> _slots = ['morning', 'noon', 'evening', 'night'];

  final Map<String, String> _slotNames = {
    'morning': 'Breakfast',
    'noon': 'Lunch',
    'evening': 'Snacks',
    'night': 'Dinner',
  };

  @override
  void initState() {
    super.initState();
    final m = widget.mess;
    if (m != null && m.hasScheduledClosure) {
      _startDate = m.closureStartDate ?? DateTime.now();
      _startSlot = m.closureStartSlot ?? 'morning';
      _endDate = m.temporarilyClosedUntil ?? DateTime.now();
      _endSlot = m.closureEndSlot ?? 'night';
    } else {
      _startDate = DateTime.now();
      _startSlot = 'morning';
      _endDate = DateTime.now();
      _endSlot = 'night';
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: OwnerColors.amber),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = date;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  Widget _buildDatePickerBtn(DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OwnerColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OwnerColors.textDark,
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: OwnerColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, bool isStart) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwnerColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: OwnerColors.textMuted),
          items: _slots
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    _slotNames[s] ?? s.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (isStart) {
                  _startSlot = val;
                } else {
                  _endSlot = val;
                }
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: OwnerColors.surfaceWarm,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFC2410C),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Schedule closure',
            style: OwnerTypography.serifHeading(fontSize: 20),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'START CLOSING FROM',
              style: OwnerTypography.overline(color: OwnerColors.textOverline),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildDatePickerBtn(_startDate, true)),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown(_startSlot, true)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'CLOSED UNTIL (INCLUSIVE)',
              style: OwnerTypography.overline(color: OwnerColors.textOverline),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildDatePickerBtn(_endDate, false)),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown(_endSlot, false)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFC2410C),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Closes selected meal slots between these dates, notifies students, and automatically records refund deductions.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF9A3412),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: OwnerColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ref
                        .read(ownerDashboardProvider.notifier)
                        .emergencyClose(
                          _startDate,
                          _startSlot,
                          _endDate,
                          _endSlot,
                          "Scheduled Closure",
                        );
                    if (context.mounted) {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      Navigator.pop(context);
                      messenger?.showSnackBar(
                        const SnackBar(
                          content: Text('Mess closure scheduled successfully. Students notified.'),
                          backgroundColor: Color(0xFFC2410C),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error scheduling closure: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC2410C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Confirm closure',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
