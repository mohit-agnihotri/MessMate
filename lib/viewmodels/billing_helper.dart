import 'dart:math';
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

/// Generates the monthly bill with precise calculations for base fees,
/// prorated discounts for mid-month joiners, skip rebates, owner closure compensations,
/// leaves, extra meals, guest meals, extra fees, and hybrid validity extensions.
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
  double carryForwardCredit = 0.0,
  List<DeductionItem> carryForwardItems = const [],
}) {
  double skipsDeduction = 0.0;
  double ownerClosureDeduction = 0.0;
  double extraMealsAddon = 0.0;
  double guestAddons = 0.0;
  double extraFeesAddon = 0.0;
  double proratedDiscount = 0.0;
  List<DeductionItem> items = [];
  int normalSkipsCount = 0;
  double normalSkipsDeduction = 0.0;
  int specialSkipsCount = 0;
  double specialSkipsDeduction = 0.0;

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
        mealSlot: 'Joined Late',
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

  // 2. Group records by day
  Map<int, List<MealRecordModel>> dailyRecords = {};
  for (var r in records) {
    dailyRecords.putIfAbsent(r.date.day, () => []).add(r);
  }

  // Fallback dynamic per-meal rebate rate
  final double dynamicPerMealRate = (allowedMeals > 0 && totalDays > 0)
      ? (baseFee / (totalDays * allowedMeals))
      : 0.0;

  final double effectiveStudentRebateRate = !mess.allowMealSkipping
      ? 0.0
      : (ownerSetRate > 0 ? ownerSetRate : dynamicPerMealRate);

  // Owner closure per-meal compensation rate:
  final double ownerClosureRate = ownerSetRate > 0
      ? ownerSetRate
      : (dynamicPerMealRate > 0 ? dynamicPerMealRate : 0.0);

  int totalValidSkips = 0;
  int totalOwnerClosures = 0;

  // 3. Evaluate each day in the month
  for (int day = 1; day <= totalDays; day++) {
    final currentDate = DateTime(year, month, day);

    // If before join date, skip
    if (student.joinDate.year == year &&
        student.joinDate.month == month &&
        day < student.joinDate.day) {
      continue;
    }

    var dayRecs = dailyRecords[day] ?? [];

    // Deduplicate slots for this day:
    // If a slot has both absent_owner and absent_self, owner closure takes precedence.
    Map<String, MealRecordModel> skippedSlotMap = {};
    for (var r in dayRecs) {
      if (r.status == 'absent_owner') {
        skippedSlotMap[r.mealSlot] = r; // owner takes priority
      } else if (r.status == 'absent_self') {
        if (!skippedSlotMap.containsKey(r.mealSlot) ||
            skippedSlotMap[r.mealSlot]?.status != 'absent_owner') {
          skippedSlotMap[r.mealSlot] = r;
        }
      } else if (r.status == 'guest') {
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

    // Integrate slot-granular leaves (zero duplicate deductions if already skipped)
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

    // Separate into owner closures and student skips
    List<MealRecordModel> ownerClosures = [];
    List<MealRecordModel> studentSkips = [];

    for (var entry in skippedSlotMap.entries) {
      if (entry.value.status == 'absent_owner') {
        ownerClosures.add(entry.value);
      } else {
        studentSkips.add(entry.value);
      }
    }

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[currentDate.weekday - 1];
    final isSpecialDay =
        mess.specialMealEnabled && mess.specialMealDays.contains(dayName);

    // Owner Closures:
    // Awarded strictly if the closed slot was part of the student's active meals for today!
    for (var r in ownerClosures) {
      if (isSlotActiveForStudent(student, plan, mess, r.mealSlot, currentDate)) {
        totalOwnerClosures++;
        final isSpecialClosure =
            isSpecialDay && (r.isSpecial || mess.specialMealSlot == r.mealSlot);

        final int feastExtendCount = mess.specialMealExtendMeals > 0
            ? mess.specialMealExtendMeals
            : (mess.specialMealMultiplier.round().clamp(1, 4));

        final double refundAmt = isSpecialClosure
            ? ((mess.specialMealFlatRate != null && mess.specialMealFlatRate! > 0)
                ? mess.specialMealFlatRate!
                : (ownerClosureRate * feastExtendCount))
            : ownerClosureRate;

        ownerClosureDeduction += refundAmt;
        items.add(
          DeductionItem(
            date: currentDate,
            mealSlot: isSpecialClosure
                ? '${r.mealSlot} (Special Feast Closed)'
                : '${r.mealSlot} (Mess Closed)',
            type: 'owner_off',
            amount: -refundAmt,
          ),
        );
      }
    }

    // Student Skips:
    // Clamped so that (ownerClosures + studentSkips) on that day cannot exceed allowedMeals
    if (allowedMeals > 0) {
      int remainingAllowance = max(0, allowedMeals - ownerClosures.length);
      int clampedSkips = min(studentSkips.length, remainingAllowance);

      if (clampedSkips > 0) {
        final int? maxAllowedSkips = plan?.deductionPolicy.maxSkipsPerMonth;
        for (int i = 0; i < clampedSkips; i++) {
          final isSpecial = isSpecialDay && studentSkips[i].isSpecial;
          final int feastExtendCount = mess.specialMealExtendMeals > 0
              ? mess.specialMealExtendMeals
              : (mess.specialMealMultiplier.round().clamp(1, 4));
          final double defaultSpecialRate = (mess.specialMealFlatRate != null &&
                  mess.specialMealFlatRate! > 0)
              ? mess.specialMealFlatRate!
              : (effectiveStudentRebateRate * feastExtendCount);
          final double standardRate =
              isSpecial ? defaultSpecialRate : effectiveStudentRebateRate;
          final skipCost = studentSkips[i].cost ??
              (mess.allowMealSkipping ? standardRate : 0.0);

          if (isSpecial) {
            specialSkipsCount++;
            specialSkipsDeduction += skipCost;
            totalValidSkips += feastExtendCount;
          } else {
            normalSkipsCount++;
            normalSkipsDeduction += skipCost;
            totalValidSkips++;
          }

          if (maxAllowedSkips != null &&
              maxAllowedSkips > 0 &&
              totalValidSkips > maxAllowedSkips) {
            // Skips beyond limit are recorded but not refunded financially
            continue;
          }

          if (compensationChoice == 'rebate' && skipCost > 0) {
            skipsDeduction += skipCost;
            items.add(
              DeductionItem(
                date: currentDate,
                mealSlot: isSpecial
                    ? '${studentSkips[i].mealSlot} (Special Feast Skip)'
                    : '${studentSkips[i].mealSlot} (Regular Skip)',
                type: isSpecial ? 'special_skip' : 'self_cancelled',
                amount: -skipCost,
              ),
            );
          }
        }
      }
    }
  }

  // 4. Hybrid Extension handling (compensationChoice == 'extend')
  int daysToExtend = 0;
  if (compensationChoice == 'extend' && allowedMeals > 0) {
    daysToExtend = totalValidSkips ~/ allowedMeals;
    int remainderSkips = totalValidSkips % allowedMeals;

    // Odd leftover skips receive a cash rebate so student loses zero value
    if (remainderSkips > 0 && effectiveStudentRebateRate > 0) {
      double remainderAmt = remainderSkips * effectiveStudentRebateRate;
      skipsDeduction += remainderAmt;
      items.add(
        DeductionItem(
          date: DateTime(year, month, totalDays),
          mealSlot:
              'Odd Skips Rebate ($remainderSkips meal${remainderSkips > 1 ? "s" : ""})',
          type: 'self_cancelled',
          amount: -remainderAmt,
        ),
      );
    }
  }

  // 5. Extra Fees Integration with targetBillingMonth
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

  // 6. Integrate Carry Forward Credit from prior paid months
  if (carryForwardCredit > 0) {
    if (carryForwardItems.isNotEmpty) {
      items.addAll(carryForwardItems);
    } else {
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      int prevMonth = month - 1;
      if (prevMonth < 1) prevMonth = 12;
      final prevMonthName = monthNames[prevMonth - 1];

      items.add(
        DeductionItem(
          date: DateTime(year, month, 1),
          mealSlot: '$prevMonthName Skips Credit (Carry Forward)',
          type: 'carry_forward',
          amount: -carryForwardCredit,
        ),
      );
    }
  }

  // Financial Sanity Guard: Skips deduction cannot exceed monthly baseFee
  if (skipsDeduction > baseFee) {
    skipsDeduction = baseFee;
  }

  // 7. Calculate Final Payable
  double calculatedTotal = baseFee -
      proratedDiscount -
      skipsDeduction -
      ownerClosureDeduction -
      carryForwardCredit +
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
    totalDeductions: skipsDeduction + ownerClosureDeduction + carryForwardCredit,
    extraMealsAddon: extraMealsAddon,
    guestAddons: guestAddons,
    extraFeesAddon: extraFeesAddon,
    finalPayable: finalPayable,
    excessCreditGenerated: excessCredit,
    previousDues: previousDues,
    isPaid: isPaid,
    autoSettled: autoSettled,
    validSkipsRewarded: totalValidSkips + totalOwnerClosures,
    daysToExtend: daysToExtend,
    planId: plan?.planId,
    planName: plan?.name,
    deductions: items,
    normalSkipsCount: normalSkipsCount,
    normalSkipsDeduction: normalSkipsDeduction,
    specialSkipsCount: specialSkipsCount,
    specialSkipsDeduction: specialSkipsDeduction,
    carryForwardCredit: carryForwardCredit,
  );
}

/// Result container for carry forward skips from previous paid months
class CarryForwardResult {
  final double amount;
  final int skipCount;
  final List<DeductionItem> items;

  const CarryForwardResult({
    this.amount = 0.0,
    this.skipCount = 0,
    this.items = const [],
  });
}

/// Calculates uncredited skips and owner closures from previous paid months
/// that were not factored into the previous month's bill when it was paid.
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

    // Only carry forward if the previous bill was marked as PAID.
    // (If it was unpaid, getPreviousUnpaidDues already handles the whole net balance).
    if (prevBill == null || !prevBill.isPaid) {
      return const CarryForwardResult();
    }

    // 2. Fetch the actual meal records of that previous month
    final List<MealRecordModel> prevRecords =
        await service.getMealRecords(studentId, prevMonth, prevYear);

    if (prevRecords.isEmpty && prevBill.excessCreditGenerated <= 0) {
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

    double actualTotalDeductions = 0.0;
    int uncreditedCount = 0;
    List<DeductionItem> carriedItems = [];

    // Group previous records by day
    Map<int, List<MealRecordModel>> dailyRecords = {};
    for (var r in prevRecords) {
      dailyRecords.putIfAbsent(r.date.day, () => []).add(r);
    }

    for (int day = 1; day <= totalDaysInPrevMonth; day++) {
      var dayRecs = dailyRecords[day] ?? [];
      for (var r in dayRecs) {
        if (r.status == 'absent_self' || r.status == 'absent_owner') {
          uncreditedCount++;
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

          actualTotalDeductions += skipCost;
        }
      }
    }

    // The uncredited amount is whatever post-payment skips happened:
    double uncreditedAmount =
        max(0.0, actualTotalDeductions - prevBill.totalDeductions);

    if (prevBill.excessCreditGenerated > 0) {
      uncreditedAmount += prevBill.excessCreditGenerated;
    }

    if (uncreditedAmount > 0) {
      const monthNames = [
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
        'Dec'
      ];
      final prevMonthName = monthNames[prevMonth - 1];

      carriedItems.add(
        DeductionItem(
          date: DateTime(currentYear, currentMonth, 1),
          mealSlot: '$prevMonthName Skips Credit (Carry Forward)',
          type: 'carry_forward',
          amount: -uncreditedAmount,
        ),
      );

      return CarryForwardResult(
        amount: uncreditedAmount,
        skipCount: uncreditedCount,
        items: carriedItems,
      );
    }

    return const CarryForwardResult();
  } catch (e) {
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
