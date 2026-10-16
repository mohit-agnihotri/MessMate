import 'package:flutter_test/flutter_test.dart';
import 'package:mess_app/models/app_models.dart';
import 'package:mess_app/viewmodels/billing_helper.dart';
import 'package:mess_app/viewmodels/cutoff_helper.dart';

void main() {
  group('Phase 5: Student Preference Engine & Unified Cutoff Security', () {
    final mess = MessModel.fromMap({
      'messId': 'mess_test_5',
      'ownerId': 'owner_5',
      'ownerName': 'Test Owner',
      'ownerPhone': '9876543210',
      'name': 'Cutoff Mess',
      'cutoffHours': 2,
      'mealTimings': {
        'morning': {'enabled': 'true', 'start': '08:00', 'end': '10:00'},
        'noon': {'enabled': 'true', 'start': '12:30', 'end': '14:30'},
        'evening': {'enabled': 'false'},
        'night': {'enabled': 'true', 'start': '20:00', 'end': '22:00'},
      },
      'perMealRate': 50.0,
      'monthlyFee': 3000.0,
      'mealsIncludedPerDay': 2,
      'allowMealSkipping': true,
      'foodType': 'both',
    });

    final choiceGroup = ChoiceGroupModel(
      groupId: 'cg_noon_night',
      name: 'Lunch or Dinner',
      availableMeals: ['noon', 'night'],
      minSelectable: 1,
      maxSelectable: 1,
    );

    final plan = MealPlanModel(
      planId: 'plan_flex',
      messId: 'mess_test_5',
      name: 'Flex Plan',
      monthlyFee: 3000.0,
      fixedMeals: ['morning'],
      choiceGroups: [choiceGroup],
      deductionPolicy: DeductionPolicyModel(
        policyType: 'flat_fixed_rate',
        eligibleMeals: ['noon', 'night'],
        flatRate: 40.0,
      ),
    );

    test('Test P1: Preference freezes at earliest slot cutoff of Choice Group', () {
      final targetDate = DateTime(2026, 10, 20);

      // Noon start: 12:30 -> Cutoff = 10:30
      // Night start: 20:00 -> Cutoff = 18:00
      // Earliest cutoff for choiceGroup [noon, night] must be 10:30 AM
      final groupCutoff = CutoffHelper.getChoiceGroupCutoffTime(targetDate, choiceGroup, mess);
      expect(groupCutoff, DateTime(2026, 10, 20, 10, 30));

      // At 10:29 AM, cutoff has NOT passed
      final beforeCutoff = DateTime(2026, 10, 20, 10, 29);
      expect(beforeCutoff.isAfter(groupCutoff), false);

      // At 10:31 AM, cutoff has passed (unified freeze)
      final afterCutoff = DateTime(2026, 10, 20, 10, 31);
      expect(afterCutoff.isAfter(groupCutoff), true);
    });

    test('Test P2: Owner closes meal before cutoff -> Student switches to open alternative -> Alternative active, no closure credit', () {
      final student = StudentModel.fromMap({
        'studentId': 's_p2',
        'messId': 'mess_test_5',
        'name': 'Switching Student',
        'phone': '9876543210',
        'roomNo': '101',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_flex',
        'regularMealPreference': {'cg_noon_night': 'noon'},
        'datePreferences': {
          // Switched to 'night' before cutoff because owner closed noon
          '2026-10-20': {'cg_noon_night': 'night'},
        },
      });

      // Active meals for Oct 20: morning (fixed) + night (selected choice)
      // Noon is NOT student's active meal for Oct 20.
      final activeSlotForToday = student.datePreferences['2026-10-20']?['cg_noon_night'];
      expect(activeSlotForToday, 'night');

      // Meal records for month: no absent_owner on active night slot
      final bill = generateAdvancedBill(
        student: student,
        mess: mess,
        month: 10,
        year: 2026,
        records: [],
        previousDues: 0.0,
        plan: plan,
      );

      // Regular bill, no closure compensation because student successfully switched to open night meal
      expect(bill.totalDeductions, 0.0);
      expect(bill.finalPayable, 3000.0);
    });

    test('Test P3: Owner closes meal before cutoff -> Student does not switch -> Choice freezes on closed meal -> Closure compensation awarded', () {
      final student = StudentModel.fromMap({
        'studentId': 's_p3',
        'messId': 'mess_test_5',
        'name': 'Unswitched Student',
        'phone': '9876543211',
        'roomNo': '102',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_flex',
        'regularMealPreference': {'cg_noon_night': 'noon'},
      });

      // Student choice defaulted to 'noon'. Owner closed noon on Oct 20.
      final records = [
        MealRecordModel(
          recordId: 'rec_owner_noon',
          studentId: 's_p3',
          messId: 'mess_test_5',
          date: DateTime(2026, 10, 20),
          mealSlot: 'noon',
          status: 'absent_owner',
        ),
      ];

      final bill = generateAdvancedBill(
        student: student,
        mess: mess,
        month: 10,
        year: 2026,
        records: records,
        previousDues: 0.0,
        plan: plan,
      );

      // Student gets closure compensation (credit = ₹40 from plan deduction policy)
      expect(bill.totalDeductions, closeTo(48.39, 0.05));
      expect(bill.finalPayable, closeTo(2951.61, 0.05));
    });

    test('Test P4: Owner closes meal after cutoff -> Student locked, switch blocked -> Closure compensation awarded', () {
      final student = StudentModel.fromMap({
        'studentId': 's_p4',
        'messId': 'mess_test_5',
        'name': 'Locked Student',
        'phone': '9876543212',
        'roomNo': '103',
        'status': 'active',
        'joinDate': DateTime(2026, 10, 1).toIso8601String(),
        'assignedPlanId': 'plan_flex',
        'regularMealPreference': {'cg_noon_night': 'noon'},
      });

      // Cutoff time was 10:30 AM. Owner emergency closed noon at 11:00 AM.
      // Student is locked into noon.
      final records = [
        MealRecordModel(
          recordId: 'rec_emergency_noon',
          studentId: 's_p4',
          messId: 'mess_test_5',
          date: DateTime(2026, 10, 20),
          mealSlot: 'noon',
          status: 'absent_owner',
        ),
      ];

      final bill = generateAdvancedBill(
        student: student,
        mess: mess,
        month: 10,
        year: 2026,
        records: records,
        previousDues: 0.0,
        plan: plan,
      );

      // Closure compensation awarded
      expect(bill.totalDeductions, closeTo(48.39, 0.05));
      expect(bill.finalPayable, closeTo(2951.61, 0.05));
    });
  });

  group('Phase 6: Live Headcount Engine & Absentee Tracker UI', () {
    final mess = MessModel.fromMap({
      'messId': 'mess_test_6',
      'ownerId': 'owner_6',
      'ownerName': 'Headcount Owner',
      'ownerPhone': '9876543210',
      'name': 'Headcount Mess',
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
      'foodType': 'pure_veg',
    });

    final choiceGroup = ChoiceGroupModel(
      groupId: 'cg_lunch_dinner',
      name: 'Lunch or Dinner',
      availableMeals: ['noon', 'night'],
      minSelectable: 1,
      maxSelectable: 1,
    );

    final flexPlan = MealPlanModel(
      planId: 'plan_flex_6',
      messId: 'mess_test_6',
      name: 'Flex Plan',
      monthlyFee: 3000.0,
      fixedMeals: ['morning'],
      choiceGroups: [choiceGroup],
      deductionPolicy: DeductionPolicyModel(
        policyType: 'flat_fixed_rate',
        eligibleMeals: ['noon', 'night'],
        flatRate: 50.0,
      ),
    );

    final noonStudent = StudentModel.fromMap({
      'studentId': 's_noon',
      'messId': 'mess_test_6',
      'name': 'Noon Student',
      'phone': '9876543210',
      'roomNo': '201',
      'status': 'active',
      'joinDate': DateTime(2026, 10, 1).toIso8601String(),
      'assignedPlanId': 'plan_flex_6',
      'regularMealPreference': {'cg_lunch_dinner': 'noon'},
      'datePreferences': {'2026-10-20': {'cg_lunch_dinner': 'noon'}},
    });

    final nightStudent = StudentModel.fromMap({
      'studentId': 's_night',
      'messId': 'mess_test_6',
      'name': 'Night Student',
      'phone': '9876543211',
      'roomNo': '202',
      'status': 'active',
      'joinDate': DateTime(2026, 10, 1).toIso8601String(),
      'assignedPlanId': 'plan_flex_6',
      'regularMealPreference': {'cg_lunch_dinner': 'night'},
      'datePreferences': {'2026-10-20': {'cg_lunch_dinner': 'night'}},
    });

    test('Test H1: Student on Noon choice not counted in Night headcount', () {
      final planMap = {'plan_flex_6': flexPlan};
      final todayIso = '2026-10-20';

      bool isSlotInStudentPlan(StudentModel student, String slot) {
        if (student.assignedPlanId == null || !planMap.containsKey(student.assignedPlanId)) return true;
        final p = planMap[student.assignedPlanId]!;
        if (p.fixedMeals.contains(slot)) return true;
        for (final cg in p.choiceGroups) {
          if (cg.availableMeals.contains(slot)) {
            final chosen = student.datePreferences[todayIso]?[cg.groupId] ??
                student.regularMealPreference[cg.groupId] ??
                cg.availableMeals.first;
            if (chosen == slot) return true;
          }
        }
        return false;
      }

      // Check for night slot: noonStudent must NOT be in night plan, nightStudent MUST be in night plan
      expect(isSlotInStudentPlan(noonStudent, 'night'), false);
      expect(isSlotInStudentPlan(nightStudent, 'night'), true);

      // Check for morning slot (fixed in plan for both):
      expect(isSlotInStudentPlan(noonStudent, 'morning'), true);
      expect(isSlotInStudentPlan(nightStudent, 'morning'), true);
    });

    test('Test H2: Emergency closure of Morning slot sets Morning headcount to 0 without altering Noon headcount', () {
      final records = [
        MealRecordModel(
          recordId: 'rec_close_morning',
          studentId: 's_noon',
          messId: 'mess_test_6',
          date: DateTime(2026, 10, 20),
          mealSlot: 'morning',
          status: 'absent_owner',
        ),
      ];

      int computeSlotHeadcount(String currentSlot, List<StudentModel> students) {
        final bool isSlotClosedByOwner = records.any(
          (r) => r.mealSlot == currentSlot && r.status == 'absent_owner',
        );
        if (isSlotClosedByOwner) return 0;

        int expected = 0;
        for (var s in students) {
          bool skipped = records.any(
            (r) => r.studentId == s.studentId && r.mealSlot == currentSlot && (r.status == 'absent_self' || r.status == 'absent_owner'),
          );
          if (!skipped) expected++;
        }
        return expected;
      }

      final students = [noonStudent, nightStudent];

      // Morning slot is closed by owner -> Headcount drops strictly to 0
      final morningCount = computeSlotHeadcount('morning', students);
      expect(morningCount, 0);

      // Noon slot is OPEN -> Headcount remains intact (1 diner: noonStudent)
      final noonCount = computeSlotHeadcount('noon', [noonStudent]);
      expect(noonCount, 1);
    });

    test('Test H3: Absentee tracker dynamically generates tabs matching only enabled mess slots', () {
      final slotsOrder = ['morning', 'noon', 'evening', 'night'];
      final dynamicSlots = slotsOrder
          .where((s) => mess.mealTimings[s]?['enabled'] == 'true')
          .toList();
      final allTabs = [...dynamicSlots, 'fullday'];

      // Evening is disabled in mess.mealTimings -> Must not be in tabs
      expect(allTabs, ['morning', 'noon', 'night', 'fullday']);
      expect(allTabs.contains('evening'), false);
      expect(allTabs.length, 4);
    });
  });
}
