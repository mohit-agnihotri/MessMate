import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_service.dart';
import '../models/stub_service.dart';
import '../models/firebase_service.dart';
import '../models/app_models.dart';
import '../services/notification_service.dart';

import 'package:geolocator/geolocator.dart';

// ─── Global Billing Logic Helper ─────────────────────────────────────────────
import 'billing_helper.dart';
export 'billing_helper.dart';
import 'cutoff_helper.dart';
export 'cutoff_helper.dart';

// ─── Global Service Provider ─────────────────────────────────────────────────
final isDemoModeProvider = StateProvider<bool>((ref) => false);

final appServiceProvider = Provider<AppService>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  return isDemo ? StubService() : FirebaseService();
});

// ─── Auth ─────────────────────────────────────────────────────────────────────
enum AuthRole { none, owner, student, admin }

class AuthState {
  final String? userId;
  final AuthRole role;
  final bool isLoading;
  final String? error;
  final bool otpSent;
  final String? verificationId;

  const AuthState({
    this.userId,
    this.role = AuthRole.none,
    this.isLoading = false,
    this.error,
    this.otpSent = false,
    this.verificationId,
  });

  AuthState copyWith({
    String? userId,
    AuthRole? role,
    bool? isLoading,
    String? error,
    bool? otpSent,
    String? verificationId,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState());

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kIsWeb) {
        // Web: Use signInWithPopup
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
        state = state.copyWith(
          isLoading: false,
          userId: userCredential.user?.uid,
        );
      } else {
        // Native (Android/iOS) - google_sign_in v7 API
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();

        // Trigger the authentication flow
        final googleUser = await googleSignIn.authenticate();


        // v7: idToken from .authentication, accessToken from authorizationClient
        final String? idToken = googleUser.authentication.idToken;

        // Request accessToken via authorization
        String? accessToken;
        try {
          final authClient = googleUser.authorizationClient;
          final auth = await authClient.authorizationForScopes([
            'email',
            'profile',
          ]);
          accessToken = auth?.accessToken;
        } catch (_) {
          // accessToken not strictly required for Firebase ID token login
        }

        // Create a new credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        // Once signed in, return the UserCredential
        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        state = state.copyWith(
          isLoading: false,
          userId: userCredential.user?.uid,
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') || errStr.contains('cancelled') || errStr.contains('canceled') || errStr.contains('16')) {
        state = state.copyWith(isLoading: false, error: null);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in with Google: ${e.toString()}',
      );
    }
  }

  void setRole(AuthRole role) => state = state.copyWith(role: role);

  void setDemoUser({required String userId, required AuthRole role}) {
    state = state.copyWith(
      userId: userId,
      role: role,
      isLoading: false,
      error: null,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await NotificationService.logout();
    } catch (_) {}
    // Also sign out from Google on native platforms
    if (!kIsWeb) {
      try {
        final gSignIn = GoogleSignIn.instance;
        await gSignIn.initialize();
        await gSignIn.signOut();
        await gSignIn.disconnect();
      } catch (_) {}
    }
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);

// ─── Owner Dashboard ─────────────────────────────────────────────────────────
class OwnerDashboardState {
  final MessModel? mess;
  final int activeStudents;
  final int expectedHeadcount;
  final int skippingCurrentMeal;
  final int pendingRequests;
  final MenuModel? currentMeal;
  final String? announcement;
  final bool isLoading;
  final String? error;
  final String currentSlot;

  // Absentee counts
  final int morningAbsents;
  final int noonAbsents;
  final int eveningAbsents;
  final int nightAbsents;

  // Lists for absentee tracker
  final List<MealRecordModel> todayRecords;
  final List<StudentModel> activeStudentsList;
  final List<LeaveModel> upcomingLeaves;

  // Guest meals: slot -> list of guest records
  final Map<String, List<MealRecordModel>> guestsBySlot;

  // Active / Upcoming closed slots from backend
  final List<Map<String, dynamic>> closedSlots;

  const OwnerDashboardState({
    this.mess,
    this.activeStudents = 0,
    this.expectedHeadcount = 0,
    this.skippingCurrentMeal = 0,
    this.pendingRequests = 0,
    this.currentMeal,
    this.announcement,
    this.isLoading = true,
    this.error,
    this.currentSlot = 'noon',
    this.morningAbsents = 0,
    this.noonAbsents = 0,
    this.eveningAbsents = 0,
    this.nightAbsents = 0,
    this.todayRecords = const [],
    this.activeStudentsList = const [],
    this.upcomingLeaves = const [],
    this.guestsBySlot = const {},
    this.closedSlots = const [],
  });

  OwnerDashboardState copyWith({
    MessModel? mess,
    int? activeStudents,
    int? expectedHeadcount,
    int? skippingCurrentMeal,
    int? pendingRequests,
    MenuModel? currentMeal,
    String? announcement,
    bool? isLoading,
    String? error,
    String? currentSlot,
    int? morningAbsents,
    int? noonAbsents,
    int? eveningAbsents,
    int? nightAbsents,
    List<MealRecordModel>? todayRecords,
    List<StudentModel>? activeStudentsList,
    List<LeaveModel>? upcomingLeaves,
    Map<String, List<MealRecordModel>>? guestsBySlot,
    List<Map<String, dynamic>>? closedSlots,
    bool clearCurrentMeal = false,
  }) => OwnerDashboardState(
    mess: mess ?? this.mess,
    activeStudents: activeStudents ?? this.activeStudents,
    expectedHeadcount: expectedHeadcount ?? this.expectedHeadcount,
    skippingCurrentMeal: skippingCurrentMeal ?? this.skippingCurrentMeal,
    pendingRequests: pendingRequests ?? this.pendingRequests,
    currentMeal: clearCurrentMeal ? null : (currentMeal ?? this.currentMeal),
    announcement: announcement ?? this.announcement,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    currentSlot: currentSlot ?? this.currentSlot,
    morningAbsents: morningAbsents ?? this.morningAbsents,
    noonAbsents: noonAbsents ?? this.noonAbsents,
    eveningAbsents: eveningAbsents ?? this.eveningAbsents,
    nightAbsents: nightAbsents ?? this.nightAbsents,
    todayRecords: todayRecords ?? this.todayRecords,
    activeStudentsList: activeStudentsList ?? this.activeStudentsList,
    upcomingLeaves: upcomingLeaves ?? this.upcomingLeaves,
    guestsBySlot: guestsBySlot ?? this.guestsBySlot,
    closedSlots: closedSlots ?? this.closedSlots,
  );
}

