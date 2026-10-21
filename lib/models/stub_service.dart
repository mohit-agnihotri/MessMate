import 'dart:typed_data';

import 'app_models.dart';
import 'app_service.dart';

/// Stub implementation — returns rich dummy data for UI testing.
/// Replace with FirebaseService once google-services.json is added.
class StubService implements AppService {
  static final MessModel _mess = MessModel(
    messId: 'mess_001',
    name: 'Sharma Bhojnalaya',
    ownerId: 'owner_001',
    ownerName: 'Mr. Sharma',
    ownerPhone: '+91 98765 43210',
    gpsLat: 26.9124,
    gpsLng: 75.7873,
    capacity: 550,
    monthlyFee: 3000,
    perMealRate: 55,
    cutoffHours: 2,
    messCode: '123456',
    isListedOnMap: true,
    showMenuToOutsiders: true,
    showMenuToStudents: true,
  );

  static final List<StudentModel> _students = [
    StudentModel(
      studentId: 's1',
      messId: 'mess_001',
      name: 'Rahul Sharma',
      phone: '+91 901-1736-5771',
      roomNo: 'B-204',
      college: 'Rajasthan University',
      course: 'B.Tech CS',
      email: 'rahul@example.com',
      joinDate: DateTime(2024, 10, 12),
      status: 'active',
      assignedPlanId: 'plan_flex',
      regularMealPreference: {'cg1': 'noon'},
      datePreferences: {},
    ),
    StudentModel(
      studentId: 's2',
      messId: 'mess_001',
      name: 'Priya Patel',
      phone: '+91 888-2345-6789',
      roomNo: 'A-101',
      college: 'Rajasthan University',
      course: 'B.Com',
      email: 'priya@example.com',
      joinDate: DateTime(2024, 10, 5),
      status: 'active',
    ),
    StudentModel(
      studentId: 's3',
      messId: 'mess_001',
      name: 'Amit Kumar',
      phone: '+91 777-9876-5432',
      roomNo: 'C-302',
      college: 'Rajasthan University',
      course: 'MBA',
      email: 'amit@example.com',
      joinDate: DateTime(2024, 9, 20),
      status: 'pending',
    ),
    StudentModel(
      studentId: 's4',
      messId: 'mess_001',
      name: 'Neha Singh',
      phone: '+91 999-1234-5678',
      roomNo: 'A-210',
      college: 'Rajasthan University',
      course: 'B.Sc Physics',
      email: 'neha@example.com',
      joinDate: DateTime(2024, 10, 15),
      status: 'active',
    ),
    StudentModel(
      studentId: 's5',
      messId: 'mess_001',
      name: 'Rohan Verma',
      phone: '+91 666-5678-1234',
      roomNo: 'B-118',
      college: 'Rajasthan University',
      course: 'B.Tech ECE',
      email: 'rohan@example.com',
      joinDate: DateTime(2024, 10, 28),
      status: 'active',
    ),
    StudentModel(
      studentId: 's6',
      messId: 'mess_001',
      name: 'Sneha Gupta',
      phone: '+91 555-4321-8765',
      roomNo: 'D-401',
      college: 'Rajasthan University',
      course: 'BBA',
      email: 'sneha@example.com',
      joinDate: DateTime(2024, 11, 1),
      status: 'inactive',
    ),
  ];

  static final List<DishModel> _dishes = [
    DishModel(dishId: 'd1', name: 'Poha', category: 'veg'),
    DishModel(dishId: 'd2', name: 'Masala Chai', category: 'veg'),
    DishModel(dishId: 'd3', name: 'Paneer Butter Masala', category: 'veg'),
    DishModel(dishId: 'd4', name: 'Dal Tadka', category: 'veg'),
    DishModel(dishId: 'd5', name: 'Steamed Basmati Rice', category: 'veg'),
    DishModel(dishId: 'd6', name: 'Chapati (3 nos.)', category: 'veg'),
    DishModel(dishId: 'd7', name: 'Mixed Veg Raita', category: 'veg'),
    DishModel(dishId: 'd8', name: 'Veg Biryani', category: 'veg'),
    DishModel(dishId: 'd9', name: 'Dal Makhani', category: 'veg'),
    DishModel(dishId: 'd10', name: 'Salad', category: 'veg'),
  ];

