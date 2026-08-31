// ============================================================
// All Data Models for MessMate App
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String name;
  final String phone;
  final String roomNo;
  final String college;
  final String course;
  final String email;
  final String? photoUrl;
  final DateTime joinDate;
  final String messId;
  final String status; // 'active', 'pending', 'left'
  // Notification preferences - controls FCM topic subscriptions
  final Map<String, bool> notificationPrefs;

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
    required this.college,
    required this.course,
    required this.email,
    this.photoUrl,
    required this.joinDate,
    required this.messId,
    required this.status,
    this.notificationPrefs = _defaultNotifPrefs,
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
    Map<String, bool>? notificationPrefs,
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
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    // Parse notification prefs with defaults for older records
    final rawPrefs = map['notificationPrefs'] as Map<String, dynamic>?;
    final prefs = <String, bool>{
      'menuPublished': rawPrefs?['menuPublished'] as bool? ?? true,
      'cutoffReminder': rawPrefs?['cutoffReminder'] as bool? ?? true,
      'billUpdated': rawPrefs?['billUpdated'] as bool? ?? true,
      'announcements': rawPrefs?['announcements'] as bool? ?? true,
    };
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
      notificationPrefs: prefs,
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
      'notificationPrefs': notificationPrefs,
    };
  }
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
  final String language; // 'en' or 'hi'
  final String? ownerPhotoUrl;
  final Map<String, Map<String, String>> mealTimings;
  // Owner notification preferences - controls FCM topic subscriptions
  final Map<String, bool> ownerNotificationPrefs;

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
    this.mealTimings = const {
      'morning': {'start': '08:00', 'end': '10:00', 'enabled': 'true'},
      'noon': {'start': '12:30', 'end': '14:30', 'enabled': 'true'},
      'evening': {'start': '17:00', 'end': '18:30', 'enabled': 'false'},
      'night': {'start': '20:00', 'end': '22:00', 'enabled': 'true'},
    },
    this.ownerNotificationPrefs = _defaultOwnerNotifPrefs,
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
    Map<String, Map<String, String>>? mealTimings,
    Map<String, bool>? ownerNotificationPrefs,
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
      mealTimings: mealTimings ?? this.mealTimings,
      ownerNotificationPrefs: ownerNotificationPrefs ?? this.ownerNotificationPrefs,
    );
  }

  factory MessModel.fromMap(Map<String, dynamic> map) {
    return MessModel(
      messId: map['messId'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      ownerPhotoUrl: map['ownerPhotoUrl'],
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      capacity: map['capacity'] ?? 0,
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      perMealRate: (map['perMealRate'] ?? 0.0).toDouble(),
      cutoffHours: map['cutoffHours'] ?? 3,
      messCode: map['messCode'] ?? '',
      isListedOnMap: map['isListedOnMap'] ?? true,
      showMenuToOutsiders: map['showMenuToOutsiders'] ?? true,
      showMenuToStudents: map['showMenuToStudents'] ?? true,
      language: map['language'] ?? 'en',
      mealTimings: map['mealTimings'] != null 
          ? (map['mealTimings'] as Map).map((k, v) {
              final val = Map<String, String>.from(v as Map);
              // Ensure 'enabled' exists for backward compatibility
              if (!val.containsKey('enabled')) val['enabled'] = 'true';
              return MapEntry(k.toString(), val);
            })
          : const {
              'morning': {'start': '08:00', 'end': '10:00', 'enabled': 'true'},
              'noon': {'start': '12:30', 'end': '14:30', 'enabled': 'true'},
              'evening': {'start': '17:00', 'end': '18:30', 'enabled': 'false'},
              'night': {'start': '20:00', 'end': '22:00', 'enabled': 'true'},
            },
      ownerNotificationPrefs: (() {
        final raw = map['ownerNotificationPrefs'] as Map<String, dynamic>?;
        return <String, bool>{
          'skipAlert': raw?['skipAlert'] as bool? ?? true,
          'joinRequest': raw?['joinRequest'] as bool? ?? true,
        };
      })(),
    );
  }

  Map<String, dynamic> toMap() => {
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
    'mealTimings': mealTimings,
    'ownerNotificationPrefs': ownerNotificationPrefs,
  };
}