class OwnerDashboardViewModel extends StateNotifier<OwnerDashboardState>
    with WidgetsBindingObserver {
  final AppService _service;
  final String ownerId;

  StreamSubscription? _studentSub;
  StreamSubscription? _leaveSub;
  StreamSubscription? _mealRecordSub;
  StreamSubscription? _menuSub;
  StreamSubscription? _announcementSub;
  StreamSubscription? _guestSub;
  Timer? _clockTimer;
  DateTime _today = DateTime.now();
  String _currentSlot = 'noon';

  List<StudentModel> _activeStudents = [];
  List<LeaveModel> _activeLeaves = [];
  List<MealRecordModel> _todayRecords = [];
  Map<String, MealPlanModel> _planMap = {};

  OwnerDashboardViewModel(this._service, this.ownerId)
    : super(const OwnerDashboardState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studentSub?.cancel();
    _leaveSub?.cancel();
    _mealRecordSub?.cancel();
    _menuSub?.cancel();
    _announcementSub?.cancel();
    _guestSub?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      _checkMidnightRollover();
    }
  }

  void _checkMidnightRollover() {
    final now = DateTime.now();
    if (now.day != _today.day ||
        now.month != _today.month ||
        now.year != _today.year) {
      _today = now;
      _subscribeToDateDependentStreams();
    }
    _recalculateCurrentSlot();
  }

  void _recalculateCurrentSlot() {
    if (state.mess == null) return;
    final now = DateTime.now();

    // Parse meal timings
    final timings = state.mess!.mealTimings;

    // Ordered list of slots
    final slots = ['morning', 'noon', 'evening', 'night'];
    String newSlot = '';

    for (String slot in slots) {
      final slotData = timings[slot];
      if (slotData != null && slotData['enabled'] == 'true') {
        final endTimeStr = slotData['end'];
        if (endTimeStr != null) {
          final parts = endTimeStr.split(':');
          if (parts.length == 2) {
            int endHour = int.tryParse(parts[0]) ?? 0;
            int endMin = int.tryParse(parts[1]) ?? 0;

            if (now.hour < endHour ||
                (now.hour == endHour && now.minute < endMin)) {
              newSlot = slot;
              break;
            }
          }
        }
      }
    }

    if (newSlot.isEmpty) {
      newSlot = 'closed';
    }

    if (newSlot != _currentSlot) {
      _currentSlot = newSlot;
      state = state.copyWith(currentSlot: newSlot);
      _recomputeHeadcount();
    }
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final mess = await _service.getMessByOwnerId(ownerId);
      if (mess == null) {
        state = state.copyWith(isLoading: false, mess: null);
        return;
      }
      state = state.copyWith(mess: mess);
      NotificationService.setUserRoleAndMess(
        role: 'owner',
        messId: mess.messId,
        userId: mess.ownerId,
        preferences: mess.ownerNotificationPrefs,
      );

      _recalculateCurrentSlot();

      _studentSub?.cancel();
      _studentSub = _service.streamStudents(mess.messId).listen((students) {
        final uniquePending = {for (var s in students.where((s) => s.status == 'pending')) s.studentId: s}.values.toList();
        _activeStudents = {for (var s in students.where((s) => s.status == 'active' || s.status == 'approved')) s.studentId: s}.values.toList();
        state = state.copyWith(
          pendingRequests: uniquePending.length,
          activeStudents: _activeStudents.length,
          activeStudentsList: _activeStudents,
        );
        _recomputeHeadcount();
      }, onError: (e) {
        debugPrint('Error in OwnerDashboard _studentSub: $e');
      });

      final leaves = await _service.getUpcomingLeaves(mess.messId);
      _activeLeaves = leaves.where((l) => l.status == 'active').toList();
      state = state.copyWith(upcomingLeaves: _activeLeaves);

      final announcements = await _service.getAnnouncements(mess.messId);
      state = state.copyWith(
        announcement: announcements.firstOrNull?.message,
      );

      try {
        final plans = await _service.getMealPlans(mess.messId);
        _planMap = {for (var p in plans) p.planId: p};
      } catch (_) {}

      try {
        final closedSlots = await _service.getClosedSlots(mess.messId);
        state = state.copyWith(closedSlots: closedSlots);
      } catch (_) {}

      // Auto-cleanup old announcements quietly in the background
      _service.cleanupOldAnnouncements(mess.messId);

      await _subscribeToDateDependentStreams();
      _recomputeHeadcount();

      _clockTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _checkMidnightRollover(),
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _subscribeToDateDependentStreams() async {
    if (state.mess == null) return;
    _mealRecordSub?.cancel();

    _mealRecordSub = _service
        .streamDailyMealRecords(state.mess!.messId, _today)
        .listen((records) {
          _todayRecords = records;
          _recomputeHeadcount();
        });

    _guestSub?.cancel();
    _guestSub = _service
        .streamTodayGuestRecords(state.mess!.messId, _today)
        .listen((guestRecords) {
          final bySlot = <String, List<MealRecordModel>>{};
          for (final r in guestRecords) {
            bySlot.putIfAbsent(r.mealSlot, () => []).add(r);
          }
          state = state.copyWith(guestsBySlot: bySlot);
        });

    final menus = await _service.getDailyMenus(state.mess!.messId, _today);
    final currentMenu = menus
        .where((m) => m.mealSlot == _currentSlot)
        .firstOrNull;
    state = state.copyWith(
      currentMeal: currentMenu,
      clearCurrentMeal: currentMenu == null,
    );
  }

  void _recomputeHeadcount() {
    if (state.mess == null ||
        _currentSlot.isEmpty ||
        _currentSlot == 'closed') {
      state = state.copyWith(expectedHeadcount: 0, skippingCurrentMeal: 0);
      return;
    }

    final slotsOrder = ['morning', 'noon', 'evening', 'night'];
    final currentSlotIdx = slotsOrder.indexOf(_currentSlot);

    // Emergency closure check: If owner closed this specific slot, expected drops strictly to 0!
    final bool isSlotClosedByOwner = _todayRecords.any(
      (r) => r.mealSlot == _currentSlot && r.status == 'absent_owner',
    );

    int expected = 0;
    int skipping = 0;
    final todayIso = _today.toIso8601String().substring(0, 10);

    for (var student in _activeStudents) {
      // 1. Slot-granular leave check
      bool isOnLeave = _activeLeaves.any((l) {
        if (l.studentId != student.studentId) return false;
        final startIso = l.startDate.toIso8601String().substring(0, 10);
        final endIso = l.endDate.toIso8601String().substring(0, 10);

        if (todayIso.compareTo(startIso) < 0 || todayIso.compareTo(endIso) > 0) {
          return false;
        }

        if (startIso == endIso && todayIso == startIso) {
          final sIdx = l.startSlot != null ? slotsOrder.indexOf(l.startSlot!) : 0;
          final eIdx = l.endSlot != null ? slotsOrder.indexOf(l.endSlot!) : slotsOrder.length - 1;
          return currentSlotIdx >= sIdx && currentSlotIdx <= eIdx;
        }

        if (todayIso == startIso) {
          final sIdx = l.startSlot != null ? slotsOrder.indexOf(l.startSlot!) : 0;
          return currentSlotIdx >= sIdx;
        }

        if (todayIso == endIso) {
          final eIdx = l.endSlot != null ? slotsOrder.indexOf(l.endSlot!) : slotsOrder.length - 1;
          return currentSlotIdx <= eIdx;
        }

        return true;
      });

      if (isOnLeave) {
        continue;
      }

      // 2. Plan-aware slot check: Is _currentSlot part of student's plan for today?
      bool isSlotInPlan = true;
      if (student.assignedPlanId != null && _planMap.containsKey(student.assignedPlanId)) {
        final plan = _planMap[student.assignedPlanId]!;
        if (plan.fixedMeals.contains(_currentSlot)) {
          isSlotInPlan = true;
        } else {
          bool foundInChoice = false;
          for (final cg in plan.choiceGroups) {
            if (cg.availableMeals.contains(_currentSlot)) {
              final chosenSlot = student.datePreferences[todayIso]?[cg.groupId] ??
                  student.regularMealPreference[cg.groupId] ??
                  cg.availableMeals.first;
              if (chosenSlot == _currentSlot) {
                foundInChoice = true;
                break;
              }
            }
          }
          isSlotInPlan = foundInChoice;
        }
      }

      if (!isSlotInPlan) {
        continue;
      }

      // 3. Skipped check
      bool hasSkipped = _todayRecords.any(
        (r) =>
            r.studentId == student.studentId &&
            r.mealSlot == _currentSlot &&
            (r.status == 'absent_self' || r.status == 'absent_owner'),
      );

      if (hasSkipped) {
        skipping++;
      } else {
        expected++;
      }
    }

    if (isSlotClosedByOwner) {
      expected = 0;
    }

    int morning = 0;
    int noon = 0;
    int evening = 0;
    int night = 0;

    for (var r in _todayRecords) {
      if (r.status == 'absent_self' || r.status == 'absent_owner') {
        if (r.mealSlot == 'morning') {
          morning++;
        } else if (r.mealSlot == 'noon') {
          noon++;
        } else if (r.mealSlot == 'evening') {
          evening++;
        } else if (r.mealSlot == 'night') {
          night++;
        }
      }
    }

    state = state.copyWith(
      expectedHeadcount: expected,
      skippingCurrentMeal: skipping,
      morningAbsents: morning,
      noonAbsents: noon,
      eveningAbsents: evening,
      nightAbsents: night,
      todayRecords: _todayRecords,
    );
  }

  Future<void> sendAnnouncement(String message) async {
    if (state.mess == null) return;
    await _service.sendAnnouncement(state.mess!.messId, message);
    try {
      await NotificationService.sendMessNotification(
        messId: state.mess!.messId,
        title: '📢 Notice from ${state.mess?.name ?? "Mess"}',
        message: message,
        targetPref: 'announcements',
        data: {'type': 'announcement', 'messId': state.mess!.messId},
      );
    } catch (e) {
      debugPrint('[OneSignal] Error sending announcement push: $e');
    }
  }

  Future<void> emergencyClose(
    DateTime startDate,
    String startSlot,
    DateTime endDate,
    String endSlot,
    String reason,
  ) async {
    if (state.mess == null) return;
    await _service.scheduleClosure(
      state.mess!,
      startDate,
      startSlot,
      endDate,
      endSlot,
      reason,
    );
    await _init();
  }

  Future<void> reopenMess([String? messId]) async {
    final targetMessId = messId ?? state.mess?.messId;
    if (targetMessId == null || targetMessId.isEmpty) return;
    await _service.reopenMess(targetMessId);
    if (state.mess != null) {
      state = state.copyWith(
        mess: state.mess!.clearClosure(),
        closedSlots: [],
      );
    }
    await _init();
  }

  Future<void> reopenSpecificSlot(String date, String mealSlot) async {
    if (state.mess == null) return;
    await _service.reopenSpecificSlot(state.mess!.messId, date, mealSlot);
    await _init();
  }

  Future<void> reload() async {
    await _init();
  }
}

final ownerDashboardProvider =
    StateNotifierProvider.autoDispose<OwnerDashboardViewModel, OwnerDashboardState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return OwnerDashboardViewModel(ref.read(appServiceProvider), uid);
    });

// ─── Owner Students ───────────────────────────────────────────────────────────
class OwnerStudentsState {
  final List<StudentModel> students;
  final List<StudentModel> pending;
  final String messCode;
  final bool isLoading;

  const OwnerStudentsState({
    this.students = const [],
    this.pending = const [],
    this.messCode = '------',
    this.isLoading = true,
  });

  OwnerStudentsState copyWith({
    List<StudentModel>? students,
    List<StudentModel>? pending,
    String? messCode,
    bool? isLoading,
  }) => OwnerStudentsState(
    students: students ?? this.students,
    pending: pending ?? this.pending,
    messCode: messCode ?? this.messCode,
    isLoading: isLoading ?? this.isLoading,
  );
}

class OwnerStudentsViewModel extends StateNotifier<OwnerStudentsState> {
  final AppService _service;
  final String ownerId;
  StreamSubscription<List<StudentModel>>? _studentsSub;

