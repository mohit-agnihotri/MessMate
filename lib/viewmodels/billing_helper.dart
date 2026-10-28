import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

/// Checks if a specific meal slot is part of the student's active plan/choice for a date.
bool isSlotActiveForStudent(
  StudentModel student,
  MealPlanModel? plan,
  MessModel mess,
  String slot,
  DateTime date,
) {
  // 0. Special Day Schedule Override:
  const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final dayName = dayNames[date.weekday - 1];
  final isSpecialDay =
      mess.specialMealEnabled && mess.specialMealDays.contains(dayName);

  if (isSpecialDay) {
    // Designated Special Feast is universally active for all enrolled students
    if (mess.specialMealSlot == slot) {
      return true;
    }
    // Slots not cooked on special days per owner schedule are inactive
    if (!mess.specialMealCookedSlots.contains(slot)) {
      return false;
    }
  }

  if (plan == null) {
    return mess.mealTimings[slot]?['enabled'] == 'true';
  }

  // Fixed meals are always active
  if (plan.fixedMeals.contains(slot)) {
    return true;
  }

  // Choice Groups: check date-specific override or regular preference
  final dateKey =
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  for (final group in plan.choiceGroups) {
    if (group.availableMeals.contains(slot)) {
      // 1. Date override takes priority
      final dateOverride = student.datePreferences[dateKey]?[group.groupId];
      if (dateOverride != null) {
        return dateOverride == slot;
      }

      // 2. Regular preference fallback
      final regularPref = student.regularMealPreference[group.groupId];
      if (regularPref != null) {
        return regularPref == slot;
      }

      // 3. Default to first available meal in the group
      return group.availableMeals.isNotEmpty &&
          group.availableMeals.first == slot;
    }
  }

  return false;
}

/// Checks if a specific date and slot is covered by an approved leave.
bool isSlotCoveredByLeave(
  LeaveModel leave,
  DateTime date,
  String slot,
) {
  if (leave.status != 'active') return false;

  final d = DateTime(date.year, date.month, date.day);
  final start =
      DateTime(leave.startDate.year, leave.startDate.month, leave.startDate.day);
  final end =
      DateTime(leave.endDate.year, leave.endDate.month, leave.endDate.day);

  if (d.isBefore(start) || d.isAfter(end)) return false;

  const slotOrder = ['morning', 'noon', 'evening', 'night'];
  final slotIdx = slotOrder.indexOf(slot);
  if (slotIdx == -1) return true;

  if (d.isAtSameMomentAs(start)) {
    final startIdx =
        leave.startSlot != null ? slotOrder.indexOf(leave.startSlot!) : 0;
    if (slotIdx < startIdx) return false;
  }

  if (d.isAtSameMomentAs(end)) {
    final endIdx = leave.endSlot != null
        ? slotOrder.indexOf(leave.endSlot!)
        : slotOrder.length - 1;
    if (slotIdx > endIdx) return false;
  }

  return true;
}

String _getMonthAbbr(int month) {
  const abbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  if (month >= 1 && month <= 12) return abbr[month - 1];
  return '';
}

/// Represents the live count and monetary value of meal skips logged in the current billing cycle.
class CurrentMonthSkipsSummary {
  final int count;
  final double amount;
  const CurrentMonthSkipsSummary({this.count = 0, this.amount = 0.0});
}

