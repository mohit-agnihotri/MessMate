import 'package:cloud_firestore/cloud_firestore.dart';
// ============================================================
// All Data Models for MessMate App — Phase 2 Enhanced
// ============================================================

// ─────────────────────────────────────────────────────────────────────────────
//  PHASE 2: NEW MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// Deduction / rebate policy for a plan.
/// policyType: 'none' | 'dynamic_prorated' | 'flat_fixed_rate'
class DeductionPolicyModel {
  final String policyType; // 'none', 'dynamic_prorated', 'flat_fixed_rate'
  final List<String> eligibleMeals;
  final double? flatRate;
  final Map<String, double>? slotRates;
  final int? maxSkipsPerMonth;

  DeductionPolicyModel({
    this.policyType = 'dynamic_prorated',
    this.eligibleMeals = const [],
    this.flatRate,
    this.slotRates,
    this.maxSkipsPerMonth,
  });

  factory DeductionPolicyModel.fromMap(Map<String, dynamic> map) {
    return DeductionPolicyModel(
      policyType: map['policyType'] ?? 'dynamic_prorated',
      eligibleMeals: List<String>.from(map['eligibleMeals'] ?? []),
      flatRate: map['flatRate'] != null ? (map['flatRate'] as num).toDouble() : null,
      slotRates: map['slotRates'] != null
          ? Map<String, double>.from(
              (map['slotRates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
      maxSkipsPerMonth: map['maxSkipsPerMonth'] != null ? (map['maxSkipsPerMonth'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'policyType': policyType,
        'eligibleMeals': eligibleMeals,
        if (flatRate != null) 'flatRate': flatRate,
        if (slotRates != null) 'slotRates': slotRates,
        if (maxSkipsPerMonth != null) 'maxSkipsPerMonth': maxSkipsPerMonth,
      };
}

/// A choice group within a meal plan.
class ChoiceGroupModel {
  final String groupId;
  final String name;
  final List<String> availableMeals;
  final int minSelectable;
  final int maxSelectable;

  ChoiceGroupModel({
    required this.groupId,
    required this.name,
    required this.availableMeals,
    this.minSelectable = 1,
    this.maxSelectable = 1,
  });

  factory ChoiceGroupModel.fromMap(Map<String, dynamic> map) {
    return ChoiceGroupModel(
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? '',
      availableMeals: List<String>.from(map['availableMeals'] ?? []),
      minSelectable: (map['minSelectable'] ?? 1) as int,
      maxSelectable: (map['maxSelectable'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'name': name,
        'availableMeals': availableMeals,
        'minSelectable': minSelectable,
        'maxSelectable': maxSelectable,
      };
}

/// A meal plan offered by a mess.
class MealPlanModel {
  final String planId;
  final String messId;
  final String name;
  final double monthlyFee;
  final List<String> fixedMeals;
  final List<ChoiceGroupModel> choiceGroups;
  final DeductionPolicyModel deductionPolicy;
  final double? extraMealRate;
  final bool isActive;
  final DateTime createdAt;

  MealPlanModel({
    required this.planId,
    required this.messId,
    required this.name,
    required this.monthlyFee,
    this.fixedMeals = const [],
    this.choiceGroups = const [],
    DeductionPolicyModel? deductionPolicy,
    this.extraMealRate,
    this.isActive = true,
    DateTime? createdAt,
  })  : deductionPolicy = deductionPolicy ?? DeductionPolicyModel(),
        createdAt = createdAt ?? DateTime.now();

  /// Auto-computed: fixed + max selectables from each group
  int get mealsIncludedPerDay =>
      fixedMeals.length +
      choiceGroups.fold(0, (acc, g) => acc + g.maxSelectable);

  /// Validates that no slot appears more than once (disjoint invariant).
  bool get isValid {
    final Set<String> seen = {...fixedMeals};
    for (final g in choiceGroups) {
      for (final slot in g.availableMeals) {
        if (!seen.add(slot)) return false;
      }
    }
    return true;
  }

  factory MealPlanModel.fromMap(Map<String, dynamic> map) {
    return MealPlanModel(
      planId: map['planId'] ?? '',
      messId: map['messId'] ?? '',
      name: map['name'] ?? '',
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      fixedMeals: List<String>.from(map['fixedMeals'] ?? []),
      choiceGroups: (map['choiceGroups'] as List<dynamic>? ?? [])
          .map((g) => ChoiceGroupModel.fromMap(g as Map<String, dynamic>))
          .toList(),
      deductionPolicy: map['deductionPolicy'] != null
          ? DeductionPolicyModel.fromMap(
              map['deductionPolicy'] as Map<String, dynamic>)
          : DeductionPolicyModel(),
      extraMealRate: map['extraMealRate'] != null
          ? (map['extraMealRate'] as num).toDouble()
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'planId': planId,
        'messId': messId,
        'name': name,
        'monthlyFee': monthlyFee,
        'fixedMeals': fixedMeals,
        'choiceGroups': choiceGroups.map((g) => g.toMap()).toList(),
        'deductionPolicy': deductionPolicy.toMap(),
        if (extraMealRate != null) 'extraMealRate': extraMealRate,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Extra fee charged to a specific student (gas, maintenance, etc.).
class ExtraFeeModel {
  final String feeId;
  final String studentId;
  final String messId;
  final DateTime originalDate;
  final int targetBillingMonth;
  final int targetBillingYear;
  final double amount;
  final String note;
  final DateTime createdAt;

  ExtraFeeModel({
    required this.feeId,
    required this.studentId,
    required this.messId,
    required this.originalDate,
    required this.targetBillingMonth,
    required this.targetBillingYear,
    required this.amount,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExtraFeeModel.fromMap(Map<String, dynamic> map) {
    return ExtraFeeModel(
      feeId: map['feeId'] ?? '',
      studentId: map['studentId'] ?? '',
      messId: map['messId'] ?? '',
      originalDate:
          DateTime.tryParse(map['originalDate'] ?? '') ?? DateTime.now(),
      targetBillingMonth:
          (map['targetBillingMonth'] ?? DateTime.now().month) as int,
      targetBillingYear:
          (map['targetBillingYear'] ?? DateTime.now().year) as int,
      amount: (map['amount'] ?? 0.0).toDouble(),
      note: map['note'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'feeId': feeId,
        'studentId': studentId,
        'messId': messId,
        'originalDate': originalDate.toIso8601String(),
        'targetBillingMonth': targetBillingMonth,
        'targetBillingYear': targetBillingYear,
        'amount': amount,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXISTING MODELS (ENHANCED)
// ─────────────────────────────────────────────────────────────────────────────

class StudentModel {
  final String studentId;
  final String name;
  final String phone;
  final String roomNo;
  // college & course retained for backward-compat serialisation but hidden from UI
  final String college;
  final String course;
  final String email;
  final String? photoUrl;
  final DateTime joinDate;
  final String messId;
  final String status; // 'active', 'pending', 'left'
  final DateTime? subscriptionEndDate;
  final Map<String, bool> notificationPrefs;
  // Phase 2 additions:
  final String? assignedPlanId;
  final Map<String, String> regularMealPreference;
  final Map<String, Map<String, String>> datePreferences;
  final String? pendingPlanId;
  final DateTime? planEffectiveFrom;
  final String dietaryPreference; // 'veg', 'non_veg', 'eggetarian'
  final String? emergencyContact;

  static const Map<String, bool> _defaultNotifPrefs = {
    'menuPublished': true,
    'cutoffReminder': true,
    'billUpdated': true,
    'announcements': true,
  };

  StudentModel({
    required this.studentId,
    required this.name,
    required this.phone,
    required this.roomNo,
    this.college = '',
    this.course = '',
    required this.email,
    this.photoUrl,
    required this.joinDate,
    required this.messId,
    required this.status,
    this.subscriptionEndDate,
    this.notificationPrefs = _defaultNotifPrefs,
    this.assignedPlanId,
    this.regularMealPreference = const {},
    this.datePreferences = const {},
    this.pendingPlanId,
    this.planEffectiveFrom,
    this.dietaryPreference = 'veg',
    this.emergencyContact,
  });

  StudentModel copyWith({
    String? studentId,
    String? name,
    String? phone,
    String? roomNo,
    String? college,
    String? course,
    String? email,
    String? photoUrl,
    DateTime? joinDate,
    String? messId,
    String? status,
    DateTime? subscriptionEndDate,
    Map<String, bool>? notificationPrefs,
    String? assignedPlanId,
    Map<String, String>? regularMealPreference,
    Map<String, Map<String, String>>? datePreferences,
    String? pendingPlanId,
    DateTime? planEffectiveFrom,
    String? dietaryPreference,
    String? emergencyContact,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      roomNo: roomNo ?? this.roomNo,
      college: college ?? this.college,
      course: course ?? this.course,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      joinDate: joinDate ?? this.joinDate,
      messId: messId ?? this.messId,
      status: status ?? this.status,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      assignedPlanId: assignedPlanId ?? this.assignedPlanId,
      regularMealPreference:
          regularMealPreference ?? this.regularMealPreference,
      datePreferences: datePreferences ?? this.datePreferences,
      pendingPlanId: pendingPlanId ?? this.pendingPlanId,
      planEffectiveFrom: planEffectiveFrom ?? this.planEffectiveFrom,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    final rawPrefs = map['notificationPrefs'] as Map<String, dynamic>?;
    final prefs = <String, bool>{
      'menuPublished': rawPrefs?['menuPublished'] as bool? ?? true,
      'cutoffReminder': rawPrefs?['cutoffReminder'] as bool? ?? true,
      'billUpdated': rawPrefs?['billUpdated'] as bool? ?? true,
      'announcements': rawPrefs?['announcements'] as bool? ?? true,
    };
    Map<String, Map<String, String>> datePrefs = {};
    final rawDatePrefs = map['datePreferences'];
    if (rawDatePrefs is Map) {
      rawDatePrefs.forEach((dateKey, groupMap) {
        if (groupMap is Map) {
          datePrefs[dateKey.toString()] = Map<String, String>.from(
              groupMap.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      });
    }
    return StudentModel(
      studentId: map['studentId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      roomNo: map['roomNo'] ?? '',
      college: map['college'] ?? '',
      course: map['course'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      joinDate: DateTime.tryParse(map['joinDate'] ?? '') ?? DateTime.now(),
      messId: map['messId'] ?? '',
      status: map['status'] ?? 'pending',
      subscriptionEndDate: map['subscriptionEndDate'] != null
          ? DateTime.tryParse(map['subscriptionEndDate'])
          : null,
      notificationPrefs: prefs,
      assignedPlanId: map['assignedPlanId'],
      regularMealPreference: map['regularMealPreference'] != null
          ? Map<String, String>.from(map['regularMealPreference'])
          : {},
      datePreferences: datePrefs,
      pendingPlanId: map['pendingPlanId'],
      planEffectiveFrom: map['planEffectiveFrom'] != null
          ? DateTime.tryParse(map['planEffectiveFrom'])
          : null,
      dietaryPreference: map['dietaryPreference'] ?? 'veg',
      emergencyContact: map['emergencyContact'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'phone': phone,
      'roomNo': roomNo,
      'college': college,
      'course': course,
      'email': email,
      'photoUrl': photoUrl,
      'joinDate': joinDate.toIso8601String(),
      'messId': messId,
      'status': status,
      if (subscriptionEndDate != null)
        'subscriptionEndDate': subscriptionEndDate!.toIso8601String(),
      'notificationPrefs': notificationPrefs,
      if (assignedPlanId != null) 'assignedPlanId': assignedPlanId,
      if (regularMealPreference.isNotEmpty)
        'regularMealPreference': regularMealPreference,
      if (datePreferences.isNotEmpty) 'datePreferences': datePreferences,
      if (pendingPlanId != null) 'pendingPlanId': pendingPlanId,
      if (planEffectiveFrom != null)
        'planEffectiveFrom': planEffectiveFrom!.toIso8601String(),
      'dietaryPreference': dietaryPreference,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
    };
  }
}

// Sentinel value to distinguish "not provided" from "null" in copyWith
class _Sentinel {
  const _Sentinel();
}

class MessModel {
  final String messId;
  final String name;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final double gpsLat;
  final double gpsLng;
  final int capacity;
  final double monthlyFee;
  final double perMealRate;
  final int cutoffHours;
  final String messCode;
  final bool isListedOnMap;
  final bool showMenuToOutsiders;
  final bool showMenuToStudents;
  final String language;
  final String? ownerPhotoUrl;
  final List<String> messPhotos;
  final int mealsIncludedPerDay;
  final Map<String, Map<String, String>> mealTimings;
  final DateTime? temporarilyClosedUntil;
  final bool allowMealSkipping;
  final Map<String, bool> ownerNotificationPrefs;
  final String? aboutContent;
  // Phase 2 additions:
  final String foodType; // 'pure_veg' | 'non_veg' | 'both'
  final List<String> masterDishNames;

  static const Map<String, bool> _defaultOwnerNotifPrefs = {
    'skipAlert': true,
    'joinRequest': true,
  };

  MessModel({
    required this.messId,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.gpsLat,
    required this.gpsLng,
    required this.capacity,
    required this.monthlyFee,
    required this.perMealRate,
    required this.cutoffHours,
    required this.messCode,
    this.isListedOnMap = true,
    this.showMenuToOutsiders = true,
    this.showMenuToStudents = true,
    this.language = 'en',
    this.ownerPhotoUrl,
    this.messPhotos = const [],
    this.mealsIncludedPerDay = 3,
    this.mealTimings = const {
      'morning': {'start': '08:00', 'end': '10:00', 'enabled': 'true'},
      'noon': {'start': '12:30', 'end': '14:30', 'enabled': 'true'},
      'evening': {'start': '17:00', 'end': '18:30', 'enabled': 'false'},
      'night': {'start': '20:00', 'end': '22:00', 'enabled': 'true'},
    },
    this.temporarilyClosedUntil,
    this.allowMealSkipping = true,
    this.ownerNotificationPrefs = _defaultOwnerNotifPrefs,
    this.aboutContent,
    this.foodType = 'pure_veg',
    this.masterDishNames = const [],
  });

  MessModel copyWith({
    String? messId,
    String? name,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    double? gpsLat,
    double? gpsLng,
    int? capacity,
    double? monthlyFee,
    double? perMealRate,
    int? cutoffHours,
    String? messCode,
    bool? isListedOnMap,
    bool? showMenuToOutsiders,
    bool? showMenuToStudents,
    String? language,
    String? ownerPhotoUrl,
    List<String>? messPhotos,
    int? mealsIncludedPerDay,
    Map<String, Map<String, String>>? mealTimings,
    DateTime? temporarilyClosedUntil,
    bool? allowMealSkipping,
    Map<String, bool>? ownerNotificationPrefs,
    Object? aboutContent = const _Sentinel(),
    String? foodType,
    List<String>? masterDishNames,
  }) {
    return MessModel(
      messId: messId ?? this.messId,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      capacity: capacity ?? this.capacity,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      perMealRate: perMealRate ?? this.perMealRate,
      cutoffHours: cutoffHours ?? this.cutoffHours,
      messCode: messCode ?? this.messCode,
      isListedOnMap: isListedOnMap ?? this.isListedOnMap,
      showMenuToOutsiders: showMenuToOutsiders ?? this.showMenuToOutsiders,
      showMenuToStudents: showMenuToStudents ?? this.showMenuToStudents,
      language: language ?? this.language,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      messPhotos: messPhotos ?? this.messPhotos,
      mealsIncludedPerDay: mealsIncludedPerDay ?? this.mealsIncludedPerDay,
      mealTimings: mealTimings ?? this.mealTimings,
      temporarilyClosedUntil:
          temporarilyClosedUntil ?? this.temporarilyClosedUntil,
      allowMealSkipping: allowMealSkipping ?? this.allowMealSkipping,
      ownerNotificationPrefs:
          ownerNotificationPrefs ?? this.ownerNotificationPrefs,
      aboutContent: aboutContent is _Sentinel
          ? this.aboutContent
          : aboutContent as String?,
      foodType: foodType ?? this.foodType,
      masterDishNames: masterDishNames ?? this.masterDishNames,
    );
  }

  factory MessModel.fromMap(Map<String, dynamic> map) {
    Map<String, Map<String, String>> timings = {
      'morning': {'start': '08:00', 'end': '10:00', 'enabled': 'true'},
      'noon': {'start': '12:30', 'end': '14:30', 'enabled': 'true'},
      'evening': {'start': '17:00', 'end': '18:30', 'enabled': 'false'},
      'night': {'start': '20:00', 'end': '22:00', 'enabled': 'true'},
    };
    if (map['mealTimings'] != null) {
      final raw = map['mealTimings'] as Map;
      raw.forEach((slot, val) {
        if (val is Map) {
          timings[slot] = Map<String, String>.from(
              val.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      });
    }
    final rawOwnerPrefs =
        map['ownerNotificationPrefs'] as Map?;
    final ownerPrefs = <String, bool>{
      'skipAlert': rawOwnerPrefs?['skipAlert'] as bool? ?? true,
      'joinRequest': rawOwnerPrefs?['joinRequest'] as bool? ?? true,
    };
    DateTime? closedUntil;
    final rawClosed = map['temporarilyClosedUntil'];
    if (rawClosed != null) {
      if (rawClosed is String) {
        closedUntil = DateTime.tryParse(rawClosed);
      } else {
        try {
          closedUntil = (rawClosed as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
    }
    return MessModel(
      messId: map['messId'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      capacity: (map['capacity'] ?? 0) as int,
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      perMealRate: (map['perMealRate'] ?? 0.0).toDouble(),
      cutoffHours: (map['cutoffHours'] ?? 2) as int,
      messCode: map['messCode'] ?? '',
      isListedOnMap: map['isListedOnMap'] ?? true,
      showMenuToOutsiders: map['showMenuToOutsiders'] ?? true,
      showMenuToStudents: map['showMenuToStudents'] ?? true,
      language: map['language'] ?? 'en',
      ownerPhotoUrl: map['ownerPhotoUrl'],
      messPhotos: List<String>.from(map['messPhotos'] ?? []),
      mealsIncludedPerDay: (map['mealsIncludedPerDay'] ?? 3) as int,
      mealTimings: timings,
      temporarilyClosedUntil: closedUntil,
      allowMealSkipping: map['allowMealSkipping'] ?? true,
      ownerNotificationPrefs: ownerPrefs,
      aboutContent: map['aboutContent'],
      foodType: map['foodType'] ?? 'pure_veg',
      masterDishNames: List<String>.from(map['masterDishNames'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messId': messId,
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'capacity': capacity,
      'monthlyFee': monthlyFee,
      'perMealRate': perMealRate,
      'cutoffHours': cutoffHours,
      'messCode': messCode,
      'isListedOnMap': isListedOnMap,
      'showMenuToOutsiders': showMenuToOutsiders,
      'showMenuToStudents': showMenuToStudents,
      'language': language,
      'ownerPhotoUrl': ownerPhotoUrl,
      'messPhotos': messPhotos,
      'mealsIncludedPerDay': mealsIncludedPerDay,
      'mealTimings': mealTimings,
      if (temporarilyClosedUntil != null)
        'temporarilyClosedUntil': temporarilyClosedUntil!.toIso8601String(),
      'allowMealSkipping': allowMealSkipping,
      'ownerNotificationPrefs': ownerNotificationPrefs,
      if (aboutContent != null) 'aboutContent': aboutContent,
      'foodType': foodType,
      'masterDishNames': masterDishNames,
    };
  }
}

class DishModel {
  final String dishId;
  final String name;
  final String imageUrl;
  final String category; // 'dal','roti','rice','sabzi','sweet','snack','curry'
  final String dishFoodType; // 'veg' | 'nonveg'
  final bool isCustom;
  final String? originalGlobalId;

  DishModel({
    required this.dishId,
    required this.name,
    this.imageUrl = '',
    this.category = 'sabzi',
    this.dishFoodType = 'veg',
    this.isCustom = false,
    this.originalGlobalId,
  });

  factory DishModel.fromMap(Map<String, dynamic> map) {
    return DishModel(
      dishId: map['dishId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'sabzi',
      dishFoodType: map['dishFoodType'] ?? map['foodType'] ?? 'veg',
      isCustom: map['isCustom'] ?? false,
      originalGlobalId: map['originalGlobalId'],
    );
  }

  factory DishModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DishModel(
      dishId: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'sabzi',
      dishFoodType: data['dishFoodType'] ?? data['foodType'] ?? 'veg',
      isCustom: data['isCustom'] ?? false,
      originalGlobalId: data['originalGlobalId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'dishId': dishId,
        'name': name,
        'imageUrl': imageUrl,
        'category': category,
        'dishFoodType': dishFoodType,
        'isCustom': isCustom,
        if (originalGlobalId != null) 'originalGlobalId': originalGlobalId,
      };
}


class MenuModel {
  final String menuId;
  final String messId;
  final DateTime date;
  final String mealSlot; // 'morning', 'noon', 'night', 'evening'
  final List<DishModel> dishes;
  final bool isFullDayEquivalent;
  final bool isPublished;

  MenuModel({
    required this.menuId,
    required this.messId,
    required this.date,
    required this.mealSlot,
    required this.dishes,
    this.isFullDayEquivalent = false,
    this.isPublished = false,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    return MenuModel(
      menuId: map['menuId'] ?? '',
      messId: map['messId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      mealSlot: map['mealSlot'] ?? 'noon',
      dishes: (map['dishes'] as List<dynamic>? ?? [])
          .map((d) => DishModel.fromMap(d as Map<String, dynamic>))
          .toList(),
      isFullDayEquivalent: map['isFullDayEquivalent'] ?? false,
      isPublished: map['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'menuId': menuId,
        'messId': messId,
        'date': date.toIso8601String(),
        'dateStr': date.toIso8601String().substring(0, 10),
        'mealSlot': mealSlot,
        'dishes': dishes.map((d) => d.toMap()).toList(),
        'isFullDayEquivalent': isFullDayEquivalent,
        'isPublished': isPublished,
      };
}

class LeaveModel {
  final String leaveId;
  final String studentId;
  final String messId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'cancelled'
  final DateTime? cancelledAt;
  final String? startSlot;
  final String? endSlot;

  LeaveModel({
    required this.leaveId,
    required this.studentId,
    required this.messId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.cancelledAt,
    this.startSlot,
    this.endSlot,
  });

  factory LeaveModel.fromMap(Map<String, dynamic> map) {
    return LeaveModel(
      leaveId: map['leaveId'] ?? '',
      studentId: map['studentId'] ?? '',
      messId: map['messId'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'active',
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.tryParse(map['cancelledAt'])
          : null,
      startSlot: map['startSlot'],
      endSlot: map['endSlot'],
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'leaveId': leaveId,
      'studentId': studentId,
      'messId': messId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
    if (startSlot != null) m['startSlot'] = startSlot;
    if (endSlot != null) m['endSlot'] = endSlot;
    return m;
  }
}

class MealRecordModel {
  final String recordId;
  final String studentId;
  final String messId;
  final DateTime date;
  final String mealSlot;
  final String status; // 'present','absent_self','absent_owner','guest','extra_meal'
  final double? cost;
  final DateTime? cancelledAt;

  MealRecordModel({
    required this.recordId,
    required this.studentId,
    required this.messId,
    required this.date,
    required this.mealSlot,
    required this.status,
    this.cost,
    this.cancelledAt,
  });

  factory MealRecordModel.fromMap(Map<String, dynamic> map) {
    return MealRecordModel(
      recordId: map['recordId'] ?? '',
      studentId: map['studentId'] ?? '',
      messId: map['messId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      mealSlot: map['mealSlot'] ?? 'noon',
      status: map['status'] ?? 'present',
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.tryParse(map['cancelledAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'recordId': recordId,
        'studentId': studentId,
        'messId': messId,
        'date': date.toIso8601String().substring(0, 10),
        'mealSlot': mealSlot,
        'status': status,
        if (cost != null) 'cost': cost,
        'cancelledAt': cancelledAt?.toIso8601String(),
      };
}

class BillModel {
  final String billId;
  final String studentId;
  final String messId;
  final int month;
  final int year;
  final double baseFee;
  final double proratedDiscount;
  final double totalDeductions;
  final double extraMealsAddon;
  final double guestAddons;
  final double extraFeesAddon;
  final double finalPayable;
  final double excessCreditGenerated;
  final double previousDues;
  final bool isPaid;
  final bool autoSettled;
  final int validSkipsRewarded;
  final int daysToExtend;
  final String? planId;
  final String? planName;
  final List<DeductionItem> deductions;

  BillModel({
    required this.billId,
    required this.studentId,
    required this.messId,
    required this.month,
    required this.year,
    required this.baseFee,
    this.proratedDiscount = 0.0,
    required this.totalDeductions,
    this.extraMealsAddon = 0.0,
    this.guestAddons = 0.0,
    this.extraFeesAddon = 0.0,
    required this.finalPayable,
    this.excessCreditGenerated = 0.0,
    this.previousDues = 0,
    required this.isPaid,
    this.autoSettled = false,
    this.validSkipsRewarded = 0,
    this.daysToExtend = 0,
    this.planId,
    this.planName,
    required this.deductions,
  });

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      billId: map['billId'] ?? '',
      studentId: map['studentId'] ?? '',
      messId: map['messId'] ?? '',
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      baseFee: (map['baseFee'] ?? 0.0).toDouble(),
      proratedDiscount: (map['proratedDiscount'] ?? 0.0).toDouble(),
      totalDeductions: (map['totalDeductions'] ?? 0.0).toDouble(),
      extraMealsAddon: (map['extraMealsAddon'] ?? 0.0).toDouble(),
      guestAddons: (map['guestAddons'] ?? 0.0).toDouble(),
      extraFeesAddon: (map['extraFeesAddon'] ?? 0.0).toDouble(),
      finalPayable: (map['finalPayable'] ?? 0.0).toDouble(),
      excessCreditGenerated: (map['excessCreditGenerated'] ?? 0.0).toDouble(),
      previousDues: (map['previousDues'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      autoSettled: map['autoSettled'] ?? false,
      validSkipsRewarded: (map['validSkipsRewarded'] ?? 0) as int,
      daysToExtend: (map['daysToExtend'] ?? 0) as int,
      planId: map['planId'],
      planName: map['planName'],
      deductions: (map['deductions'] as List<dynamic>? ?? [])
          .map((d) => DeductionItem.fromMap(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'billId': billId,
        'studentId': studentId,
        'messId': messId,
        'month': month,
        'year': year,
        'baseFee': baseFee,
        'proratedDiscount': proratedDiscount,
        'totalDeductions': totalDeductions,
        'extraMealsAddon': extraMealsAddon,
        'guestAddons': guestAddons,
        'extraFeesAddon': extraFeesAddon,
        'finalPayable': finalPayable,
        'excessCreditGenerated': excessCreditGenerated,
        'previousDues': previousDues,
        'isPaid': isPaid,
        'autoSettled': autoSettled,
        'validSkipsRewarded': validSkipsRewarded,
        'daysToExtend': daysToExtend,
        if (planId != null) 'planId': planId,
        if (planName != null) 'planName': planName,
        'deductions': deductions.map((d) => d.toMap()).toList(),
      };
}

class DeductionItem {
  final DateTime date;
  final String mealSlot;
  final String type; // 'self_cancelled','owner_off','guest','extra_meal','extra_fee','prorated_discount'
  final double amount;

  DeductionItem({
    required this.date,
    required this.mealSlot,
    required this.type,
    required this.amount,
  });

  factory DeductionItem.fromMap(Map<String, dynamic> map) {
    return DeductionItem(
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      mealSlot: map['mealSlot'] ?? 'noon',
      type: map['type'] ?? 'self_cancelled',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'mealSlot': mealSlot,
        'type': type,
        'amount': amount,
      };
}

class AnnouncementModel {
  final String announcementId;
  final String messId;
  final String message;
  final DateTime timestamp;

  AnnouncementModel({
    required this.announcementId,
    required this.messId,
    required this.message,
    required this.timestamp,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    DateTime ts = DateTime.now();
    final rawTs = map['timestamp'];
    if (rawTs is DateTime) {
      ts = rawTs;
    } else if (rawTs != null &&
        rawTs.runtimeType.toString().contains('Timestamp')) {
      try {
        ts = (rawTs as dynamic).toDate() as DateTime;
      } catch (_) {}
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    }
    return AnnouncementModel(
      announcementId: map['announcementId'] ?? '',
      messId: map['messId'] ?? '',
      message: map['message'] ?? '',
      timestamp: ts,
    );
  }

  Map<String, dynamic> toMap() => {
        'announcementId': announcementId,
        'messId': messId,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}

class FeedbackModel {
  final String feedbackId;
  final String messId;
  final String studentId;
  final DateTime date;
  final String mealSlot;
  final double rating;
  final String? comment;
  final List<String> dishes;

  FeedbackModel({
    required this.feedbackId,
    required this.messId,
    required this.studentId,
    required this.date,
    required this.mealSlot,
    required this.rating,
    this.comment,
    this.dishes = const [],
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      feedbackId: map['feedbackId'] ?? '',
      messId: map['messId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      mealSlot: map['mealSlot'] ?? '',
      rating: (map['rating'] ?? 5).toDouble(),
      comment: map['comment'],
      dishes: List<String>.from(map['dishes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'feedbackId': feedbackId,
        'messId': messId,
        'studentId': studentId,
        'date': date.toIso8601String(),
        'mealSlot': mealSlot,
        'rating': rating,
        'comment': comment,
        'dishes': dishes,
      };
}