  OwnerStudentsViewModel(this._service, this.ownerId)
    : super(const OwnerStudentsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final mess = await _service.getMessByOwnerId(ownerId);
      if (mess == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(messCode: mess.messCode);

      _studentsSub?.cancel();
      _studentsSub = _service.streamStudents(mess.messId).listen((rawStudents) {
        // Deduplicate by studentId to guarantee zero duplicacy
        final uniquePending = {for (var s in rawStudents.where((s) => s.status == 'pending')) s.studentId: s}.values.toList();
        final uniqueActive = {for (var s in rawStudents.where((s) => s.status == 'active' || s.status == 'approved')) s.studentId: s}.values.toList();
        state = state.copyWith(
          students: uniqueActive,
          pending: uniquePending,
          isLoading: false,
        );
      }, onError: (e) {
        debugPrint('Error streaming students in OwnerStudentsViewModel: $e');
        state = state.copyWith(isLoading: false);
      });
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> accept(String studentId, [String? planId]) async {
    final mess = await _service.getMessByOwnerId(ownerId);
    if (mess != null) {
      await _service.acceptStudent(mess.messId, studentId, planId);
    }
  }

  Future<void> reject(String studentId) async {
    final mess = await _service.getMessByOwnerId(ownerId);
    if (mess != null) {
      await _service.rejectStudent(mess.messId, studentId);
    }
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    super.dispose();
  }

  Future<void> toggleBillPaymentStatus(
    StudentModel student,
    BillModel previewBill,
    bool isPaid, {
    int? extendDays,
  }) async {
    final billId = '${student.studentId}_${previewBill.month}_${previewBill.year}';
    final existingBill = await _service.getBill(student.studentId, previewBill.month, previewBill.year);
    final bool wasPaid = existingBill?.isPaid ?? false;

    // Idempotency: if already in target state, do nothing
    if (wasPaid == isPaid && existingBill != null) {
      return;
    }

    final finalBill = BillModel(
      billId: billId,
      studentId: previewBill.studentId,
      messId: previewBill.messId.isNotEmpty ? previewBill.messId : student.messId,
      month: previewBill.month,
      year: previewBill.year,
      baseFee: previewBill.baseFee,
      proratedDiscount: previewBill.proratedDiscount,
      totalDeductions: previewBill.totalDeductions,
      extraMealsAddon: previewBill.extraMealsAddon,
      guestAddons: previewBill.guestAddons,
      extraFeesAddon: previewBill.extraFeesAddon,
      finalPayable: previewBill.finalPayable,
      excessCreditGenerated: previewBill.excessCreditGenerated,
      previousDues: previewBill.previousDues,
      isPaid: isPaid,
      autoSettled: previewBill.autoSettled,
      validSkipsRewarded: previewBill.validSkipsRewarded,
      daysToExtend: isPaid ? (extendDays ?? previewBill.daysToExtend) : 0,
      planId: previewBill.planId,
      planName: previewBill.planName,
      deductions: previewBill.deductions,
      platformFee: previewBill.platformFee,
      carryForwardCredit: previewBill.carryForwardCredit,
      normalSkipsCount: previewBill.normalSkipsCount,
      normalSkipsDeduction: previewBill.normalSkipsDeduction,
      specialSkipsCount: previewBill.specialSkipsCount,
      specialSkipsDeduction: previewBill.specialSkipsDeduction,
      currentMonthSkipsCount: previewBill.currentMonthSkipsCount,
      currentMonthSkipsAmount: previewBill.currentMonthSkipsAmount,
    );
    await _service.saveBill(finalBill);

    // Fire student push notification in background (non-blocking)
    if (student.notificationPrefs['billUpdated'] != false) {
      NotificationService.sendStudentNotification(
        studentId: student.studentId,
        title: isPaid ? '💳 Bill Marked Paid' : '📄 Bill Updated',
        message: isPaid
            ? 'Payment recorded for ${previewBill.month}. Amount: ₹${previewBill.finalPayable}'
            : 'Your bill for ${previewBill.month} has been updated. Amount: ₹${previewBill.finalPayable}',
        data: {
          'type': 'bill',
          'billId': finalBill.billId,
          'studentId': student.studentId,
        },
      ).catchError((e) {
        debugPrint('[OneSignal] Error sending student bill push: $e');
        return false;
      });
    }

    // Handle Extend Validity logic properly and idempotently
    final effectiveExtendDays = extendDays ?? existingBill?.daysToExtend ?? previewBill.daysToExtend;
    if (wasPaid != isPaid && effectiveExtendDays > 0) {
      final currentStudent =
          await _service.getStudentById(student.studentId) ?? student;
      final int bYear = previewBill.year;
      final int bMonth = previewBill.month;
      final DateTime defaultMonthEnd = DateTime(bYear, bMonth + 1, 0);
      final DateTime baseEndDate = (currentStudent.subscriptionEndDate != null &&
              currentStudent.subscriptionEndDate!.isAfter(DateTime(bYear, bMonth, 1)))
          ? currentStudent.subscriptionEndDate!
          : defaultMonthEnd;

      if (!wasPaid && isPaid) {
        // Toggled ON: Add the extended days once from baseEndDate
        final newEndDate = baseEndDate.add(Duration(days: effectiveExtendDays));
        await _service.updateStudent(
          currentStudent.copyWith(subscriptionEndDate: newEndDate),
        );
      } else if (wasPaid && !isPaid) {
        // Toggled OFF: Subtract the days back once
        final newEndDate = currentStudent.subscriptionEndDate != null
            ? currentStudent.subscriptionEndDate!.subtract(Duration(days: effectiveExtendDays))
            : defaultMonthEnd;
        await _service.updateStudent(
          currentStudent.copyWith(subscriptionEndDate: newEndDate),
        );
      }
    }
  }

    Future<void> regenerateCode() async {
    final mess = await _service.getMessByOwnerId(ownerId);
    if (mess != null) {
      final code = await _service.regenerateMessCode(mess.messId);
      state = state.copyWith(messCode: code);
    }
  }
}

final ownerStudentsProvider =
    StateNotifierProvider<OwnerStudentsViewModel, OwnerStudentsState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return OwnerStudentsViewModel(ref.read(appServiceProvider), uid);
    });

// ─── Owner Menu ───────────────────────────────────────────────────────────────
class OwnerMenuState {
  final bool isLoading;
  final String messId;
  final MessModel? mess;
  final String selectedDay; // 'Mon', 'Tue', 'Wed', etc.
  final String selectedSlot; // 'morning', 'noon', 'evening', 'night'
  final List<MenuModel> weeklyTemplates;
  final List<DishModel> selectedDishes;

  // Search state
  final String searchQuery;
  final List<DishModel> searchResults;
  final bool isSearching;

  const OwnerMenuState({
    this.isLoading = false,
    this.messId = '',
    this.mess,
    this.selectedDay = 'Mon',
    this.selectedSlot = 'morning',
    this.weeklyTemplates = const [],
    this.selectedDishes = const [],
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
  });

  OwnerMenuState copyWith({
    bool? isLoading,
    String? messId,
    MessModel? mess,
    String? selectedDay,
    String? selectedSlot,
    List<MenuModel>? weeklyTemplates,
    List<DishModel>? selectedDishes,
    String? searchQuery,
    List<DishModel>? searchResults,
    bool? isSearching,
  }) {
    return OwnerMenuState(
      isLoading: isLoading ?? this.isLoading,
      messId: messId ?? this.messId,
      mess: mess ?? this.mess,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      weeklyTemplates: weeklyTemplates ?? this.weeklyTemplates,
      selectedDishes: selectedDishes ?? this.selectedDishes,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class OwnerMenuViewModel extends StateNotifier<OwnerMenuState> {
  final AppService _service;
  final String ownerId;

  OwnerMenuViewModel(this._service, this.ownerId)
    : super(const OwnerMenuState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final mess = await _service.getMessByOwnerId(ownerId);
      if (mess == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final templates = await _service.getWeeklyTemplate(mess.messId);

      String activeSlot = state.selectedSlot;
      if (mess.mealTimings[activeSlot]?['enabled'] != 'true') {
        final slots = ['morning', 'noon', 'evening', 'night'];
        for (final s in slots) {
          if (mess.mealTimings[s]?['enabled'] == 'true') {
            activeSlot = s;
            break;
          }
        }
      }

      state = state.copyWith(
        messId: mess.messId,
        mess: mess,
        isLoading: false,
        weeklyTemplates: templates,
      );
      _updateSelectedFor(state.selectedDay, activeSlot, templates);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Error loading menu templates: $e');
    }
  }

  void _updateSelectedFor(String day, String slot, List<MenuModel> templates) {
    final template = templates.firstWhere(
      (m) =>
          m.menuId == slot ||
          m.menuId == '${day}_$slot' ||
          (m.mealSlot == slot && m.dishes.isNotEmpty),
      orElse: () => MenuModel(
        menuId: slot,
        messId: state.messId,
        date: DateTime.now(),
        mealSlot: slot,
        dishes: [],
      ),
    );
    state = state.copyWith(
      selectedDay: day,
      selectedSlot: slot,
      weeklyTemplates: templates,
      selectedDishes: template.dishes,
    );
  }

  void selectDay(String day) {
    _updateSelectedFor(day, state.selectedSlot, state.weeklyTemplates);
  }

  void selectSlot(String slot) {
    _updateSelectedFor(state.selectedDay, slot, state.weeklyTemplates);
  }

  void _syncTemplates(List<DishModel> newDishes) {
    final slot = state.selectedSlot;
    final existingIndex = state.weeklyTemplates.indexWhere(
      (m) => m.menuId == slot || m.mealSlot == slot,
    );

    final updatedMenu = MenuModel(
      menuId: slot,
      messId: state.messId,
      date: DateTime.now(),
      mealSlot: slot,
      dishes: newDishes,
    );

    final newTemplates = List<MenuModel>.from(state.weeklyTemplates);
    if (existingIndex >= 0) {
      newTemplates[existingIndex] = updatedMenu;
    } else {
      newTemplates.add(updatedMenu);
    }

    state = state.copyWith(
      selectedDishes: newDishes,
      weeklyTemplates: newTemplates,
    );
  }

  void addDish(DishModel dish) {
    if (!state.selectedDishes.any((d) => d.dishId == dish.dishId)) {
      _syncTemplates([...state.selectedDishes, dish]);
    }
  }

  void removeDish(DishModel dish) {
    _syncTemplates(
      state.selectedDishes.where((d) => d.dishId != dish.dishId).toList(),
    );
  }

  Future<void> searchGlobalDishes(String query) async {
    state = state.copyWith(searchQuery: query, isSearching: true);
    try {
      final results = await _service.searchGlobalDishes(query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false);
      debugPrint('Error searching: $e');
    }
  }

  Future<void> saveTemplate() async {
    final slot = state.selectedSlot;
    final menu = MenuModel(
      menuId: slot,
      messId: state.messId,
      date: DateTime.now(),
      mealSlot: slot,
      dishes: state.selectedDishes,
    );

    // Save as primary regular slot menu
    await _service.saveWeeklyTemplate(menu, slot);

    // Also populate all 7 days for seamless backward compatibility
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final day in days) {
      final dayMenu = MenuModel(
        menuId: '${day}_$slot',
        messId: state.messId,
        date: DateTime.now(),
        mealSlot: slot,
        dishes: state.selectedDishes,
      );
      await _service.saveWeeklyTemplate(dayMenu, '${day}_$slot');
    }

    // Refresh state
    await load();
  }

  Future<void> publishTodayMenu({
    required String slot,
    required String menuType, // 'regular' or 'special'
    required List<DishModel> dishes,
  }) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10);
    final menu = MenuModel(
      menuId: '${dateStr}_$slot',
      messId: state.messId,
      date: now,
      mealSlot: slot,
      dishes: dishes,
      menuType: menuType,
      isFullDayEquivalent: menuType == 'special',
      isPublished: true,
    );
    await _service.publishDailyMenu(menu);
    await load();
    try {
      final dishNames = dishes.map((d) => d.name).take(3).join(', ');
      final title = menuType == 'special'
          ? '✨ Special Today Menu (${slot.toUpperCase()})'
          : "Today's Menu Updated (${slot.toUpperCase()})";
      final body = dishNames.isNotEmpty
          ? 'Menu: $dishNames'
          : 'Check out today\'s meal options!';
      await NotificationService.sendMessNotification(
        messId: state.messId,
        title: title,
        message: body,
        targetPref: 'menuPublished',
        data: {'type': 'menu', 'slot': slot, 'messId': state.messId},
      );
    } catch (e) {
      debugPrint('[OneSignal] Error sending menu push: $e');
    }
  }

