import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_models.dart';
import 'app_service.dart';
import '../viewmodels/cutoff_helper.dart';

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
    final snap = await _db
        .collection('messes')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
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
  Future<List<MessModel>> getAllListedMesses({String? lastMessId, int limit = 10}) async {
    var query = _db
        .collection('messes')
        .where('isListedOnMap', isEqualTo: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (lastMessId != null) {
      final doc = await _db.collection('messes').doc(lastMessId).get();
      if (doc.exists) {
        query = query.startAfterDocument(doc);
      }
    }

    final snapshot = await query.get();
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
  Future<String> uploadImage(
    String path,
    Uint8List bytes,
    String extension,
  ) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final fullPath = '$path/$fileName';

    await Supabase.instance.client.storage
        .from('mess_photos')
        .uploadBinary(
          fullPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );

    return Supabase.instance.client.storage
        .from('mess_photos')
        .getPublicUrl(fullPath);
  }

  // STUDENTS
  @override
  Future<List<StudentModel>> getStudents(String messId) async {
    final snap = await _db
        .collection('students')
        .where('messId', isEqualTo: messId)
        .get();
    return snap.docs.map((d) => StudentModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<StudentModel>> streamStudents(String messId) {
    return _db
        .collection('students')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => StudentModel.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<List<StudentModel>> getPendingRequests(String messId) async {
    final snap = await _db
        .collection('students')
        .where('messId', isEqualTo: messId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.map((d) => StudentModel.fromMap(d.data())).toList();
  }

  @override
  Future<void> acceptStudent(String messId, String studentId, [String? planId]) async {
    final Map<String, dynamic> updateData = {
      'status': 'active',
    };
    if (planId != null && planId.isNotEmpty) {
      updateData['assignedPlanId'] = planId;
    }
    await _db.collection('students').doc(studentId).update(updateData);
  }

  @override
  Future<void> rejectStudent(String messId, String studentId) async {
    await _db.collection('students').doc(studentId).update({
      'status': 'rejected',
    });
  }

  @override
  Future<StudentModel?> getStudentById(String studentId) async {
    final doc = await _db.collection('students').doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _db
        .collection('students')
        .doc(student.studentId)
        .set(student.toMap(), SetOptions(merge: true));
  }

  // MENU
  @override
  Future<List<MenuModel>> getWeeklyMenu(
    String messId,
    DateTime weekStart,
  ) async {
    final startIso = weekStart.toIso8601String().substring(0, 10);
    final endIso = weekStart
        .add(const Duration(days: 7))
        .toIso8601String()
        .substring(0, 10);

    final snap = await _db
        .collection('menus')
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
    final dateStr = date.toIso8601String().substring(0, 10);

    return _db
        .collection('messes')
        .doc(messId)
        .collection('weekly_templates')
        .snapshots()
        .map((snap) {
          final allMenus = snap.docs.map((d) => MenuModel.fromMap(d.data())).toList();
          final Map<String, MenuModel> slotMenus = {};

          // 1. Base regular templates: marked as 'template' (unposted for today)
          for (final m in allMenus) {
            if (m.menuId == m.mealSlot || !m.menuId.contains('_')) {
              slotMenus[m.mealSlot] = m.copyWith(
                menuType: 'template',
                isPublished: false,
                date: date,
                menuId: '${dateStr}_${m.mealSlot}',
              );
            }
          }
          for (final m in allMenus) {
            if (m.menuId.startsWith('${dayStr}_')) {
              slotMenus[m.mealSlot] = m.copyWith(
                menuType: 'template',
                isPublished: false,
                date: date,
                menuId: '${dateStr}_${m.mealSlot}',
              );
            }
          }

          // 2. Specific date post (e.g. "${dateStr}_night") overrides template
          for (final m in allMenus) {
            if (m.menuId.startsWith('${dateStr}_') || m.menuId == '${dateStr}_${m.mealSlot}') {
              slotMenus[m.mealSlot] = m.copyWith(
                isPublished: true,
                date: date,
              );
            }
          }

          return slotMenus.values.toList();
        });
  }

  @override
  Future<List<MenuModel>> getDailyMenus(String messId, DateTime date) async {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayStr = days[date.weekday - 1];
    final dateStr = date.toIso8601String().substring(0, 10);

    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('weekly_templates')
        .get();

    final allMenus = snap.docs.map((d) => MenuModel.fromMap(d.data())).toList();
    final Map<String, MenuModel> slotMenus = {};

    // 1. Base regular templates: marked as 'template'
    for (final m in allMenus) {
      if (m.menuId == m.mealSlot || !m.menuId.contains('_')) {
        slotMenus[m.mealSlot] = m.copyWith(
          menuType: 'template',
          isPublished: false,
          date: date,
          menuId: '${dateStr}_${m.mealSlot}',
        );
      }
    }
    for (final m in allMenus) {
      if (m.menuId.startsWith('${dayStr}_')) {
        slotMenus[m.mealSlot] = m.copyWith(
          menuType: 'template',
          isPublished: false,
          date: date,
          menuId: '${dateStr}_${m.mealSlot}',
        );
      }
    }

    // 2. Specific date post overrides template
    for (final m in allMenus) {
      if (m.menuId.startsWith('${dateStr}_') || m.menuId == '${dateStr}_${m.mealSlot}') {
        slotMenus[m.mealSlot] = m.copyWith(
          isPublished: true,
          date: date,
        );
      }
    }

    return slotMenus.values.toList();
  }

  @override
  Future<void> saveMenu(MenuModel menu) async {
    await _db.collection('menus').doc(menu.menuId).set(menu.toMap());
  }

  @override
  Future<void> publishMenu(String menuId) async {
    await _db.collection('menus').doc(menuId).update({'isPublished': true});
  }

  @override
  Future<void> publishDailyMenu(MenuModel menu) async {
    final dateStr = menu.date.toIso8601String().substring(0, 10);
    final docId = '${dateStr}_${menu.mealSlot}';
    final toSave = menu.copyWith(
      menuId: docId,
      isPublished: true,
    );
    await _db
        .collection('messes')
        .doc(menu.messId)
        .collection('weekly_templates')
        .doc(docId)
        .set(toSave.toMap());
  }

  @override
  Future<void> deleteDailyMenu(String messId, String menuId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('weekly_templates')
        .doc(menuId)
        .delete();
  }

  // MENU (Weekly Templates)
  @override
  Future<List<MenuModel>> getWeeklyTemplate(String messId) async {
    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('weekly_templates')
        .get();
    return snap.docs.map((d) => MenuModel.fromMap(d.data())).toList();
  }

  @override
  Future<void> saveWeeklyTemplate(MenuModel menu, String dayOfWeek) async {
    await _db
        .collection('messes')
        .doc(menu.messId)
        .collection('weekly_templates')
        .doc(dayOfWeek)
        .set(menu.toMap());
  }

  // GLOBAL DISHES
  @override
  Future<List<DishModel>> searchGlobalDishes(String query) async {
    if (query.isEmpty) return [];
    final searchTerm = query.toLowerCase().trim();

    // Strategy 1: Fast server-side prefix search (requires name_lower field)
    final snap = await _db
        .collection('global_dishes')
        .where('name_lower', isGreaterThanOrEqualTo: searchTerm)
        .where('name_lower', isLessThanOrEqualTo: searchTerm + '\uf8ff')
        .limit(20)
        .get();
    
    var results = snap.docs.map((d) => DishModel.fromFirestore(d)).toList();

    // Strategy 2: Backward-compatible fallback
    // If we got nothing, it might be because the name_lower field hasn't been backfilled yet.
    if (results.isEmpty) {
      final fallbackSnap = await _db.collection('global_dishes').get();
      final allDishes = fallbackSnap.docs.map((d) => DishModel.fromFirestore(d)).toList();
      results = allDishes.where((dish) {
        return dish.name.toLowerCase().contains(searchTerm);
      }).toList();
    }

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
    final messDoc = await _db.collection('messes').doc(record.messId).get();
    if (messDoc.exists) {
      final mess = MessModel.fromMap(messDoc.data()!);
      if (CutoffHelper.isSlotCutoffPassed(record.date, record.mealSlot, mess)) {
        throw Exception('Cutoff time has passed for this meal slot.');
      }
    }
    final recordRef = _db.collection('meal_records').doc(record.recordId);
    await recordRef.set(record.toMap());
  }

  @override
  Future<void> undoSkipMeal(String recordId) async {
    final recordDoc = await _db.collection('meal_records').doc(recordId).get();
    if (recordDoc.exists) {
      final data = recordDoc.data()!;
      final messId = data['messId'] as String?;
      final slot = data['mealSlot'] as String?;
      final dateStr = data['date'] as String?;
      if (messId != null && slot != null && dateStr != null) {
        final messDoc = await _db.collection('messes').doc(messId).get();
        if (messDoc.exists) {
          final mess = MessModel.fromMap(messDoc.data()!);
          final date = DateTime.parse(dateStr.contains('T') ? dateStr : '${dateStr}T00:00:00.000');
          if (CutoffHelper.isSlotCutoffPassed(date, slot, mess)) {
            throw Exception('Cutoff time has passed. Cannot undo skip.');
          }
        }
      }
    }
    await _db.collection('meal_records').doc(recordId).delete();
  }

  @override
  Future<List<MealRecordModel>> getMealRecords(
    String studentId,
    int month,
    int year,
  ) async {
    final startIso = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final endIso = (month == 12)
        ? DateTime(year + 1, 1, 1).toIso8601String().substring(0, 10)
        : DateTime(year, month + 1, 1).toIso8601String().substring(0, 10);

    final snap = await _db
        .collection('meal_records')
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThan: endIso)
        .get();
    final records = snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList();

    // Fetch closed slots for the student's mess
    final studentSnap = await _db.collection('students').doc(studentId).get();
    if (studentSnap.exists) {
      final messId = studentSnap.data()?['messId'] as String?;
      if (messId != null) {
        final closedSnap = await _db
            .collection('messes')
            .doc(messId)
            .collection('closed_slots')
            .where('date', isGreaterThanOrEqualTo: startIso)
            .where('date', isLessThan: endIso)
            .get();

        for (var doc in closedSnap.docs) {
          final data = doc.data();
          records.add(MealRecordModel(
            recordId: doc.id,
            studentId: studentId,
            messId: messId,
            date: DateTime.parse(data['date'] + 'T00:00:00.000'),
            mealSlot: data['mealSlot'],
            status: 'absent_owner',
          ));
        }
      }
    }

    return records;
  }

  @override
  Stream<List<MealRecordModel>> streamDailyMealRecords(
    String messId,
    DateTime date,
  ) {
    final startIso = date.toIso8601String().substring(0, 10);
    final endIso = date
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    return _db
        .collection('meal_records')
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThan: endIso)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList(),
        );
  }

  @override
  Stream<List<MealRecordModel>> streamStudentDailyMealRecords(
    String studentId,
    String messId,
    DateTime date,
  ) {
    final startIso = date.toIso8601String().substring(0, 10);
    // Fetch today and tomorrow
    final endIso = date
        .add(const Duration(days: 2))
        .toIso8601String()
        .substring(0, 10);
    return _db
        .collection('meal_records')
        .where('studentId', isEqualTo: studentId)
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startIso)
        .where('date', isLessThan: endIso)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> ownerCloseDay(
    String messId,
    DateTime date,
    String mealSlot,
  ) async {
    final recordId =
        '${messId}_${date.toIso8601String().substring(0, 10)}_$mealSlot';
    await _db
        .collection('messes')
        .doc(messId)
        .collection('closed_slots')
        .doc(recordId)
        .set({
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
    await _db.collection('leaves').doc(leaveId).update({
      'status': 'cancelled',
      'cancelledAt': cancelledAt.toIso8601String(),
    });
  }

  @override
  Future<List<LeaveModel>> getUpcomingLeaves(String messId) async {
    final snap = await _db
        .collection('leaves')
        .where('messId', isEqualTo: messId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map((d) => LeaveModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<LeaveModel>> streamLeaves(String messId) {
    return _db
        .collection('leaves')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => LeaveModel.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<LeaveModel?> getActiveLeave(String studentId) async {
    final snap = await _db
        .collection('leaves')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (snap.docs.isEmpty) return null;

    final activeLeaves = snap.docs
        .map((d) => LeaveModel.fromMap(d.data()))
        .where((l) => l.status == 'active')
        .toList();

    return activeLeaves.isNotEmpty ? activeLeaves.first : null;
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
  Future<double> getPreviousUnpaidDues(
    String studentId,
    int month,
    int year,
  ) async {
    final querySnapshot = await _db
        .collection('bills')
        .where('studentId', isEqualTo: studentId)
        .where('isPaid', isEqualTo: false)
        .get();

    double totalDues = 0;
    final currentVal = year * 12 + month;

    for (var doc in querySnapshot.docs) {
      final bill = BillModel.fromMap(doc.data());
      final billVal = bill.year * 12 + bill.month;
      // Only include bills from strict previous months
      if (billVal < currentVal) {
        totalDues += bill.finalPayable;
      }
    }
    return totalDues;
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
  Future<void> addGuestMeal(
    String studentId,
    String mealSlot,
    DateTime date,
    double cost, {
    int count = 1,
  }) async {
    final studentDoc = await _db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) return;
    final messId = studentDoc.data()?['messId'];
    if (messId == null) return;

    final messDoc = await _db.collection('messes').doc(messId).get();
    if (messDoc.exists) {
      final mess = MessModel.fromMap(messDoc.data()!);
      if (CutoffHelper.isSlotCutoffPassed(date, mealSlot, mess)) {
        throw Exception('Cutoff time has passed for adding guest meals.');
      }
    }

    final batch = _db.batch();
    for (int i = 0; i < count; i++) {
      final recordId =
          '${studentId}_guest_${DateTime.now().millisecondsSinceEpoch}_$i';
      final docRef = _db.collection('meal_records').doc(recordId);
      batch.set(docRef, {
        'recordId': recordId,
        'studentId': studentId,
        'messId': messId,
        'date': date.toIso8601String().substring(0, 10),
        'mealSlot': mealSlot,
        'status': 'guest',
        'cost': cost,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // GUEST MEAL REMOVAL
  @override
  Future<void> removeGuestMeal(String recordId) async {
    await _db.collection('meal_records').doc(recordId).delete();
  }

  @override
  Stream<List<MealRecordModel>> streamTodayGuestRecords(
      String messId, DateTime today) {
    final dateStr = today.toIso8601String().substring(0, 10);
    return _db
        .collection('meal_records')
        .where('messId', isEqualTo: messId)
        .where('date', isEqualTo: dateStr)
        .where('status', isEqualTo: 'guest')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MealRecordModel.fromMap(d.data())).toList());
  }

  // ANNOUNCEMENTS
  @override
  Future<void> cleanupOldAnnouncements(String messId) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 15));
      final snap = await _db
          .collection('announcements')
          .where('messId', isEqualTo: messId)
          .get();
      
      final batch = _db.batch();
      int count = 0;
      
      for (var doc in snap.docs) {
        final data = doc.data();
        DateTime ts = DateTime.now();
        final rawTs = data['timestamp'];
        if (rawTs != null && rawTs.runtimeType.toString().contains('Timestamp')) {
          try { ts = (rawTs as dynamic).toDate() as DateTime; } catch (_) {}
        } else if (rawTs is String) {
          ts = DateTime.tryParse(rawTs) ?? DateTime.now();
        }
        
        if (ts.isBefore(cutoff)) {
          batch.delete(doc.reference);
          count++;
        }
      }
      
      if (count > 0) {
        await batch.commit();
        print("Cleaned up $count old announcements");
      }
    } catch (e) {
      print("Failed to clean up announcements: $e");
    }
  }

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
    return _db
        .collection('announcements')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => AnnouncementModel.fromMap({...d.data(), 'announcementId': d.id}))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list.take(15).toList();
        });
  }

  @override
  Future<List<AnnouncementModel>> getAnnouncements(String messId) async {
    final snap = await _db
        .collection('announcements')
        .where('messId', isEqualTo: messId)
        .get();
    final list = snap.docs.map((d) => AnnouncementModel.fromMap({...d.data(), 'announcementId': d.id})).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(15).toList();
  }

  @override
  Future<void> emergencyCloseMess(String messId, DateTime date) async {
    await _db.collection('announcements').add({
      'messId': messId,
      'message':
          '🚨 EMERGENCY: Mess is closed for today (${date.toIso8601String().substring(0, 10)})',
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Add to closed_slots for all 3 meals
    final dateStr = date.toIso8601String().substring(0, 10);
    final batch = _db.batch();
    for (var slot in ['morning', 'noon', 'evening', 'night']) {
      final doc = _db
          .collection('messes')
          .doc(messId)
          .collection('closed_slots')
          .doc('${messId}_${dateStr}_$slot');
      batch.set(doc, {
        'date': dateStr,
        'mealSlot': slot,
        'closedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> scheduleClosure(
    MessModel mess,
    DateTime startDate,
    String startSlot,
    DateTime endDate,
    String endSlot,
    String reason,
  ) async {
    final batch = _db.batch();

    // 0. Clean up previous upcoming closed_slots so modified ranges take full effect
    final startDayStr = startDate.toIso8601String().substring(0, 10);
    final existingClosed = await _db
        .collection('messes')
        .doc(mess.messId)
        .collection('closed_slots')
        .where('date', isGreaterThanOrEqualTo: startDayStr)
        .get();

    for (var doc in existingClosed.docs) {
      batch.delete(doc.reference);
    }

    // 1. Update MessModel
    final messRef = _db.collection('messes').doc(mess.messId);
    batch.update(messRef, {
      'temporarilyClosedUntil': endDate.toIso8601String(),
    });

    // 2. Iterate dates
    DateTime currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final endBound = DateTime(endDate.year, endDate.month, endDate.day);

    final allSlots = ['morning', 'noon', 'evening', 'night'];

    while (!currentDate.isAfter(endBound)) {
      List<String> activeSlots = allSlots
          .where((s) => mess.mealTimings[s]?['enabled'] == 'true')
          .toList();

      bool isStartDay = currentDate.isAtSameMomentAs(
        DateTime(startDate.year, startDate.month, startDate.day),
      );
      bool isEndDay = currentDate.isAtSameMomentAs(endBound);

      if (isStartDay && activeSlots.contains(startSlot)) {
        int startIndex = activeSlots.indexOf(startSlot);
        if (startIndex != -1) activeSlots = activeSlots.sublist(startIndex);
      }

      if (isEndDay && activeSlots.contains(endSlot)) {
        int endIndex = activeSlots.indexOf(endSlot);
        if (endIndex != -1) activeSlots = activeSlots.sublist(0, endIndex + 1);
      }

      final dateStr = currentDate.toIso8601String().substring(0, 10);
      for (var slot in activeSlots) {
        final docRef = _db
            .collection('messes')
            .doc(mess.messId)
            .collection('closed_slots')
            .doc('${mess.messId}_${dateStr}_$slot');
        batch.set(docRef, {
          'date': dateStr,
          'mealSlot': slot,
          'closedAt': FieldValue.serverTimestamp(),
        });
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Add announcement
    final annRef = _db.collection('announcements').doc();
    batch.set(annRef, {
      'messId': mess.messId,
      'message':
          '🚨 UPDATE: Mess is closed from ${startDate.toIso8601String().substring(0, 10)} ($startSlot) to ${endDate.toIso8601String().substring(0, 10)} ($endSlot).',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> reopenMess(String messId) async {
    final batch = _db.batch();

    // 1. Clear temporarilyClosedUntil on mess
    final messRef = _db.collection('messes').doc(messId);
    batch.update(messRef, {
      'temporarilyClosedUntil': null,
    });

    // 2. Remove upcoming closed_slots from today onwards
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final closedDocs = await _db
        .collection('messes')
        .doc(messId)
        .collection('closed_slots')
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .get();

    for (var doc in closedDocs.docs) {
      batch.delete(doc.reference);
    }

    // 3. Post Announcement
    final annRef = _db.collection('announcements').doc();
    batch.set(annRef, {
      'messId': messId,
      'message':
          '🎉 UPDATE: Mess is open for service! Normal meal schedules have resumed.',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // MESS CODE
  @override
  Future<String> generateUniqueMessCode() async {
    String newCode = '';
    bool isUnique = false;
    final random = math.Random.secure();
    while (!isUnique) {
      newCode = (100000 + random.nextInt(900000)).toString(); // 6 digit random
      final snap = await _db
          .collection('messes')
          .where('messCode', isEqualTo: newCode)
          .limit(1)
          .get();
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
    final snap = await _db
        .collection('messes')
        .where('messCode', isEqualTo: code)
        .limit(1)
        .get();
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
    final dateStr = "${feedback.date.year}_${feedback.date.month}_${feedback.date.day}";
    final docId = "${feedback.studentId}_${dateStr}_${feedback.mealSlot}";
    final docRef = _db
        .collection('messes')
        .doc(feedback.messId)
        .collection('feedbacks')
        .doc(docId);
    final data = feedback.toMap();
    data['feedbackId'] = docRef.id;
    await docRef.set(data);
  }

  @override
  Stream<List<FeedbackModel>> streamFeedbacks(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('feedbacks')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FeedbackModel.fromMap(d.data())).toList(),
        );
  }

  // DISH RATINGS
  @override
  Future<void> submitOrUpdateDishRating(DishRatingModel dishRating) async {
    final sanitizedDish = dishRating.dishName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final docId = dishRating.ratingId.isNotEmpty 
        ? dishRating.ratingId 
        : "${dishRating.studentId}_$sanitizedDish";

    final docRef = _db
        .collection('messes')
        .doc(dishRating.messId)
        .collection('dish_ratings')
        .doc(docId);

    final data = dishRating.toMap();
    data['ratingId'] = docRef.id;
    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteDishRating(String messId, String ratingId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('dish_ratings')
        .doc(ratingId)
        .delete();
  }

  @override
  Stream<List<DishRatingModel>> streamDishRatings(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('dish_ratings')
        .snapshots()
        .map((snap) => snap.docs.map((d) => DishRatingModel.fromMap(d.data())).toList());
  }

  // MESS REVIEWS
  @override
  Future<void> submitOrUpdateMessReview(MessReviewModel review) async {
    final docId = review.reviewId.isNotEmpty ? review.reviewId : review.studentId;
    final docRef = _db
        .collection('messes')
        .doc(review.messId)
        .collection('reviews')
        .doc(docId);

    final data = review.toMap();
    data['reviewId'] = docRef.id;
    await docRef.set(data, SetOptions(merge: true));

    // Recompute aggregate mess rating and count
    await _recalculateMessRating(review.messId);
  }

  @override
  Future<void> deleteMessReview(String messId, String reviewId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Recompute aggregate mess rating and count
    await _recalculateMessRating(messId);
  }

  @override
  Stream<List<MessReviewModel>> streamMessReviews(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('reviews')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessReviewModel.fromMap(d.data())).toList());
  }

  Future<void> _recalculateMessRating(String messId) async {
    try {
      final reviewsSnap = await _db
          .collection('messes')
          .doc(messId)
          .collection('reviews')
          .get();

      if (reviewsSnap.docs.isEmpty) {
        await _db.collection('messes').doc(messId).update({
          'rating': 0.0,
          'reviewCount': 0,
        });
        return;
      }

      double total = 0.0;
      for (final doc in reviewsSnap.docs) {
        final r = (doc.data()['rating'] as num?)?.toDouble() ?? 5.0;
        total += r;
      }
      final avg = double.parse((total / reviewsSnap.docs.length).toStringAsFixed(1));

      await _db.collection('messes').doc(messId).update({
        'rating': avg,
        'reviewCount': reviewsSnap.docs.length,
      });
    } catch (_) {}
  }

  // PLANS
  @override
  Future<List<MealPlanModel>> getMealPlans(String messId) async {
    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('meal_plans')
        .get();
    return snap.docs.map((d) => MealPlanModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<MealPlanModel>> streamMealPlans(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('meal_plans')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MealPlanModel.fromMap(d.data())).toList());
  }

  @override
  Future<void> saveMealPlan(MealPlanModel plan) async {
    await _db
        .collection('messes')
        .doc(plan.messId)
        .collection('meal_plans')
        .doc(plan.planId)
        .set(plan.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> toggleMealPlanActive(
      String messId, String planId, bool isActive) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('meal_plans')
        .doc(planId)
        .update({'isActive': isActive});
  }

  @override
  Future<void> deleteMealPlan(String messId, String planId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('meal_plans')
        .doc(planId)
        .delete();
  }

  @override
  Future<MealPlanModel?> getMealPlanById(String messId, String planId) async {
    final doc = await _db
        .collection('messes')
        .doc(messId)
        .collection('meal_plans')
        .doc(planId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return MealPlanModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateStudentMealPreference(
    String studentId,
    String messId,
    String dateIso,
    String choiceGroupId,
    String selectedSlot,
  ) async {
    final messDoc = await _db.collection('messes').doc(messId).get();
    final studentDoc = await _db.collection('students').doc(studentId).get();
    if (messDoc.exists && studentDoc.exists) {
      final mess = MessModel.fromMap(messDoc.data()!);
      final planId = studentDoc.data()?['assignedPlanId'] as String?;
      if (planId != null) {
        final plan = await getMealPlanById(messId, planId);
        if (plan != null) {
          final group = plan.choiceGroups.where((g) => g.groupId == choiceGroupId).firstOrNull;
          if (group != null) {
            final date = DateTime.parse('${dateIso}T00:00:00.000');
            if (CutoffHelper.isChoiceGroupCutoffPassed(date, group, mess)) {
              throw Exception('Cutoff time has passed for this choice group.');
            }
          }
        }
      }
    }

    final studentRef = _db.collection('students').doc(studentId);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(studentRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final rawDatePrefs = data['datePreferences'];
      Map<String, dynamic> datePrefs =
          rawDatePrefs is Map ? Map<String, dynamic>.from(rawDatePrefs) : {};
      Map<String, dynamic> dayPref =
          datePrefs[dateIso] is Map ? Map<String, dynamic>.from(datePrefs[dateIso]) : {};
      dayPref[choiceGroupId] = selectedSlot;
      datePrefs[dateIso] = dayPref;
      transaction.update(studentRef, {'datePreferences': datePrefs});
    });
  }

  @override
  Future<void> updateStudentRegularPreference(
    String studentId,
    String choiceGroupId,
    String selectedSlot,
  ) async {
    await _db.collection('students').doc(studentId).update({
      'regularMealPreference.$choiceGroupId': selectedSlot,
    });
  }

  // EXTRA FEES
  @override
  Future<List<ExtraFeeModel>> getExtraFees(
      String messId, String studentId) async {
    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('extra_fees')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.map((d) => ExtraFeeModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<ExtraFeeModel>> streamExtraFees(
      String messId, String studentId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('extra_fees')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExtraFeeModel.fromMap(d.data())).toList());
  }

  @override
  Future<void> addExtraFee(ExtraFeeModel fee) async {
    await _db
        .collection('messes')
        .doc(fee.messId)
        .collection('extra_fees')
        .doc(fee.feeId)
        .set(fee.toMap());
  }

  @override
  Future<void> deleteExtraFee(String messId, String feeId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('extra_fees')
        .doc(feeId)
        .delete();
  }

  // MESS DISHES (Isolated Mess Subcollection)
  @override
  Future<List<DishModel>> getMessDishes(String messId) async {
    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('dishes')
        .get();
    return snap.docs.map((d) => DishModel.fromMap(d.data())).toList();
  }

  @override
  Stream<List<DishModel>> streamMessDishes(String messId) {
    return _db
        .collection('messes')
        .doc(messId)
        .collection('dishes')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DishModel.fromMap(d.data())).toList());
  }

  @override
  Future<void> addDishToMess(String messId, DishModel dish) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('dishes')
        .doc(dish.dishId)
        .set(dish.toMap(), SetOptions(merge: true));

    await _db.collection('messes').doc(messId).update({
      'masterDishNames': FieldValue.arrayUnion([dish.name]),
    });
  }

  @override
  Future<void> removeDishFromMess(String messId, String dishId) async {
    final doc = await _db
        .collection('messes')
        .doc(messId)
        .collection('dishes')
        .doc(dishId)
        .get();
    String? dishName;
    if (doc.exists && doc.data() != null) {
      dishName = doc.data()!['name'] as String?;
    }

    await _db
        .collection('messes')
        .doc(messId)
        .collection('dishes')
        .doc(dishId)
        .delete();

    if (dishName != null) {
      await _db.collection('messes').doc(messId).update({
        'masterDishNames': FieldValue.arrayRemove([dishName]),
      });
    }
  }

  @override
  Future<void> updateMessDish(String messId, DishModel dish) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('dishes')
        .doc(dish.dishId)
        .set(dish.toMap(), SetOptions(merge: true));
  }
}
