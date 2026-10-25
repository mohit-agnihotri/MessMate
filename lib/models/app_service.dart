import 'dart:typed_data';

import 'app_models.dart';

/// Abstract service interface — Firebase implementation will replace stub later.
abstract class AppService {
  // AUTH
  Future<String?> getCurrentUserId();
  Future<void> signOut();

  // MESS
  Future<MessModel?> getMessByOwnerId(String ownerId);
  Future<MessModel?> getMessById(String messId);
  Future<List<MessModel>> getAllListedMesses({String? lastMessId, int limit = 10});
  Future<void> createMess(MessModel mess);
  Future<void> updateMess(MessModel mess);
  Future<String> uploadImage(String path, Uint8List bytes, String extension);

  // STUDENTS
  Future<List<StudentModel>> getStudents(String messId);
  Stream<List<StudentModel>> streamStudents(String messId);
  Future<List<StudentModel>> getPendingRequests(String messId);
  Future<void> acceptStudent(String messId, String studentId, [String? planId]);
  Future<void> rejectStudent(String messId, String studentId);
  Future<StudentModel?> getStudentById(String studentId);
  Future<void> updateStudent(StudentModel student);

  // MENU (Weekly Templates)
  Future<List<MenuModel>> getWeeklyTemplate(String messId);
  Future<void> saveWeeklyTemplate(MenuModel menu, String dayOfWeek);

  // LEGACY MENU (Keep for now to not break students immediately)
  Future<List<MenuModel>> getWeeklyMenu(String messId, DateTime weekStart);
  Stream<List<MenuModel>> streamDailyMenus(String messId, DateTime date);
  Future<List<MenuModel>> getDailyMenus(String messId, DateTime date);
  Future<void> saveMenu(MenuModel menu);
  Future<void> publishMenu(String menuId);
  Future<void> publishDailyMenu(MenuModel menu);
  Future<void> deleteDailyMenu(String messId, String menuId);

  // GLOBAL DISHES
  Future<List<DishModel>> searchGlobalDishes(String query);

  // MEAL RECORDS
  Future<void> skipMeal(MealRecordModel record);
  Future<void> undoSkipMeal(String recordId);
  Future<List<MealRecordModel>> getMealRecords(
    String studentId,
    int month,
    int year, {
    String? messId,
  });
  Stream<List<MealRecordModel>> streamDailyMealRecords(
    String messId,
    DateTime date,
  );
  Stream<List<MealRecordModel>> streamStudentDailyMealRecords(
    String studentId,
    String messId,
    DateTime date,
  );
  Future<void> ownerCloseDay(String messId, DateTime date, String mealSlot);
  Future<void> scheduleClosure(
    MessModel mess,
    DateTime startDate,
    String startSlot,
    DateTime endDate,
    String endSlot,
    String reason,
  );
  Future<void> emergencyCloseMess(String messId, DateTime date);
  Future<void> reopenMess(String messId);
  Future<List<Map<String, dynamic>>> getClosedSlots(String messId);
  Future<void> reopenSpecificSlot(String messId, String date, String mealSlot);
  
  // FEEDBACK & RATINGS
  Future<void> submitFeedback(FeedbackModel feedback);
  Future<void> submitOrUpdateDishRating(DishRatingModel dishRating);
  Future<void> deleteDishRating(String messId, String ratingId);
  Stream<List<DishRatingModel>> streamDishRatings(String messId);

  // MESS REVIEWS
  Future<void> submitOrUpdateMessReview(MessReviewModel review);
  Future<void> deleteMessReview(String messId, String reviewId);
  Stream<List<MessReviewModel>> streamMessReviews(String messId);


  // LEAVES
  Future<void> applyLeave(LeaveModel leave);
  Future<void> cancelLeave(String leaveId, DateTime cancelledAt);
  Future<List<LeaveModel>> getUpcomingLeaves(String messId);
  Stream<List<LeaveModel>> streamLeaves(String messId);
  Future<LeaveModel?> getActiveLeave(String studentId);
  Future<List<LeaveModel>> getStudentLeaves(String studentId, {String? messId});

  // BILLING
  Future<BillModel?> getBill(String studentId, int month, int year);
  Future<double> getPreviousUnpaidDues(String studentId, int month, int year, {String? messId});
  Future<void> saveBill(BillModel bill);
  Future<void> markAsPaid(String billId);
  Future<void> addGuestMeal(
    String studentId,
    String mealSlot,
    DateTime date,
    double cost, {
    int count = 1,
  });

  Future<void> removeGuestMeal(String recordId);
  Stream<List<MealRecordModel>> streamTodayGuestRecords(String messId, DateTime today);

  // ANNOUNCEMENTS
  Future<void> sendAnnouncement(String messId, String message);
  Stream<List<AnnouncementModel>> streamAnnouncements(String messId);
  Future<List<AnnouncementModel>> getAnnouncements(String messId);
  Future<void> cleanupOldAnnouncements(String messId);

  // MESS CODE
  Future<String> generateUniqueMessCode();
  Future<String> regenerateMessCode(String messId);
  Future<MessModel?> getMessByCode(String code);
  Future<void> joinMess(String studentId, String messCode);


  Stream<List<FeedbackModel>> streamFeedbacks(String messId);

  // PLANS
  Future<List<MealPlanModel>> getMealPlans(String messId);
  Stream<List<MealPlanModel>> streamMealPlans(String messId);
  Future<void> saveMealPlan(MealPlanModel plan);
  Future<void> toggleMealPlanActive(String messId, String planId, bool isActive);
  Future<void> deleteMealPlan(String messId, String planId);
  Future<MealPlanModel?> getMealPlanById(String messId, String planId);
  Future<void> updateStudentMealPreference(
    String studentId,
    String messId,
    String dateIso,
    String choiceGroupId,
    String selectedSlot,
  );
  Future<void> updateStudentRegularPreference(
    String studentId,
    String choiceGroupId,
    String selectedSlot,
  );

  // EXTRA FEES
  Future<List<ExtraFeeModel>> getExtraFees(String messId, String studentId);
  Stream<List<ExtraFeeModel>> streamExtraFees(String messId, String studentId);
  Future<void> addExtraFee(ExtraFeeModel fee);
  Future<void> deleteExtraFee(String messId, String feeId);

  // MESS DISHES (Isolated Mess Subcollection)
  Future<List<DishModel>> getMessDishes(String messId);
  Stream<List<DishModel>> streamMessDishes(String messId);
  Future<void> addDishToMess(String messId, DishModel dish);
  Future<void> removeDishFromMess(String messId, String dishId);
  Future<void> updateMessDish(String messId, DishModel dish);
}