  Future<void> removeTodayMenu(String slot) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10);
    final menuId = '${dateStr}_$slot';
    await _service.deleteDailyMenu(state.messId, menuId);
    await load();
  }
}

final ownerMenuProvider =
    StateNotifierProvider.autoDispose<OwnerMenuViewModel, OwnerMenuState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return OwnerMenuViewModel(ref.read(appServiceProvider), uid);
    });

// OwnerDishesViewModel removed as per Phase 2

// ─── Student Home ─────────────────────────────────────────────────────────────
class StudentHomeState {
  final MessModel? mess;
  final StudentModel? student;
  final MealPlanModel? assignedPlan;
  final MenuModel? currentMeal;
  final MenuModel? nextMeal;
  final LeaveModel? activeLeave;
  final Duration? timeLeftToCutoff;
  final bool hasSelfSkipped;
  final bool isLoading;
  final AnnouncementModel? announcement;
  final List<AnnouncementModel> announcements;
  final int unseenAnnouncementsCount;
  final String currentSlot;
  final String nextSlot;
  final List<String> upcomingSlots;
  final Map<String, MenuModel> todayMenus;
  final Map<String, MenuModel> tomorrowMenus;
  final Map<String, String> skippedUpcomingMeals;
  final String? error;

  const StudentHomeState({
    this.mess,
    this.student,
    this.assignedPlan,
    this.currentMeal,
    this.nextMeal,
    this.activeLeave,
    this.timeLeftToCutoff,
    this.hasSelfSkipped = false,
    this.isLoading = true,
    this.announcement,
    this.announcements = const [],
    this.unseenAnnouncementsCount = 0,
    this.currentSlot = 'morning',
    this.nextSlot = 'noon',
    this.upcomingSlots = const [],
    this.todayMenus = const {},
    this.tomorrowMenus = const {},
    this.skippedUpcomingMeals = const {},
    this.error,
  });

  bool get isNextMealTomorrow {
    final slots = ['morning', 'noon', 'evening', 'night'];
    return currentSlot == 'closed' ||
        slots.indexOf(nextSlot) <= slots.indexOf(currentSlot);
  }

  StudentHomeState copyWith({
    MessModel? mess,
    StudentModel? student,
    MealPlanModel? assignedPlan,
    MenuModel? currentMeal,
    MenuModel? nextMeal,
    LeaveModel? activeLeave,
    Duration? timeLeftToCutoff,
    bool? hasSelfSkipped,
    bool? isLoading,
    AnnouncementModel? announcement,
    List<AnnouncementModel>? announcements,
    int? unseenAnnouncementsCount,
    String? currentSlot,
    String? nextSlot,
    List<String>? upcomingSlots,
    Map<String, MenuModel>? todayMenus,
    Map<String, MenuModel>? tomorrowMenus,
    Map<String, String>? skippedUpcomingMeals,
    String? error,
    bool clearCurrentMeal = false,
    bool clearNextMeal = false,
    bool clearActiveLeave = false,
  }) => StudentHomeState(
    mess: mess ?? this.mess,
    student: student ?? this.student,
    assignedPlan: assignedPlan ?? this.assignedPlan,
    currentMeal: clearCurrentMeal ? null : (currentMeal ?? this.currentMeal),
    nextMeal: clearNextMeal ? null : (nextMeal ?? this.nextMeal),
    activeLeave: clearActiveLeave ? null : (activeLeave ?? this.activeLeave),
    timeLeftToCutoff: timeLeftToCutoff ?? this.timeLeftToCutoff,
    hasSelfSkipped: hasSelfSkipped ?? this.hasSelfSkipped,
    isLoading: isLoading ?? this.isLoading,
    announcement: announcement ?? this.announcement,
    announcements: announcements ?? this.announcements,
    unseenAnnouncementsCount: unseenAnnouncementsCount ?? this.unseenAnnouncementsCount,
    currentSlot: currentSlot ?? this.currentSlot,
    nextSlot: nextSlot ?? this.nextSlot,
    upcomingSlots: upcomingSlots ?? this.upcomingSlots,
    todayMenus: todayMenus ?? this.todayMenus,
    tomorrowMenus: tomorrowMenus ?? this.tomorrowMenus,
    skippedUpcomingMeals: skippedUpcomingMeals ?? this.skippedUpcomingMeals,
    error: error ?? this.error,
  );
}