/// Computes the exact real-time meal skips count and monetary value for a student in a month.
/// Works directly from live attendance records and active leaves even if a bill was previously saved.
CurrentMonthSkipsSummary calculateCurrentMonthSkipsSummary({
  required List<MealRecordModel> records,
  required List<LeaveModel> leaves,
  required StudentModel student,
  required MessModel mess,
  MealPlanModel? plan,
  required int month,
  required int year,
}) {
  final int totalDays = DateTime(year, month + 1, 0).day;
  final double baseFee = plan?.monthlyFee ?? mess.monthlyFee;
  final int allowedMeals =
      plan != null ? plan.mealsIncludedPerDay : mess.mealsIncludedPerDay;
  final double ownerSetRate =
      (plan?.deductionPolicy.policyType == 'flat_fixed_rate' &&
              (plan?.deductionPolicy.flatRate ?? 0) > 0)
          ? plan!.deductionPolicy.flatRate!
          : (mess.perMealRate > 0 ? mess.perMealRate : 0.0);
  final double dynamicPerMealRate = (allowedMeals > 0 && totalDays > 0)
      ? (baseFee / (totalDays * allowedMeals))
      : 0.0;
  final double effectiveStudentRebateRate = !mess.allowMealSkipping
      ? 0.0
      : (ownerSetRate > 0 ? ownerSetRate : dynamicPerMealRate);

  Map<int, List<MealRecordModel>> dailyRecords = {};
  for (var r in records) {
    dailyRecords.putIfAbsent(r.date.day, () => []).add(r);
  }

  int count = 0;
  double amount = 0.0;

  for (int day = 1; day <= totalDays; day++) {
    final currentDate = DateTime(year, month, day);
    if (student.joinDate.year == year &&
        student.joinDate.month == month &&
        day < student.joinDate.day) {
      continue;
    }

    var dayRecs = dailyRecords[day] ?? [];
    Map<String, MealRecordModel> skippedSlotMap = {};

    for (var r in dayRecs) {
      if (r.status == 'absent_owner') {
        skippedSlotMap[r.mealSlot] = r;
      } else if (r.status == 'absent_self') {
        if (!skippedSlotMap.containsKey(r.mealSlot) ||
            skippedSlotMap[r.mealSlot]?.status != 'absent_owner') {
          skippedSlotMap[r.mealSlot] = r;
        }
      }
    }

    for (var leave in leaves) {
      for (var slot in ['morning', 'noon', 'evening', 'night']) {
        if (isSlotCoveredByLeave(leave, currentDate, slot)) {
          if (!skippedSlotMap.containsKey(slot) &&
              isSlotActiveForStudent(student, plan, mess, slot, currentDate)) {
            skippedSlotMap[slot] = MealRecordModel(
              recordId: 'leave_${leave.leaveId}_${day}_$slot',
              studentId: student.studentId,
              messId: mess.messId,
              date: currentDate,
              mealSlot: slot,
              status: 'absent_self',
            );
          }
        }
      }
    }

    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = dayNames[currentDate.weekday - 1];
    final isSpecialDay =
        mess.specialMealEnabled && mess.specialMealDays.contains(dayName);

    for (var entry in skippedSlotMap.entries) {
      final r = entry.value;
      if (isSlotActiveForStudent(student, plan, mess, r.mealSlot, currentDate)) {
        final isSpecial = isSpecialDay &&
            (r.isSpecial || mess.specialMealSlot == r.mealSlot);
        final int feastExtendCount = mess.specialMealExtendMeals > 0
            ? mess.specialMealExtendMeals
            : (mess.specialMealMultiplier.round().clamp(1, 4));
        final double defaultSpecialRate = (mess.specialMealFlatRate != null &&
                mess.specialMealFlatRate! > 0)
            ? mess.specialMealFlatRate!
            : (effectiveStudentRebateRate * feastExtendCount);
        final double standardRate =
            isSpecial ? defaultSpecialRate : effectiveStudentRebateRate;
        final double skipCost = r.cost ?? standardRate;

        count++;
        amount += skipCost;
      }
    }
  }

  return CurrentMonthSkipsSummary(count: count, amount: amount);
}

