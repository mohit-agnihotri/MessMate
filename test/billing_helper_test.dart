import 'package:flutter_test/flutter_test.dart';
import 'package:mess_app/models/app_models.dart';
import 'package:mess_app/viewmodels/billing_helper.dart';

void main() {
  group('BillingHelper Tests', () {
    final mess = MessModel.fromMap({
      'messId': 'm1',
      'ownerId': 'o1',
      'ownerName': 'Owner Name',
      'ownerPhone': '1112223334',
      'name': 'Test Mess',
      'mealTimings': {
        'morning': {'enabled': 'true'},
        'noon': {'enabled': 'true'},
        'evening': {'enabled': 'false'},
        'night': {'enabled': 'true'}
      },
      'perMealRate': 50.0,
      'monthlyFee': 3000.0,
      'mealsIncludedPerDay': 3,
    });

    final student = StudentModel.fromMap({
      'studentId': 's1',
      'messId': 'm1',
      'name': 'John Doe',
      'phone': '1234567890',
      'roomNo': '101',
      'college': 'Test College',
      'status': 'active',
      'joinDate': DateTime(2023, 10, 1).toIso8601String(),
    });

    test('Normal month with no skips or guests', () {
      final bill = generateAdvancedBill(
        student: student,
        mess: mess,
        month: 10,
        year: 2023,
        records: [],
        previousDues: 0.0,
      );

      // October has 31 days. Base fee 3000.
      expect(bill.month, 10);
      expect(bill.year, 2023);
      expect(bill.baseFee, 3000.0);
      expect(bill.finalPayable, 3000.0);
    });

    test('Skips deduction correctly computes', () {
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r1',
          'studentId': 's1',
          'messId': 'm1',
          'date': DateTime(2023, 10, 5).toIso8601String(),
          'mealSlot': 'morning',
          'status': 'absent_self',
          'cancelledAt': DateTime(2023, 10, 4).toIso8601String(),
        }),
      ];

      final bill = generateAdvancedBill(
        student: student,
        mess: mess,
        month: 10,
        year: 2023,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.totalDeductions, 50.0);
      expect(bill.finalPayable, 3000.0 - 50.0);
    });

    test('Guest meal added to addons', () {
      final records = [
        MealRecordModel.fromMap({
          'recordId': 'r1',
          'studentId': 's1',
          'messId': 'm1',
          'date': DateTime(2023, 10, 5).toIso8601String(),
          'mealSlot': 'morning',
          'status': 'guest',
          'cost': 60.0,
          'cancelledAt': null,
        }),
        MealRecordModel.fromMap({
          'recordId': 'r2',
          'studentId': 's1',
          'messId': 'm1',
          'date': DateTime(2023, 10, 5).toIso8601String(),
          'mealSlot': 'morning',
          'status': 'guest',
          'cost': 60.0,
          'cancelledAt': null,
        }),
      ];

      final bill = generateAdvancedBill(
        student: student,
        mess: mess,
        month: 10,
        year: 2023,
        records: records,
        previousDues: 0.0,
      );

      expect(bill.guestAddons, 120.0);
      expect(bill.finalPayable, 3000.0 + 120.0);
    });

    test('Prorated discount applies for late joiners', () {
      final lateStudent = StudentModel.fromMap({
        'studentId': 's2',
        'messId': 'm1',
        'name': 'Jane Doe',
        'phone': '0987654321',
        'roomNo': '102',
        'college': 'Test College',
        'status': 'active',
        'joinDate': DateTime(2023, 10, 16).toIso8601String(),
      });

      final bill = generateAdvancedBill(
        student: lateStudent,
        mess: mess,
        month: 10,
        year: 2023,
        records: [],
        previousDues: 0.0,
      );

      // Missed 15 days in Oct (31 days). Daily rate = 3000/31 = 96.77
      double expectedDiscount = 15 * (3000.0 / 31.0);
      expect(bill.proratedDiscount, closeTo(expectedDiscount, 0.01));
      expect(bill.finalPayable, closeTo(3000.0 - expectedDiscount, 0.01));
    });
  });
}