class StudentHomeViewModel extends StateNotifier<StudentHomeState>
    with WidgetsBindingObserver {
  final AppService _service;
  final Ref? _ref;

  StreamSubscription? _mealRecordSub;
  StreamSubscription? _menuSub;
  StreamSubscription? _tomorrowMenuSub;
  StreamSubscription? _announcementSub;
  Timer? _clockTimer;
  DateTime _today = DateTime.now();

  bool _isSkipping = false;
  bool _isUndoing = false;
  bool _isAddingGuest = false;

  StudentHomeViewModel(this._service, [this._ref]) : super(const StudentHomeState()) {
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mealRecordSub?.cancel();
    _menuSub?.cancel();
    _tomorrowMenuSub?.cancel();
    _announcementSub?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      _checkMidnightRollover();
    }
  }

  void _checkMidnightRollover() {
    final now = DateTime.now();
    if (now.day != _today.day ||
        now.month != _today.month ||
        now.year != _today.year) {
      _today = now;
      _subscribeToDateDependentStreams();
    }
    _recalculateTimeState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final student = await _service.getStudentById(uid);
      final mess = student != null
          ? await _service.getMessById(student.messId)
          : null;
      final leave = student != null ? await _service.getActiveLeave(uid) : null;

      if (mess != null) {
        try {
          FirebaseMessaging.instance.subscribeToTopic('mess_${mess.messId}');
        } catch (_) {}

        _announcementSub = _service.streamAnnouncements(mess.messId).listen((
          anns,
        ) async {
          final prefs = await SharedPreferences.getInstance();
          final lastSeen = prefs.getString('last_seen_announcement_id');
          int unseenCount = 0;
          for (final a in anns) {
            if (a.announcementId == lastSeen) break;
            unseenCount++;
          }
          state = state.copyWith(
            announcement: anns.firstOrNull,
            announcements: anns,
            unseenAnnouncementsCount: unseenCount,
          );
        });
      }

      MealPlanModel? plan;
      if (student?.assignedPlanId != null && mess != null) {
        try {
          plan = await _service.getMealPlanById(mess.messId, student!.assignedPlanId!);
        } catch (_) {}
      }
      state = state.copyWith(student: student, activeLeave: leave, mess: mess, assignedPlan: plan);

      _subscribeToDateDependentStreams();
      _recalculateTimeState();

      _clockTimer?.cancel();
      _clockTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _checkMidnightRollover(),
      );
    } catch (e, st) {
      debugPrint('Error loading student dashboard: $e');
      debugPrint(st.toString());
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void _subscribeToDateDependentStreams() {
    if (state.mess == null || state.student == null) return;
    _mealRecordSub?.cancel();
    _menuSub?.cancel();
    _tomorrowMenuSub?.cancel();

    _mealRecordSub = _service
        .streamStudentDailyMealRecords(
          state.student!.studentId,
          state.mess!.messId,
          _today,
        )
        .listen((records) {
          bool hasSelfSkipped = false;
          final Map<String, String> skippedMeals = {};
          final todayIso = _today.toIso8601String().substring(0, 10);

          for (final r in records) {
            if (r.status == 'absent_self') {
              final rDate = r.date.toIso8601String().substring(0, 10);
              if (rDate == todayIso && r.mealSlot == state.currentSlot) {
                hasSelfSkipped = true;
              }
              skippedMeals['${rDate}_${r.mealSlot}'] = r.recordId;
            }
          }
          state = state.copyWith(
            hasSelfSkipped: hasSelfSkipped,
            skippedUpcomingMeals: skippedMeals,
          );
        });

    _menuSub = _service.streamDailyMenus(state.mess!.messId, _today).listen((
      menus,
    ) {
      final Map<String, MenuModel> todayMenusMap = {
        for (var m in menus) m.mealSlot: m,
      };

      if (state.currentSlot != 'closed') {
        final currentMenu = todayMenusMap[state.currentSlot];

        // Only use today's menu for next meal if next meal is also today
        MenuModel? nextMenu;
        final slots = ['morning', 'noon', 'evening', 'night'];
        if (slots.indexOf(state.nextSlot) > slots.indexOf(state.currentSlot)) {
          nextMenu = todayMenusMap[state.nextSlot];
        }

        state = state.copyWith(
          currentMeal: currentMenu,
          clearCurrentMeal: currentMenu == null,
          nextMeal: nextMenu ?? state.nextMeal,
          clearNextMeal: nextMenu == null && state.isNextMealTomorrow == false,
          todayMenus: todayMenusMap,
        );
      } else {
        state = state.copyWith(
          clearCurrentMeal: true,
          todayMenus: todayMenusMap,
        );
      }
    });

    final tomorrow = _today.add(const Duration(days: 1));
    _tomorrowMenuSub = _service
        .streamDailyMenus(state.mess!.messId, tomorrow)
        .listen((menus) {
          final Map<String, MenuModel> tomorrowMap = {
            for (var m in menus) m.mealSlot: m,
          };
          final slots = ['morning', 'noon', 'evening', 'night'];
          // Update nextMeal if the next meal is tomorrow
          if (state.currentSlot == 'closed' ||
              slots.indexOf(state.nextSlot) <=
                  slots.indexOf(state.currentSlot)) {
            final nextMenu = tomorrowMap[state.nextSlot];
            state = state.copyWith(
              nextMeal: nextMenu,
              tomorrowMenus: tomorrowMap,
            );
          } else {
            state = state.copyWith(tomorrowMenus: tomorrowMap);
          }
        });
  }

  void _recalculateTimeState() {
    if (state.mess == null) return;
    final now = DateTime.now();

    // Parse meal timings
    final timings = state.mess!.mealTimings;

    // Ordered list of slots
    final slots = ['morning', 'noon', 'evening', 'night'];
    final enabledSlots = slots
        .where((s) => timings[s]?['enabled'] == 'true')
        .toList();
    if (enabledSlots.isEmpty) return;

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[now.weekday - 1];
    final isSpecialDay = state.mess!.specialMealEnabled &&
        state.mess!.specialMealDays.contains(dayName);

    // On configured feast days, if owner specified cooked slots (e.g. 1 meal only), focus on cooked slots
    final List<String> activeSlots;
    if (isSpecialDay && state.mess!.specialMealCookedSlots.isNotEmpty) {
      activeSlots = enabledSlots
          .where((s) => state.mess!.specialMealCookedSlots.contains(s))
          .toList();
    } else {
      activeSlots = enabledSlots;
    }
    if (activeSlots.isEmpty) return;

    String currentSlot = '';
    String nextSlot = '';
    List<String> upcomingSlots = [];

    for (int i = 0; i < activeSlots.length; i++) {
      String slot = activeSlots[i];
      final slotData = timings[slot];
      final endTimeStr = slotData?['end'];
      if (endTimeStr != null) {
        final parts = endTimeStr.split(':');
        if (parts.length == 2) {
          int endHour = int.tryParse(parts[0]) ?? 0;
          int endMin = int.tryParse(parts[1]) ?? 0;

          if (now.hour < endHour ||
              (now.hour == endHour && now.minute < endMin)) {
            currentSlot = slot;
            nextSlot = activeSlots[(i + 1) % activeSlots.length];
            if (i + 1 < activeSlots.length) {
              upcomingSlots = activeSlots.sublist(i + 1);
            }
            break;
          }
        }
      }
    }

    if (currentSlot.isEmpty) {
      currentSlot = 'closed';
      nextSlot = activeSlots.first;
    }

    final startStr =
        timings[currentSlot == 'closed' ? nextSlot : currentSlot]?['start'] ??
        '00:00';
    DateTime cutoffTime = _parseTimeToday(startStr)
        .subtract(Duration(hours: state.mess!.cutoffHours));

    Duration timeLeft = cutoffTime.difference(now);
    if (timeLeft.isNegative) timeLeft = Duration.zero;

    bool slotChanged = currentSlot != state.currentSlot;

    state = state.copyWith(
      currentSlot: currentSlot,
      nextSlot: nextSlot,
      upcomingSlots: upcomingSlots,
      timeLeftToCutoff: timeLeft,
    );

    if (slotChanged) {
      _subscribeToDateDependentStreams();
    }
  }

  DateTime _parseTimeToday(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  Future<void> skipMeal(String mealSlot, {DateTime? date}) async {
    if (_isSkipping) return;
    _isSkipping = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final mealDate = date ?? _today;
      final mess = state.mess;
      final currentSkipRate = state.assignedPlan?.deductionPolicy.flatRate ?? mess?.perMealRate ?? 40.0;

      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final dayName = dayNames[mealDate.weekday - 1];
      // Strict Feast Rule (Option B): Special rebate strictly restricted to configured Feast Days
      final isSpecialDay = mess?.specialMealEnabled == true &&
          (mess?.specialMealDays.contains(dayName) ?? false);
      final isSpecialSlot = isSpecialDay && mess?.specialMealSlot == mealSlot;
      final isSpecialPosted = isSpecialDay &&
          (state.todayMenus[mealSlot]?.menuType == 'special' ||
              (state.todayMenus[mealSlot]?.isFullDayEquivalent ?? false));
      final isSpecial = isSpecialDay && (isSpecialSlot || isSpecialPosted);

      final double effectiveCost;
      if (isSpecial) {
        if (mess?.specialMealFlatRate != null && mess!.specialMealFlatRate! > 0) {
          effectiveCost = mess.specialMealFlatRate!;
        } else {
          final extendCount = (mess?.specialMealExtendMeals != null &&
                  mess!.specialMealExtendMeals > 0)
              ? mess.specialMealExtendMeals
              : (mess?.specialMealMultiplier.round() ?? 1);
          effectiveCost = currentSkipRate * extendCount;
        }
      } else {
        effectiveCost = currentSkipRate;
      }

      final record = MealRecordModel(
        recordId:
            '${uid}_${mealSlot}_${mealDate.toIso8601String().substring(0, 10)}',
        studentId: uid,
        messId: mess?.messId ?? '',
        date: mealDate,
        mealSlot: mealSlot,
        status: 'absent_self',
        cost: effectiveCost,
        isSpecial: isSpecial,
        cancelledAt: DateTime.now(),
      );
      await _service.skipMeal(record);
      _ref?.invalidate(studentHistoryProvider);
      _ref?.invalidate(studentBillProvider);

      if (mess != null && mess.ownerId.isNotEmpty) {
        try {
          final bill =
              await _service.getBill(uid, mealDate.month, mealDate.year);
          final isAlreadyPaid = bill?.isPaid ?? false;
          final studentName = state.student?.name ?? 'A student';
          final slotUpper = mealSlot.toUpperCase();
          final dateStr = '${mealDate.day}/${mealDate.month}';

          if (isAlreadyPaid &&
              mess.ownerNotificationPrefs['postPaymentSkipAlert'] == true) {
            await NotificationService.sendOwnerNotification(
              ownerId: mess.ownerId,
              title: '⏭️ Post-Payment Skip Alert',
              message:
                  '$studentName (Paid Member) skipped $slotUpper on $dateStr. Will adjust in next bill.',
              data: {
                'type': 'post_payment_skip',
                'studentId': uid,
                'messId': mess.messId,
              },
            );
          } else if (!isAlreadyPaid &&
              mess.ownerNotificationPrefs['skipAlert'] == true) {
            await NotificationService.sendOwnerNotification(
              ownerId: mess.ownerId,
              title: '⏭️ Meal Skip Alert',
              message: '$studentName skipped $slotUpper on $dateStr.',
              data: {
                'type': 'meal_skip',
                'studentId': uid,
                'messId': mess.messId,
              },
            );
          }
        } catch (e) {
          debugPrint('[OneSignal] Error sending skip push to owner: $e');
        }
      }
    } finally {
      _isSkipping = false;
    }
  }

  Future<void> undoSkip(String recordId) async {
    if (_isUndoing) return;
    _isUndoing = true;
    try {
      await _service.undoSkipMeal(recordId);
      state = state.copyWith(hasSelfSkipped: false);
      _ref?.invalidate(studentHistoryProvider);
      _ref?.invalidate(studentBillProvider);
    } catch (e) {
      debugPrint('[StudentHomeViewModel] undoSkip error: $e');
      rethrow;
    } finally {
      _isUndoing = false;
    }
  }

  Future<void> addGuest(
    String mealSlot,
    double cost, {
    DateTime? date,
    int count = 1,
  }) async {
    if (_isAddingGuest) return;
    _isAddingGuest = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _service.addGuestMeal(
        uid,
        mealSlot,
        date ?? DateTime.now(),
        cost,
        count: count,
      );
    } finally {
      _isAddingGuest = false;
    }
  }

  Future<void> selectChoiceMeal(String choiceGroupId, String selectedSlot, {DateTime? date}) async {
    if (state.student == null || state.mess == null) return;
    final mealDate = date ?? _today;
    final dateIso = mealDate.toIso8601String().substring(0, 10);
    try {
      await _service.updateStudentMealPreference(
        state.student!.studentId,
        state.mess!.messId,
        dateIso,
        choiceGroupId,
        selectedSlot,
      );
      final currentPrefs = Map<String, Map<String, String>>.from(state.student!.datePreferences);
      final dayPrefs = Map<String, String>.from(currentPrefs[dateIso] ?? {});
      dayPrefs[choiceGroupId] = selectedSlot;
      currentPrefs[dateIso] = dayPrefs;
      final updatedStudent = state.student!.copyWith(datePreferences: currentPrefs);
      state = state.copyWith(student: updatedStudent);
    } catch (e) {
      debugPrint('Error updating choice meal: $e');
      rethrow;
    }
  }

  Future<void> saveRegularPreference(String choiceGroupId, String selectedSlot) async {
    if (state.student == null) return;
    try {
      await _service.updateStudentRegularPreference(
        state.student!.studentId,
        choiceGroupId,
        selectedSlot,
      );
      final regPrefs = Map<String, String>.from(state.student!.regularMealPreference);
      regPrefs[choiceGroupId] = selectedSlot;

      // If today's cutoff has NOT passed yet, also sync today's date preference so home screen updates immediately
      Map<String, Map<String, String>> updatedDatePrefs =
          Map<String, Map<String, String>>.from(state.student!.datePreferences);
      final todayIso = _today.toIso8601String().substring(0, 10);
      bool shouldSyncToday = false;

      if (state.mess != null && state.assignedPlan != null) {
        final group = state.assignedPlan!.choiceGroups
            .where((g) => g.groupId == choiceGroupId)
            .firstOrNull;
        if (group != null) {
          final isCutoffPassed = CutoffHelper.isChoiceGroupCutoffPassed(DateTime.now(), group, state.mess!);
          if (!isCutoffPassed) {
            shouldSyncToday = true;
          }
        }
      }

      if (shouldSyncToday && state.mess != null) {
        try {
          await _service.updateStudentMealPreference(
            state.student!.studentId,
            state.mess!.messId,
            todayIso,
            choiceGroupId,
            selectedSlot,
          );
          final dayPrefs = Map<String, String>.from(updatedDatePrefs[todayIso] ?? {});
          dayPrefs[choiceGroupId] = selectedSlot;
          updatedDatePrefs[todayIso] = dayPrefs;
        } catch (e) {
          debugPrint('Could not sync today preference with default: $e');
        }
      }

      final updatedStudent = state.student!.copyWith(
        regularMealPreference: regPrefs,
        datePreferences: updatedDatePrefs,
      );
      state = state.copyWith(student: updatedStudent);
    } catch (e) {
      debugPrint('Error saving regular preference: $e');
      rethrow;
    }
  }

  Future<void> cancelLeave() async {
    if (state.activeLeave != null) {
      await _service.cancelLeave(state.activeLeave!.leaveId, DateTime.now());
      state = state.copyWith(activeLeave: null);
    }
  }

  Future<void> rateMeal(String menuId, String slot, int rating) async {
    if (state.student == null || state.mess == null) return;
    try {
      final feedback = FeedbackModel(
        feedbackId: '',
        messId: state.mess!.messId,
        studentId: state.student!.studentId,
        date: DateTime.now(),
        mealSlot: slot,
        rating: rating.toDouble(),
      );
      await _service.submitFeedback(feedback);
      debugPrint("Saved rating of $rating for $slot meal to database.");
    } catch (e) {
      state = state.copyWith(error: "Failed to submit rating: $e");
    }
  }

  Future<void> markAnnouncementsAsSeen() async {
    if (state.announcements.isNotEmpty) {
      final latestId = state.announcements.first.announcementId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_announcement_id', latestId);
      state = state.copyWith(unseenAnnouncementsCount: 0);
    }
  }
}