  static final List<MealRecordModel> _records = [
    MealRecordModel(
      recordId: 'r1',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 4),
      mealSlot: 'noon',
      status: 'absent_self',
      cancelledAt: DateTime(2024, 10, 4, 11),
    ),
    MealRecordModel(
      recordId: 'r2',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 11),
      mealSlot: 'night',
      status: 'absent_self',
      cancelledAt: DateTime(2024, 10, 11, 18),
    ),
    MealRecordModel(
      recordId: 'r3',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 12),
      mealSlot: 'morning',
      status: 'absent_self',
      cancelledAt: DateTime(2024, 10, 12, 8),
    ),
    MealRecordModel(
      recordId: 'r4',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 19),
      mealSlot: 'fullday',
      status: 'absent_self',
      cancelledAt: DateTime(2024, 10, 19, 9),
    ),
    MealRecordModel(
      recordId: 'r5',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 21),
      mealSlot: 'fullday',
      status: 'absent_owner',
      cancelledAt: DateTime(2024, 10, 21, 9),
    ),
    MealRecordModel(
      recordId: 'r6',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 25),
      mealSlot: 'noon',
      status: 'absent_self',
      cancelledAt: DateTime(2024, 10, 25, 11),
    ),
    MealRecordModel(
      recordId: 'r7',
      studentId: 's1',
      messId: 'mess_001',
      date: DateTime(2024, 10, 25),
      mealSlot: 'night',
      status: 'absent_self',
      cancelledAt: DateTime(2024, 10, 25, 18),
    ),
  ];

  static BillModel _bill = BillModel(
    billId: 'bill_001',
    studentId: 's1',
    messId: 'mess_001',
    month: 10,
    year: 2024,
    baseFee: 3000,
    totalDeductions: 550,
    guestAddons: 110,
    finalPayable: 2560,
    isPaid: false,
    deductions: [
      DeductionItem(
        date: DateTime(2024, 10, 11),
        mealSlot: 'Night',
        type: 'self_cancelled',
        amount: -55,
      ),
      DeductionItem(
        date: DateTime(2024, 10, 19),
        mealSlot: 'Full Day',
        type: 'self_cancelled',
        amount: -110,
      ),
      DeductionItem(
        date: DateTime(2024, 10, 21),
        mealSlot: 'Full Day',
        type: 'owner_off',
        amount: 0,
      ),
      DeductionItem(
        date: DateTime(2024, 10, 25),
        mealSlot: 'Lunch',
        type: 'self_cancelled',
        amount: -55,
      ),
    ],
  );

  @override
  Future<String?> getCurrentUserId() async => 'owner_001';
  @override
  Future<void> signOut() async {}
  @override
  Future<MessModel?> getMessByOwnerId(String ownerId) async => _mess;
  @override
  Future<MessModel?> getMessById(String messId) async => _mess;
  @override
  Future<List<MessModel>> getAllListedMesses({String? lastMessId, int limit = 10}) async => [_mess];
  @override
  Future<void> createMess(MessModel mess) async {}
  @override
  Future<void> updateMess(MessModel mess) async {}
  @override
  Future<String> uploadImage(
    String path,
    Uint8List bytes,
    String extension,
  ) async => 'https://via.placeholder.com/150';
  @override
  Future<List<StudentModel>> getStudents(String messId) async =>
      _students.where((s) => s.status == 'active').toList();
  @override
  Stream<List<StudentModel>> streamStudents(String messId) =>
      Stream.value(_students.where((s) => s.status != 'pending').toList());
  @override
  Future<List<StudentModel>> getPendingRequests(String messId) async =>
      _students.where((s) => s.status == 'pending').toList();
  @override
  Future<void> acceptStudent(String messId, String studentId, [String? planId]) async {}
  @override
  Future<void> rejectStudent(String messId, String studentId) async {}
  @override
  Future<StudentModel?> getStudentById(String studentId) async =>
      _students.first;
  @override
  Future<void> updateStudent(StudentModel student) async {}
  @override
  Future<List<MenuModel>> getWeeklyMenu(
    String messId,
    DateTime weekStart,
  ) async => [];
  @override
  Stream<List<MenuModel>> streamDailyMenus(String messId, DateTime date) =>
      Stream.value([]);
  @override
  Future<List<MenuModel>> getDailyMenus(String messId, DateTime date) async =>
      [];
  @override
  Future<void> saveMenu(MenuModel menu) async {}
  @override
  Future<void> publishMenu(String menuId) async {}
  @override
  Future<void> publishDailyMenu(MenuModel menu) async {}
  @override
  Future<void> deleteDailyMenu(String messId, String menuId) async {}
  @override
  Future<List<MenuModel>> getWeeklyTemplate(String messId) async => [];
  @override
  Future<void> saveWeeklyTemplate(MenuModel menu, String dayOfWeek) async {}
  @override
  Future<List<DishModel>> searchGlobalDishes(String query) async => _dishes;
  @override
  Future<void> skipMeal(MealRecordModel record) async {}
  @override
  Future<void> undoSkipMeal(String recordId) async {}
  @override
  Future<List<MealRecordModel>> getMealRecords(
    String studentId,
    int month,
    int year,
  ) async => _records;
  @override
  Stream<List<MealRecordModel>> streamDailyMealRecords(
    String messId,
    DateTime date,
  ) => Stream.value(_records);
  @override
  Stream<List<MealRecordModel>> streamStudentDailyMealRecords(
    String studentId,
    String messId,
    DateTime date,
  ) => Stream.value(_records);
  @override
  Future<void> ownerCloseDay(
    String messId,
    DateTime date,
    String mealSlot,
  ) async {}
  @override
  Future<void> scheduleClosure(
    MessModel mess,
    DateTime startDate,
    String startSlot,
    DateTime endDate,
    String endSlot,
    String reason,
  ) async {}
  @override
  Future<void> emergencyCloseMess(String messId, DateTime date) async {}
  @override
  Future<void> reopenMess(String messId) async {}
  @override
  Future<List<Map<String, dynamic>>> getClosedSlots(String messId) async => [];
  @override
  Future<void> reopenSpecificSlot(String messId, String date, String mealSlot) async {}
  @override
  Future<void> applyLeave(LeaveModel leave) async {}
  @override
  Future<void> cancelLeave(String leaveId, DateTime cancelledAt) async {}
  @override
  Future<List<LeaveModel>> getUpcomingLeaves(String messId) async => [];
  @override
  Stream<List<LeaveModel>> streamLeaves(String messId) => Stream.value([]);
  @override
  Future<LeaveModel?> getActiveLeave(String studentId) async => null;
  @override
  Future<BillModel?> getBill(String studentId, int month, int year) async =>
      _bill;
  @override
  Future<void> saveBill(BillModel bill) async {
    _bill = bill;
  }

  @override
  Future<void> markAsPaid(String billId) async {}
  @override
  Future<void> addGuestMeal(
    String studentId,
    String mealSlot,
    DateTime date,
    double cost, {
    int count = 1,
  }) async {}

  @override
  Future<void> removeGuestMeal(String recordId) async {}

  @override
  Stream<List<MealRecordModel>> streamTodayGuestRecords(String messId, DateTime today) =>
      Stream.value([]);
  @override
  Future<void> sendAnnouncement(String messId, String message) async {}
  @override
  Stream<List<AnnouncementModel>> streamAnnouncements(String messId) =>
      Stream.value([]);
  @override
  Future<List<AnnouncementModel>> getAnnouncements(String messId) async => [];
  @override
  Future<String> generateUniqueMessCode() async => '123456';
  @override
  Future<String> regenerateMessCode(String messId) async => '123456';
  @override
  Future<MessModel?> getMessByCode(String code) async => _mess;
  @override
  Future<void> joinMess(String studentId, String messCode) async {}
  @override
  Future<void> submitFeedback(FeedbackModel feedback) async {}
  @override
  Stream<List<FeedbackModel>> streamFeedbacks(String messId) =>
      Stream.value([]);

  @override
  Future<void> submitOrUpdateDishRating(DishRatingModel dishRating) async {}
  @override
  Future<void> deleteDishRating(String messId, String ratingId) async {}
  @override
  Stream<List<DishRatingModel>> streamDishRatings(String messId) =>
      Stream.value([]);

  @override
  Future<void> submitOrUpdateMessReview(MessReviewModel review) async {}
  @override
  Future<void> deleteMessReview(String messId, String reviewId) async {}
  @override
  Stream<List<MessReviewModel>> streamMessReviews(String messId) =>
      Stream.value([]);
  @override
  Future<double> getPreviousUnpaidDues(
    String studentId,
    int month,
    int year,
  ) async {
    return 0.0;
  }

  @override
  Future<void> cleanupOldAnnouncements(String messId) async {}


  static final List<MealPlanModel> _plans = [
    MealPlanModel(
      planId: 'plan_full',
      messId: 'mess_001',
      name: 'तीनों टाइम का खाना (Full Day)',
      monthlyFee: 3500.0,
      fixedMeals: ['morning', 'noon', 'night'],
      choiceGroups: [],
      deductionPolicy: DeductionPolicyModel(
        policyType: 'flat',
        eligibleMeals: ['morning', 'noon', 'night'],
        flatRate: 50.0,
      ),
      isActive: true,
    ),
    MealPlanModel(
      planId: 'plan_2meal',
      messId: 'mess_001',
      name: 'दोपहर + रात का खाना (2 Meals Daily)',
      monthlyFee: 2800.0,
      fixedMeals: ['noon', 'night'],
      choiceGroups: [],
      deductionPolicy: DeductionPolicyModel(
        policyType: 'flat',
        eligibleMeals: ['noon', 'night'],
        flatRate: 50.0,
      ),
      isActive: true,
    ),
    MealPlanModel(
      planId: 'plan_flex',
      messId: 'mess_001',
      name: 'नाश्ता या दोपहर + पक्का डिनर (2 Meals Flexible)',
      monthlyFee: 2600.0,
      fixedMeals: ['night'],
      choiceGroups: [
        ChoiceGroupModel(
          groupId: 'cg1',
          name: 'नाश्ता या दोपहर (Morning or Noon)',
          availableMeals: ['morning', 'noon'],
          minSelectable: 1,
          maxSelectable: 1,
        ),
      ],
      deductionPolicy: DeductionPolicyModel(
        policyType: 'flat',
        eligibleMeals: ['morning', 'noon', 'night'],
        flatRate: 50.0,
      ),
      isActive: true,
    ),
    MealPlanModel(
      planId: 'plan_choice',
      messId: 'mess_001',
      name: 'मनपसंद 1 खाना (1-Meal Choice)',
      monthlyFee: 1800.0,
      fixedMeals: [],
      choiceGroups: [
        ChoiceGroupModel(
          groupId: 'cg2',
          name: 'दोपहर या रात (Lunch or Dinner)',
          availableMeals: ['noon', 'night'],
          minSelectable: 1,
          maxSelectable: 1,
        ),
      ],
      deductionPolicy: DeductionPolicyModel(
        policyType: 'flat',
        eligibleMeals: ['noon', 'night'],
        flatRate: 50.0,
      ),
      isActive: true,
    ),
  ];
  // PLANS
  @override
  Future<List<MealPlanModel>> getMealPlans(String messId) async =>
      _plans.where((p) => p.messId == messId || messId.isEmpty).toList();

  @override
  Stream<List<MealPlanModel>> streamMealPlans(String messId) =>
      Stream.value(_plans.where((p) => p.messId == messId || messId.isEmpty).toList());

  @override
  Future<void> saveMealPlan(MealPlanModel plan) async {
    _plans.removeWhere((p) => p.planId == plan.planId);
    _plans.add(plan);
  }

  @override
  Future<void> toggleMealPlanActive(String messId, String planId, bool isActive) async {
    final idx = _plans.indexWhere((p) => p.planId == planId);
    if (idx != -1) {
      final p = _plans[idx];
      _plans[idx] = MealPlanModel(
        planId: p.planId,
        messId: p.messId,
        name: p.name,
        monthlyFee: p.monthlyFee,
        fixedMeals: p.fixedMeals,
        choiceGroups: p.choiceGroups,
        deductionPolicy: p.deductionPolicy,
        extraMealRate: p.extraMealRate,
        isActive: isActive,
        createdAt: p.createdAt,
      );
    }
  }

  @override
  Future<void> deleteMealPlan(String messId, String planId) async {
    _plans.removeWhere((p) => p.planId == planId);
  }

  @override
  Future<MealPlanModel?> getMealPlanById(String messId, String planId) async {
    try {
      return _plans.firstWhere((p) => p.planId == planId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateStudentMealPreference(
    String studentId,
    String messId,
    String dateIso,
    String choiceGroupId,
    String selectedSlot,
  ) async {
    final idx = _students.indexWhere((s) => s.studentId == studentId);
    if (idx != -1) {
      final st = _students[idx];
      final currentMap = Map<String, Map<String, String>>.from(st.datePreferences);
      final dateMap = Map<String, String>.from(currentMap[dateIso] ?? {});
      dateMap[choiceGroupId] = selectedSlot;
      currentMap[dateIso] = dateMap;
      _students[idx] = st.copyWith(datePreferences: currentMap);
    }
  }

  @override
  Future<void> updateStudentRegularPreference(
    String studentId,
    String choiceGroupId,
    String selectedSlot,
  ) async {
    final idx = _students.indexWhere((s) => s.studentId == studentId);
    if (idx != -1) {
      final st = _students[idx];
      final regMap = Map<String, String>.from(st.regularMealPreference);
      regMap[choiceGroupId] = selectedSlot;
      _students[idx] = st.copyWith(regularMealPreference: regMap);
    }
  }

  // EXTRA FEES
  @override
  Future<List<ExtraFeeModel>> getExtraFees(String messId, String studentId) async => [];
  @override
  Stream<List<ExtraFeeModel>> streamExtraFees(String messId, String studentId) => Stream.value([]);
  @override
  Future<void> addExtraFee(ExtraFeeModel fee) async {}
  @override
  Future<void> deleteExtraFee(String messId, String feeId) async {}

  // MESS DISHES
  @override
  Future<List<DishModel>> getMessDishes(String messId) async => [];
  @override
  Stream<List<DishModel>> streamMessDishes(String messId) => Stream.value([]);
  @override
  Future<void> addDishToMess(String messId, DishModel dish) async {}
  @override
  Future<void> removeDishFromMess(String messId, String dishId) async {}
  @override
  Future<void> updateMessDish(String messId, DishModel dish) async {}
}
