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
import 'theme/student_inspired_theme.dart';

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
        backgroundColor: StudentColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: StudentColors.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: StudentColors.sageDark,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isHindi ? 'बधाई हो! अनुरोध स्वीकृत हुआ' : 'Congratulations! Request Approved',
              style: StudentTypography.serifHeading(
                fontSize: 20,
                color: StudentColors.walnut,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isHindi
                  ? 'मेस संचालक ने आपका अनुरोध स्वीकार कर लिया है। अब आप मेस की सभी सेवाओं का उपयोग कर सकते हैं।'
                  : 'The mess owner has approved your request. You can now access all mess services.',
              style: StudentTypography.body(
                fontSize: 13,
                color: StudentColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StudentColors.sage,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
          final isHi = ref.read(localizationProvider) == 'hi';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'rejected'
                  ? (isHi ? 'मेस संचालक ने अनुरोध अस्वीकार कर दिया है।' : 'Mess owner has rejected the request.')
                  : (isHi ? 'अभी भी समीक्षाधीन है। मेस संचालक द्वारा अप्रूवल मिलते ही स्क्रीन खुल जाएगी।' : 'Still pending review. The screen will open once approved by mess owner.')),
              backgroundColor: status == 'rejected'
                  ? StudentColors.brickRed
                  : StudentColors.walnut,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isHi = ref.read(localizationProvider) == 'hi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHi ? 'जांचने में त्रुटि: $e' : 'Error checking status: $e'),
            backgroundColor: StudentColors.brickRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _cancelAndReapply() async {
    final isHiDialog = ref.read(localizationProvider) == 'hi';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: StudentColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isHiDialog ? 'अनुरोध रद्द करें?' : 'Cancel Request?',
          style: StudentTypography.serifHeading(fontSize: 20),
        ),
        content: Text(
          isHiDialog
              ? 'क्या आप वास्तव में इस मेस से जुड़ने का अनुरोध रद्द करना चाहते हैं? आप किसी अन्य मेस से जुड़ सकेंगे।'
              : 'Are you sure you want to cancel your request to join this mess? You will be able to join another mess.',
          style: StudentTypography.body(fontSize: 14, color: StudentColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              isHiDialog ? 'रद्द न करें' : 'Keep Request',
              style: StudentTypography.bold(fontSize: 13, color: StudentColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.brickRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isHiDialog ? 'हाँ, रद्द करें' : 'Yes, Cancel',
              style: StudentTypography.bold(fontSize: 13, color: Colors.white),
            ),
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
        final isHi = ref.read(localizationProvider) == 'hi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHi ? 'रद्द करने में त्रुटि: $e' : 'Error cancelling request: $e'),
            backgroundColor: StudentColors.brickRed,
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

  String _formatPendingPlanName(String? raw, MealPlanModel? plan, bool isHindi) {
    if (plan != null && plan.name.isNotEmpty && !plan.name.contains('_')) {
      return plan.name;
    }
    final target = (plan?.name.isNotEmpty == true) ? plan!.name : (raw ?? '');
    if (target.isEmpty) {
      return isHindi ? 'मानक मेस मील प्लान' : 'Standard Mess Meal Plan';
    }
    final lower = target.toLowerCase();
    if (lower.contains('morning_or_noon') || (lower.contains('morning') && lower.contains('noon'))) {
      return isHindi ? 'फ्लेक्सी चॉइस (नाश्ता/दोपहर + रात)' : 'Flexi Choice (Breakfast/Lunch + Dinner)';
    } else if (lower.contains('full') || lower.contains('all') || lower.contains('3_meal') || lower.contains('4_meal')) {
      return isHindi ? 'ऑल मील्स प्लान (अनलिमिटेड)' : 'Full Day All-Meals Plan';
    } else if (lower.contains('lunch_dinner') || lower.contains('noon_night') || lower.contains('2_meal')) {
      return isHindi ? 'लंच और डिनर कॉम्बो' : 'Lunch & Dinner Regular Combo';
    } else if (lower.contains('breakfast_dinner') || lower.contains('morning_night')) {
      return isHindi ? 'नाश्ता और डिनर प्लान' : 'Breakfast & Dinner Plan';
    }
    final parts = target.split('_');
    final meaningfulParts = parts.where((p) => !RegExp(r'^[A-Za-z0-9]{6,}$').hasMatch(p) && !RegExp(r'^\d+$').hasMatch(p)).toList();
    if (meaningfulParts.isNotEmpty) {
      return meaningfulParts.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
    return isHindi ? 'मासिक मेस मील प्लान' : 'Monthly Mess Meal Plan';
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _student?.status == 'rejected';
    final messName = _mess?.name ?? widget.initialMessName ?? (isHindi ? 'मेस' : 'Mess');
    final rawPlanStr = widget.initialPlanName ?? _student?.assignedPlanId;
    final planName = _formatPendingPlanName(rawPlanStr, _plan, isHindi);

    return Scaffold(
      backgroundColor: StudentColors.canvasWarm,
      appBar: AppBar(
        title: Text(
          isHindi ? 'अनुरोध की स्थिति' : 'Join Request Status',
          style: StudentTypography.serifHeading(
            fontSize: 20,
            color: StudentColors.walnut,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          InkWell(
            onTap: () {
              ref.read(localizationProvider.notifier).toggleLanguage(isHindi ? 'en' : 'hi');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: StudentColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: StudentColors.walnut),
                  const SizedBox(width: 4),
                  Text(
                    isHindi ? 'English' : 'हिंदी',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: StudentColors.walnut),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: StudentColors.walnutMuted),
            tooltip: isHindi ? 'लॉगआउट' : 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StudentColors.sage))
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
                          ? StudentColors.brickRedLight
                          : StudentColors.amberLight,
                      shape: BoxShape.circle,
                      boxShadow: StudentColors.softShadow,
                    ),
                    child: Icon(
                      isRejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded,
                      size: 44,
                      color: isRejected
                          ? StudentColors.brickRed
                          : StudentColors.amberDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isRejected
                        ? (isHindi ? 'अनुरोध अस्वीकृत' : 'Request Rejected')
                        : (isHindi ? 'अनुरोध समीक्षाधीन है' : 'Approval Pending'),
                    style: StudentTypography.serifHeading(
                      fontSize: 24,
                      color: StudentColors.walnut,
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
                      style: StudentTypography.body(
                        fontSize: 13,
                        color: StudentColors.textMuted,
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
                      border: Border.all(color: StudentColors.borderSubtle),
                      boxShadow: StudentColors.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: StudentColors.sageLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: StudentColors.sageBorder),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: StudentColors.sageDark, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    messName,
                                    style: StudentTypography.serifHeading(
                                      fontSize: 18,
                                      color: StudentColors.walnut,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_mess?.messCode != null &&
                                      _mess!.messCode.isNotEmpty)
                                    Text(
                                      '${isHindi ? 'मेस कोड' : 'Mess Code'}: ${_mess!.messCode}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: StudentColors.textMuted,
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
                                    ? StudentColors.brickRedLight
                                    : StudentColors.amberLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRejected
                                      ? StudentColors.brickRedBorder
                                      : StudentColors.amberPill,
                                ),
                              ),
                              child: Text(
                                isRejected ? (isHindi ? 'अस्वीकृत' : 'Rejected') : (isHindi ? 'समीक्षाधीन' : 'Pending'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isRejected
                                      ? StudentColors.brickRed
                                      : StudentColors.amberText,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 28, color: StudentColors.borderSubtle),

                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded,
                                size: 18, color: StudentColors.walnutMuted),
                            const SizedBox(width: 8),
                            Text(
                              isHindi ? 'चुना हुआ मील प्लान: ' : 'Selected Plan: ',
                              style: StudentTypography.body(
                                fontSize: 13,
                                color: StudentColors.textMuted,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                planName,
                                style: StudentTypography.bold(
                                  fontSize: 13,
                                  color: StudentColors.walnut,
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
                                  size: 18, color: StudentColors.walnutMuted),
                              const SizedBox(width: 8),
                              Text(
                                isHindi ? 'मासिक शुल्क: ' : 'Monthly Fee: ',
                                style: StudentTypography.body(
                                  fontSize: 13,
                                  color: StudentColors.textMuted,
                                ),
                              ),
                              Text(
                                isHindi ? '₹${_plan!.monthlyFee.toStringAsFixed(0)} / महीना' : '₹${_plan!.monthlyFee.toStringAsFixed(0)} / mo',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: StudentColors.sage,
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
                                  size: 18, color: StudentColors.walnutMuted),
                              const SizedBox(width: 8),
                              Text(
                                isHindi ? 'आवेदक: ' : 'Applicant: ',
                                style: StudentTypography.body(
                                  fontSize: 13,
                                  color: StudentColors.textMuted,
                                ),
                              ),
                              Text(
                                '${_student!.name} (${_student!.roomNo.isNotEmpty ? _student!.roomNo : _student!.phone})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: StudentColors.textDark,
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
                          backgroundColor: StudentColors.sage,
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
                              ? (isHindi ? 'जांच रहे हैं...' : 'Checking...')
                              : (isHindi ? 'स्थिति रिफ्रेश करें' : 'Check Status Now'),
                          style: GoogleFonts.inter(
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
                          foregroundColor: StudentColors.brickRed,
                          side: const BorderSide(color: StudentColors.brickRedBorder),
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
                          backgroundColor: StudentColors.amber,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _cancelAndReapply,
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: Text(
                          isHindi ? 'दूसरा मेस कोड दर्ज करें' : 'Enter Another Code',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.account_circle_outlined,
                        size: 16, color: StudentColors.walnutMuted),
                    label: Text(
                      isHindi ? 'दूसरा अकाउंट चुनें' : 'Switch Account',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.walnutMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}