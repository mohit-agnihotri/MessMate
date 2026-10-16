import '../../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../student/student_pending_approval_page.dart';
import 'role_selection_page.dart';

import '../../../models/app_models.dart';
//
import '../../../viewmodels/all_viewmodels.dart';
import '../student/student_discovery_page.dart';

class StudentSetupPage extends ConsumerStatefulWidget {
  const StudentSetupPage({super.key});

  @override
  ConsumerState<StudentSetupPage> createState() => _StudentSetupPageState();
}

class _StudentSetupPageState extends ConsumerState<StudentSetupPage> {
  bool get isHindi => ref.watch(localizationProvider) == 'hi';

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String _dietaryPreference = 'veg'; // 'veg', 'non_veg', 'eggetarian'
  bool _showMessEntry = false;
  bool _requestSent = false;
  bool _isSubmitting = false;
  String _joinedMessName = '';
  String _joinedPlanName = '';

  // New Code-Find & Meal Plan Selection State
  bool _isSearchingMess = false;
  String? _searchError;
  MessModel? _foundMess;
  List<MealPlanModel> _availablePlans = [];
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      _nameCtrl.text = user.displayName!;
    }
    if (user != null && user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      _phoneCtrl.text = user.phoneNumber!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoleConflict());
  }


  Future<void> _checkRoleConflict() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final appService = ref.read(appServiceProvider);
      final existingMess = await appService.getMessByOwnerId(user.uid);
      if (existingMess != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'अकाउंट टकराव (Role Conflict)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'यह ईमेल (${user.email ?? ""}) पहले से ही एक मेस मालिक (${existingMess.name}) के रूप में दर्ज है।\n\nछात्र (Student) के रूप में जुड़ने के लिए कृपया दूसरी ईमेल ID से लॉगिन करें।',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                      (r) => false,
                    );
                  }
                },
                child: Text(
                  'दूसरा अकाउंट चुनें (Switch Account)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roomCtrl.dispose();
    _emergencyCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String _slotNameHindi(String slotKey) {
    switch (slotKey.toLowerCase()) {
      case 'morning':
        return 'सुबह का नाश्ता';
      case 'noon':
        return 'दोपहर का खाना';
      case 'evening':
        return 'शाम का नाश्ता';
      case 'night':
        return 'रात का खाना';
      default:
        return slotKey;
    }
  }

  String _formatTime12(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      final period = h >= 12 ? 'PM' : 'AM';
      int h12 = h % 12;
      if (h12 == 0) h12 = 12;
      final mm = m.toString().padLeft(2, '0');
      return '$h12:$mm $period';
    } catch (_) {
      return time24;
    }
  }

  Future<void> _findMessByCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया 6 अंकों का मान्य मेस कोड दर्ज करें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearchingMess = true;
      _searchError = null;
      _foundMess = null;
      _availablePlans = [];
      _selectedPlanId = null;
    });

    try {
      final appService = ref.read(appServiceProvider);
      final mess = await appService.getMessByCode(code);

      if (mess == null) {
        setState(() {
          _isSearchingMess = false;
          _searchError = 'कोड "$code" से कोई मेस नहीं मिली। कृपया अपने मेस संचालक से सही कोड पूछें।';
        });
        return;
      }

      // Fetch active meal plans for this mess
      final allPlans = await appService.getMealPlans(mess.messId);
      final activePlans = allPlans.where((p) => p.isActive).toList();

      setState(() {
        _isSearchingMess = false;
        _foundMess = mess;
        _availablePlans = activePlans;
        if (activePlans.isNotEmpty) {
          _selectedPlanId = activePlans.first.planId;
        }
      });
    } catch (e) {
      setState(() {
        _isSearchingMess = false;
        _searchError = 'मेस खोजने में त्रुटि हुई: $e';
      });
    }
  }

  Widget _buildInput(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isOptional)
              Text(
                ' (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
              : null,
          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            prefixText: keyboardType == TextInputType.phone ? '+91 ' : null,
            prefixStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDietaryPreferenceSelector() {
    final options = [
      {'key': 'veg', 'label': 'शाकाहारी (Veg)', 'sub': 'Veg only meals'},
      {'key': 'non_veg', 'label': 'मांसाहारी (Non-Veg)', 'sub': 'Includes meat & eggs'},
      {'key': 'eggetarian', 'label': 'अंडा युक्त (Eggetarian)', 'sub': 'Veg with egg dishes'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'भोजन प्राथमिकता (Dietary Preference)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = _dietaryPreference == opt['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _dietaryPreference = opt['key']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opt['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  Future<void> _submitJoinRequest() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final room = _roomCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया सभी अनिवार्य फ़ील्ड्स (नाम, फ़ोन, रूम नंबर) भरें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया 10 अंकों का मान्य भारतीय मोबाइल नंबर दर्ज करें (6-9 से शुरू)।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final emergency = _emergencyCtrl.text.trim();
    if (emergency.isNotEmpty) {
      if (!phoneRegex.hasMatch(emergency)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया आपातकालीन फोन नंबर भी 10 अंकों का मान्य नंबर दर्ज करें।'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      if (emergency == phone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('आपातकालीन नंबर आपके प्राथमिक मोबाइल नंबर से अलग होना चाहिए।'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    if (_foundMess == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया पहले 6-अंकीय कोड डालकर "खोजें" पर क्लिक करें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया पहले लॉग इन करें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final appService = ref.read(appServiceProvider);

      String planName = 'डिफ़ॉल्ट मेस प्लान';
      if (_selectedPlanId != null && _availablePlans.isNotEmpty) {
        final matched = _availablePlans.where((p) => p.planId == _selectedPlanId);
        if (matched.isNotEmpty) {
          planName = matched.first.name;
        }
      }

      final student = StudentModel(
        studentId: user.uid,
        name: name,
        phone: phone,
        status: 'pending',
        messId: _foundMess!.messId,
        joinDate: DateTime.now(),
        roomNo: room,
        college: '',
        course: '',
        email: user.email ?? '',
        dietaryPreference: _dietaryPreference,
        emergencyContact: _emergencyCtrl.text.trim(),
        assignedPlanId: _selectedPlanId,
      );

      await appService.updateStudent(student);

      setState(() {
        _requestSent = true;
        _isSubmitting = false;
        _joinedMessName = _foundMess!.name;
        _joinedPlanName = planName;
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentPendingApprovalPage(
              initialMessName: _foundMess!.name,
              initialPlanName: planName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('अनुरोध भेजने में त्रुटि: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildMessPreviewCard(MessModel mess) {
    final timings = mess.mealTimings;
    final activeSlots = timings.entries.where((e) => e.value['enabled'] == 'true').toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'मेस मिल गई (Verified)',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mess.foodType == 'pure_veg' ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mess.foodType == 'pure_veg' ? '🌿 शुद्ध शाकाहारी' : '🍲 शाकाहारी + मांसाहारी',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: mess.foodType == 'pure_veg' ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mess.name,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'संचालक: ${mess.ownerName}',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
              if (mess.ownerPhone.isNotEmpty) ...[
                const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                Text(
                  mess.ownerPhone,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ],
            ],
          ),
          if (activeSlots.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Text(
              'भोजन का समय (Meal Timings):',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: activeSlots.map((entry) {
                final slotKey = entry.key;
                final start = _formatTime12(entry.value['start']);
                final end = _formatTime12(entry.value['end']);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${_slotNameHindi(slotKey)}: $start - $end',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildMealPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              'अपना मील प्लान चुनें (Choose Meal Plan) *',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'इस मेस में उपलब्ध प्लान्स में से अपना मनपसंद प्लान चुनें। ओनर इसी प्लान को अप्रूव करेंगे:',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        if (_availablePlans.isEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _selectedPlanId = null),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedPlanId == null ? const Color(0xFFECFDF5) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedPlanId == null ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  width: _selectedPlanId == null ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedPlanId == null ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: _selectedPlanId == null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'डिफ़ॉल्ट मेस प्लान (Standard Mess Plan)',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_foundMess!.monthlyFee.toInt()} / महीना • छुट्टी पर ₹${_foundMess!.perMealRate.toInt()} रिफंड',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ..._availablePlans.map((plan) {
            final isSelected = _selectedPlanId == plan.planId;
            final fee = plan.monthlyFee.toInt();
            final refund = plan.extraMealRate ?? plan.deductionPolicy.flatRate ?? 40.0;
            final fixedMeals = plan.fixedMeals;
            final choiceGroups = plan.choiceGroups;

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanId = plan.planId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '₹$fee / माह',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                  const Text('  •  ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                  Text(
                                    'छुट्टी रिफंड: ₹${refund == refund.roundToDouble() ? refund.toInt() : refund}/मील',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...fixedMeals.map((slot) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '✓ ${_slotNameHindi(slot)}',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                              )),
                          ...choiceGroups.map((cg) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  '⇄ विकल्प: ${cg.availableMeals.map((m) => _slotNameHindi(m)).join(' या ')} (कोई 1)',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_requestSent) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Color(0xFF10B981),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'अनुरोध भेजा गया! (Request Sent)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'आपका मेस में जुड़ने का अनुरोध सफलता पूर्वक दर्ज हो चुका है।',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _joinedMessName,
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('चुना हुआ प्लान:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                            Flexible(
                              child: Text(
                                _joinedPlanName,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('स्थिति (Status):', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'स्वीकृति प्रतीक्षित (Pending Approval)',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'जैसे ही मेस संचालक आपके अनुरोध को स्वीकार करेंगे, आपका चुना हुआ प्लान तुरंत सक्रिय हो जाएगा।',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E40AF), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentDiscoveryPage()),
                        );
                      },
                      child: Text(
                        'अन्य मेस देखें (Browse Other Messes)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'छात्र प्रोफाइल सेटअप (Student Setup)',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'व्यक्तिगत विवरण (Personal Details)',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'मेस हाजिरी और बिलिंग के लिए आवश्यक जानकारी।',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            _buildInput('पूरा नाम (Full Name) *', _nameCtrl, hint: 'जैसे: राहुल शर्मा'),
            _buildInput('मोबाइल / WhatsApp नंबर *', _phoneCtrl,
                hint: 'जैसे: 9876543210', keyboardType: TextInputType.phone),
            _buildInput('कमरा / हॉस्टल नंबर (Room / Hostel No.) *', _roomCtrl,
                hint: 'जैसे: रूम 204, ब्लॉक B'),
            _buildDietaryPreferenceSelector(),
            _buildInput(
              isHindi ? 'आपातकालीन / रूममेट फोन (Emergency Phone)' : 'Emergency / Roommate Phone',
              _emergencyCtrl,
              hint: 'जैसे: 9876500000',
              keyboardType: TextInputType.phone,
              isOptional: true,
            ),

            const Divider(height: 32, color: Color(0xFFE2E8F0)),

            Text(
              'मेस से जुड़ें (Connect with Your Mess)',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'अपने मेस संचालक से 6-अंकीय कोड मांगें, या आस-पास की मेस एक्सप्लोर करें।',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            if (!_showMessEntry) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 20),
                  label: Text(
                    '6-अंकीय मेस कोड दर्ज करें (Enter Code)',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => setState(() => _showMessEntry = true),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.explore_rounded, color: Color(0xFF3B82F6), size: 20),
                  label: Text(
                    'आस-पास की मेस देखें (Explore Nearby)',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final name = _nameCtrl.text.trim();
                    final phone = _phoneCtrl.text.trim();
                    final room = _roomCtrl.text.trim();
                    if (name.isEmpty || phone.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया सभी अनिवार्य फ़ील्ड्स (नाम, फ़ोन, रूम नंबर) भरें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया 10 अंकों का मान्य भारतीय मोबाइल नंबर दर्ज करें (6-9 से शुरू)।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final emergency = _emergencyCtrl.text.trim();
    if (emergency.isNotEmpty) {
      if (!phoneRegex.hasMatch(emergency)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया आपातकालीन फोन नंबर भी 10 अंकों का मान्य नंबर दर्ज करें।'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      if (emergency == phone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('आपातकालीन नंबर आपके प्राथमिक मोबाइल नंबर से अलग होना चाहिए।'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final student = StudentModel(
                        studentId: user.uid,
                        name: name,
                        phone: phone,
                        status: 'pending',
                        messId: '',
                        joinDate: DateTime.now(),
                        roomNo: room,
                        college: '',
                        course: '',
                        email: user.email ?? '',
                        dietaryPreference: _dietaryPreference,
                        emergencyContact: _emergencyCtrl.text.trim(),
                      );
                      ref.read(appServiceProvider).updateStudent(student);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentDiscoveryPage()),
                    );
                  },
                ),
              ),
            ] else ...[
              Text(
                'मेस कोड (6 Digits Mess Code) *',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: '482910',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 16, letterSpacing: 2),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        if (_foundMess != null) {
                          setState(() {
                            _foundMess = null;
                            _availablePlans = [];
                            _selectedPlanId = null;
                            _searchError = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: _isSearchingMess ? null : _findMessByCode,
                      icon: _isSearchingMess
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded, size: 20),
                      label: Text(
                        _isSearchingMess ? 'खोज रहे...' : 'खोजें (Find)',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),

              if (_searchError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _searchError!,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_foundMess != null) ...[
                _buildMessPreviewCard(_foundMess!),
                _buildMealPlansSection(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submitJoinRequest,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'अनुरोध भेजें (Send Join Request)',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _showMessEntry = false;
                    _foundMess = null;
                    _availablePlans = [];
                    _selectedPlanId = null;
                    _searchError = null;
                  }),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                    'रद्द करें (Cancel Code Entry)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}