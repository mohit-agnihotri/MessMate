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
  Future<List<MessModel>> getAllListedMesses();
  Future<void> createMess(MessModel mess);
  Future<void> updateMess(MessModel mess);
  Future<String> uploadImage(String path, Uint8List bytes, String extension);

  // STUDENTS
  Future<List<StudentModel>> getStudents(String messId);
  Stream<List<StudentModel>> streamStudents(String messId);
  Future<List<StudentModel>> getPendingRequests(String messId);
  Future<void> acceptStudent(String messId, String studentId);
  Future<void> rejectStudent(String messId, String studentId);
  Future<StudentModel?> getStudentById(String studentId);
  Future<void> updateStudent(StudentModel student);

  // MENU (Weekly Templates)
  Future<List<MenuModel>> getWeeklyTemplate(String messId);
  Future<void> saveWeeklyTemplate(MenuModel menu, String dayOfWeek);
  
  // LEGACY MENU (Keep for now to not break students immediately)
  Future<List<MenuModel>> getWeeklyMenu(String messId, DateTime weekStart);
  Stream<List<MenuModel>> streamDailyMenus(String messId, DateTime date);
  Future<void> saveMenu(MenuModel menu);
  Future<void> publishMenu(String menuId);

  // GLOBAL DISHES
  Future<List<DishModel>> searchGlobalDishes(String query);

  // MEAL RECORDS
  Future<void> skipMeal(MealRecordModel record);
  Future<void> undoSkipMeal(String recordId);
  Future<List<MealRecordModel>> getMealRecords(String studentId, int month, int year);
  Stream<List<MealRecordModel>> streamDailyMealRecords(String messId, DateTime date);
  Stream<List<MealRecordModel>> streamStudentDailyMealRecords(String studentId, String messId, DateTime date);
  Future<void> ownerCloseDay(String messId, DateTime date, String mealSlot);

  // LEAVES
  Future<void> applyLeave(LeaveModel leave);
  Future<void> cancelLeave(String leaveId, DateTime cancelledAt);
  Future<List<LeaveModel>> getUpcomingLeaves(String messId);
  Stream<List<LeaveModel>> streamLeaves(String messId);
  Future<LeaveModel?> getActiveLeave(String studentId);

  // BILLING
  Future<BillModel?> getBill(String studentId, int month, int year);
  Future<void> saveBill(BillModel bill);
  Future<void> markAsPaid(String billId);
  Future<void> addGuestMeal(String studentId, String mealSlot, DateTime date, double cost);

  // ANNOUNCEMENTS
  Future<void> sendAnnouncement(String messId, String message);
  Stream<List<AnnouncementModel>> streamAnnouncements(String messId);

  // MESS CODE
  Future<String> generateUniqueMessCode();
  Future<String> regenerateMessCode(String messId);
  Future<MessModel?> getMessByCode(String code);
  Future<void> joinMess(String studentId, String messCode);

  // FEEDBACK
  Future<void> submitFeedback(FeedbackModel feedback);
  Stream<List<FeedbackModel>> streamFeedbacks(String messId);
}
