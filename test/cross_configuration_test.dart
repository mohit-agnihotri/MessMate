import 'package:flutter_test/flutter_test.dart';
import 'package:mess_app/models/app_models.dart';
import 'package:mess_app/viewmodels/billing_helper.dart';
import 'package:mess_app/viewmodels/cutoff_helper.dart';

void main() {
  group('Phase 8: Cross-Configuration Testing (1, 2, 3, and 4 Meal Messes)', () {
    // ─── Configuration 1: 1-Meal Mess (Dinner Only Tiffin Center) ─────────────
    test('Config 1: 1-Meal Mess (Dinner-only) end-to-end lifecycle', () {
      final mess1 = MessModel.fromMap({
        'messId': 'mess_1_meal',
        'ownerId': 'owner_1m',
        'ownerName': 'Tiffin Owner',
        'ownerPhone': '9876543201',
        'name': 'Night Tiffin Service',
        'cutoffHours': 2,
        'mealTimings': {
          'morning': {'enabled': 'false'},
          'noon': {'enabled': 'false'},
          'evening': {'enabled': 'false'},
          'night': {'enabled': 'true', 'start': '19:30', 'end': '21:30'},
        },
        'perMealRate': 60.0,
        'monthlyFee': 1800.0,
        'mealsIncludedPerDay': 1,
        'allowMealSkipping': true,
        'foodType': 'pure_veg',
      });

      // Verify only 1 slot enabled
      final enabledSlots = ['morning', 'noon', 'evening', 'night']
          .where((s) => mess1.mealTimings[s]?['enabled'] == 'true')
          .toList();
      expect(enabledSlots, ['night']);

      // 1-Meal Plan
      final plan1 = MealPlanModel(
        planId: 'plan_1m',
        messId: 'mess_1_meal',
        name: 'Single Dinner Plan',
        monthlyFee: 1800.0,
        fixedMeals: ['night'],
        choiceGroups: [],
        deductionPolicy: DeductionPolicyModel(
          policyType: 'flat_fixed_rate',
          eligibleMeals: ['night'],
          flatRate: 50.0,
        ),
      );

      final student1 = StudentModel.fromMap({
        'studentId': 's_1m',
        'messId': 'mess_1_meal',
        'name': 'Dinner Student',
        'phone': '9876543202',
        'roomNo': '101',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_1m',
      });

      // Cutoff verification
      final cutoff = CutoffHelper.getSlotCutoffTime(DateTime(2026, 10, 15), 'night', mess1);
      expect(cutoff, DateTime(2026, 10, 15, 17, 30));

      // 2 skips during October
      final records = [
        MealRecordModel(
          recordId: 'r1',
          studentId: 's_1m',
          messId: 'mess_1_meal',
          date: DateTime(2026, 10, 10),
          mealSlot: 'night',
          status: 'absent_self',
        ),
        MealRecordModel(
          recordId: 'r2',
          studentId: 's_1m',
          messId: 'mess_1_meal',
          date: DateTime(2026, 10, 20),
          mealSlot: 'night',
          status: 'absent_self',
        ),
      ];

      final bill = generateAdvancedBill(
        student: student1,
        mess: mess1,
        month: 10,
        year: 2026,
        records: records,
        previousDues: 0.0,
        plan: plan1,
      );

      // 2 valid skips @ ₹50 = ₹100 rebate
      expect(bill.baseFee, 1800.0);
      expect(bill.totalDeductions, 100.0);
      expect(bill.finalPayable, 1700.0);
    });

    // ─── Configuration 2: 2-Meal Mess (Lunch & Dinner) ────────────────────────
    test('Config 2: 2-Meal Mess (Lunch & Dinner with Choice Group)', () {
      final mess2 = MessModel.fromMap({
        'messId': 'mess_2_meal',
        'ownerId': 'owner_2m',
        'ownerName': 'Campus Mess',
        'ownerPhone': '9876543203',
        'name': 'Campus Dining',
        'cutoffHours': 2,
        'mealTimings': {
          'morning': {'enabled': 'false'},
          'noon': {'enabled': 'true', 'start': '12:00', 'end': '14:00'},
          'evening': {'enabled': 'false'},
          'night': {'enabled': 'true', 'start': '20:00', 'end': '22:00'},
        },
        'perMealRate': 50.0,
        'monthlyFee': 2500.0,
        'mealsIncludedPerDay': 2,
        'allowMealSkipping': true,
        'foodType': 'both',
      });

      final enabledSlots = ['morning', 'noon', 'evening', 'night']
          .where((s) => mess2.mealTimings[s]?['enabled'] == 'true')
          .toList();
      expect(enabledSlots, ['noon', 'night']);

      final plan2 = MealPlanModel(
        planId: 'plan_2m',
        messId: 'mess_2_meal',
        name: 'Lunch & Dinner Fixed Plan',
        monthlyFee: 2500.0,
        fixedMeals: ['noon', 'night'],
        choiceGroups: [],
      );

      final student2 = StudentModel.fromMap({
        'studentId': 's_2m',
        'messId': 'mess_2_meal',
        'name': 'Double Meal Student',
        'phone': '9876543204',
        'roomNo': '202',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_2m',
      });

      final bill = generateAdvancedBill(
        student: student2,
        mess: mess2,
        month: 10,
        year: 2026,
        records: [],
        previousDues: 0.0,
        plan: plan2,
      );

      expect(bill.baseFee, 2500.0);
      expect(bill.finalPayable, 2500.0);
    });

    // ─── Configuration 3: 3-Meal Mess (Breakfast, Lunch & Dinner) ─────────────
    test('Config 3: 3-Meal Mess (Morning, Noon, Night with Choice Plan)', () {
      final mess3 = MessModel.fromMap({
        'messId': 'mess_3_meal',
        'ownerId': 'owner_3m',
        'ownerName': 'Hostel Mess',
        'ownerPhone': '9876543205',
        'name': 'Grand Hostel Mess',
        'cutoffHours': 2,
        'mealTimings': {
          'morning': {'enabled': 'true', 'start': '08:00', 'end': '10:00'},
          'noon': {'enabled': 'true', 'start': '12:30', 'end': '14:30'},
          'evening': {'enabled': 'false'},
          'night': {'enabled': 'true', 'start': '20:00', 'end': '22:00'},
        },
        'perMealRate': 45.0,
        'monthlyFee': 3200.0,
        'mealsIncludedPerDay': 2,
        'allowMealSkipping': true,
        'foodType': 'both',
      });

      final choiceGroup = ChoiceGroupModel(
        groupId: 'cg_lunch_dinner',
        name: 'Lunch or Dinner',
        availableMeals: ['noon', 'night'],
        minSelectable: 1,
        maxSelectable: 1,
      );

      final plan3 = MealPlanModel(
        planId: 'plan_3m',
        messId: 'mess_3_meal',
        name: 'Breakfast + 1 Meal Plan',
        monthlyFee: 2600.0,
        fixedMeals: ['morning'],
        choiceGroups: [choiceGroup],
      );

      final student3 = StudentModel.fromMap({
        'studentId': 's_3m',
        'messId': 'mess_3_meal',
        'name': 'Hostel Diner',
        'phone': '9876543206',
        'roomNo': '303',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_3m',
        'regularMealPreference': {'cg_lunch_dinner': 'night'},
      });

      // Extra Fee added
      final extraFee = ExtraFeeModel(
        feeId: 'fee_1',
        studentId: 's_3m',
        messId: 'mess_3_meal',
        originalDate: DateTime(2026, 10, 12),
        targetBillingMonth: 10,
        targetBillingYear: 2026,
        amount: 250.0,
        note: 'Special Feast & Festival Sweet Box',
      );

      final bill = generateAdvancedBill(
        student: student3,
        mess: mess3,
        month: 10,
        year: 2026,
        records: [],
        extraFees: [extraFee],
        previousDues: 0.0,
        plan: plan3,
      );

      expect(bill.baseFee, 2600.0);
      expect(bill.extraFeesAddon, 250.0);
      expect(bill.finalPayable, 2850.0);
    });

    // ─── Configuration 4: 4-Meal Mess (All 4 Slots Enabled) ───────────────────
    test('Config 4: 4-Meal Mess (Morning, Noon, Evening Snack, Night Dinner)', () {
      final mess4 = MessModel.fromMap({
        'messId': 'mess_4_meal',
        'ownerId': 'owner_4m',
        'ownerName': 'Full Boarding Owner',
        'ownerPhone': '9876543207',
        'name': 'Full Boarding Mess',
        'cutoffHours': 1,
        'mealTimings': {
          'morning': {'enabled': 'true', 'start': '07:30', 'end': '09:30'},
          'noon': {'enabled': 'true', 'start': '12:30', 'end': '14:30'},
          'evening': {'enabled': 'true', 'start': '17:00', 'end': '18:30'},
          'night': {'enabled': 'true', 'start': '20:00', 'end': '22:00'},
        },
        'perMealRate': 40.0,
        'monthlyFee': 4200.0,
        'mealsIncludedPerDay': 4,
        'allowMealSkipping': true,
        'foodType': 'both',
      });

      final allSlots = ['morning', 'noon', 'evening', 'night']
          .where((s) => mess4.mealTimings[s]?['enabled'] == 'true')
          .toList();
      expect(allSlots, ['morning', 'noon', 'evening', 'night']);

      // 4-Meal Plan
      final plan4 = MealPlanModel(
        planId: 'plan_4m',
        messId: 'mess_4_meal',
        name: 'Full 4-Meal All-Inclusive Plan',
        monthlyFee: 4200.0,
        fixedMeals: ['morning', 'noon', 'evening', 'night'],
        choiceGroups: [],
      );

      final student4 = StudentModel.fromMap({
        'studentId': 's_4m',
        'messId': 'mess_4_meal',
        'name': 'Boarding Student',
        'phone': '9876543208',
        'roomNo': '404',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_4m',
      });

      // Student skipped evening snacks 4 times in October
      final records = [
        for (int i = 5; i <= 8; i++)
          MealRecordModel(
            recordId: 'snack_skip_$i',
            studentId: 's_4m',
            messId: 'mess_4_meal',
            date: DateTime(2026, 10, i),
            mealSlot: 'evening',
            status: 'absent_self',
          ),
      ];

      final bill = generateAdvancedBill(
        student: student4,
        mess: mess4,
        month: 10,
        year: 2026,
        records: records,
        previousDues: 0.0,
        plan: plan4,
      );

      // October has 31 days. Daily rate = 4200 / 31 = 135.4838.
      // 4 meals/day -> Per-meal prorated rebate = 135.4838 / 4 = 33.87096.
      // 4 skips = 4 * 33.87096 = 135.48 rebate.
      expect(bill.baseFee, 4200.0);
      expect(bill.totalDeductions, closeTo(135.48, 0.1));
      expect(bill.finalPayable, closeTo(4064.52, 0.1));
    });
  });
}