/// Generates the advance monthly bill with precise calculations for base fees,
/// prorated discounts for mid-month joiners, leaves, extra meals, guest meals, extra fees,
/// and retrospective carry-forward skips compensation from the prior month.
BillModel generateAdvancedBill({
  required StudentModel student,
  required MessModel mess,
  MealPlanModel? plan,
  required int month,
  required int year,
  required List<MealRecordModel> records,
  required double previousDues,
  String compensationChoice = 'rebate',
  List<ExtraFeeModel> extraFees = const [],
  List<LeaveModel> leaves = const [],
  DateTime? priorSubscriptionEndDate,
  CarryForwardResult? carryForwardResult,
  double carryForwardCredit = 0.0,
  List<DeductionItem> carryForwardItems = const [],
}) {
  double extraMealsAddon = 0.0;
  double guestAddons = 0.0;
  double extraFeesAddon = 0.0;
  double proratedDiscount = 0.0;
  List<DeductionItem> items = [];

  // Effective base fee and allowed meals from plan or mess defaults
  final double baseFee = plan?.monthlyFee ?? mess.monthlyFee;
  final int allowedMeals = plan != null
      ? plan.mealsIncludedPerDay
      : mess.mealsIncludedPerDay;

  // Priority: If owner configured a per-meal rate, compute daily rate cleanly from it
  // (e.g. 2 meals/day * ₹45 = ₹90/day) with zero month-length dividing fractions
  final double ownerSetRate = (plan?.deductionPolicy.policyType == 'flat_fixed_rate' &&
          (plan?.deductionPolicy.flatRate ?? 0) > 0)
      ? plan!.deductionPolicy.flatRate!
      : (mess.perMealRate > 0 ? mess.perMealRate : 0.0);

  final double ownerDailyRate = ownerSetRate > 0 && allowedMeals > 0
      ? (ownerSetRate * allowedMeals)
      : 0.0;

  // Calculate total days in the specified month (fallback if no owner rate set)
  final totalDays = DateTime(year, month + 1, 0).day;
  final double dailyRate = ownerDailyRate > 0
      ? ownerDailyRate
      : (totalDays > 0 ? (baseFee / totalDays) : 0.0);

  // 1. Calculate prorated discount if joined mid-month
  if (student.joinDate.year == year &&
      student.joinDate.month == month &&
      student.joinDate.day > 1) {
    int missingDays = student.joinDate.day - 1;
    proratedDiscount = missingDays * dailyRate;
    items.add(
      DeductionItem(
        date: DateTime(year, month, student.joinDate.day),
        mealSlot: 'Joined Late (${student.joinDate.day} ${_getMonthAbbr(month)})',
        type: 'prorated_discount',
        amount: -proratedDiscount,
      ),
    );
  }

  // 1b. Check if prior subscription was extended into this month (prevent double-charging)
  final effectivePriorEnd = priorSubscriptionEndDate ?? student.subscriptionEndDate;
  if (effectivePriorEnd != null &&
      effectivePriorEnd.year == year &&
      effectivePriorEnd.month == month &&
      effectivePriorEnd.day >= 1 &&
      student.joinDate.isBefore(DateTime(year, month, 1))) {
    // Days from 1 up to effectivePriorEnd.day were covered by previous validity extension
    int extendedDaysInMonth = min(effectivePriorEnd.day, totalDays);
    if (extendedDaysInMonth > 0 && proratedDiscount == 0.0) {
      proratedDiscount = extendedDaysInMonth * dailyRate;
      items.add(
        DeductionItem(
          date: DateTime(year, month, 1),
          mealSlot: 'Extended Subscription Credit ($extendedDaysInMonth days)',
          type: 'prorated_discount',
          amount: -proratedDiscount,
        ),
      );
    }
  }

  // Fallback dynamic per-meal rebate rate
  final double dynamicPerMealRate = (allowedMeals > 0 && totalDays > 0)
      ? (baseFee / (totalDays * allowedMeals))
      : 0.0;

  final double effectiveStudentRebateRate = !mess.allowMealSkipping
      ? 0.0
      : (ownerSetRate > 0 ? ownerSetRate : dynamicPerMealRate);

  // 2. Track current month's live activity
  // Group records by day
  Map<int, List<MealRecordModel>> dailyRecords = {};
  for (var r in records) {
    dailyRecords.putIfAbsent(r.date.day, () => []).add(r);
  }

  // Process live current month skips dynamically
  final currentSkipsSummary = calculateCurrentMonthSkipsSummary(
    records: records,
    leaves: leaves,
    student: student,
    mess: mess,
    plan: plan,
    month: month,
    year: year,
  );
  int currentMonthSkipsCount = currentSkipsSummary.count;
  double currentMonthSkipsAmount = currentSkipsSummary.amount;

  // Process days in current month: Add-ons (guest/extra meals)
  for (int day = 1; day <= totalDays; day++) {
    var dayRecs = dailyRecords[day] ?? [];
    for (var r in dayRecs) {
      if (r.status == 'guest') {
        double guestCost = r.cost ?? mess.perMealRate;
        guestAddons += guestCost;
        items.add(
          DeductionItem(
            date: r.date,
            mealSlot: r.mealSlot,
            type: 'guest',
            amount: guestCost,
          ),
        );
      } else if (r.status == 'extra_meal') {
        double extraAmt = r.cost ?? (plan?.extraMealRate ?? mess.perMealRate);
        extraMealsAddon += extraAmt;
        items.add(
          DeductionItem(
            date: r.date,
            mealSlot: r.mealSlot,
            type: 'extra_meal',
            amount: extraAmt,
          ),
        );
      }
    }
  }

  // 3. Extra Fees
  for (var fee in extraFees) {
    if (fee.targetBillingMonth == month && fee.targetBillingYear == year) {
      extraFeesAddon += fee.amount;
      items.add(
        DeductionItem(
          date: fee.originalDate,
          mealSlot: fee.note.isNotEmpty ? fee.note : 'Extra Fee',
          type: 'extra_fee',
          amount: fee.amount,
        ),
      );
    }
  }

  // 4. Retrospective Skips Compensation (from Prior Month Carry Forward)
  final int totalPriorValidSkips = carryForwardResult != null
      ? carryForwardResult.totalValidSkips
      : (carryForwardCredit > 0 && effectiveStudentRebateRate > 0
          ? (carryForwardCredit / effectiveStudentRebateRate).round()
          : 0);

  final double priorCreditAmount =
      carryForwardResult != null ? carryForwardResult.amount : carryForwardCredit;

  final int normalSkipsCount = carryForwardResult?.normalSkipsCount ??
      (carryForwardResult == null ? totalPriorValidSkips : 0);
  final double normalSkipsDeduction = carryForwardResult?.normalSkipsDeduction ??
      (carryForwardResult == null ? priorCreditAmount : 0.0);
  final int specialSkipsCount = carryForwardResult?.specialSkipsCount ?? 0;
  final double specialSkipsDeduction =
      carryForwardResult?.specialSkipsDeduction ?? 0.0;
  final List<DeductionItem> priorItems =
      carryForwardResult?.items ?? carryForwardItems;

  double skipsDeduction = 0.0;
  int daysToExtend = 0;

  if (compensationChoice == 'extend') {
    if (allowedMeals > 0 && totalPriorValidSkips > 0) {
      daysToExtend = totalPriorValidSkips ~/ allowedMeals;
      int remainderSkips = totalPriorValidSkips % allowedMeals;

      // Odd leftover skips receive a cash rebate so student loses zero value
      if (remainderSkips > 0 && effectiveStudentRebateRate > 0) {
        double remainderAmt = remainderSkips * effectiveStudentRebateRate;
        skipsDeduction = remainderAmt;
        items.add(
          DeductionItem(
            date: DateTime(year, month, 1),
            mealSlot:
                'Odd Skips Rebate ($remainderSkips meal${remainderSkips > 1 ? "s" : ""})',
            type: 'carry_forward',
            amount: -remainderAmt,
          ),
        );
      }
    }
  } else {
    // compensationChoice == 'rebate'
    daysToExtend = 0;
    skipsDeduction = priorCreditAmount;

    if (priorItems.isNotEmpty) {
      items.addAll(priorItems);
    } else if (priorCreditAmount > 0) {
      int prevMonth = month - 1;
      if (prevMonth < 1) prevMonth = 12;
      final prevMonthName = _getMonthAbbr(prevMonth);

      items.add(
        DeductionItem(
          date: DateTime(year, month, 1),
          mealSlot: '$prevMonthName Skips Credit (Carry Forward)',
          type: 'carry_forward',
          amount: -priorCreditAmount,
        ),
      );
    }
  }

  // Financial Sanity Guard: Skips deduction cannot exceed monthly baseFee
  if (skipsDeduction > baseFee) {
    skipsDeduction = baseFee;
  }

  // 5. Calculate Final Payable
  double calculatedTotal = baseFee -
      proratedDiscount -
      skipsDeduction +
      extraMealsAddon +
      guestAddons +
      extraFeesAddon +
      previousDues;

  double finalPayable = calculatedTotal;
  double excessCredit = 0.0;
  bool autoSettled = false;
  bool isPaid = false;

  // Zero-Bill Auto-Settlement
  if (finalPayable <= 0.0) {
    autoSettled = true;
    isPaid = true;
    if (finalPayable < 0.0) {
      excessCredit = -finalPayable;
      finalPayable = 0.0;
    } else {
      finalPayable = 0.0;
    }
  }

  return BillModel(
    billId: 'preview',
    studentId: student.studentId,
    messId: mess.messId,
    month: month,
    year: year,
    baseFee: baseFee,
    proratedDiscount: proratedDiscount,
    totalDeductions: skipsDeduction,
    extraMealsAddon: extraMealsAddon,
    guestAddons: guestAddons,
    extraFeesAddon: extraFeesAddon,
    finalPayable: finalPayable,
    excessCreditGenerated: excessCredit,
    previousDues: previousDues,
    isPaid: isPaid,
    autoSettled: autoSettled,
    validSkipsRewarded: totalPriorValidSkips,
    daysToExtend: daysToExtend,
    planId: plan?.planId,
    planName: plan?.name,
    deductions: items,
    normalSkipsCount: normalSkipsCount,
    normalSkipsDeduction: normalSkipsDeduction,
    specialSkipsCount: specialSkipsCount,
    specialSkipsDeduction: specialSkipsDeduction,
    carryForwardCredit: skipsDeduction,
    currentMonthSkipsCount: currentMonthSkipsCount,
    currentMonthSkipsAmount: currentMonthSkipsAmount,
  );
}

