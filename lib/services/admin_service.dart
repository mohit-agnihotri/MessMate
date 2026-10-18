import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/admin_config.dart';
import '../models/app_models.dart';
import 'notification_service.dart';

/// Provider for AdminService
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

/// StreamProvider for real-time Master Toggles & Config
final adminConfigStreamProvider = StreamProvider<AdminGlobalConfigModel>((ref) {
  return ref.watch(adminServiceProvider).streamGlobalConfig();
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
    });
  }

  /// Verifies entered PIN against Firestore vault or fallback default PIN.
  Future<bool> verifyMasterPin(String inputPin) async {
    final clean = inputPin.trim();
    if (clean.isEmpty) return false;

    try {
      final config = await getGlobalConfig();
      if (clean == config.masterPin.trim()) return true;
      // Fallback
      return clean == AdminConfig.defaultMasterPin;
    } catch (e) {
      return clean == AdminConfig.defaultMasterPin;
    }
  }

  /// Updates Master PIN in Firestore vault with real-time propagation.
  Future<void> updateMasterPin(String newPin) async {
    final clean = newPin.trim();
    if (clean.length < 4) {
      throw Exception('Master PIN must be at least 4 digits');
    }
    await _db.collection(_vaultCollection).doc(_vaultDoc).set(
      {'masterPin': clean},
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
        title: '$categoryBadge from MessMate Dev',
        body: reply.trim(),
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

    // Fetch bills generated for this mess during this month
    final billsSnap = await _db
        .collection('bills')
        .where('messId', isEqualTo: messId)
        .where('generatedAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('generatedAt', isLessThanOrEqualTo: endOfMonth.toIso8601String())
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
  }

  /// Fetches the itemized list of billed students for zero-dispute audit.
  Future<List<Map<String, dynamic>>> getBilledStudentsForMess(
    String messId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final billsSnap = await _db
        .collection('bills')
        .where('messId', isEqualTo: messId)
        .where('generatedAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('generatedAt', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();

    return billsSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'billId': doc.id,
        'studentId': data['studentId'] ?? '',
        'studentName': data['studentName'] ?? 'Student',
        'finalAmount': (data['finalAmount'] ?? 0.0).toDouble(),
        'generatedAt': data['generatedAt'] ?? '',
        'status': data['status'] ?? 'pending',
      };
    }).toList();
  }
}
