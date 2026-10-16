import '../models/app_models.dart';

/// Utilities for calculating and enforcing meal slot and choice group cutoff times.
class CutoffHelper {
  /// Returns the start DateTime for a given slot on a specific date.
  static DateTime getSlotStartTime(DateTime date, String slot, MessModel mess) {
    final timing = mess.mealTimings[slot];
    final startStr = timing?['start'] ?? _defaultSlotTime(slot);
    final parts = startStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 12;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Returns the cutoff DateTime (startTime - cutoffHours) for a given slot.
  static DateTime getSlotCutoffTime(DateTime date, String slot, MessModel mess) {
    final startTime = getSlotStartTime(date, slot, mess);
    return startTime.subtract(Duration(hours: mess.cutoffHours));
  }

  /// Returns true if the cutoff time for the slot on the date has passed.
  static bool isSlotCutoffPassed(DateTime date, String slot, MessModel mess) {
    return DateTime.now().isAfter(getSlotCutoffTime(date, slot, mess));
  }

  /// Choice group freezes at the earliest cutoff time among its available meal slots.
  static DateTime getChoiceGroupCutoffTime(
    DateTime date,
    ChoiceGroupModel group,
    MessModel mess,
  ) {
    DateTime? earliest;
    for (final slot in group.availableMeals) {
      final cutoff = getSlotCutoffTime(date, slot, mess);
      if (earliest == null || cutoff.isBefore(earliest)) {
        earliest = cutoff;
      }
    }
    return earliest ?? DateTime(date.year, date.month, date.day, 6, 0);
  }

  /// Returns true if the unified cutoff for this Choice Group has already passed.
  static bool isChoiceGroupCutoffPassed(
    DateTime date,
    ChoiceGroupModel group,
    MessModel mess,
  ) {
    return DateTime.now().isAfter(getChoiceGroupCutoffTime(date, group, mess));
  }

  static String _defaultSlotTime(String slot) {
    switch (slot) {
      case 'morning':
        return '08:00';
      case 'noon':
        return '12:30';
      case 'evening':
        return '17:00';
      case 'night':
        return '20:00';
      default:
        return '12:00';
    }
  }
}