/// Result container for carry forward skips from previous paid months
class CarryForwardResult {
  final double amount;
  final int skipCount;
  final List<DeductionItem> items;
  final int normalSkipsCount;
  final double normalSkipsDeduction;
  final int specialSkipsCount;
  final double specialSkipsDeduction;
  final int ownerClosureCount;
  final double ownerClosureDeduction;
  final int totalValidSkips;

  const CarryForwardResult({
    this.amount = 0.0,
    this.skipCount = 0,
    this.items = const [],
    this.normalSkipsCount = 0,
    this.normalSkipsDeduction = 0.0,
    this.specialSkipsCount = 0,
    this.specialSkipsDeduction = 0.0,
    this.ownerClosureCount = 0,
    this.ownerClosureDeduction = 0.0,
    this.totalValidSkips = 0,
  });
}

/// Calculates uncredited skips and owner closures from previous months
/// that are to be credited retrospectively into the advance bill.
Future<CarryForwardResult> calculateCarryForwardCredit({
  required String studentId,
  required int currentMonth,
  required int currentYear,
  required dynamic service,
  required MessModel mess,
  MealPlanModel? plan,
}) async {
  try {
    int prevMonth = currentMonth - 1;
    int prevYear = currentYear;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear = currentYear - 1;
    }

    // 1. Get the previous month's bill
    final BillModel? prevBill =
        await service.getBill(studentId, prevMonth, prevYear);

    // 2. Fetch the actual meal records of that previous month
    final List<MealRecordModel> prevRecords =
        await service.getMealRecords(studentId, prevMonth, prevYear);

    if (prevRecords.isEmpty &&
        (prevBill == null || prevBill.excessCreditGenerated <= 0)) {
      return const CarryForwardResult();
    }

    // 3. Calculate full deductions for all skips in that month
    final double baseFee = plan?.monthlyFee ?? mess.monthlyFee;
    final int allowedMeals =
        plan != null ? plan.mealsIncludedPerDay : mess.mealsIncludedPerDay;
    final double ownerSetRate =
        (plan?.deductionPolicy.policyType == 'flat_fixed_rate' &&
                (plan?.deductionPolicy.flatRate ?? 0) > 0)
            ? plan!.deductionPolicy.flatRate!
            : (mess.perMealRate > 0 ? mess.perMealRate : 0.0);
    final totalDaysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
    final double dynamicPerMealRate =
        (allowedMeals > 0 && totalDaysInPrevMonth > 0)
            ? (baseFee / (totalDaysInPrevMonth * allowedMeals))
            : 0.0;
    final double effectiveRate = !mess.allowMealSkipping
        ? 0.0
        : (ownerSetRate > 0 ? ownerSetRate : dynamicPerMealRate);

    final prevMonthName = _getMonthAbbr(prevMonth);
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];

    int normalSkipsCount = 0;
    double normalSkipsDeduction = 0.0;
    int specialSkipsCount = 0;
    double specialSkipsDeduction = 0.0;
    int ownerClosureCount = 0;
    double ownerClosureDeduction = 0.0;
    int totalValidSkips = 0;
    List<DeductionItem> carriedItems = [];

    // Group previous records by day
    Map<int, List<MealRecordModel>> dailyRecords = {};
    for (var r in prevRecords) {
      dailyRecords.putIfAbsent(r.date.day, () => []).add(r);
    }

    for (int day = 1; day <= totalDaysInPrevMonth; day++) {
      var dayRecs = dailyRecords[day] ?? [];
      final currentDate = DateTime(prevYear, prevMonth, day);
      final dayName = dayNames[currentDate.weekday - 1];
      final isSpecialDay =
          mess.specialMealEnabled && mess.specialMealDays.contains(dayName);

      // Deduplicate slots for this day: absent_owner takes precedence over absent_self
      Map<String, MealRecordModel> skippedSlotMap = {};
      for (var r in dayRecs) {
        if (r.status == 'absent_owner') {
          skippedSlotMap[r.mealSlot] = r;
        } else if (r.status == 'absent_self') {
          if (!skippedSlotMap.containsKey(r.mealSlot) ||
              skippedSlotMap[r.mealSlot]?.status != 'absent_owner') {
            skippedSlotMap[r.mealSlot] = r;
          }
        }
      }

      for (var entry in skippedSlotMap.entries) {
        final r = entry.value;
        final isSpecial = isSpecialDay &&
            (r.isSpecial || mess.specialMealSlot == r.mealSlot);
        final int feastExtendCount = mess.specialMealExtendMeals > 0
            ? mess.specialMealExtendMeals
            : (mess.specialMealMultiplier.round().clamp(1, 4));
        final double defaultSpecialRate =
            (mess.specialMealFlatRate != null && mess.specialMealFlatRate! > 0)
                ? mess.specialMealFlatRate!
                : (effectiveRate * feastExtendCount);
        final double standardRate =
            isSpecial ? defaultSpecialRate : effectiveRate;
        final double skipCost = r.cost ?? standardRate;

        if (r.status == 'absent_owner') {
          ownerClosureCount++;
          ownerClosureDeduction += skipCost;
          totalValidSkips += (isSpecial ? feastExtendCount : 1);
          carriedItems.add(
            DeductionItem(
              date: r.date,
              mealSlot: isSpecial
                  ? '$prevMonthName Special Feast Closed (${r.mealSlot})'
                  : '$prevMonthName Mess Closed (${r.mealSlot})',
              type: 'carry_forward',
              amount: -skipCost,
            ),
          );
        } else if (r.status == 'absent_self') {
          if (isSpecial) {
            specialSkipsCount++;
            specialSkipsDeduction += skipCost;
            totalValidSkips += feastExtendCount;
            carriedItems.add(
              DeductionItem(
                date: r.date,
                mealSlot: '$prevMonthName Special Feast Skip (${r.mealSlot})',
                type: 'carry_forward',
                amount: -skipCost,
              ),
            );
          } else {
            normalSkipsCount++;
            normalSkipsDeduction += skipCost;
            totalValidSkips++;
            carriedItems.add(
              DeductionItem(
                date: r.date,
                mealSlot: '$prevMonthName Regular Skip (${r.mealSlot})',
                type: 'carry_forward',
                amount: -skipCost,
              ),
            );
          }
        }
      }
    }

    // Option 1: If previous bill was settled with validity extension,
    // coveredSkips = prevBill.daysToExtend * allowedMeals was consumed for subscription extension.
    // The remaining leftover odd skips must carry forward into this month's bill as cash credit!
    final int coveredSkipsByExtension = (prevBill != null && prevBill.daysToExtend > 0 && allowedMeals > 0)
        ? (prevBill.daysToExtend * allowedMeals)
        : 0;

    if (coveredSkipsByExtension > 0) {
      if (totalValidSkips <= coveredSkipsByExtension) {
        // All meal skips were consumed for validity extension
        return const CarryForwardResult();
      }

      final int remainderSkips = totalValidSkips - coveredSkipsByExtension;
      final carriedRemainderItems = carriedItems.length > coveredSkipsByExtension
          ? carriedItems.skip(coveredSkipsByExtension).toList()
          : <DeductionItem>[];

      double remainderAmount = carriedRemainderItems.fold<double>(
        0.0,
        (sum, item) => sum + item.amount.abs(),
      );
      if (remainderAmount <= 0 && remainderSkips > 0) {
        remainderAmount = remainderSkips * effectiveRate;
      }

      final int remNormal = carriedRemainderItems
          .where((i) => i.mealSlot.contains('Regular'))
          .length;
      final int remSpecial = carriedRemainderItems
          .where((i) => i.mealSlot.contains('Special'))
          .length;
      final int remClosed = carriedRemainderItems
          .where((i) => i.mealSlot.contains('Closed'))
          .length;

      return CarryForwardResult(
        amount: remainderAmount,
        skipCount: carriedRemainderItems.isNotEmpty
            ? carriedRemainderItems.length
            : remainderSkips,
        items: carriedRemainderItems,
        normalSkipsCount: remNormal > 0 ? remNormal : remainderSkips,
        normalSkipsDeduction: remainderAmount,
        specialSkipsCount: remSpecial,
        specialSkipsDeduction: 0.0,
        ownerClosureCount: remClosed,
        ownerClosureDeduction: 0.0,
        totalValidSkips: remainderSkips,
      );
    }

    double totalPrevSkipsAmount =
        normalSkipsDeduction + specialSkipsDeduction + ownerClosureDeduction;

    // Check if any deductions were already given in prevBill (legacy safety)
    double alreadyDeductedInPrevBill = 0.0;
    if (prevBill != null) {
      for (var d in prevBill.deductions) {
        if (d.type == 'self_cancelled' ||
            d.type == 'owner_off' ||
            d.type == 'special_skip') {
          alreadyDeductedInPrevBill += d.amount.abs();
        }
      }
    }

    double uncreditedAmount =
        max(0.0, totalPrevSkipsAmount - alreadyDeductedInPrevBill);

    if (prevBill != null && prevBill.excessCreditGenerated > 0) {
      uncreditedAmount += prevBill.excessCreditGenerated;
    }

    if (uncreditedAmount > 0 || totalValidSkips > 0) {
      return CarryForwardResult(
        amount: uncreditedAmount,
        skipCount: normalSkipsCount + specialSkipsCount + ownerClosureCount,
        items: carriedItems,
        normalSkipsCount: normalSkipsCount,
        normalSkipsDeduction: normalSkipsDeduction,
        specialSkipsCount: specialSkipsCount,
        specialSkipsDeduction: specialSkipsDeduction,
        ownerClosureCount: ownerClosureCount,
        ownerClosureDeduction: ownerClosureDeduction,
        totalValidSkips: totalValidSkips,
      );
    }

    return const CarryForwardResult();
  } catch (e) {
    debugPrint('[CarryForward] error: $e');
    return const CarryForwardResult();
  }
}