final studentHomeProvider =
    StateNotifierProvider.autoDispose<StudentHomeViewModel, StudentHomeState>((ref) {
      return StudentHomeViewModel(ref.read(appServiceProvider), ref);
    });

// ─── Student History ──────────────────────────────────────────────────────────
class StudentHistoryState {
  final List<MealRecordModel> records;
  final List<LeaveModel> leaves;
  final int selfAbsent;
  final int ownerOff;
  final DateTime selectedMonth;
  final bool isLoading;

  const StudentHistoryState({
    this.records = const [],
    this.leaves = const [],
    this.selfAbsent = 0,
    this.ownerOff = 0,
    required this.selectedMonth,
    this.isLoading = true,
  });

  StudentHistoryState copyWith({
    List<MealRecordModel>? records,
    List<LeaveModel>? leaves,
    int? selfAbsent,
    int? ownerOff,
    DateTime? selectedMonth,
    bool? isLoading,
  }) => StudentHistoryState(
    records: records ?? this.records,
    leaves: leaves ?? this.leaves,
    selfAbsent: selfAbsent ?? this.selfAbsent,
    ownerOff: ownerOff ?? this.ownerOff,
    selectedMonth: selectedMonth ?? this.selectedMonth,
    isLoading: isLoading ?? this.isLoading,
  );
}

class StudentHistoryViewModel extends StateNotifier<StudentHistoryState> {
  final AppService _service;
  final String studentId;

  StudentHistoryViewModel(this._service, this.studentId)
    : super(StudentHistoryState(selectedMonth: DateTime.now())) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    List<MealRecordModel> records = [];
    List<LeaveModel> leaves = [];
    try {
      records = await _service.getMealRecords(
        studentId,
        state.selectedMonth.month,
        state.selectedMonth.year,
      );
    } catch (e) {
      debugPrint('[StudentHistoryViewModel] error loading records: $e');
    }
    try {
      leaves = await _service.getStudentLeaves(studentId);
    } catch (e) {
      debugPrint('[StudentHistoryViewModel] error loading leaves: $e');
    }
    final self = records.where((r) => r.status == 'absent_self').length;
    final ownerOff = records.where((r) => r.status == 'absent_owner').length;
    state = state.copyWith(
      records: records,
      leaves: leaves,
      selfAbsent: self,
      ownerOff: ownerOff,
      isLoading: false,
    );
  }

  void changeMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
    load();
  }

  Future<void> applyLeave(
    DateTime start,
    DateTime end, {
    String? startSlot,
    String? endSlot,
  }) async {
    final student = await _service.getStudentById(studentId);
    if (student == null) return;
    final uniqueId = FirebaseFirestore.instance.collection('leaves').doc().id;
    final leave = LeaveModel(
      leaveId: uniqueId,
      studentId: studentId,
      messId: student.messId,
      startDate: start,
      endDate: end,
      status: 'active',
      startSlot: startSlot,
      endSlot: endSlot,
    );
    await _service.applyLeave(leave);
    await load();
  }

  Future<void> cancelLeave(String leaveId) async {
    await _service.cancelLeave(leaveId, DateTime.now());
    await load();
  }

  Future<void> cancelGuest(String recordId) async {
    await _service.removeGuestMeal(recordId);
    await load();
  }
}

final studentHistoryProvider =
    StateNotifierProvider.autoDispose<StudentHistoryViewModel, StudentHistoryState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return StudentHistoryViewModel(ref.read(appServiceProvider), uid);
    });

// ─── Student Bill ─────────────────────────────────────────────────────────────
class StudentBillState {
  final BillModel? bill;
  final DateTime selectedMonth;
  final bool isLoading;
  final bool isPreview;
  final String? error;
  final double postPaymentSkipsAmount;
  final int mealsPerDay;

  const StudentBillState({
    this.bill,
    required this.selectedMonth,
    this.isLoading = true,
    this.isPreview = false,
    this.error,
    this.postPaymentSkipsAmount = 0.0,
    this.mealsPerDay = 3,
  });

  StudentBillState copyWith({
    BillModel? bill,
    DateTime? selectedMonth,
    bool? isLoading,
    bool? isPreview,
    String? error,
    double? postPaymentSkipsAmount,
    int? mealsPerDay,
  }) => StudentBillState(
    bill: bill ?? this.bill,
    selectedMonth: selectedMonth ?? this.selectedMonth,
    isLoading: isLoading ?? this.isLoading,
    isPreview: isPreview ?? this.isPreview,
    error: error,
    postPaymentSkipsAmount:
        postPaymentSkipsAmount ?? this.postPaymentSkipsAmount,
    mealsPerDay: mealsPerDay ?? this.mealsPerDay,
  );
}

class StudentBillViewModel extends StateNotifier<StudentBillState> {
  final AppService _service;
  final String studentId;

