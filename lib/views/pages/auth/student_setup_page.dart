import '../../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../student/student_discovery_page.dart';
import '../student/student_pending_approval_page.dart';
import 'login_page.dart';
import 'role_selection_page.dart';

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

  // Code-Find & Meal Plan Selection State
  bool _isSearchingMess = false;
  String? _searchError;
  MessModel? _foundMess;
  List<MealPlanModel> _availablePlans = [];
  String? _selectedPlanId;

  // Phone Validation State
  bool _phoneHasBlurred = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      _nameCtrl.text = user.displayName!;
    }
    if (user != null &&
        user.phoneNumber != null &&
        user.phoneNumber!.isNotEmpty) {
      _phoneCtrl.text = user.phoneNumber!.replaceFirst('+91', '').trim();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoleConflict());
  }

  Future<void> _handleBackToLogin() async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(authProvider.notifier).signOut();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFFFAF8F3),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFB93822), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHindi ? 'खाता टकराव' : 'Role Conflict',
                    style: GoogleFonts.newsreader(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              isHindi
                  ? 'यह ईमेल (${user.email ?? ""}) पहले से ही एक मेस संचालक (${existingMess.name}) के रूप में दर्ज है।\n\nछात्र के रूप में जुड़ने के लिए कृपया दूसरी ईमेल ID से लॉगिन करें।'
                  : 'This email (${user.email ?? ""}) is already registered as a mess owner (${existingMess.name}).\n\nPlease log in with a different email to join as a student.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF5E6D59),
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RoleSelectionPage()),
                      (r) => false,
                    );
                  }
                },
                child: Text(
                  isHindi ? 'दूसरा खाता चुनें' : 'Switch Account',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB93822),
                  ),
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

  String _slotDisplayName(String slotKey) {
    if (isHindi) {
      switch (slotKey.toLowerCase()) {
        case 'morning':
          return 'नाश्ता';
        case 'noon':
          return 'दोपहर खाना';
        case 'evening':
          return 'शाम नाश्ता';
        case 'night':
          return 'रात खाना';
        default:
          return slotKey;
      }
    } else {
      switch (slotKey.toLowerCase()) {
        case 'morning':
          return 'Breakfast';
        case 'noon':
          return 'Lunch';
        case 'evening':
          return 'Evening Snacks';
        case 'night':
          return 'Dinner';
        default:
          return slotKey;
      }
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

  bool _isPhoneValid(String text) {
    final clean = text.replaceAll(RegExp(r'\D'), '');
    return clean.length == 10 && RegExp(r'^[6-9]').hasMatch(clean);
  }

  Future<void> _findMessByCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया 6 अंकों का मान्य मेस कोड दर्ज करें।'
              : 'Please enter a valid 6-digit mess code.'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

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
          _searchError = isHindi
              ? 'कोड "$code" से कोई मेस नहीं मिली। कृपया अपने मेस संचालक से सही कोड पूछें।'
              : 'No mess found with code "$code". Please verify the code with your mess owner.';
        });
        return;
      }

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
        _searchError = isHindi
            ? 'मेस खोजने में त्रुटि हुई: $e'
            : 'Error searching mess: $e';
      });
    }
  }

  Future<void> _submitJoinRequest() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final room = _roomCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया सभी अनिवार्य फ़ील्ड्स (नाम, फ़ोन, रूम नंबर) भरें।'
              : 'Please fill all required fields (Name, Phone, Room No.).'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    if (!_isPhoneValid(phone)) {
      setState(() => _phoneHasBlurred = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया 10 अंकों का मान्य भारतीय मोबाइल नंबर दर्ज करें।'
              : 'Please enter a valid 10-digit mobile number.'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    final emergency = _emergencyCtrl.text.trim();
    if (emergency.isNotEmpty) {
      if (!_isPhoneValid(emergency)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHindi
                ? 'कृपया आपातकालीन फोन नंबर भी 10 अंकों का मान्य नंबर दर्ज करें।'
                : 'Please enter a valid 10-digit emergency phone number.'),
            backgroundColor: const Color(0xFFB93822),
          ),
        );
        return;
      }
      if (emergency == phone) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHindi
                ? 'आपातकालीन नंबर आपके प्राथमिक मोबाइल नंबर से अलग होना चाहिए।'
                : 'Emergency phone must be different from primary phone.'),
            backgroundColor: const Color(0xFFB93822),
          ),
        );
        return;
      }
    }

    if (_foundMess == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया पहले 6-अंकीय कोड डालकर मेस खोजें।'
              : 'Please enter 6-digit code and find mess first.'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया पहले लॉग इन करें।'
              : 'Please log in first.'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final appService = ref.read(appServiceProvider);

      String planName = isHindi ? 'डिफ़ॉल्ट मेस प्लान' : 'Standard Mess Plan';
      if (_selectedPlanId != null && _availablePlans.isNotEmpty) {
        final matched =
            _availablePlans.where((p) => p.planId == _selectedPlanId);
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
            content: Text(isHindi
                ? 'अनुरोध भेजने में त्रुटि: $e'
                : 'Error sending request: $e'),
            backgroundColor: const Color(0xFFB93822),
          ),
        );
      }
    }
  }

  void _onExploreNearby() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final room = _roomCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया सभी अनिवार्य फ़ील्ड्स (नाम, फ़ोन, रूम नंबर) भरें।'
              : 'Please fill all required fields (Name, Phone, Room No.).'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    if (!_isPhoneValid(phone)) {
      setState(() => _phoneHasBlurred = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया 10 अंकों का मान्य भारतीय मोबाइल नंबर दर्ज करें।'
              : 'Please enter a valid 10-digit mobile number.'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
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
  }

  @override
  Widget build(BuildContext context) {
    if (_requestSent) {
      return _buildSuccessScreen();
    }

    final phoneText = _phoneCtrl.text.trim();
    final showPhoneError = _phoneHasBlurred &&
        phoneText.isNotEmpty &&
        !_isPhoneValid(phoneText);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackToLogin();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F3EC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with circular back button and Serif Title
              Row(
                children: [
                  InkWell(
                    onTap: _handleBackToLogin,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8DE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: Color(0xFF231A14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isHindi ? 'छात्र प्रोफाइल' : 'Student profile',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 1: Personal Details
              Text(
                isHindi ? 'व्यक्तिगत विवरण' : 'Personal details',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF231A14),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHindi
                    ? 'मेस अटेंडेंस और बिलिंग के लिए आवश्यक जानकारी।'
                    : 'Needed for mess attendance and billing.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7A7971),
                ),
              ),

              const SizedBox(height: 20),

              // FULL NAME *
              _buildFieldLabel(isHindi ? 'पूरा नाम *' : 'FULL NAME *'),
              const SizedBox(height: 8),
              _buildInputField(
                controller: _nameCtrl,
                hint: isHindi ? 'जैसे: मोहित अग्निहोत्री' : 'e.g. Mohit Agnihotri',
              ),

              const SizedBox(height: 18),

              // MOBILE / WHATSAPP *
              _buildFieldLabel(isHindi ? 'मोबाइल / व्हाट्सएप *' : 'MOBILE / WHATSAPP *'),
              const SizedBox(height: 8),
              _buildInputField(
                controller: _phoneCtrl,
                hint: '9876543210',
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) {
                  if (_phoneHasBlurred) setState(() {});
                },
              ),
              if (showPhoneError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    isHindi
                        ? 'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें'
                        : 'Enter a valid 10-digit mobile number',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFB93822),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // ROOM / HOSTEL NO. *
              _buildFieldLabel(isHindi ? 'कमरा / हॉस्टल नंबर *' : 'ROOM / HOSTEL NO. *'),
              const SizedBox(height: 8),
              _buildInputField(
                controller: _roomCtrl,
                hint: isHindi ? 'जैसे: रूम 204, ब्लॉक B' : 'e.g. Room 204, Block B',
              ),

              const SizedBox(height: 18),

              // DIETARY PREFERENCE
              _buildFieldLabel(isHindi ? 'भोजन प्राथमिकता' : 'DIETARY PREFERENCE'),
              const SizedBox(height: 10),
              _buildDietaryChips(),

              const SizedBox(height: 18),

              // EMERGENCY / ROOMMATE PHONE · OPTIONAL
              _buildFieldLabel(isHindi
                  ? 'आपातकालीन / रूममेट फोन · वैकल्पिक'
                  : 'EMERGENCY / ROOMMATE PHONE · OPTIONAL'),
              const SizedBox(height: 8),
              _buildInputField(
                controller: _emergencyCtrl,
                hint: '9876500000',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              const SizedBox(height: 28),

              // Section 2: Connect with your mess
              Text(
                isHindi ? 'मेस से जुड़ें' : 'Connect with your mess',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF231A14),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHindi
                    ? 'अपने मेस संचालक से 6-अंकीय कोड पूछें, या आस-पास की मेस देखें।'
                    : 'Ask your mess owner for the 6-digit code, or explore nearby messes.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7A7971),
                ),
              ),

              const SizedBox(height: 20),

              if (!_showMessEntry) ...[
                // Primary Button: Enter 6-digit mess code (Golden Amber)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF09E38),
                      foregroundColor: const Color(0xFF231A14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => setState(() => _showMessEntry = true),
                    child: Text(
                      isHindi ? '6-अंकीय मेस कोड दर्ज करें' : 'Enter 6-digit mess code',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary Button: Explore nearby messes (Soft Sage)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8DE),
                      foregroundColor: const Color(0xFF2B3B2C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _onExploreNearby,
                    child: Text(
                      isHindi ? 'आस-पास की मेस देखें' : 'Explore nearby messes',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B3B2C),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Code Input Form Area (Matching screenshot WhatsApp Image 2026-10-21 at 17.01.06.jpeg)
                _buildFieldLabel(isHindi ? 'मेस कोड (6 अंक) *' : 'MESS CODE (6 DIGITS) *'),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x1A2D231C),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.newsreader(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                            color: const Color(0xFF231A14),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '482910',
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
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
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF231A14),
                          foregroundColor: const Color(0xFFF09E38),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        onPressed: _isSearchingMess ? null : _findMessByCode,
                        child: _isSearchingMess
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF09E38),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isHindi ? 'खोजें' : 'Find',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF09E38),
                                ),
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
                      color: const Color(0xFFFDE8E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF2B8B1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFB93822), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchError!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFB93822),
                              fontWeight: FontWeight.w500,
                            ),
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
                        backgroundColor: const Color(0xFFF09E38),
                        foregroundColor: const Color(0xFF231A14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submitJoinRequest,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFF231A14),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isHindi
                                      ? 'अनुरोध भेजें →'
                                      : 'Send Join Request →',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF231A14),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showMessEntry = false;
                      _foundMess = null;
                      _availablePlans = [];
                      _selectedPlanId = null;
                      _searchError = null;
                    }),
                    child: Text(
                      isHindi ? '✕ रद्द करें' : '✕ Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A7971),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: const Color(0xFF4E654F),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1A2D231C),
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus && controller == _phoneCtrl) {
            setState(() => _phoneHasBlurred = true);
          }
        },
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF231A14),
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF231A14),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF9E9A90),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryChips() {
    final chips = [
      {'key': 'veg', 'label': isHindi ? 'शाकाहारी' : 'Vegetarian'},
      {'key': 'non_veg', 'label': isHindi ? 'मांसाहारी' : 'Non-veg'},
      {'key': 'eggetarian', 'label': isHindi ? 'अंडा युक्त' : 'Eggetarian'},
    ];

    return Row(
      children: chips.map((c) {
        final isSelected = _dietaryPreference == c['key'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _dietaryPreference = c['key']!),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE2E8DE)
                      : const Color(0xFFFAF8F3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4E654F)
                        : const Color(0x142D231C),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    isSelected ? '✓ ${c['label']}' : c['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF2B3B2C)
                          : const Color(0xFF231A14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessPreviewCard(MessModel mess) {
    final timings = mess.mealTimings;
    final activeSlots =
        timings.entries.where((e) => e.value['enabled'] == 'true').toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E654F), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8DE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF4E654F)),
                    const SizedBox(width: 4),
                    Text(
                      isHindi ? 'वेरिफाइड मेस' : 'Verified Mess',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2B3B2C),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mess.foodType == 'pure_veg'
                      ? const Color(0xFFE2E8DE)
                      : const Color(0xFFFDF1E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mess.foodType == 'pure_veg'
                      ? (isHindi ? '🌿 शुद्ध शाकाहारी' : '🌿 Pure Veg')
                      : (isHindi ? '🍲 वेज व नॉन-वेज' : '🍲 Veg & Non-Veg'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: mess.foodType == 'pure_veg'
                        ? const Color(0xFF2B3B2C)
                        : const Color(0xFF8F4700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mess.name,
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF231A14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHindi ? 'संचालक: ${mess.ownerName}' : 'Owner: ${mess.ownerName}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7A7971),
            ),
          ),
          if (activeSlots.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0x142D231C)),
            const SizedBox(height: 10),
            Text(
              isHindi ? 'भोजन का समय:' : 'Meal Timings:',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4E654F),
              ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x142D231C)),
                  ),
                  child: Text(
                    '${_slotDisplayName(slotKey)}: $start - $end',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF231A14),
                    ),
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
        Text(
          isHindi ? 'प्लान चुनें *' : 'CHOOSE MEAL PLAN *',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: const Color(0xFF4E654F),
          ),
        ),
        const SizedBox(height: 10),
        if (_availablePlans.isEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _selectedPlanId = null),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPlanId == null
                    ? const Color(0xFFE2E8DE)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedPlanId == null
                      ? const Color(0xFF4E654F)
                      : const Color(0x1A2D231C),
                  width: _selectedPlanId == null ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedPlanId == null
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _selectedPlanId == null
                        ? const Color(0xFF4E654F)
                        : const Color(0xFF7A7971),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'डिफ़ॉल्ट मेस प्लान' : 'Standard Mess Plan',
                          style: GoogleFonts.newsreader(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF231A14),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHindi
                              ? '₹${_foundMess!.monthlyFee.toInt()} / महीना • छुट्टी पर ₹${_foundMess!.perMealRate.toInt()} रिफंड'
                              : '₹${_foundMess!.monthlyFee.toInt()} / month • ₹${_foundMess!.perMealRate.toInt()} refund on skip',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4E654F),
                          ),
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
            final refund =
                plan.extraMealRate ?? plan.deductionPolicy.flatRate ?? 40.0;
            final fixedMeals = plan.fixedMeals;
            final choiceGroups = plan.choiceGroups;

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanId = plan.planId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE2E8DE).withValues(alpha: 0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4E654F)
                        : const Color(0x1A2D231C),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? const Color(0xFF4E654F)
                              : const Color(0xFF7A7971),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            plan.name,
                            style: GoogleFonts.newsreader(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF231A14),
                            ),
                          ),
                        ),
                        Text(
                          '₹$fee/mo',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4E654F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text(
                        isHindi
                            ? 'स्किप रिफंड: ₹${refund.toInt()}/मील'
                            : 'Skip refund: ₹${refund.toInt()}/meal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7A7971),
                        ),
                      ),
                    ),
                    if (fixedMeals.isNotEmpty || choiceGroups.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...fixedMeals.map((slot) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF8F3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0x142D231C)),
                                  ),
                                  child: Text(
                                    '✓ ${_slotDisplayName(slot)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF231A14),
                                    ),
                                  ),
                                )),
                            ...choiceGroups.map((cg) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8DE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isHindi
                                        ? '⇄ विकल्प: ${cg.availableMeals.map((m) => _slotDisplayName(m)).join(' या ')}'
                                        : '⇄ Choice: ${cg.availableMeals.map((m) => _slotDisplayName(m)).join(' or ')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2B3B2C),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8DE),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      color: Color(0xFF4E654F),
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isHindi ? 'अनुरोध भेजा गया!' : 'Request Sent!',
                  style: GoogleFonts.newsreader(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF231A14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isHindi
                      ? 'आपका मेस में जुड़ने का अनुरोध सफलतापूर्वक दर्ज हो चुका है।'
                      : 'Your request to join the mess has been sent successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF7A7971),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x1A2D231C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _joinedMessName,
                        style: GoogleFonts.newsreader(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isHindi ? 'चुना हुआ प्लान:' : 'Selected Plan:',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF7A7971),
                            ),
                          ),
                          Text(
                            _joinedPlanName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF231A14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF09E38),
                      foregroundColor: const Color(0xFF231A14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StudentDiscoveryPage()),
                      );
                    },
                    child: Text(
                      isHindi ? 'अन्य मेस देखें' : 'Browse Other Messes',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF231A14),
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
}