/// Checks if a currently PAID bill has accrued new skips after being marked as paid.
double calculatePostPaymentSkipsAmount({
  required BillModel savedBill,
  required List<MealRecordModel> currentRecords,
  required MessModel mess,
  MealPlanModel? plan,
}) {
  if (!savedBill.isPaid) return 0.0;

  final double ownerSetRate =
      (plan?.deductionPolicy.policyType == 'flat_fixed_rate' &&
              (plan?.deductionPolicy.flatRate ?? 0) > 0)
          ? plan!.deductionPolicy.flatRate!
          : (mess.perMealRate > 0 ? mess.perMealRate : 0.0);
  final totalDays = DateTime(savedBill.year, savedBill.month + 1, 0).day;
  final int allowedMeals =
      plan != null ? plan.mealsIncludedPerDay : mess.mealsIncludedPerDay;
  final double dynamicPerMealRate = (allowedMeals > 0 && totalDays > 0)
      ? (savedBill.baseFee / (totalDays * allowedMeals))
      : 0.0;
  final double effectiveRate = !mess.allowMealSkipping
      ? 0.0
      : (ownerSetRate > 0 ? ownerSetRate : dynamicPerMealRate);

  double actualTotal = 0.0;
  for (var r in currentRecords) {
    if (r.status == 'absent_self' || r.status == 'absent_owner') {
      final int feastExtendCount = mess.specialMealExtendMeals > 0
          ? mess.specialMealExtendMeals
          : (mess.specialMealMultiplier.round().clamp(1, 4));
      final double defaultSpecialRate =
          (mess.specialMealFlatRate != null && mess.specialMealFlatRate! > 0)
              ? mess.specialMealFlatRate!
              : (effectiveRate * feastExtendCount);
      final double standardRate =
          r.isSpecial ? defaultSpecialRate : effectiveRate;
      final double skipCost = r.cost ?? standardRate;
      actualTotal += skipCost;
    }
  }

  return max(0.0, actualTotal - savedBill.totalDeductions);
}
