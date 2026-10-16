import 'package:flutter_test/flutter_test.dart';
import 'package:mess_app/models/app_models.dart';
import 'package:mess_app/viewmodels/billing_helper.dart';

void main() {
  group('Phase 1: 11-Scenario Billing Engine Regression Tests', () {
    // Standard test mess offering 3 meals (morning, noon, night), 2 allowed meals
    final standardMess = MessModel.fromMap({
      'messId': 'mess_1',
      'ownerId': 'owner_1',
      'ownerName': 'Test Owner',
      'ownerPhone': '9876543210',
      'name': 'Standard Mess',
      'mealTimings': {
        'morning': {'enabled': 'true'},
        'noon': {'enabled': 'true'},
        'evening': {'enabled': 'false'},
        'night': {'enabled': 'true'},
      },
      'perMealRate': 50.0,
      'monthlyFee': 2700.0,
      'mealsIncludedPerDay': 2,
      'allowMealSkipping': true,
    });

    final fullMonthStudent = StudentModel.fromMap({
      'studentId': 's_full',
      'messId': 'mess_1',
      'name': 'Rahul Sharma',
      'phone': '9876543211',
      'roomNo': '101',
      'status': 'active',
      'joinDate': DateTime(2026, 9, 1).toIso8601String(),
    });

    test('Test 1: Exact ₹3,299 bug reproduction -> Corrected strictly equals ₹1,829', () {
      // Student joined on October 11, 2026.
      // October has 31 days. 10 missing days (Oct 1 to 10).
      // Daily rate = 2700 / 31 = 87.0967...
      // Prorated discount = 10 * (2700 / 31) = 870.9677...
      // Previously, 21 non-skipped days @ 1 extra meal/day = +₹1,470 -> ₹3,299 bug.
      // In corrected engine, normal enrolled days have ZERO extra meal charges.
      final midMonthStudent = StudentModel.fromMap({
        'studentId': 's_mid',
        'messId': 'mess_1',
        'name': 'Mid-Month Student',
        'phone': '9876543212',
        'roomNo': '102',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 11).toIso8601String(),
      });

      final bill = generateAdvancedBill(
        student: midMonthStudent,
        mess: standardMess,
        month: 10,
        year: 2026,
        records: [],
        previousDues: 0.0,
      );

      expect(bill.extraMealsAddon, 0.0);
      expect(bill.proratedDiscount, closeTo(870.97, 0.05));
      expect(bill.finalPayable.round(), 1829);
    });

    test('Test 2: Full month normal attendance (30 days, 0 skips) -> Base ₹2,700 flat, Extra = ₹0', () {
      // September has 30 days. No records.
      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: [],
        previousDues: 0.0,
      );

      expect(bill.baseFee, 2700.0);
      expect(bill.extraMealsAddon, 0.0);
      expect(bill.totalDeductions, 0.0);
      expect(bill.finalPayable, 2700.0);
    });

    test('Test 3: Single valid skip -> Base Fee - 1 dynamic rebate', () {
      // September has 30 days. Allowed 2 meals/day = 60 meals.
      // Dynamic rebate rate = 2700 / 60 = 45.0.
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_skip_1',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 5).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
          'cancelledAt': DateTime(2026, 9, 4, 18, 0).toIso8601String(),
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.totalDeductions, 45.0);
      expect(bill.finalPayable, 2700.0 - 45.0);
      expect(bill.validSkipsRewarded, 1);
    });

    test('Test 4: Full day off (3 meals skipped, allowed = 2) -> Clamped to 2 meals rebate', () {
      // Student skips morning, noon, night on Sep 10. Allowed is 2.
      // Clamped to 2 meals rebate = 2 * 45 = 90.0.
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_off_m',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 10).toIso8601String(),
          'mealSlot': 'morning',
          'status': 'absent_self',
        }),
        MealRecordModel.fromMap({
          'recordId': 'r_off_n',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 10).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
        }),
        MealRecordModel.fromMap({
          'recordId': 'r_off_ni',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 10).toIso8601String(),
          'mealSlot': 'night',
          'status': 'absent_self',
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.totalDeductions, 90.0);
      expect(bill.validSkipsRewarded, 2);
      expect(bill.finalPayable, 2700.0 - 90.0);
    });

    test('Test 5: Guest meal -> Base Fee + guest rate', () {
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_guest',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 12).toIso8601String(),
          'mealSlot': 'night',
          'status': 'guest',
          'cost': 80.0,
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.guestAddons, 80.0);
      expect(bill.finalPayable, 2700.0 + 80.0);
    });

    test('Test 6: Explicit extra meal -> Base Fee + extra meal rate', () {
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_extra',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 14).toIso8601String(),
          'mealSlot': 'evening',
          'status': 'extra_meal',
          'cost': 60.0,
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.extraMealsAddon, 60.0);
      expect(bill.finalPayable, 2700.0 + 60.0);
    });

    test('Test 7: Hybrid Extension mode (compensationChoice = extend) with odd skips', () {
      // 3 skips in September (allowed = 2).
      // daysToExtend = 3 ~/ 2 = 1 day.
      // remainderSkips = 3 % 2 = 1 meal -> discounted as cash rebate = 1 * 45.0 = 45.0.
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_s1',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 2).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
        }),
        MealRecordModel.fromMap({
          'recordId': 'r_s2',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 3).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
        }),
        MealRecordModel.fromMap({
          'recordId': 'r_s3',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 4).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
        compensationChoice: 'extend',
      );

      expect(bill.daysToExtend, 1);
      expect(bill.totalDeductions, 45.0); // odd skip rebate
      expect(bill.finalPayable, 2700.0 - 45.0);
    });

    test('Test 8: Deductions disabled mess (allowMealSkipping = false) -> ₹0 rebate', () {
      final noSkippingMess = MessModel.fromMap({
        'messId': 'mess_no_skip',
        'ownerId': 'owner_1',
        'ownerName': 'Owner',
        'ownerPhone': '9876543210',
        'name': 'No Skip Mess',
        'mealTimings': {'noon': {'enabled': 'true'}, 'night': {'enabled': 'true'}},
        'perMealRate': 50.0,
        'monthlyFee': 2500.0,
        'mealsIncludedPerDay': 2,
        'allowMealSkipping': false,
      });

      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_skip',
          'studentId': 's_full',
          'messId': 'mess_no_skip',
          'date': DateTime(2026, 9, 5).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: noSkippingMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.totalDeductions, 0.0);
      expect(bill.finalPayable, 2500.0);
    });

    test('Test 9: Duplicate self-skip + owner closure on same slot -> Deduplicated to 1 credit, labeled owner_off', () {
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r_owner_close',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 8).toIso8601String(),
          'mealSlot': 'night',
          'status': 'absent_owner',
        }),
        MealRecordModel.fromMap({
          'recordId': 'r_self_skip',
          'studentId': 's_full',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 8).toIso8601String(),
          'mealSlot': 'night',
          'status': 'absent_self',
        }),
      ];

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.totalDeductions, 45.0); // Exactly 1 meal compensated
      expect(bill.validSkipsRewarded, 1);
      final item = bill.deductions.firstWhere((d) => d.type == 'owner_off');
      expect(item.type, 'owner_off');
    });

    test('Test 10: Zero allowed meals edge case -> Safe handling, no division by zero', () {
      final zeroMealMess = MessModel.fromMap({
        'messId': 'mess_zero',
        'ownerId': 'owner_1',
        'ownerName': 'Owner',
        'ownerPhone': '9876543210',
        'name': 'Zero Meal Mess',
        'mealTimings': {},
        'perMealRate': 50.0,
        'monthlyFee': 1000.0,
        'mealsIncludedPerDay': 0,
        'allowMealSkipping': true,
      });

      final bill = generateAdvancedBill(
        student: fullMonthStudent,
        mess: zeroMealMess,
        month: 9,
        year: 2026,
        records: [],
        previousDues: 0.0,
      );

      expect(bill.baseFee, 1000.0);
      expect(bill.totalDeductions, 0.0);
      expect(bill.finalPayable, 1000.0);
      expect(bill.daysToExtend, 0);
    });

    test('Test 11: Owner student management summary card -> Displays total deductions including prorated discount', () {
      final midMonthStudent = StudentModel.fromMap({
        'studentId': 's_mid_2',
        'messId': 'mess_1',
        'name': 'Mid-Month Student',
        'phone': '9876543212',
        'roomNo': '102',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 11).toIso8601String(),
      });

      final skipRecord = [
        MealRecordModel.fromMap({
          'recordId': 'r_oct_skip',
          'studentId': 's_mid_2',
          'messId': 'mess_1',
          'date': DateTime(2026, 10, 15).toIso8601String(),
          'mealSlot': 'noon',
          'status': 'absent_self',
        }),
      ];

      final bill = generateAdvancedBill(
        student: midMonthStudent,
        mess: standardMess,
        month: 10,
        year: 2026,
        records: skipRecord,
        previousDues: 0.0,
      );

      // October dynamic rebate rate = 2700 / (31 * 2) = 43.548...
      // Total deductions displayed on summary card: totalDeductions + proratedDiscount
      final totalDeductionsWithProration = bill.totalDeductions + bill.proratedDiscount;
      expect(totalDeductionsWithProration, closeTo(870.97 + 43.55, 0.1));
      expect(bill.finalPayable.round(), 2700 - totalDeductionsWithProration.round());
    });
  });

  group('Phase 4: Plan-Aware Billing Engine Regression Tests', () {
    final standardMess = MessModel.fromMap({
      'messId': 'mess_1',
      'ownerId': 'owner_1',
      'ownerName': 'Test Owner',
      'ownerPhone': '9876543210',
      'name': 'Standard Mess',
      'mealTimings': {
        'morning': {'enabled': 'true'},
        'noon': {'enabled': 'true'},
        'evening': {'enabled': 'false'},
        'night': {'enabled': 'true'},
      },
      'perMealRate': 50.0,
      'monthlyFee': 3000.0,
      'mealsIncludedPerDay': 2,
      'allowMealSkipping': true,
    });

    test('Test C1: Plan-specific deduction policies (none, dynamic, flat_fixed)', () {
      final student = StudentModel.fromMap({
        'studentId': 's1',
        'messId': 'mess_1',
        'name': 'Aarav',
        'phone': '1111111111',
        'roomNo': '101',
        'status': 'active',
        'joinDate': DateTime(2026, 9, 1).toIso8601String(),
      });

      final skipRecord = [
        MealRecordModel.fromMap({
          'recordId': 'r1',
          'studentId': 's1',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 5).toIso8601String(),
          'mealSlot': 'night',
          'status': 'absent_self',
        }),
      ];

      // Policy: none
      final planNone = MealPlanModel(
        planId: 'p_none',
        messId: 'mess_1',
        name: 'Fixed No-Refund Plan',
        monthlyFee: 2400.0,
        fixedMeals: ['night'],
        deductionPolicy: DeductionPolicyModel(policyType: 'none'),
      );
      final billNone = generateAdvancedBill(
        student: student,
        mess: standardMess,
        plan: planNone,
        month: 9,
        year: 2026,
        records: skipRecord,
        previousDues: 0.0,
      );
      expect(billNone.totalDeductions, 0.0);
      expect(billNone.finalPayable, 2400.0);

      // Policy: flat_fixed_rate (₹60 flat per skip)
      final planFlat = MealPlanModel(
        planId: 'p_flat',
        messId: 'mess_1',
        name: 'Flat Rate Plan',
        monthlyFee: 2400.0,
        fixedMeals: ['night'],
        deductionPolicy: DeductionPolicyModel(
          policyType: 'flat_fixed_rate',
          flatRate: 60.0,
        ),
      );
      final billFlat = generateAdvancedBill(
        student: student,
        mess: standardMess,
        plan: planFlat,
        month: 9,
        year: 2026,
        records: skipRecord,
        previousDues: 0.0,
      );
      expect(billFlat.totalDeductions, 60.0);
      expect(billFlat.finalPayable, 2400.0 - 60.0);

      // Policy: dynamic_prorated (30 days, 1 meal/day = 30 meals, 2400/30 = 80.0)
      final planDynamic = MealPlanModel(
        planId: 'p_dyn',
        messId: 'mess_1',
        name: 'Dynamic Plan',
        monthlyFee: 2400.0,
        fixedMeals: ['night'],
        deductionPolicy: DeductionPolicyModel(policyType: 'dynamic_prorated'),
      );
      final billDynamic = generateAdvancedBill(
        student: student,
        mess: standardMess,
        plan: planDynamic,
        month: 9,
        year: 2026,
        records: skipRecord,
        previousDues: 0.0,
      );
      expect(billDynamic.totalDeductions, 80.0);
      expect(billDynamic.finalPayable, 2400.0 - 80.0);
    });

    test('Test C2: Owner closure compensation awarded for active plan slot under policyType == none mess', () {
      final student = StudentModel.fromMap({
        'studentId': 's1',
        'messId': 'mess_1',
        'name': 'Aarav',
        'phone': '1111111111',
        'roomNo': '101',
        'status': 'active',
        'joinDate': DateTime(2026, 9, 1).toIso8601String(),
      });

      final planNone = MealPlanModel(
        planId: 'p_none',
        messId: 'mess_1',
        name: 'No Skip Rebates Plan',
        monthlyFee: 3000.0,
        fixedMeals: ['night'],
        deductionPolicy: DeductionPolicyModel(policyType: 'none'),
      );

      // Owner closes night dinner on Sep 10
      final closureRecord = [
        MealRecordModel.fromMap({
          'recordId': 'r_close',
          'studentId': 's1',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 10).toIso8601String(),
          'mealSlot': 'night',
          'status': 'absent_owner',
        }),
      ];

      final bill = generateAdvancedBill(
        student: student,
        mess: standardMess,
        plan: planNone,
        month: 9,
        year: 2026,
        records: closureRecord,
        previousDues: 0.0,
      );

      // September 30 days, 1 meal/day = 30 meals -> dynamic closure rate = 3000 / 30 = 100.0
      expect(bill.totalDeductions, 100.0);
      expect(bill.finalPayable, 3000.0 - 100.0);
      expect(bill.deductions.any((d) => d.type == 'owner_off'), isTrue);
    });

    test('Test C3: Owner closure on Morning for student with active choice Noon -> strictly ₹0 compensation awarded', () {
      final planWithChoice = MealPlanModel(
        planId: 'p_choice',
        messId: 'mess_1',
        name: 'Flexible Choice Plan',
        monthlyFee: 3000.0,
        fixedMeals: ['night'],
        choiceGroups: [
          ChoiceGroupModel(
            groupId: 'grp_brk_lunch',
            name: 'Morning or Noon Choice',
            availableMeals: ['morning', 'noon'],
            minSelectable: 1,
            maxSelectable: 1,
          ),
        ],
      );

      // Student Rahul has active choice Noon (via regularMealPreference)
      final studentRahul = StudentModel(
        studentId: 'rahul_1',
        messId: 'mess_1',
        name: 'Rahul',
        phone: '9999999999',
        roomNo: '202',
        college: '',
        course: '',
        email: 'rahul@test.com',
        joinDate: DateTime(2026, 9, 1),
        status: 'active',
        assignedPlanId: 'p_choice',
        regularMealPreference: {'grp_brk_lunch': 'noon'},
      );

      // Owner closes Morning on Sep 15
      final morningClosure = [
        MealRecordModel.fromMap({
          'recordId': 'r_morning_off',
          'studentId': 'rahul_1',
          'messId': 'mess_1',
          'date': DateTime(2026, 9, 15).toIso8601String(),
          'mealSlot': 'morning',
          'status': 'absent_owner',
        }),
      ];

      final bill = generateAdvancedBill(
        student: studentRahul,
        mess: standardMess,
        plan: planWithChoice,
        month: 9,
        year: 2026,
        records: morningClosure,
        previousDues: 0.0,
      );

      // Morning was NOT in Rahul's active meals for that day -> ₹0 compensation
      expect(bill.totalDeductions, 0.0);
      expect(bill.finalPayable, 3000.0);
      expect(bill.deductions.any((d) => d.type == 'owner_off'), isFalse);
    });

    test('Test C4: Extra fee accounting integration with target billing month', () {
      final student = StudentModel.fromMap({
        'studentId': 's1',
        'messId': 'mess_1',
        'name': 'Aarav',
        'phone': '1111111111',
        'roomNo': '101',
        'status': 'active',
        'joinDate': DateTime(2026, 9, 1).toIso8601String(),
      });

      final extraFees = [
        ExtraFeeModel(
          feeId: 'fee_1',
          studentId: 's1',
          messId: 'mess_1',
          originalDate: DateTime(2026, 8, 25),
          targetBillingMonth: 9, // Carried forward to September
          targetBillingYear: 2026,
          amount: 250.0,
          note: 'Special Festival Feast Add-on',
        ),
        ExtraFeeModel(
          feeId: 'fee_2',
          studentId: 's1',
          messId: 'mess_1',
          originalDate: DateTime(2026, 9, 15),
          targetBillingMonth: 10, // Assigned to October
          targetBillingYear: 2026,
          amount: 150.0,
          note: 'October advance fee',
        ),
      ];

      final bill = generateAdvancedBill(
        student: student,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: [],
        previousDues: 0.0,
        extraFees: extraFees,
      );

      // Only fee_1 belongs to September (month 9)
      expect(bill.extraFeesAddon, 250.0);
      expect(bill.finalPayable, 3000.0 + 250.0);
      expect(bill.deductions.any((d) => d.type == 'extra_fee' && d.amount == 250.0), isTrue);
      expect(bill.deductions.any((d) => d.amount == 150.0), isFalse);
    });

    test('Test C5: Hybrid extension with odd skips itemized cleanly', () {
      // 5 skips on 2-meal plan (30 days, fee ₹3,000, allowed 2 meals/day -> rebate = 3000 / 60 = 50.0)
      // daysToExtend = 5 ~/ 2 = 2 days
      // remainderSkips = 5 % 2 = 1 meal -> cash rebate = 1 * 50.0 = 50.0
      final student = StudentModel.fromMap({
        'studentId': 's1',
        'messId': 'mess_1',
        'name': 'Aarav',
        'phone': '1111111111',
        'roomNo': '101',
        'status': 'active',
        'joinDate': DateTime(2026, 9, 1).toIso8601String(),
      });

      final fiveSkips = List.generate(5, (i) => MealRecordModel.fromMap({
        'recordId': 'skip_$i',
        'studentId': 's1',
        'messId': 'mess_1',
        'date': DateTime(2026, 9, i + 2).toIso8601String(),
        'mealSlot': 'night',
        'status': 'absent_self',
      }));

      final bill = generateAdvancedBill(
        student: student,
        mess: standardMess,
        month: 9,
        year: 2026,
        records: fiveSkips,
        previousDues: 0.0,
        compensationChoice: 'extend',
      );

      expect(bill.daysToExtend, 2);
      expect(bill.totalDeductions, 50.0);
      expect(bill.finalPayable, 3000.0 - 50.0);
      expect(bill.deductions.any((d) => d.mealSlot.contains('Odd Skips Rebate')), isTrue);
    });

    test('Test C6: Next billing cycle proration verifying student is not double-billed for extended days', () {
      // Student enrolled in prior month, and subscription was extended up to Oct 5, 2026
      // October has 31 days. Daily rate = 3000 / 31 = 96.774...
      // Days 1 through 5 (5 days) were covered by prior validity extension
      // Prorated discount = 5 * (3000 / 31) = 483.87
      final studentWithExtension = StudentModel(
        studentId: 's_ext',
        messId: 'mess_1',
        name: 'Extended Student',
        phone: '1111111111',
        roomNo: '101',
        college: '',
        course: '',
        email: 'test@mess.com',
        joinDate: DateTime(2026, 8, 1),
        status: 'active',
        subscriptionEndDate: DateTime(2026, 10, 5),
      );

      final bill = generateAdvancedBill(
        student: studentWithExtension,
        mess: standardMess,
        month: 10,
        year: 2026,
        records: [],
        previousDues: 0.0,
        priorSubscriptionEndDate: DateTime(2026, 10, 5),
      );

      expect(bill.proratedDiscount, closeTo(5 * (3000.0 / 31.0), 0.05));
      expect(bill.finalPayable, closeTo(3000.0 - (5 * (3000.0 / 31.0)), 0.05));
      expect(bill.deductions.any((d) => d.type == 'prorated_discount'), isTrue);
    });
  });

}
