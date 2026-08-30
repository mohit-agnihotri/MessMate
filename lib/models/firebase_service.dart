import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_models.dart';
import 'app_service.dart';

class FirebaseService implements AppService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // AUTH
  @override
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // MESS
  @override
  Future<MessModel?> getMessByOwnerId(String ownerId) async {
    final snap = await _db.collection('messes').where('ownerId', isEqualTo: ownerId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return MessModel.fromMap(snap.docs.first.data());
  }

  @override
  Future<MessModel?> getMessById(String messId) async {
    final doc = await _db.collection('messes').doc(messId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MessModel.fromMap(doc.data()!);
  }

  @override
  Future<List<MessModel>> getAllListedMesses() async {
    final snapshot = await _db
        .collection('messes')
        .where('isListedOnMap', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => MessModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> createMess(MessModel mess) async {
    await _db.collection('messes').doc(mess.messId).set(mess.toMap());
  }

  @override
  Future<void> updateMess(MessModel mess) async {
    await _db.collection('messes').doc(mess.messId).update(mess.toMap());
  }

  @override
  Future<String> uploadImage(String path, Uint8List bytes, String extension) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final fullPath = '$path/$fileName';
    
    await Supabase.instance.client.storage
        .from('mess_photos')
        .uploadBinary(fullPath, bytes, fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'));
        
    return Supabase.instance.client.storage.from('mess_photos').getPublicUrl(fullPath);
  }

  // STUDENTS
  @override
  Future<List<StudentModel>> getStudents(String messId) async {
    final snap = await _db.collection('students').where('messId', isEqualTo: messId).get();
    return snap.docs.map((d) => StudentModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<StudentModel>> streamStudents(String messId) {
    return _db.collection('students')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StudentModel.fromMap(d.data())).toList());
  }

  @override
  Future<List<StudentModel>> getPendingRequests(String messId) async {
    final snap = await _db.collection('students')
        .where('messId', isEqualTo: messId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.map((d) => StudentModel.fromMap(d.data())).toList();
  }

  @override
  Future<void> acceptStudent(String messId, String studentId) async {
    await _db.collection('students').doc(studentId).update({'status': 'active'});
  }

  @override
  Future<void> rejectStudent(String messId, String studentId) async {
    await _db.collection('students').doc(studentId).update({'status': 'rejected'});
  }

  @override
  Future<StudentModel?> getStudentById(String studentId) async {
    final doc = await _db.collection('students').doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _db.collection('students').doc(student.studentId).set(student.toMap(), SetOptions(merge: true));
  }

  // MENU
  @override
  Future<List<MenuModel>> getWeeklyMenu(String messId, DateTime weekStart) async {
    final startIso = weekStart.toIso8601String().substring(0, 10);
    final endIso = weekStart.add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    
    final snap = await _db.collection('menus')
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThan: endIso)
        .get();
    return snap.docs.map((d) => MenuModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<MenuModel>> streamDailyMenus(String messId, DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayStr = days[date.weekday - 1];
    
    // Auto-repeating weekly menu logic: fetch templates for the corresponding day of the week
    return _db.collection('messes')
        .doc(messId)
        .collection('weekly_templates')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => MenuModel.fromMap(d.data()))
              .where((m) => m.menuId.startsWith(dayStr + '_'))
              .toList();
        });
  }

  @override
  Future<void> saveMenu(MenuModel menu) async {
    await _db.collection('menus').doc(menu.menuId).set(menu.toMap());
  }

  @override
  Future<void> publishMenu(String menuId) async {
    await _db.collection('menus').doc(menuId).update({'isPublished': true});
  }

  // MENU (Weekly Templates)
  @override
  Future<List<MenuModel>> getWeeklyTemplate(String messId) async {
    final snap = await _db.collection('messes').doc(messId).collection('weekly_templates').get();
    return snap.docs.map((d) => MenuModel.fromMap(d.data())).toList();
  }

  @override
  Future<void> saveWeeklyTemplate(MenuModel menu, String dayOfWeek) async {
    await _db.collection('messes').doc(menu.messId).collection('weekly_templates').doc(dayOfWeek).set(menu.toMap());
  }

  // GLOBAL DISHES
  @override
  Future<List<DishModel>> searchGlobalDishes(String query) async {
    if (query.isEmpty) return [];
    
    // Fetch all global dishes and filter locally for a true substring case-insensitive match
    // In production with thousands of dishes, use Algolia/ElasticSearch.
    final snap = await _db.collection('global_dishes').get();
    final allDishes = snap.docs.map((d) => DishModel.fromFirestore(d)).toList();
    
    final searchTerm = query.toLowerCase().trim();
    final results = allDishes.where((dish) {
      return dish.name.toLowerCase().contains(searchTerm);
    }).toList();
    
    // Sort so exact prefix matches come first
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aStarts = aName.startsWith(searchTerm) ? 0 : 1;
      final bStarts = bName.startsWith(searchTerm) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      return aName.compareTo(bName);
    });
    
    return results.take(20).toList();
  }

  // MEAL RECORDS
  @override
  Future<void> skipMeal(MealRecordModel record) async {
    await _db.collection('meal_records').doc(record.recordId).set(record.toMap());
  }

  @override
  Future<void> undoSkipMeal(String recordId) async {
    await _db.collection('meal_records').doc(recordId).delete();
  }

  @override
  Future<List<MealRecordModel>> getMealRecords(String studentId, int month, int year) async {
    // simplified for month bounds
    final snap = await _db.collection('meal_records')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<MealRecordModel>> streamDailyMealRecords(String messId, DateTime date) {
    final startIso = date.toIso8601String().substring(0, 10);
    final endIso = date.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    return _db.collection('meal_records')
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThan: endIso)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList());
  }

  @override
  Stream<List<MealRecordModel>> streamStudentDailyMealRecords(String studentId, String messId, DateTime date) {
    final startIso = date.toIso8601String().substring(0, 10);
    final endIso = date.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    return _db.collection('meal_records')
        .where('studentId', isEqualTo: studentId)
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThan: endIso)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList());
  }

  @override
  Future<void> ownerCloseDay(String messId, DateTime date, String mealSlot) async {
    final recordId = '${messId}_${date.toIso8601String().substring(0, 10)}_$mealSlot';
    await _db.collection('messes').doc(messId).collection('closed_slots').doc(recordId).set({
      'date': date.toIso8601String().substring(0, 10),
      'mealSlot': mealSlot,
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  // LEAVES
  @override
  Future<void> applyLeave(LeaveModel leave) async {
    await _db.collection('leaves').doc(leave.leaveId).set(leave.toMap());
  }

  @override
  Future<void> cancelLeave(String leaveId, DateTime cancelledAt) async {
    await _db.collection('leaves').doc(leaveId).update({'status': 'cancelled', 'cancelledAt': cancelledAt.toIso8601String()});
  }

  @override
  Future<List<LeaveModel>> getUpcomingLeaves(String messId) async {
    final snap = await _db.collection('leaves')
        .where('messId', isEqualTo: messId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map((d) => LeaveModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<LeaveModel>> streamLeaves(String messId) {
    return _db.collection('leaves')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LeaveModel.fromMap(d.data())).toList());
  }

  @override
  Future<LeaveModel?> getActiveLeave(String studentId) async {
    final snap = await _db.collection('leaves')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LeaveModel.fromMap(snap.docs.first.data());
  }

  // BILLING
  @override
  Future<BillModel?> getBill(String studentId, int month, int year) async {
    final billId = '${studentId}_${month}_${year}';
    final doc = await _db.collection('bills').doc(billId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BillModel.fromMap(doc.data()!);
  }

  @override
  Future<void> saveBill(BillModel bill) async {
    await _db.collection('bills').doc(bill.billId).set(bill.toMap());
  }

  @override
  Future<void> markAsPaid(String billId) async {
    await _db.collection('bills').doc(billId).update({'isPaid': true});
  }

  @override
  Future<void> addGuestMeal(String studentId, String mealSlot, DateTime date, double cost) async {
    final recordId = '${studentId}_guest_${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('meal_records').doc(recordId).set({
      'recordId': recordId,
      'studentId': studentId,
      'date': date.toIso8601String().substring(0, 10),
      'mealSlot': mealSlot,
      'status': 'guest',
      'cost': cost,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ANNOUNCEMENTS
  @override
  Future<void> sendAnnouncement(String messId, String message) async {
    await _db.collection('announcements').add({
      'messId': messId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AnnouncementModel>> streamAnnouncements(String messId) {
    return _db.collection('announcements')
        .where('messId', isEqualTo: messId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnnouncementModel.fromMap(d.data())).toList());
  }

  @override
  Future<void> emergencyCloseMess(String messId, DateTime date) async {
    await _db.collection('announcements').add({
      'messId': messId,
      'message': '🚨 EMERGENCY: Mess is closed for today (${date.toIso8601String().substring(0, 10)})',
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Add to closed_slots for all 3 meals
    final dateStr = date.toIso8601String().substring(0, 10);
    final batch = _db.batch();
    for (var slot in ['morning', 'noon', 'night']) {
      final doc = _db.collection('messes').doc(messId).collection('closed_slots').doc('${messId}_${dateStr}_$slot');
      batch.set(doc, {'date': dateStr, 'mealSlot': slot, 'closedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  // MESS CODE
  @override
  Future<String> generateUniqueMessCode() async {
    String newCode = '';
    bool isUnique = false;
    while (!isUnique) {
      newCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString(); // 6 digit random
      final snap = await _db.collection('messes').where('messCode', isEqualTo: newCode).limit(1).get();
      if (snap.docs.isEmpty) {
        isUnique = true;
      }
    }
    return newCode;
  }

  @override
  Future<String> regenerateMessCode(String messId) async {
    final newCode = await generateUniqueMessCode();
    await _db.collection('messes').doc(messId).update({'messCode': newCode});
    return newCode;
  }

  @override
  Future<MessModel?> getMessByCode(String code) async {
    final snap = await _db.collection('messes').where('messCode', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return MessModel.fromMap(snap.docs.first.data());
  }

  @override
  Future<void> joinMess(String studentId, String messCode) async {
    final mess = await getMessByCode(messCode);
    if (mess != null) {
      await _db.collection('students').doc(studentId).update({
        'messId': mess.messId,
        'status': 'pending',
      });
    }
  }

  // FEEDBACK
  @override
  Future<void> submitFeedback(FeedbackModel feedback) async {
    final docRef = _db.collection('messes').doc(feedback.messId).collection('feedbacks').doc();
    final data = feedback.toMap();
    data['feedbackId'] = docRef.id;
    await docRef.set(data);
  }

  @override
  Stream<List<FeedbackModel>> streamFeedbacks(String messId) {
    return _db.collection('messes').doc(messId).collection('feedbacks')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeedbackModel.fromMap(d.data())).toList());
  }
}
