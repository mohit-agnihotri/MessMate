import '../../../services/localization_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../auth/role_selection_page.dart';
import '../auth/student_setup_page.dart';
import 'student_main_page.dart';

class StudentPendingApprovalPage extends ConsumerStatefulWidget {
  final String? initialMessName;
  final String? initialPlanName;

  const StudentPendingApprovalPage({
    super.key,
    this.initialMessName,
    this.initialPlanName,
  });

  @override
  ConsumerState<StudentPendingApprovalPage> createState() =>
      _StudentPendingApprovalPageState();
}

class _StudentPendingApprovalPageState
    extends ConsumerState<StudentPendingApprovalPage> {
  bool get isHindi => ref.watch(localizationProvider) == 'hi';

  StreamSubscription<DocumentSnapshot>? _subscription;
  bool _isChecking = false;
  StudentModel? _student;
  MessModel? _mess;
  MealPlanModel? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startLiveListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final appService = ref.read(appServiceProvider);
      final student = await appService.getStudentById(user.uid);
      if (student != null) {
        _student = student;
        if (student.messId.isNotEmpty) {
          final mess = await appService.getMessById(student.messId);
          _mess = mess;

          if (student.assignedPlanId != null && student.assignedPlanId!.isNotEmpty) {
            final plans = await appService.getMealPlans(student.messId);
            final matched = plans.where((p) => p.planId == student.assignedPlanId);
            if (matched.isNotEmpty) {
              _plan = matched.first;
            }
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLiveListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;
      final status = data['status'] as String? ?? 'pending';

      if ((status == 'active' || status == 'approved') && mounted) {
        _subscription?.cancel();
        _onApproved();
      } else if (status == 'rejected' && mounted) {
        setState(() {
          if (_student != null) {
            _student = _student!.copyWith(status: 'rejected');
          }
        });
      }
    });
  }

  void _onApproved() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'बधाई हो! अनुरोध स्वीकृत हुआ',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'मेस संचालक ने आपका अनुरोध स्वीकार कर लिया है। अब आप मेस की सभी सेवाओं का उपयोग कर सकते हैं।',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentMainPage()),
                    (route) => false,
                  );
                },
                child: Text(
                  isHindi ? 'मेस डैशबोर्ड खोलें' : 'Open Dashboard',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkStatusManual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isChecking = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final status = doc.data()!['status'] as String? ?? 'pending';
        if ((status == 'active' || status == 'approved') && mounted) {
          _onApproved();
          return;
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'rejected'
                  ? 'मेस संचालक ने अनुरोध अस्वीकार कर दिया है।'
                  : 'अभी भी समीक्षाधीन है। मेस संचालक द्वारा अप्रूवल मिलते ही स्क्रीन खुल जाएगी।'),
              backgroundColor: status == 'rejected'
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF3B82F6),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('जांचने में त्रुटि: '),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _cancelAndReapply() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('अनुरोध रद्द करें?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text(
            'क्या आप वास्तव में इस मेस से जुड़ने का अनुरोध रद्द करना चाहते हैं? आप किसी अन्य मेस से जुड़ सकेंगे।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('रद्द न करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हाँ, रद्द करें'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentSetupPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('रद्द करने में त्रुटि: '),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
        final isRejected = _student?.status == 'rejected';
    final messName = _mess?.name ?? widget.initialMessName ?? 'मेस';
    final planName = _plan?.name ?? widget.initialPlanName ?? 'चयनित प्लान';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isHindi ? 'अनुरोध की स्थिति' : 'Join Request Status',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          InkWell(
            onTap: () {
              ref.read(localizationProvider.notifier).toggleLanguage(isHindi ? 'en' : 'hi');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: Color(0xFF0F172A)),
                  const SizedBox(width: 4),
                  Text(
                    isHindi ? 'English' : 'हिंदी',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: isHindi ? 'लॉगआउट' : 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isRejected
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isRejected
                              ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isRejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded,
                      size: 44,
                      color: isRejected
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isRejected
                        ? (isHindi ? 'अनुरोध अस्वीकृत' : 'Request Rejected')
                        : (isHindi ? 'अनुरोध समीक्षाधीन है' : 'Approval Pending'),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isRejected
                          ? (isHindi ? 'मेस संचालक ने आपका अनुरोध अस्वीकार कर दिया है। आप नीचे दिए गए बटन से दूसरा कोड डालकर पुनः आवेदन कर सकते हैं।' : 'The mess owner has rejected your join request. You can re-apply using another mess code below.')
                          : (isHindi ? 'आपकी जुड़ने की रिक्वेस्ट मेस संचालक को भेज दी गई है। जैसे ही संचालक इसे स्वीकार करेंगे, आपका डैशबोर्ड स्वतः खुल जाएगा।' : 'Your request has been submitted to the mess owner. Once approved, your dashboard will unlock automatically.'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Color(0xFF2563EB), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    messName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_mess?.messCode != null &&
                                      _mess!.messCode.isNotEmpty)
                                    Text(
                                      'मेस कोड: ${_mess!.messCode}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isRejected
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isRejected ? (isHindi ? 'अस्वीकृत' : 'Rejected') : (isHindi ? 'समीक्षाधीन' : 'Pending'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isRejected
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 28, color: Color(0xFFF1F5F9)),

                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded,
                                size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              isHindi ? 'चुना हुआ मील प्लान: ' : 'Selected Plan: ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                planName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        if (_plan != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.currency_rupee_rounded,
                                  size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                isHindi ? 'मासिक शुल्क: ' : 'Monthly Fee: ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '₹${_plan!.monthlyFee.toStringAsFixed(0)} / माह',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (_student != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                isHindi ? 'आवेदक: ' : 'Applicant: ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '${_student!.name} (${_student!.roomNo.isNotEmpty ? _student!.roomNo : _student!.phone})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (!isRejected) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isChecking ? null : _checkStatusManual,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          _isChecking
                              ? 'जांच रहे हैं...'
                              : isHindi ? 'स्थिति रिफ्रेश करें' : 'Check Status Now',
                          style: GoogleFonts.outfit(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _cancelAndReapply,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          isHindi ? 'अनुरोध रद्द करें' : 'Cancel Request',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _cancelAndReapply,
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: Text(
                          isHindi ? 'दूसरा मेस कोड दर्ज करें' : 'Enter Another Code',
                          style: GoogleFonts.outfit(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.account_circle_outlined,
                        size: 16, color: Color(0xFF64748B)),
                    label: Text(
                      isHindi ? 'दूसरा अकाउंट चुनें' : 'Switch Account',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}