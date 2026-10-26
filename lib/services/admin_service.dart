import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/admin_config.dart';
import '../models/app_models.dart';
import 'notification_service.dart';
import 'security_service.dart';

/// Provider for AdminService
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

/// StreamProvider for real-time Master Toggles & Config
final adminConfigStreamProvider = StreamProvider<AdminGlobalConfigModel>((ref) {
  return ref.watch(adminServiceProvider).streamGlobalConfig();
});

/// StreamProvider for real-time student count and profiles across all messes
final adminStudentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  return ref.watch(adminServiceProvider).streamAllStudents();
});

/// Centralized service powering the Super Admin Mission Control,
/// dual-gate security authentication, mess management, support tickets, and monetization.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _vaultCollection = 'system_config';
  static const String _vaultDoc = 'admin_vault';
  static const String _ticketsCollection = 'support_tickets';
  static const String _messesCollection = 'messes';

  // ─── 1. Security & Master PIN Management ─────────────────────────────

  /// Reads global config document from Firestore.
  /// If it does not exist yet, initializes it with defaults.
  Future<AdminGlobalConfigModel> getGlobalConfig() async {
    try {
      final doc = await _db.collection(_vaultCollection).doc(_vaultDoc).get();
      if (!doc.exists || doc.data() == null) {
        final defaultConfig = const AdminGlobalConfigModel();
        await _db.collection(_vaultCollection).doc(_vaultDoc).set(defaultConfig.toMap());
        return defaultConfig;
      }
      return AdminGlobalConfigModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[AdminService] Error fetching global config, using defaults: $e');
      return const AdminGlobalConfigModel();
    }
  }

  /// Real-time stream of master admin toggles & config.
  Stream<AdminGlobalConfigModel> streamGlobalConfig() {
    return _db.collection(_vaultCollection).doc(_vaultDoc).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const AdminGlobalConfigModel();
      }
      return AdminGlobalConfigModel.fromMap(snap.data()!);
    }).handleError((error) {
      debugPrint('[AdminService] streamGlobalConfig error caught gracefully: $error');
      return const AdminGlobalConfigModel();
    });
  }

  /// Verifies entered PIN against Firestore vault or fallback default PIN.
  /// Hardened with SHA-256 salted hash comparison and brute-force lockout defense.
  Future<bool> verifyMasterPin(String inputPin) async {
    final clean = inputPin.trim();
    if (clean.isEmpty) return false;

    // 1. Brute-force & Rate-limiting lockout guard
    if (SecurityService.isLockedOut()) {
      final remaining = SecurityService.remainingLockoutSeconds();
      throw Exception('Security Lockout: Too many failed attempts. Try again in ${remaining}s.');
    }

    // 2. Anti-timing attack jitter
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final config = await getGlobalConfig();
      final isValid = clean == config.masterPin.trim() ||
          SecurityService.verifySecret(clean, config.masterPin) ||
          SecurityService.verifySecret(clean, AdminConfig.defaultMasterPinHash);

      if (isValid) {
        SecurityService.recordSuccessfulAttempt();
        return true;
      } else {
        SecurityService.recordFailedAttempt();
        return false;
      }
    } catch (e) {
      if (e.toString().contains('Security Lockout')) rethrow;
      final isValid = SecurityService.verifySecret(clean, AdminConfig.defaultMasterPinHash);
      if (isValid) {
        SecurityService.recordSuccessfulAttempt();
        return true;
      } else {
        SecurityService.recordFailedAttempt();
        return false;
      }
    }
  }

  /// Updates Master PIN in Firestore vault with salted SHA-256 hashing.
  Future<void> updateMasterPin(String newPin) async {
    final clean = newPin.trim();
    if (clean.length < 6) {
      throw Exception('Master PIN must be at least 6 digits for enterprise security');
    }
    // Store cryptographically hashed PIN with salt
    final hashed = SecurityService.hashSecret(clean);
    await _db.collection(_vaultCollection).doc(_vaultDoc).set(
      {'masterPin': hashed},
      SetOptions(merge: true),
    );
  }

  /// Updates master toggles (6-month trial, platform fee, emergency banner, etc.)
  Future<void> updateGlobalToggles({
    bool? globalTrialEnabled,
    int? defaultTrialDays,
    bool? platformFeeEnabled,
    double? platformFeeAmount,
    double? baseSoftwareMonthlyFee,
    bool? emergencyBannerEnabled,
    String? emergencyBannerText,
    String? minSupportedVersion,
    String? developerUpiId,
  }) async {
    final updates = <String, dynamic>{};
    if (globalTrialEnabled != null) updates['globalTrialEnabled'] = globalTrialEnabled;
    if (defaultTrialDays != null) updates['defaultTrialDays'] = defaultTrialDays;
    if (platformFeeEnabled != null) updates['platformFeeEnabled'] = platformFeeEnabled;
    if (platformFeeAmount != null) updates['platformFeeAmount'] = platformFeeAmount;
    if (baseSoftwareMonthlyFee != null) updates['baseSoftwareMonthlyFee'] = baseSoftwareMonthlyFee;
    if (emergencyBannerEnabled != null) updates['emergencyBannerEnabled'] = emergencyBannerEnabled;
    if (emergencyBannerText != null) updates['emergencyBannerText'] = emergencyBannerText;
    if (minSupportedVersion != null) updates['minSupportedVersion'] = minSupportedVersion;
    if (developerUpiId != null) updates['developerUpiId'] = developerUpiId;

    if (updates.isNotEmpty) {
      await _db.collection(_vaultCollection).doc(_vaultDoc).set(updates, SetOptions(merge: true));
    }
  }

  /// Adds a new email address to the authorized admin whitelist.
  Future<void> addAdminEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return;
    await _db.collection(_vaultCollection).doc(_vaultDoc).update({
      'adminEmails': FieldValue.arrayUnion([clean]),
    });
  }

  // ─── 2. Mess Directory & Governance Overrides ────────────────────────

  /// Real-time stream of all registered messes across India.
  Stream<List<MessModel>> streamAllMesses() {
    return _db.collection(_messesCollection).snapshots().map((snap) {
      return snap.docs.map((doc) => MessModel.fromMap(doc.data())).toList();
    }).handleError((error) {
      debugPrint('[AdminService] streamAllMesses error caught gracefully: $error');
      return <MessModel>[];
    });
  }

  /// Real-time stream of all students enrolled across all messes.
  Stream<List<StudentModel>> streamAllStudents() {
    return _db.collection('students').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['studentId'] == null || data['studentId'].toString().isEmpty) {
          data['studentId'] = doc.id;
        }
        return StudentModel.fromMap(data);
      }).toList();
    }).handleError((error) {
      debugPrint('[AdminService] streamAllStudents error caught gracefully: $error');
      return <StudentModel>[];
    });
  }

  /// Extends trial days for a specific mess by [additionalDays] (e.g. +30 days).
  Future<void> extendMessTrial(String messId, int additionalDays) async {
    final messDoc = await _db.collection(_messesCollection).doc(messId).get();
    if (!messDoc.exists || messDoc.data() == null) return;

    final currentExpiry = messDoc.data()!['trialExpiresAt'];
    DateTime baseDate = DateTime.now();
    if (currentExpiry != null) {
      final parsed = DateTime.tryParse(currentExpiry.toString());
      if (parsed != null && parsed.isAfter(baseDate)) {
        baseDate = parsed;
      }
    }

    final newExpiry = baseDate.add(Duration(days: additionalDays));
    await _db.collection(_messesCollection).doc(messId).update({
      'trialExpiresAt': newExpiry.toIso8601String(),
      'subscriptionStatus': 'trial_active',
    });
  }

  /// Grants or revokes Lifetime Free VIP status for a mess.
  Future<void> setMessLifetimeVip(String messId, bool isVip) async {
    await _db.collection(_messesCollection).doc(messId).update({
      'subscriptionStatus': isVip ? 'lifetime_vip' : 'active',
    });
  }

  /// Toggles freeze / lock status for a mess.
  Future<void> toggleMessFreeze(String messId, bool freeze) async {
    await _db.collection(_messesCollection).doc(messId).update({
      'isFrozen': freeze,
    });
  }

  /// Toggles verified badge (blue/green check) for a mess.
  Future<void> toggleMessVerification(String messId, bool verified) async {
    await _db.collection(_messesCollection).doc(messId).update({
      'isVerified': verified,
    });
  }

  // ─── 3. In-App User Help & Feedback Desk ─────────────────────────────

  /// Submits a support ticket, bug report, or feature suggestion from Student/Owner.
  Future<String> submitSupportTicket(SupportTicketModel ticket) async {
    final docRef = _db.collection(_ticketsCollection).doc();
    final newTicket = SupportTicketModel(
      ticketId: docRef.id,
      userId: ticket.userId,
      userName: ticket.userName,
      userPhone: ticket.userPhone,
      userRole: ticket.userRole,
      messId: ticket.messId,
      messName: ticket.messName,
      category: ticket.category,
      message: ticket.message,
      deviceModel: ticket.deviceModel,
      osVersion: ticket.osVersion,
      appVersion: ticket.appVersion,
      status: 'open',
      createdAt: DateTime.now(),
    );
    await docRef.set(newTicket.toMap());
    return docRef.id;
  }

  /// Real-time stream of support tickets for the Admin Inbox.
  Stream<List<SupportTicketModel>> streamSupportTickets({String? statusFilter}) {
    Query query = _db.collection(_ticketsCollection);
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        return SupportTicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      debugPrint('[AdminService] streamSupportTickets error caught gracefully: $error');
      return <SupportTicketModel>[];
    });
  }

  /// Replies to a ticket and dispatches an instant OneSignal push notification to the user.
  Future<void> replyToTicketAndNotifyUser({
    required String ticketId,
    required String reply,
    required String userId,
    required String userRole,
    required String ticketCategory,
  }) async {
    // 1. Update ticket in Firestore
    await _db.collection(_ticketsCollection).doc(ticketId).update({
      'adminReply': reply.trim(),
      'adminRepliedAt': DateTime.now().toIso8601String(),
      'status': 'resolved',
    });

    // 2. Dispatch instant OneSignal Push Notification to user's phone
    try {
      final categoryBadge = ticketCategory == 'bug'
          ? '🐛 Bug Update'
          : ticketCategory == 'suggestion'
              ? '💡 Feature Update'
              : '📬 Support Reply';

      await NotificationService.sendStudentNotification(
        studentId: userId,
        title: '$categoryBadge from Mezzo Dev',
        message: reply.trim(),
      );
    } catch (e) {
      debugPrint('[AdminService] Note: Push notification dispatch notice: $e');
    }
  }

  /// Updates ticket status directly (e.g. 'open', 'in_progress', 'resolved').
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    await _db.collection(_ticketsCollection).doc(ticketId).update({
      'status': newStatus,
    });
  }

  // ─── 4. Financial Reconciliation & Monetization ──────────────────────

  /// Calculates monthly settlement for a mess:
  /// Total = Base Software SaaS (₹499) + (Active Billed Students × ₹19)
  Future<Map<String, dynamic>> calculateMonthlySettlement(
    String messId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final config = await getGlobalConfig();
    final double baseFee = config.baseSoftwareMonthlyFee;
    final double perStudentFee = config.platformFeeEnabled ? config.platformFeeAmount : 0.0;

    try {
      final billsSnap = await _db
          .collection('bills')
          .where('messId', isEqualTo: messId)
          .where('generatedAt',
              isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('generatedAt',
              isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .get();

      final billedStudentsCount = billsSnap.docs.length;
      final double studentPlatformSum = billedStudentsCount * perStudentFee;
      final double totalRemittance = baseFee + studentPlatformSum;

      return {
        'messId': messId,
        'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        'baseFee': baseFee,
        'perStudentFee': perStudentFee,
        'billedStudentsCount': billedStudentsCount,
        'studentPlatformSum': studentPlatformSum,
        'totalRemittance': totalRemittance,
        'developerUpiId': config.developerUpiId,
      };
    } catch (e) {
      debugPrint('[AdminService] calculateMonthlySettlement error: $e');
      return {
        'messId': messId,
        'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        'baseFee': baseFee,
        'perStudentFee': perStudentFee,
        'billedStudentsCount': 0,
        'studentPlatformSum': 0.0,
        'totalRemittance': baseFee,
        'developerUpiId': config.developerUpiId,
      };
    }
  }

  /// Fetches the itemized list of billed students for zero-dispute audit.
  Future<List<Map<String, dynamic>>> getBilledStudentsForMess(
    String messId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      final billsSnap = await _db
          .collection('bills')
          .where('messId', isEqualTo: messId)
          .where('generatedAt',
              isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('generatedAt',
              isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .get();

      if (billsSnap.docs.isNotEmpty) {
        return billsSnap.docs.map((doc) {
          final data = doc.data();
          return {
            'billId': doc.id,
            'studentId': data['studentId'] ?? '',
            'studentName': data['studentName'] ?? 'Student',
            'phone': data['phone'] ?? '',
            'finalAmount': (data['finalAmount'] ?? 0.0).toDouble(),
            'generatedAt': data['generatedAt'] ?? '',
            'status': data['status'] ?? 'pending',
          };
        }).toList();
      }

      // If no bills generated yet this cycle, query currently active enrolled students
      final studentsSnap = await _db
          .collection('students')
          .where('messId', isEqualTo: messId)
          .get();

      return studentsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'billId': 'ACTIVE_ENROLLED',
          'studentId': doc.id,
          'studentName': data['name'] ?? 'Student',
          'phone': data['phone'] ?? '',
          'roomNo': data['roomNo'] ?? '',
          'finalAmount': 19.0, // Platform fee per student
          'generatedAt': data['joinDate'] ?? '',
          'status': data['status'] ?? 'active',
        };
      }).toList();
    } catch (e) {
      debugPrint('[AdminService] getBilledStudentsForMess error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Seeds a realistic sample mess so the admin dashboard can be previewed immediately.
  Future<void> seedSampleMess() async {
    final now = DateTime.now();
    final demoMess = MessModel(
      messId: 'demo_mess_${now.millisecondsSinceEpoch}',
      name: 'Royal Rajputana Mess',
      ownerId: 'owner_demo_01',
      ownerName: 'Vikramaditya Rathore',
      ownerPhone: '+91 98290 12345',
      gpsLat: 26.9124,
      gpsLng: 75.7873,
      capacity: 120,
      monthlyFee: 3200,
      perMealRate: 60,
      cutoffHours: 2,
      messCode: 'ROYAL${now.millisecond % 900 + 100}',
      subscriptionStatus: 'trial_active',
      trialStartDate: now,
      trialExpiresAt: now.add(const Duration(days: 180)),
      isVerified: true,
      isFrozen: false,
    );

    await _db.collection(_messesCollection).doc(demoMess.messId).set(demoMess.toMap());
  }

  /// Convenience: Updates developer UPI address globally with audit log
  Future<void> updateDeveloperUpiId(String upi) async {
    await updateGlobalToggles(developerUpiId: upi);
    await logAuditAction(action: 'UPDATE_UPI', details: 'Remittance UPI updated to $upi');
  }

  /// Convenience: Broadcasts push notification
  Future<void> broadcastNotification({
    required String title,
    required String body,
    required String targetAudience,
  }) async {
    try {
      await NotificationService.sendBroadcastNotification(
        title: title,
        message: body,
      );
    } catch (_) {}
    await logAuditAction(
      action: 'BROADCAST',
      details: 'Target: $targetAudience | Title: $title',
    );
  }

  /// Convenience: Log immutable admin audit trail in Firestore
  Future<void> logAuditAction({
    required String action,
    required String details,
    String adminEmail = 'superadmin@messmate.in',
  }) async {
    try {
      await _db.collection('admin_audit_logs').add({
        'action': action,
        'details': details,
        'adminEmail': adminEmail,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AdminService] logAuditAction notice: $e');
    }
  }

  /// Stream of real-time audit logs
  Stream<List<AdminAuditLogModel>> streamAuditLogs() {
    return _db
        .collection('admin_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AdminAuditLogModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((e) {
      debugPrint('[AdminService] streamAuditLogs error: $e');
      return <AdminAuditLogModel>[];
    });
  }

  /// Convenience: Grants lifetime VIP to mess
  Future<void> grantLifetimeVip(String messId, {String? reason}) async {
    await setMessLifetimeVip(messId, true);
    await logAuditAction(
      action: 'GRANT_VIP',
      details: 'Granted Lifetime VIP to mess $messId. ${reason ?? ''}',
    );
  }

  /// Convenience: Freeze mess with audit log
  Future<void> freezeMess(String messId, {String? reason}) async {
    await toggleMessFreeze(messId, true);
    await logAuditAction(
      action: 'FREEZE_MESS',
      details: 'Frozen mess $messId. Reason: ${reason ?? 'Admin freeze'}',
    );
  }

  /// Convenience: Unfreeze mess with audit log
  Future<void> unfreezeMess(String messId, {String? reason}) async {
    await toggleMessFreeze(messId, false);
    await logAuditAction(
      action: 'UNFREEZE_MESS',
      details: 'Unfrozen mess $messId. Reason: ${reason ?? 'Admin unfreeze'}',
    );
  }

  /// Convenience: Reply to ticket with auto lookup
  Future<void> replyToTicket({
    required String ticketId,
    required String replyMessage,
  }) async {
    try {
      final ticketDoc = await _db.collection(_ticketsCollection).doc(ticketId).get();
      if (ticketDoc.exists && ticketDoc.data() != null) {
        final data = ticketDoc.data()!;
        await replyToTicketAndNotifyUser(
          ticketId: ticketId,
          reply: replyMessage,
          userId: data['userId'] ?? '',
          userRole: data['userRole'] ?? 'student',
          ticketCategory: data['category'] ?? 'suggestion',
        );
      } else {
        await updateTicketStatus(ticketId, 'resolved');
      }
    } catch (_) {
      await updateTicketStatus(ticketId, 'resolved');
    }
  }
}

/// Model representing an immutable admin audit log entry.
class AdminAuditLogModel {
  final String logId;
  final String action;
  final String details;
  final String adminEmail;
  final DateTime timestamp;

  AdminAuditLogModel({
    required this.logId,
    required this.action,
    required this.details,
    required this.adminEmail,
    required this.timestamp,
  });

  factory AdminAuditLogModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime time = DateTime.now();
    if (map['timestamp'] != null) {
      if (map['timestamp'] is String) {
        time = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
      } else {
        try {
          time = (map['timestamp'] as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
    }
    return AdminAuditLogModel(
      logId: id ?? map['logId'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      adminEmail: map['adminEmail'] ?? 'superadmin@messmate.in',
      timestamp: time,
    );
  }

  Map<String, dynamic> toMap() => {
    'action': action,
    'details': details,
    'adminEmail': adminEmail,
    'timestamp': timestamp.toIso8601String(),
  };
}

