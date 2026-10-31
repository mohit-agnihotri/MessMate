import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/cloudinary_config.dart';
import '../services/notification_service.dart';
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
    // 1. Strict MIME / extension validation for security
    final cleanExt = extension.toLowerCase().replaceAll('.', '').trim();
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowedExtensions.contains(cleanExt)) {
      throw Exception('Unsupported format: .$cleanExt. Only JPG, PNG, and WebP are allowed.');
    }

    // 2. Strict file size safety guard (Max 5 MB)
    const maxAllowedBytes = 5 * 1024 * 1024;
    if (bytes.lengthInBytes > maxAllowedBytes) {
      throw Exception('Image file is too large (${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1)} MB). Max limit is 5MB.');
    }

    // 3. Upload to Cloudinary with Unsigned Preset & Folder Isolation
    try {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['folder'] = 'messmate/$path'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}.$cleanExt',
          ),
        );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> responseJson = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 &&
          responseJson.containsKey('secure_url')) {
        final rawUrl = responseJson['secure_url'] as String;
        // Return Cloudinary auto-optimized CDN URL
        return CloudinaryConfig.getOptimizedUrl(rawUrl);
      } else {
        final errorMsg = responseJson['error']?['message'] ??
            'Cloudinary upload failed (HTTP ${streamedResponse.statusCode})';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[Cloudinary] Primary upload failed: $e, checking fallback...');
      // Fallback: If Cloudinary network error occurs, attempt Supabase upload if available
      try {
        final client = Supabase.instance.client;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
        final fullPath = '$path/$fileName';

        await client.storage
            .from('mess_photos')
            .uploadBinary(
              fullPath,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: 'image/$cleanExt',
              ),
            );

        return client.storage.from('mess_photos').getPublicUrl(fullPath);
      } catch (fallbackError) {
        debugPrint('[Storage] Both Cloudinary and fallback failed: $fallbackError');
        throw Exception('Image upload failed: $e');
      }
    }
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
        .where('name_lower', isLessThanOrEqualTo: '$searchTerm\uf8ff')
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
    int year, {
    String? messId,
  }) async {
    final startIso = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final endIso = (month == 12)
        ? DateTime(year + 1, 1, 1).toIso8601String().substring(0, 10)
        : DateTime(year, month + 1, 1).toIso8601String().substring(0, 10);

    String resolvedMessId = messId ?? '';
    if (resolvedMessId.isEmpty) {
      try {
        final sDoc = await _db.collection('students').doc(studentId).get();
        if (sDoc.exists && sDoc.data()?['messId'] != null) {
          resolvedMessId = sDoc.data()!['messId'] as String;
        }
      } catch (_) {}
    }

    Query query = _db.collection('meal_records').where('studentId', isEqualTo: studentId);
    if (resolvedMessId.isNotEmpty) {
      query = query.where('messId', isEqualTo: resolvedMessId);
    }

    final snap = await query.get();
    final records = snap.docs
        .map((d) => MealRecordModel.fromMap(d.data() as Map<String, dynamic>))
        .where((r) {
          final dStr = r.date.toIso8601String().substring(0, 10);
          return dStr.compareTo(startIso) >= 0 && dStr.compareTo(endIso) < 0;
        })
        .toList();

    // Fetch closed slots for the student's mess
    if (resolvedMessId.isNotEmpty) {
      final closedSnap = await _db
          .collection('messes')
          .doc(resolvedMessId)
          .collection('closed_slots')
          .get();

      // Check mess special meal configuration to properly set isSpecial
      MessModel? mess;
      try {
        final messSnap = await _db.collection('messes').doc(resolvedMessId).get();
        if (messSnap.exists && messSnap.data() != null) {
          mess = MessModel.fromMap(messSnap.data()!);
        }
      } catch (_) {}

      final existingKeys = <String>{};
      for (var r in records) {
        final dStr = r.date.toIso8601String().substring(0, 10);
        existingKeys.add('${dStr}_${r.mealSlot}');
      }

      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (var doc in closedSnap.docs) {
        final data = doc.data();
        final dateStr = (data['date'] as String?) ?? '';
        if (dateStr.compareTo(startIso) < 0 || dateStr.compareTo(endIso) >= 0) {
          continue;
        }
        final mealSlot = (data['mealSlot'] as String?) ?? '';
        final key = '${dateStr}_$mealSlot';

        if (!existingKeys.contains(key)) {
          existingKeys.add(key);

          final parsedDate = DateTime.tryParse('${dateStr}T00:00:00.000') ?? DateTime.now();
          final dayName = dayNames[parsedDate.weekday - 1];
          final bool isSpecialDay = mess != null &&
              mess.specialMealEnabled &&
              mess.specialMealDays.contains(dayName);
          final bool isSpecialSlot = mess != null &&
              isSpecialDay &&
              (mess.specialMealSlot == mealSlot);
          final bool isExplicitSpecial = data['isSpecial'] == true;

          records.add(MealRecordModel(
            recordId: doc.id,
            studentId: studentId,
            messId: resolvedMessId,
            date: parsedDate,
            mealSlot: mealSlot,
            status: 'absent_owner',
            isSpecial: isExplicitSpecial || isSpecialSlot,
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
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MealRecordModel.fromMap(d.data()))
              .where((r) {
                final dStr = r.date.toIso8601String().substring(0, 10);
                return dStr.compareTo(startIso) >= 0 && dStr.compareTo(endIso) < 0;
              })
              .toList(),
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

  @override
  Future<List<LeaveModel>> getStudentLeaves(
    String studentId, {
    String? messId,
  }) async {
    String resolvedMessId = messId ?? '';
    if (resolvedMessId.isEmpty) {
      try {
        final sDoc = await _db.collection('students').doc(studentId).get();
        if (sDoc.exists && sDoc.data()?['messId'] != null) {
          resolvedMessId = sDoc.data()!['messId'] as String;
        }
      } catch (_) {}
    }

    Query query = _db.collection('leaves').where('studentId', isEqualTo: studentId);
    if (resolvedMessId.isNotEmpty) {
      query = query.where('messId', isEqualTo: resolvedMessId);
    }

    final snap = await query.get();

    final leaves = snap.docs.map((d) => LeaveModel.fromMap(d.data() as Map<String, dynamic>)).toList();
    leaves.sort((a, b) => b.startDate.compareTo(a.startDate));
    return leaves;
  }

  // BILLING
  @override
  Future<BillModel?> getBill(String studentId, int month, int year) async {
    try {
      final billId = '${studentId}_${month}_$year';
      final doc = await _db.collection('bills').doc(billId).get();
      if (!doc.exists || doc.data() == null) return null;
      return BillModel.fromMap(doc.data()!);
    } catch (e) {
      if (e is FirebaseException && (e.code == 'permission-denied' || e.code == 'not-found')) {
        debugPrint('[Billing] getBill ungenerated bill fallback to preview: $e');
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<double> getPreviousUnpaidDues(
    String studentId,
    int month,
    int year, {
    String? messId,
  }) async {
    String resolvedMessId = messId ?? '';
    if (resolvedMessId.isEmpty) {
      try {
        final sDoc = await _db.collection('students').doc(studentId).get();
        if (sDoc.exists && sDoc.data()?['messId'] != null) {
          resolvedMessId = sDoc.data()!['messId'] as String;
        }
      } catch (_) {}
    }

    Query query = _db.collection('bills').where('studentId', isEqualTo: studentId);
    if (resolvedMessId.isNotEmpty) {
      query = query.where('messId', isEqualTo: resolvedMessId);
    }

    try {
      final querySnapshot = await query.get();

      double totalDues = 0;
      final currentVal = year * 12 + month;

      for (var doc in querySnapshot.docs) {
        final bill = BillModel.fromMap(doc.data() as Map<String, dynamic>);
        if (!bill.isPaid) {
          final billVal = bill.year * 12 + bill.month;
          // Only include bills from strict previous months
          if (billVal < currentVal) {
            totalDues += bill.finalPayable;
          }
        }
      }
      return totalDues;
    } catch (e) {
      debugPrint('[Billing] getPreviousUnpaidDues error: $e');
      return 0.0;
    }
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
        debugPrint("Cleaned up $count old announcements");
      }
    } catch (e) {
      debugPrint("Failed to clean up announcements: $e");
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
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final messRef = _db.collection('messes').doc(mess.messId);
    batch.update(messRef, {
      'temporarilyClosedUntil': endDateTime.toIso8601String(),
      'closureStartDate': startDate.toIso8601String(),
      'closureStartSlot': startSlot,
      'closureEndSlot': endSlot,
      'closureReason': reason,
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

    // 1. Delete closure fields from mess document
    final messRef = _db.collection('messes').doc(messId);
    batch.update(messRef, {
      'temporarilyClosedUntil': FieldValue.delete(),
      'closureStartDate': FieldValue.delete(),
      'closureStartSlot': FieldValue.delete(),
      'closureEndSlot': FieldValue.delete(),
      'closureReason': FieldValue.delete(),
    });

    // 2. Remove all closed_slots
    final closedDocs = await _db
        .collection('messes')
        .doc(messId)
        .collection('closed_slots')
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

  @override
  Future<List<Map<String, dynamic>>> getClosedSlots(String messId) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('closed_slots')
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .get();

    final list = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList();

    final slotOrder = {'morning': 1, 'noon': 2, 'evening': 3, 'night': 4};
    list.sort((a, b) {
      final dateComp = (a['date'] as String? ?? '').compareTo(b['date'] as String? ?? '');
      if (dateComp != 0) return dateComp;
      final slotA = slotOrder[a['mealSlot']] ?? 0;
      final slotB = slotOrder[b['mealSlot']] ?? 0;
      return slotA.compareTo(slotB);
    });

    return list;
  }

  @override
  Future<void> reopenSpecificSlot(String messId, String date, String mealSlot) async {
    final docId = '${messId}_${date}_$mealSlot';
    await _db
        .collection('messes')
        .doc(messId)
        .collection('closed_slots')
        .doc(docId)
        .delete();

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final remaining = await _db
        .collection('messes')
        .doc(messId)
        .collection('closed_slots')
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .limit(1)
        .get();

    if (remaining.docs.isEmpty) {
      await _db.collection('messes').doc(messId).update({
        'temporarilyClosedUntil': null,
        'closureStartDate': null,
        'closureStartSlot': null,
        'closureEndSlot': null,
        'closureReason': null,
      });
    }

    final slotNames = {
      'morning': 'Breakfast',
      'noon': 'Lunch',
      'evening': 'Snacks',
      'night': 'Dinner',
    };
    final prettySlot = slotNames[mealSlot] ?? mealSlot.toUpperCase();

    await _db.collection('announcements').add({
      'messId': messId,
      'message': '🎉 UPDATE: $prettySlot on $date is re-opened for service!',
      'timestamp': FieldValue.serverTimestamp(),
    });
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

  // ─── EXPENSE LEDGER (KHAATA / DAILY RATION EXPENSES) ─────────────────────
  @override
  Future<void> createExpense(ExpenseModel expense) async {
    if (expense.messId.trim().isEmpty) {
      throw ArgumentError('Mess ID cannot be empty when creating an expense');
    }
    final expensesCol = _db
        .collection('messes')
        .doc(expense.messId)
        .collection('expenses');
    final docRef = expense.id.isNotEmpty
        ? expensesCol.doc(expense.id)
        : expensesCol.doc();
    final data = expense.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _db
        .collection('messes')
        .doc(expense.messId)
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String messId, String expenseId) async {
    await _db
        .collection('messes')
        .doc(messId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  @override
  Stream<List<ExpenseModel>> streamMonthlyExpenses(String messId, int month, int year) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);

    return _db
        .collection('messes')
        .doc(messId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ExpenseModel.fromMap(doc.data(), doc.id)).toList());
  }

  @override
  Future<List<ExpenseModel>> getMonthlyExpenses(String messId, int month, int year) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);

    final snap = await _db
        .collection('messes')
        .doc(messId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((doc) => ExpenseModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<Map<String, double>> getMonthlyFinancialOverview(String messId, int month, int year) async {
    // 1. Get active enrolled students count and mess fee
    int activeCount = 0;
    double defaultMonthlyFee = 0.0;
    try {
      final messDoc = await _db.collection('messes').doc(messId).get();
      if (messDoc.exists) {
        defaultMonthlyFee = (messDoc.data()?['monthlyFee'] as num?)?.toDouble() ?? 0.0;
      }
      final studentsSnap = await _db
          .collection('students')
          .where('messId', isEqualTo: messId)
          .where('status', isEqualTo: 'active')
          .get();
      activeCount = studentsSnap.docs.length;
    } catch (_) {}

    // 2. Query monthly bills
    final snap = await _db
        .collection('bills')
        .where('messId', isEqualTo: messId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    double collected = 0.0;
    double pending = 0.0;
    int paidCount = 0;
    int pendingCount = 0;

    for (var doc in snap.docs) {
      final data = doc.data();
      final payable = (data['finalPayable'] as num?)?.toDouble() ?? 0.0;
      final isPaid = data['isPaid'] == true;
      if (isPaid) {
        collected += payable;
        paidCount++;
      } else {
        pending += payable;
        pendingCount++;
      }
    }

    // 3. Fallback: if month bills have not been generated yet, calculate projected from active students
    if (snap.docs.isEmpty && activeCount > 0 && defaultMonthlyFee > 0) {
      pending = defaultMonthlyFee * activeCount;
      pendingCount = activeCount;
    }

    return {
      'collected': collected,
      'totalCollected': collected,
      'pending': pending,
      'totalPending': pending,
      'paidCount': paidCount.toDouble(),
      'pendingCount': pendingCount.toDouble(),
      'activeCount': activeCount.toDouble(),
    };
  }

  // ─── CASCADE ACCOUNT DELETION HELPERS ──────────────────────────────
  Future<void> _deleteQueryBatch(Query query) async {
    final snap = await query.limit(300).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (snap.docs.length >= 300) {
      await _deleteQueryBatch(query);
    }
  }

  Future<void> _deleteSubcollection(DocumentReference docRef, String subcollectionName) async {
    await _deleteQueryBatch(docRef.collection(subcollectionName));
  }

  Future<void> _deleteUserWithReauthFallback(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('[FirebaseService] requires-recent-login: attempting seamless reauthentication...');
        final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
        if (isGoogle) {
          if (kIsWeb) {
            final googleProvider = GoogleAuthProvider();
            googleProvider.setCustomParameters({'prompt': 'select_account'});
            await user.reauthenticateWithPopup(googleProvider);
          } else {
            final googleSignIn = GoogleSignIn.instance;
            await googleSignIn.initialize();
            final googleUser = await googleSignIn.authenticate();
            final String? idToken = googleUser.authentication.idToken;
            String? accessToken;
            try {
              final authClient = googleUser.authorizationClient;
              final auth = await authClient.authorizationForScopes(['email', 'profile']);
              accessToken = auth?.accessToken;
            } catch (_) {}
            final credential = GoogleAuthProvider.credential(
              accessToken: accessToken,
              idToken: idToken,
            );
            await user.reauthenticateWithCredential(credential);
          }
          await user.delete();
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteStudentAccount(String studentId) async {
    // 1. Delete student meal records
    try {
      await _deleteQueryBatch(
        _db.collection('meal_records').where('studentId', isEqualTo: studentId),
      );
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting student meal_records: $e');
    }

    // 2. Delete student leaves
    try {
      await _deleteQueryBatch(
        _db.collection('leaves').where('studentId', isEqualTo: studentId),
      );
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting student leaves: $e');
    }

    // 3. Delete student support tickets
    try {
      await _deleteQueryBatch(
        _db.collection('support_tickets').where('userId', isEqualTo: studentId),
      );
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting student support tickets: $e');
    }

    // 4. Delete student document itself
    try {
      await _db.collection('students').doc(studentId).delete();
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting student doc: $e');
    }

    // 5. Revoke notification token
    try {
      await NotificationService.logout();
    } catch (_) {}

    // 6. Delete FirebaseAuth account (with seamless re-authentication if requires-recent-login)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == studentId) {
      await _deleteUserWithReauthFallback(user);
    }
  }

  @override
  Future<void> deleteOwnerAccount(String ownerId, String messId) async {
    if (messId.isNotEmpty) {
      final messRef = _db.collection('messes').doc(messId);

      // 1. Delete all subcollections inside mess doc
      const subcollections = [
        'dishes',
        'meal_plans',
        'extra_fees',
        'weekly_templates',
        'closed_slots',
        'expenses',
        'feedbacks',
        'dish_ratings',
        'reviews',
      ];
      for (final sub in subcollections) {
        try {
          await _deleteSubcollection(messRef, sub);
        } catch (e) {
          debugPrint('[FirebaseService] Error deleting subcollection $sub: $e');
        }
      }

      // 2. Delete root collections associated with this mess
      final rootMessQueries = [
        _db.collection('menus').where('messId', isEqualTo: messId),
        _db.collection('announcements').where('messId', isEqualTo: messId),
        _db.collection('bills').where('messId', isEqualTo: messId),
        _db.collection('meal_records').where('messId', isEqualTo: messId),
        _db.collection('leaves').where('messId', isEqualTo: messId),
      ];
      for (final query in rootMessQueries) {
        try {
          await _deleteQueryBatch(query);
        } catch (e) {
          debugPrint('[FirebaseService] Error deleting mess root query: $e');
        }
      }

      // 3. Release enrolled students (status left, messId cleared)
      try {
        final studentsSnap = await _db
            .collection('students')
            .where('messId', isEqualTo: messId)
            .get();
        if (studentsSnap.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in studentsSnap.docs) {
            batch.update(doc.reference, {
              'messId': '',
              'status': 'left',
              'assignedPlanId': null,
            });
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('[FirebaseService] Error releasing enrolled students: $e');
      }

      // 4. Delete mess doc itself
      try {
        await messRef.delete();
      } catch (e) {
        debugPrint('[FirebaseService] Error deleting mess doc: $e');
      }
    }

    // 5. Delete owner support tickets
    try {
      await _deleteQueryBatch(
        _db.collection('support_tickets').where('userId', isEqualTo: ownerId),
      );
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting owner support tickets: $e');
    }

    // 6. Revoke notification token
    try {
      await NotificationService.logout();
    } catch (_) {}

    // 7. Delete FirebaseAuth account (with seamless re-authentication if requires-recent-login)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == ownerId) {
      await _deleteUserWithReauthFallback(user);
    }
  }

  // DISH BATTLES / LIVE VOTING
  @override
  Future<void> createDishBattle(DishBattleModel battle) async {
    final messRef = _db.collection('messes').doc(battle.messId);
    final col = messRef.collection('dish_battles');
    final docRef = battle.battleId.isEmpty ? col.doc() : col.doc(battle.battleId);
    final toSave = DishBattleModel(
      battleId: docRef.id,
      messId: battle.messId,
      title: battle.title,
      targetSlot: battle.targetSlot,
      targetDate: battle.targetDate,
      options: battle.options,
      voterSelections: battle.voterSelections,
      createdAt: battle.createdAt,
      closesAt: battle.closesAt,
      isClosed: battle.isClosed,
      winningDishName: battle.winningDishName,
    );
    final map = toSave.toMap();

    // 1. Primary resilient path: write activeBattle on messes/{messId} (allowed by current owner rules)
    try {
      await messRef.set({'activeBattle': map}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating messes doc activeBattle: $e');
    }

    // 2. Subcollection path (for deployed rules & historical records)
    try {
      await docRef.set(map);
    } catch (e) {
      debugPrint('Subcollection dish_battles permission notice: $e');
    }
  }

  @override
  Stream<DishBattleModel?> streamActiveDishBattle(String messId) {
    if (messId.isEmpty) return Stream.value(null);

    late StreamController<DishBattleModel?> controller;
    StreamSubscription? messSub;
    StreamSubscription? ratingsSub;
    String? currentBattleId;
    DishBattleModel? latestBaseBattle;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> latestRatingsDocs = [];

    void emitMergedBattle() {
      if (latestBaseBattle == null) {
        if (!controller.isClosed) controller.add(null);
        return;
      }
      final base = latestBaseBattle!;
      if (base.isClosed) {
        if (!controller.isClosed) controller.add(base);
        return;
      }

      final voterMap = <String, String>{};
      final voteCounts = <String, int>{};

      for (final doc in latestRatingsDocs) {
        final d = doc.data();
        final sId = d['studentId'] as String?;
        final oId = d['optionId'] as String?;
        if (sId != null && oId != null) {
          voterMap[sId] = oId;
          voteCounts[oId] = (voteCounts[oId] ?? 0) + 1;
        }
      }

      for (final entry in base.voterSelections.entries) {
        if (!voterMap.containsKey(entry.key)) {
          voterMap[entry.key] = entry.value;
          voteCounts[entry.value] = (voteCounts[entry.value] ?? 0) + 1;
        }
      }

      final updatedOptions = base.options.map((opt) {
        final count = voteCounts[opt.id] ?? 0;
        return DishBattleOption(
          id: opt.id,
          name: opt.name,
          votes: count,
          icon: opt.icon,
        );
      }).toList();

      final updatedBattle = DishBattleModel(
        battleId: base.battleId,
        messId: base.messId,
        title: base.title,
        targetSlot: base.targetSlot,
        targetDate: base.targetDate,
        options: updatedOptions,
        voterSelections: voterMap,
        createdAt: base.createdAt,
        closesAt: base.closesAt,
        isClosed: base.isClosed,
        winningDishName: base.winningDishName,
      );

      if (!controller.isClosed) {
        controller.add(updatedBattle);
      }
    }

    controller = StreamController<DishBattleModel?>.broadcast(
      onListen: () {
        messSub = _db.collection('messes').doc(messId).snapshots().listen((messSnap) {
          if (!messSnap.exists) {
            latestBaseBattle = null;
            emitMergedBattle();
            return;
          }
          final raw = messSnap.data()?['activeBattle'];
          if (raw == null || raw is! Map) {
            latestBaseBattle = null;
            emitMergedBattle();
            return;
          }

          final battle = DishBattleModel.fromMap(Map<String, dynamic>.from(raw));
          latestBaseBattle = battle;

          if (battle.isClosed) {
            ratingsSub?.cancel();
            emitMergedBattle();
            return;
          }

          if (currentBattleId != battle.battleId) {
            currentBattleId = battle.battleId;
            ratingsSub?.cancel();
            ratingsSub = _db
                .collection('messes')
                .doc(messId)
                .collection('dish_ratings')
                .where('battleId', isEqualTo: battle.battleId)
                .snapshots()
                .listen((ratingsSnap) {
              latestRatingsDocs = ratingsSnap.docs;
              emitMergedBattle();
            }, onError: (e) {
              debugPrint('dish_ratings stream error: $e');
            });
          }

          emitMergedBattle();
        });
      },
      onCancel: () {
        ratingsSub?.cancel();
        messSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<DishBattleModel?> getActiveDishBattle(String messId) async {
    if (messId.isEmpty) return null;
    try {
      final snap = await _db.collection('messes').doc(messId).get();
      if (snap.exists) {
        final raw = snap.data()?['activeBattle'];
        if (raw != null && raw is Map) {
          return DishBattleModel.fromMap(Map<String, dynamic>.from(raw));
        }
      }
    } catch (_) {}

    // Fallback to subcollection
    try {
      final snap = await _db
          .collection('messes')
          .doc(messId)
          .collection('dish_battles')
          .where('isClosed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return DishBattleModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> voteDishBattle({
    required String messId,
    required String battleId,
    required String studentId,
    required String optionId,
  }) async {
    final effectiveStudentId = studentId.isNotEmpty
        ? studentId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (effectiveStudentId.isEmpty) return;

    // 1. Primary write: save vote doc in dish_ratings (enrolled student always has write permission)
    try {
      final voteDoc = _db
          .collection('messes')
          .doc(messId)
          .collection('dish_ratings')
          .doc('poll_${battleId}_$effectiveStudentId');

      await voteDoc.set({
        'studentId': effectiveStudentId,
        'battleId': battleId,
        'optionId': optionId,
        'rating': 5,
        'dishName': 'Food Battle Vote',
        'studentName': 'Student',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error writing to dish_ratings: $e');
    }

    // 2. Also save to student profile
    try {
      await _db.collection('students').doc(effectiveStudentId).set({
        'currentVote': {
          'battleId': battleId,
          'optionId': optionId,
          'votedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error writing to student profile: $e');
    }

    // 3. Subcollection dish_battles (for deployed rules & historical records)
    try {
      final battleDoc = _db
          .collection('messes')
          .doc(messId)
          .collection('dish_battles')
          .doc(battleId);
      final snap = await battleDoc.get();
      if (snap.exists) {
        final battle = DishBattleModel.fromMap(snap.data()!, snap.id);
        final updatedVoters = Map<String, String>.from(battle.voterSelections);
        final prevOpt = updatedVoters[effectiveStudentId];
        if (prevOpt != optionId) {
          updatedVoters[effectiveStudentId] = optionId;
          final updatedOptions = battle.options.map((opt) {
            int v = opt.votes;
            if (opt.id == prevOpt) v = math.max(0, v - 1);
            if (opt.id == optionId) v = v + 1;
            return DishBattleOption(id: opt.id, name: opt.name, votes: v, icon: opt.icon);
          }).toList();
          await battleDoc.update({
            'voterSelections': updatedVoters,
            'options': updatedOptions.map((o) => o.toMap()).toList(),
          });
        }
      }
    } catch (_) {}

    // 4. Update root mess doc ONLY if current user is owner (students never touch mess doc directly to prevent PERMISSION_DENIED)
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final messRef = _db.collection('messes').doc(messId);
      final snap = await messRef.get();
      if (snap.exists) {
        final ownerId = snap.data()?['ownerId'] as String?;
        if (currentUser != null && currentUser.uid == ownerId) {
          final raw = snap.data()?['activeBattle'];
          if (raw != null && raw is Map) {
            final battle = DishBattleModel.fromMap(Map<String, dynamic>.from(raw));
            final updatedVoters = Map<String, String>.from(battle.voterSelections);
            final prevOpt = updatedVoters[effectiveStudentId];
            if (prevOpt != optionId) {
              updatedVoters[effectiveStudentId] = optionId;
              final updatedOptions = battle.options.map((opt) {
                int v = opt.votes;
                if (opt.id == prevOpt) v = math.max(0, v - 1);
                if (opt.id == optionId) v = v + 1;
                return DishBattleOption(id: opt.id, name: opt.name, votes: v, icon: opt.icon);
              }).toList();

              final updatedBattle = DishBattleModel(
                battleId: battle.battleId,
                messId: battle.messId,
                title: battle.title,
                targetSlot: battle.targetSlot,
                targetDate: battle.targetDate,
                options: updatedOptions,
                voterSelections: updatedVoters,
                createdAt: battle.createdAt,
                closesAt: battle.closesAt,
                isClosed: battle.isClosed,
                winningDishName: battle.winningDishName,
              );

              await messRef.update({'activeBattle': updatedBattle.toMap()});
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> closeDishBattle(String messId, String battleId, [String? winningDish]) async {
    final messRef = _db.collection('messes').doc(messId);
    final docRef = messRef.collection('dish_battles').doc(battleId);

    try {
      final snap = await messRef.get();
      if (snap.exists) {
        final raw = snap.data()?['activeBattle'];
        if (raw != null && raw is Map) {
          final updated = Map<String, dynamic>.from(raw);
          updated['isClosed'] = true;
          if (winningDish != null && winningDish.isNotEmpty) {
            updated['winningDishName'] = winningDish;
          }
          await messRef.update({'activeBattle': updated});
        }
      }
    } catch (_) {}

    try {
      await docRef.update({
        'isClosed': true,
        if (winningDish != null && winningDish.isNotEmpty) 'winningDishName': winningDish,
      });
    } catch (_) {}
  }

  @override
  Future<void> extendDishBattle(String messId, String battleId, Duration extension) async {
    final messRef = _db.collection('messes').doc(messId);
    final docRef = messRef.collection('dish_battles').doc(battleId);

    try {
      final snap = await messRef.get();
      if (snap.exists) {
        final raw = snap.data()?['activeBattle'];
        if (raw != null && raw is Map) {
          final battle = DishBattleModel.fromMap(Map<String, dynamic>.from(raw));
          final updatedClosesAt = battle.closesAt.add(extension);
          final updated = Map<String, dynamic>.from(raw);
          updated['closesAt'] = Timestamp.fromDate(updatedClosesAt);
          await messRef.update({'activeBattle': updated});
        }
      }
    } catch (_) {}

    try {
      final snap = await docRef.get();
      if (snap.exists) {
        final battle = DishBattleModel.fromMap(snap.data()!, snap.id);
        await docRef.update({
          'closesAt': Timestamp.fromDate(battle.closesAt.add(extension)),
        });
      }
    } catch (_) {}
  }
}