  StudentBillViewModel(this._service, this.studentId)
    : super(StudentBillState(selectedMonth: DateTime.now())) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bill = await _service.getBill(
        studentId,
        state.selectedMonth.month,
        state.selectedMonth.year,
      );

      if (bill != null) {
        double postPaymentSkips = 0.0;
        BillModel effectiveBill = bill;
        int allowedMeals = 3;
        try {
          final student = await _service.getStudentById(studentId);
          if (student != null) {
            final mess = await _service.getMessById(student.messId);
            if (mess != null) {
              MealPlanModel? plan;
              if (student.assignedPlanId != null &&
                  student.assignedPlanId!.isNotEmpty) {
                plan = await _service.getMealPlanById(
                    student.messId, student.assignedPlanId!);
              }
              allowedMeals = plan != null
                  ? plan.mealsIncludedPerDay
                  : mess.mealsIncludedPerDay;
              final currentRecords = await _service.getMealRecords(
                studentId,
                state.selectedMonth.month,
                state.selectedMonth.year,
              );
              final leaves = await _service.getStudentLeaves(studentId);
              final liveSkips = calculateCurrentMonthSkipsSummary(
                records: currentRecords,
                leaves: leaves,
                student: student,
                mess: mess,
                plan: plan,
                month: state.selectedMonth.month,
                year: state.selectedMonth.year,
              );
              effectiveBill = bill.copyWith(
                currentMonthSkipsCount: liveSkips.count,
                currentMonthSkipsAmount: liveSkips.amount,
              );
              if (bill.isPaid) {
                postPaymentSkips = calculatePostPaymentSkipsAmount(
                  savedBill: bill,
                  currentRecords: currentRecords,
                  mess: mess,
                  plan: plan,
                );
              }
            }
          }
        } catch (e) {
          debugPrint('[StudentBill] liveSkips sync error: $e');
        }
        state = state.copyWith(
          bill: effectiveBill,
          isPreview: false,
          isLoading: false,
          postPaymentSkipsAmount: postPaymentSkips,
          mealsPerDay: allowedMeals > 0 ? allowedMeals : 3,
        );
      } else {
        // Calculate preview
        final student = await _service.getStudentById(studentId);
        if (student == null) {
          state = state.copyWith(isLoading: false, error: 'Student not found');
          return;
        }

        final mess = await _service.getMessById(student.messId);
        if (mess == null) {
          state = state.copyWith(isLoading: false, error: 'Mess not found');
          return;
        }

        final records = await _service.getMealRecords(
          studentId,
          state.selectedMonth.month,
          state.selectedMonth.year,
        );

        final previousDues = await _service.getPreviousUnpaidDues(
          studentId,
          state.selectedMonth.month,
          state.selectedMonth.year,
        );

        MealPlanModel? plan;
        if (student.assignedPlanId != null && student.assignedPlanId!.isNotEmpty) {
          plan = await _service.getMealPlanById(student.messId, student.assignedPlanId!);
        }
        final int allowedMeals = plan != null ? plan.mealsIncludedPerDay : mess.mealsIncludedPerDay;

        final extraFees = await _service.getExtraFees(student.messId, studentId);
        final leaves = await _service.getStudentLeaves(studentId);

        final carryForward = await calculateCarryForwardCredit(
          studentId: studentId,
          currentMonth: state.selectedMonth.month,
          currentYear: state.selectedMonth.year,
          service: _service,
          mess: mess,
          plan: plan,
        );

        final previewBill = generateAdvancedBill(
          student: student,
          mess: mess,
          plan: plan,
          month: state.selectedMonth.month,
          year: state.selectedMonth.year,
          records: records,
          previousDues: previousDues,
          extraFees: extraFees,
          leaves: leaves,
          carryForwardResult: carryForward,
          carryForwardCredit: carryForward.amount,
          carryForwardItems: carryForward.items,
        );

        state = state.copyWith(
          bill: previewBill,
          isPreview: true,
          isLoading: false,
          mealsPerDay: allowedMeals > 0 ? allowedMeals : 3,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void changeMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
    load();
  }
}

final studentBillProvider =
    StateNotifierProvider.autoDispose<StudentBillViewModel, StudentBillState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return StudentBillViewModel(ref.read(appServiceProvider), uid);
    });

// ─── Owner Settings ───────────────────────────────────────────────────────────
class OwnerSettingsState {
  final MessModel? mess;
  final bool isLoading;
  final bool isSaved;

  const OwnerSettingsState({
    this.mess,
    this.isLoading = true,
    this.isSaved = false,
  });
  OwnerSettingsState copyWith({
    MessModel? mess,
    bool? isLoading,
    bool? isSaved,
  }) => OwnerSettingsState(
    mess: mess ?? this.mess,
    isLoading: isLoading ?? this.isLoading,
    isSaved: isSaved ?? this.isSaved,
  );
}

class OwnerSettingsViewModel extends StateNotifier<OwnerSettingsState> {
  final AppService _service;
  final String ownerId;

  OwnerSettingsViewModel(this._service, this.ownerId)
    : super(const OwnerSettingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final mess = await _service.getMessByOwnerId(ownerId);
    state = state.copyWith(mess: mess, isLoading: false);
    if (mess != null) {
      NotificationService.setUserRoleAndMess(
        role: 'owner',
        messId: mess.messId,
        userId: mess.ownerId,
        preferences: mess.ownerNotificationPrefs,
      );
    }
  }

  Future<void> save(MessModel updated) async {
    await _service.updateMess(updated);
    state = state.copyWith(mess: updated, isSaved: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) state = state.copyWith(isSaved: false);
    });
  }

  /// Toggles an owner-side FCM notification preference.
  /// Subscribes/unsubscribes from the corresponding owner FCM topic
  /// and persists the updated pref to the mess document.
  Future<void> toggleOwnerNotification(String key, bool value) async {
    final mess = state.mess;
    if (mess == null) return;

    final topicMap = {
      'skipAlert': 'owner_${mess.ownerId}_skip',
      'postPaymentSkipAlert': 'owner_${mess.ownerId}_post_skip',
      'joinRequest': 'owner_${mess.ownerId}_join',
    };
    final topic = topicMap[key];
    if (topic != null) {
      try {
        if (value) {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        }
      } catch (_) {
        // FCM may fail on web; still save the pref
      }
    }

    final updatedPrefs = Map<String, bool>.from(mess.ownerNotificationPrefs)
      ..[key] = value;
    await save(mess.copyWith(ownerNotificationPrefs: updatedPrefs));
    NotificationService.updateNotificationPreference(key, value);
  }

  Future<bool> updateGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) return false;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (state.mess != null) {
        final updated = state.mess!.copyWith(
          gpsLat: position.latitude,
          gpsLng: position.longitude,
        );
        await save(updated);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("GPS Error: $e");
      return false;
    }
  }

  Future<bool> updateAboutContent(String deltaJson) async {
    try {
      final mess = state.mess;
      if (mess == null) return false;
      final updated = mess.copyWith(aboutContent: deltaJson);
      await _service.updateMess(updated);
      state = state.copyWith(mess: updated);
      return true;
    } catch (e) {
      debugPrint('updateAboutContent error: $e');
      return false;
    }
  }
}

final ownerSettingsProvider =
    StateNotifierProvider.autoDispose<OwnerSettingsViewModel, OwnerSettingsState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return OwnerSettingsViewModel(ref.read(appServiceProvider), uid);
    });

// ─── Student Profile ──────────────────────────────────────────────────────────
class StudentProfileState {
  final StudentModel? student;
  final MessModel? mess;
  final MealPlanModel? plan;
  final List<MealPlanModel> availablePlans;
  final bool isLoading;

  const StudentProfileState({
    this.student,
    this.mess,
    this.plan,
    this.availablePlans = const [],
    this.isLoading = true,
  });

  StudentProfileState copyWith({
    StudentModel? student,
    MessModel? mess,
    MealPlanModel? plan,
    List<MealPlanModel>? availablePlans,
    bool? isLoading,
  }) => StudentProfileState(
    student: student ?? this.student,
    mess: mess ?? this.mess,
    plan: plan ?? this.plan,
    availablePlans: availablePlans ?? this.availablePlans,
    isLoading: isLoading ?? this.isLoading,
  );
}

class StudentProfileViewModel extends StateNotifier<StudentProfileState> {
  final AppService _service;
  final String studentId;

