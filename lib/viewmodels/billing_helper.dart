import '../models/app_models.dart';

BillModel generateAdvancedBill({
  required StudentModel student,
  required MessModel mess,
  required int month,
  required int year,
  required List<MealRecordModel> records,
  required double previousDues,
}) {
  double skipsDeduction = 0.0;
  double extraMealsAddon = 0.0;
  double guestAddons = 0.0;
  double proratedDiscount = 0.0;
  List<DeductionItem> items = [];

  // Calculate total days in the specified month
  final totalDays = DateTime(year, month + 1, 0).day;

  // 1. Calculate prorated discount if joined this month
  if (student.joinDate.year == year &&
      student.joinDate.month == month &&
      student.joinDate.day > 1) {
    int missingDays = student.joinDate.day - 1;
    double dailyRate = mess.monthlyFee / totalDays;
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

  // 2. Group records by day
  Map<int, List<MealRecordModel>> dailyRecords = {};
  for (var r in records) {
    dailyRecords.putIfAbsent(r.date.day, () => []).add(r);
  }

  // Calculate offered meals count per day from settings
  int dailyOfferedMeals = mess.mealTimings.values
      .where((m) => m['enabled'] == 'true')
      .length;
  if (dailyOfferedMeals == 0) dailyOfferedMeals = 3; // Fallback

  int allowedMeals = mess.mealsIncludedPerDay;

  // 3. Evaluate each day in the month up to today (or end of month)
  int todayDay = (DateTime.now().year == year && DateTime.now().month == month)
      ? DateTime.now().day
      : totalDays;

  for (int day = 1; day <= todayDay; day++) {
    // If before join date, skip
    if (student.joinDate.year == year &&
        student.joinDate.month == month &&
        day < student.joinDate.day) {
      continue;
    }

    var dayRecs = dailyRecords[day] ?? [];

    // Count skipped meals
    int skippedCount = 0;
    for (var r in dayRecs) {
      if (r.status == 'absent_self' || r.status == 'absent_owner') {
        skippedCount++;
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
      }
    }

    int consumedMeals = dailyOfferedMeals - skippedCount;
    if (consumedMeals < 0) consumedMeals = 0;

    if (consumedMeals < allowedMeals) {
      // Refund for (allowed - consumed)
      int refundMeals = allowedMeals - consumedMeals;
      double refundAmt = refundMeals * mess.perMealRate;
      skipsDeduction += refundAmt;

      items.add(
        DeductionItem(
          date: DateTime(year, month, day),
          mealSlot: 'Valid Skips ($refundMeals)',
          type: 'self_cancelled',
          amount: -refundAmt,
        ),
      );
    } else if (consumedMeals > allowedMeals) {
      // Extra charge for (consumed - allowed)
      int extraCount = consumedMeals - allowedMeals;
      double extraAmt = extraCount * mess.perMealRate;
      extraMealsAddon += extraAmt;
      items.add(
        DeductionItem(
          date: DateTime(year, month, day),
          mealSlot: 'Extra Meals ($extraCount)',
          type: 'extra_meal',
          amount: extraAmt,
        ),
      );
    }
  }

  double finalPayable =
      mess.monthlyFee -
      proratedDiscount -
      skipsDeduction +
      extraMealsAddon +
      guestAddons +
      previousDues;

  return BillModel(
    billId: 'preview',
    studentId: student.studentId,
    messId: mess.messId,
    month: month,
    year: year,
    baseFee: mess.monthlyFee,
    proratedDiscount: proratedDiscount,
    totalDeductions: skipsDeduction,
    extraMealsAddon: extraMealsAddon,
    guestAddons: guestAddons,
    finalPayable: finalPayable,
    previousDues: previousDues,
    isPaid: false,
    deductions: items,
  );
}