class DishModel {
  final String dishId;
  final String name;
  final String category; // 'veg', 'nonveg', 'dal', 'roti', 'sweet'
  final String? imageUrl;

  DishModel({
    required this.dishId,
    required this.name,
    required this.category,
    this.imageUrl,
  });

  factory DishModel.fromMap(Map<String, dynamic> map) {
    return DishModel(
      dishId: map['dishId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'veg',
      imageUrl: map['imageUrl'],
    );
  }

  /// Deserialize from a Firestore DocumentSnapshot (global_dishes collection).
  /// The Flutter app uses this to read cached imageUrl from Firestore only.
  factory DishModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DishModel(
      dishId: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'veg',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'dishId': dishId,
    'name': name,
    'category': category,
    'imageUrl': imageUrl,
  };
}

class MenuModel {
  final String menuId;
  final String messId;
  final DateTime date;
  final String mealSlot; // 'morning', 'noon', 'night'
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

  LeaveModel({
    required this.leaveId,
    required this.studentId,
    required this.messId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.cancelledAt,
  });

  factory LeaveModel.fromMap(Map<String, dynamic> map) {
    return LeaveModel(
      leaveId: map['leaveId'] ?? '',
      studentId: map['studentId'] ?? '',
      messId: map['messId'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'active',
      cancelledAt: map['cancelledAt'] != null ? DateTime.tryParse(map['cancelledAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'leaveId': leaveId,
    'studentId': studentId,
    'messId': messId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
    'cancelledAt': cancelledAt?.toIso8601String(),
  };
}

class MealRecordModel {
  final String recordId;
  final String studentId;
  final String messId;
  final DateTime date;
  final String mealSlot; // 'morning', 'noon', 'night'
  final String status; // 'present', 'absent_self', 'absent_owner', 'guest'
  final DateTime? cancelledAt;

  MealRecordModel({
    required this.recordId,
    required this.studentId,
    required this.messId,
    required this.date,
    required this.mealSlot,
    required this.status,
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
      cancelledAt: map['cancelledAt'] != null ? DateTime.tryParse(map['cancelledAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'recordId': recordId,
    'studentId': studentId,
    'messId': messId,
    'date': date.toIso8601String(),
    'mealSlot': mealSlot,
    'status': status,
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
  final double totalDeductions;
  final double guestAddons;
  final double finalPayable;
  final double previousDues;
  final bool isPaid;
  final List<DeductionItem> deductions;

  BillModel({
    required this.billId,
    required this.studentId,
    required this.messId,
    required this.month,
    required this.year,
    required this.baseFee,
    required this.totalDeductions,
    required this.guestAddons,
    required this.finalPayable,
    this.previousDues = 0,
    required this.isPaid,
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
      totalDeductions: (map['totalDeductions'] ?? 0.0).toDouble(),
      guestAddons: (map['guestAddons'] ?? 0.0).toDouble(),
      finalPayable: (map['finalPayable'] ?? 0.0).toDouble(),
      previousDues: (map['previousDues'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
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
    'totalDeductions': totalDeductions,
    'guestAddons': guestAddons,
    'finalPayable': finalPayable,
    'previousDues': previousDues,
    'isPaid': isPaid,
    'deductions': deductions.map((d) => d.toMap()).toList(),
  };
}

class DeductionItem {
  final DateTime date;
  final String mealSlot;
  final String type; // 'self_cancelled', 'owner_off', 'guest'
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
    return AnnouncementModel(
      announcementId: map['announcementId'] ?? '',
      messId: map['messId'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
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