  StudentProfileViewModel(this._service, this.studentId)
    : super(const StudentProfileState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final student = await _service.getStudentById(studentId);
    final mess = student != null
        ? await _service.getMessById(student.messId)
        : null;
    MealPlanModel? plan;
    List<MealPlanModel> plans = [];
    if (student != null && mess != null && mess.messId.isNotEmpty) {
      try {
        plans = await _service.getMealPlans(mess.messId);
        if (student.assignedPlanId != null && student.assignedPlanId!.isNotEmpty) {
          plan = plans.where((p) => p.planId == student.assignedPlanId).firstOrNull ??
              await _service.getMealPlanById(mess.messId, student.assignedPlanId!);
        }
      } catch (_) {}
    }
    state = state.copyWith(
      student: student,
      mess: mess,
      plan: plan,
      availablePlans: plans,
      isLoading: false,
    );

    // Sync FCM topic subscriptions to match persisted prefs
    if (student != null && student.messId.isNotEmpty) {
      NotificationService.setUserRoleAndMess(
        role: 'student',
        messId: student.messId,
        userId: student.studentId,
        preferences: student.notificationPrefs,
      );

      final prefs = student.notificationPrefs;
      final messId = student.messId;
      final sid = student.studentId;
      final topicMap = {
        'menuPublished': 'mess_${messId}_menu',
        'cutoffReminder': 'mess_${messId}_cutoff',
        'billUpdated': 'student_${sid}_bill',
        'announcements': 'mess_${messId}_announcements',
      };
      for (final entry in topicMap.entries) {
        try {
          if (prefs[entry.key] ?? true) {
            await FirebaseMessaging.instance.subscribeToTopic(entry.value);
          } else {
            await FirebaseMessaging.instance.unsubscribeFromTopic(entry.value);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> updateProfile(StudentModel updated) async {
    await _service.updateStudent(updated);
    state = state.copyWith(student: updated);
  }

  Future<void> uploadProfilePicture(
    String path,
    Uint8List bytes,
    String extension,
  ) async {
    try {
      final url = await _service.uploadImage(path, bytes, extension);
      if (state.student != null) {
        final updatedStudent = state.student!.copyWith(photoUrl: url);
        await updateProfile(updatedStudent);
      }
    } catch (e) {
      debugPrint("Error uploading profile picture: $e");
    }
  }

  /// Toggles a specific FCM notification preference for the student.
  /// Subscribes or unsubscribes from the corresponding FCM topic
  /// and persists the choice to Firestore.
  Future<void> toggleNotification(String key, bool value) async {
    final student = state.student;
    if (student == null) return;
    final messId = student.messId;

    // Map key -> FCM topic name
    final topicMap = {
      'menuPublished': 'mess_${messId}_menu',
      'cutoffReminder': 'mess_${messId}_cutoff',
      'billUpdated': 'student_${student.studentId}_bill',
      'announcements': 'mess_${messId}_announcements',
    };

    final topic = topicMap[key];
    if (topic != null) {
      try {
        if (value) {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        }
      } catch (_) {
        // FCM topic ops may fail on web; we still save the pref
      }
    }

    final updatedPrefs = Map<String, bool>.from(student.notificationPrefs)
      ..[key] = value;
    final updated = student.copyWith(notificationPrefs: updatedPrefs);
    await _service.updateStudent(updated);
    state = state.copyWith(student: updated);
    NotificationService.updateNotificationPreference(key, value);
  }

  Future<void> requestPlanChange(String newPlanId) async {
    if (state.student != null) {
      final now = DateTime.now();
      final nextMonthFirst = (now.month == 12)
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      final updated = state.student!.copyWith(
        pendingPlanId: newPlanId,
        planEffectiveFrom: nextMonthFirst,
      );
      await _service.updateStudent(updated);
      state = state.copyWith(student: updated);
    }
  }

  Future<void> changeMealPlan(String newPlanId) => requestPlanChange(newPlanId);

  Future<void> leaveMess() async {

    if (state.student != null) {
      // Unsubscribe from all mess topics before leaving
      final messId = state.student!.messId;
      final sid = state.student!.studentId;
      for (final topic in [
        'mess_${messId}_menu',
        'mess_${messId}_cutoff',
        'student_${sid}_bill',
        'mess_${messId}_announcements',
      ]) {
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        } catch (_) {}
      }
      final updated = state.student!.copyWith(status: 'left', messId: '');
      await _service.updateStudent(updated);
      state = state.copyWith(student: updated, mess: null);
    }
  }
}

final studentProfileProvider =
    StateNotifierProvider.autoDispose<StudentProfileViewModel, StudentProfileState>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.watch(authProvider).userId ?? '';
      return StudentProfileViewModel(ref.read(appServiceProvider), uid);
    });

// ─── Owner Analytics & Ratings ──────────────────────────────────────────────
final ownerFeedbacksProvider = StreamProvider.autoDispose
    .family<List<FeedbackModel>, String>((ref, messId) {
      return ref.watch(appServiceProvider).streamFeedbacks(messId);
    });

final dishRatingsProvider = StreamProvider.autoDispose
    .family<List<DishRatingModel>, String>((ref, messId) {
      return ref.watch(appServiceProvider).streamDishRatings(messId);
    });

final messReviewsProvider = StreamProvider.autoDispose
    .family<List<MessReviewModel>, String>((ref, messId) {
      return ref.watch(appServiceProvider).streamMessReviews(messId);
    });

// ─── Kitchen Kharcha & Expense Ledger (Owner) ─────────────────────────────────
class OwnerExpenseLedgerState {
  final List<ExpenseModel> expenses;
  final DateTime selectedMonth;
  final String? selectedCategoryFilter;
  final bool isLoading;
  final double totalCollectedFees;
  final int paidStudentsCount;
  final double totalPendingFees;
  final int pendingStudentsCount;
  final int totalActiveStudents;

  const OwnerExpenseLedgerState({
    this.expenses = const [],
    required this.selectedMonth,
    this.selectedCategoryFilter,
    this.isLoading = false,
    this.totalCollectedFees = 0.0,
    this.paidStudentsCount = 0,
    this.totalPendingFees = 0.0,
    this.pendingStudentsCount = 0,
    this.totalActiveStudents = 0,
  });

  double get totalExpenses =>
      expenses.fold(0.0, (acc, e) => acc + e.amount);

  double get todayExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  double get netCashProfit => totalCollectedFees - totalExpenses;

  double get projectedProfit =>
      (totalCollectedFees + totalPendingFees) - totalExpenses;

  double get perStudentCost =>
      totalActiveStudents > 0 ? (totalExpenses / totalActiveStudents) : 0.0;

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final exp in expenses) {
      map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
    }
    return map;
  }

  List<ExpenseModel> get filteredExpenses {
    if (selectedCategoryFilter == null || selectedCategoryFilter == 'all') {
      return expenses;
    }
    return expenses
        .where((e) => e.category == selectedCategoryFilter)
        .toList();
  }

  OwnerExpenseLedgerState copyWith({
    List<ExpenseModel>? expenses,
    DateTime? selectedMonth,
    String? selectedCategoryFilter,
    bool clearCategoryFilter = false,
    bool? isLoading,
    double? totalCollectedFees,
    int? paidStudentsCount,
    double? totalPendingFees,
    int? pendingStudentsCount,
    int? totalActiveStudents,
  }) =>
      OwnerExpenseLedgerState(
        expenses: expenses ?? this.expenses,
        selectedMonth: selectedMonth ?? this.selectedMonth,
        selectedCategoryFilter: clearCategoryFilter
            ? null
            : (selectedCategoryFilter ?? this.selectedCategoryFilter),
        isLoading: isLoading ?? this.isLoading,
        totalCollectedFees: totalCollectedFees ?? this.totalCollectedFees,
        paidStudentsCount: paidStudentsCount ?? this.paidStudentsCount,
        totalPendingFees: totalPendingFees ?? this.totalPendingFees,
        pendingStudentsCount: pendingStudentsCount ?? this.pendingStudentsCount,
        totalActiveStudents: totalActiveStudents ?? this.totalActiveStudents,
      );
}

typedef ExpenseLedgerState = OwnerExpenseLedgerState;

class OwnerExpenseLedgerViewModel extends StateNotifier<OwnerExpenseLedgerState> {
  final AppService _service;
  final String messId;
  StreamSubscription<List<ExpenseModel>>? _sub;

  OwnerExpenseLedgerViewModel(this._service, this.messId)
      : super(OwnerExpenseLedgerState(selectedMonth: DateTime.now())) {
    if (messId.isNotEmpty) {
      _listenToExpenses();
      _loadFinancialOverview();
    }
  }

  void _listenToExpenses() {
    _sub?.cancel();
    state = state.copyWith(isLoading: true);
    _sub = _service
        .streamMonthlyExpenses(
          messId,
          state.selectedMonth.month,
          state.selectedMonth.year,
        )
        .listen((expList) {
      state = state.copyWith(expenses: expList, isLoading: false);
    }, onError: (_) {
      state = state.copyWith(isLoading: false);
    });
  }

  Future<void> _loadFinancialOverview() async {
    try {
      final overview = await _service.getMonthlyFinancialOverview(
        messId,
        state.selectedMonth.month,
        state.selectedMonth.year,
      );
      state = state.copyWith(
        totalCollectedFees: overview['totalCollected'] ?? 0.0,
        paidStudentsCount: (overview['paidCount'] ?? 0.0).toInt(),
        totalPendingFees: overview['totalPending'] ?? 0.0,
        pendingStudentsCount: (overview['pendingCount'] ?? 0.0).toInt(),
        totalActiveStudents: (overview['activeCount'] ?? 0.0).toInt(),
      );
    } catch (_) {}
  }

  Future<void> changeMonth(DateTime newMonth) async {
    state = state.copyWith(
      selectedMonth: newMonth,
      clearCategoryFilter: true,
      isLoading: true,
    );
    _listenToExpenses();
    await _loadFinancialOverview();
  }

  void setCategoryFilter(String category) {
    if (category == 'all') {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(selectedCategoryFilter: category);
    }
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String title,
    String? notes,
    required DateTime date,
    required String paymentMode,
  }) async {
    final exp = ExpenseModel(
      id: '',
      messId: messId,
      title: title,
      amount: amount,
      category: category,
      date: date,
      paymentMode: paymentMode,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _service.createExpense(exp);
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _service.updateExpense(expense);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _service.deleteExpense(messId, expenseId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final ownerExpenseLedgerProvider = StateNotifierProvider.autoDispose<
    OwnerExpenseLedgerViewModel, OwnerExpenseLedgerState>((ref) {
  final mess = ref.watch(ownerDashboardProvider).mess;
  final messId = mess?.messId ?? '';
  return OwnerExpenseLedgerViewModel(ref.read(appServiceProvider), messId);
});

