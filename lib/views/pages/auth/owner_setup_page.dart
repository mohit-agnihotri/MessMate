import '../../../services/localization_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../services/admin_service.dart';
import '../../../services/notification_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../owner/owner_main_page.dart';
import 'role_selection_page.dart';

/// OwnerSetupPage:
/// 3-step setup wizard for mess owners.
/// Step 0: Meal Timings & Cut-off (Interactive Editorial TimePickers)
/// Step 1: Dynamic Meal Plans & Pricing (Adapts dynamically to enabled Step 0 slots)
/// Step 2: Mess Profile & Launch
class OwnerSetupPage extends ConsumerStatefulWidget {
  const OwnerSetupPage({super.key});

  @override
  ConsumerState<OwnerSetupPage> createState() => _OwnerSetupPageState();
}

class _OwnerSetupPageState extends ConsumerState<OwnerSetupPage> {
  bool get isHindi => ref.watch(localizationProvider) == 'hi';

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // STEP 0: Meal Timings & Cutoff
  final Map<String, Map<String, dynamic>> _timings = {
    'morning': {
      'name': 'Breakfast',
      'nameHi': 'सुबह का नाश्ता',
      'slotName': 'नाश्ता',
      'slotNameEn': 'Breakfast',
      'enabled': true,
      'start': '08:00',
      'end': '10:00',
      'color': const Color(0xFFF09E38),
    },
    'noon': {
      'name': 'Lunch',
      'nameHi': 'दोपहर का खाना',
      'slotName': 'दोपहर खाना',
      'slotNameEn': 'Lunch',
      'enabled': true,
      'start': '12:30',
      'end': '14:30',
      'color': const Color(0xFF4E654F),
    },
    'evening': {
      'name': 'Evening snacks',
      'nameHi': 'शाम का नाश्ता',
      'slotName': 'शाम नाश्ता',
      'slotNameEn': 'Evening Snacks',
      'enabled': false,
      'start': '17:00',
      'end': '18:30',
      'color': const Color(0xFF8C7A6B),
    },
    'night': {
      'name': 'Dinner',
      'nameHi': 'रात का खाना',
      'slotName': 'रात खाना',
      'slotNameEn': 'Dinner',
      'enabled': true,
      'start': '19:30',
      'end': '22:00',
      'color': const Color(0xFF231A14),
    },
  };
  int _cutoffLeadHours = 2;

  // STEP 1: Dynamically generated meal plans based on Step 0 enabled slots
  List<Map<String, dynamic>> _planConfigs = [];
  String _lastActiveSlotsKey = '';

  // STEP 2: Mess Profile
  final _messNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _capacityCtrl = TextEditingController(text: '50');
  String _foodType = 'pure_veg'; // pure_veg, both

  @override
  void initState() {
    super.initState();
    _syncPlansToActiveSlots(force: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoleConflict());
  }

  Future<void> _checkRoleConflict() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final appService = ref.read(appServiceProvider);
      final existingStudent = await appService.getStudentById(user.uid);
      if (existingStudent != null && mounted) {
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
                  ? 'यह ईमेल (${user.email ?? ""}) पहले से ही एक छात्र (${existingStudent.name}) के रूप में पंजीकृत है।\n\nमेस संचालक बनने के लिए कृपया दूसरी ईमेल ID से लॉगिन करें।'
                  : 'This email (${user.email ?? ""}) is already registered as a student (${existingStudent.name}).\n\nPlease log in with a different email to create a mess as owner.',
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
    _pageController.dispose();
    _messNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _capacityCtrl.dispose();
    for (final p in _planConfigs) {
      (p['feeCtrl'] as TextEditingController?)?.dispose();
      (p['skipCtrl'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  TimeOfDay _parseTimeOfDay(String time24) {
    try {
      final parts = time24.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTime12(String time24) {
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

  /// Custom Editorial Time Picker Modal
  /// Matching Screenshot WhatsApp Image 2026-10-21 at 17.01.05 (1).jpeg
  Future<String?> _showAlarmClockTimePicker({
    required BuildContext context,
    required String title,
    required String initialTime24,
  }) async {
    final parsed = _parseTimeOfDay(initialTime24);
    int selectedHour = parsed.hourOfPeriod == 0 ? 12 : parsed.hourOfPeriod;
    int selectedMinute = parsed.minute;
    bool isPm = parsed.period == DayPeriod.pm;

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final displayTime =
                '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: 14,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD6C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title (Newsreader Serif)
                  Text(
                    title,
                    style: GoogleFonts.newsreader(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Card (Big Serif Time + AM/PM Segmented Switch)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0x1A2D231C),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.newsreader(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: const Color(0xFF231A14),
                          ),
                        ),
                        // AM / PM Pill Segment
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8DE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setModalState(() => isPm = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isPm
                                        ? const Color(0xFF231A14)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'AM',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !isPm
                                          ? const Color(0xFFF09E38)
                                          : const Color(0xFF4E654F),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setModalState(() => isPm = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isPm
                                        ? const Color(0xFF231A14)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'PM',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isPm
                                          ? const Color(0xFFF09E38)
                                          : const Color(0xFF4E654F),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SELECT HOUR (Uppercase Sage Label)
                  Text(
                    isHindi ? 'घंटा चुनें' : 'SELECT HOUR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFF4E654F),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal 1..12 Hour Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(12, (i) {
                        final hourVal = i + 1;
                        final isSel = selectedHour == hourVal;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () =>
                                setModalState(() => selectedHour = hourVal),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 38,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF231A14)
                                    : const Color(0xFFE2E8DE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$hourVal',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? const Color(0xFFF09E38)
                                        : const Color(0xFF2B3B2C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SELECT MINUTES (Uppercase Sage Label)
                  Text(
                    isHindi ? 'मिनट चुनें' : 'SELECT MINUTES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFF4E654F),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4 Minute Pills (:00, :15, :30, :45)
                  Row(
                    children: [0, 15, 30, 45].map((m) {
                      final isSel = selectedMinute == m;
                      final label = ':${m.toString().padLeft(2, '0')}';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () =>
                                setModalState(() => selectedMinute = m),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 46,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF231A14)
                                    : const Color(0xFFE2E8DE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? const Color(0xFFF09E38)
                                        : const Color(0xFF2B3B2C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Confirm Time Button
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
                        int hour24 = selectedHour;
                        if (isPm) {
                          if (hour24 < 12) hour24 += 12;
                        } else {
                          if (hour24 == 12) hour24 = 0;
                        }
                        final formatted24 =
                            '${hour24.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                        Navigator.pop(modalCtx, formatted24);
                      },
                      child: Text(
                        isHindi
                            ? 'समय पुष्टि करें ($displayTime)'
                            : 'Confirm time ($displayTime)',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickTime(String key, bool isStart) async {
    final current = isStart
        ? (_timings[key]!['start'] as String)
        : (_timings[key]!['end'] as String);
    final slotName = isHindi
        ? (_timings[key]!['slotName'] as String)
        : (_timings[key]!['slotNameEn'] as String);

    final title = isStart
        ? (isHindi ? '$slotName शुरू समय' : '$slotName start time')
        : (isHindi ? '$slotName समाप्ति समय' : '$slotName end time');

    final result = await _showAlarmClockTimePicker(
      context: context,
      title: title,
      initialTime24: current,
    );

    if (result != null) {
      setState(() {
        if (isStart) {
          _timings[key]!['start'] = result;
        } else {
          _timings[key]!['end'] = result;
        }
      });
      _syncPlansToActiveSlots();
    }
  }

  void _syncPlansToActiveSlots({bool force = false}) {
    final activeSlots = _timings.entries
        .where((e) => e.value['enabled'] == true)
        .map((e) => e.key)
        .toList();

    final activeKey = activeSlots.join(',');
    if (!force && activeKey == _lastActiveSlotsKey) return;
    _lastActiveSlotsKey = activeKey;

    final existingState = <String, Map<String, dynamic>>{};
    for (final p in _planConfigs) {
      existingState[p['id'] as String] = {
        'fee': (p['feeCtrl'] as TextEditingController?)?.text,
        'skip': (p['skipCtrl'] as TextEditingController?)?.text,
        'maxSkip': p['maxSkip'],
        'enabled': p['enabled'],
      };
    }

    final newConfigs = <Map<String, dynamic>>[];
    final hasMorning = activeSlots.contains('morning');
    final hasNoon = activeSlots.contains('noon');
    final hasNight = activeSlots.contains('night');

    if (activeSlots.length == 4) {
      newConfigs.add({
        'id': 'full_4',
        'name': 'Full 4-Meal Plan',
        'nameHi': 'चारों वक्त का पूरा खाना',
        'badge': 'MOST POPULAR',
        'desc': 'Breakfast + Lunch + Evening Snacks + Dinner',
        'fixedMeals': ['morning', 'noon', 'evening', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 3800.0,
        'skipRefund': 35.0,
        'maxSkip': 8,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'regular_3',
        'name': 'Full 3-Meal Plan',
        'nameHi': 'तीनों वक्त का खाना',
        'badge': 'POPULAR CHOICE',
        'desc': 'Breakfast + Lunch + Dinner',
        'fixedMeals': ['morning', 'noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 3000.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'core_2',
        'name': 'Lunch & Dinner Plan',
        'nameHi': 'दोपहर + रात का खाना',
        'badge': 'POPULAR CHOICE',
        'desc': 'Lunch and dinner daily',
        'fixedMeals': ['noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 2400.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'choice_flex',
        'name': 'Flexi Choice Plan',
        'nameHi': 'फ्लेक्सी चॉइस प्लान',
        'badge': 'FLEXI CHOICE',
        'desc': 'Lunch & Dinner + Choice between Breakfast or Snacks',
        'fixedMeals': ['noon', 'night'],
        'hasChoice': true,
        'choiceSlots': ['morning', 'evening'],
        'choiceDesc': 'Student picks 1: Breakfast or Snacks',
        'monthlyFee': 2800.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'single_choice',
        'name': 'Single Meal Choice Plan',
        'nameHi': 'सिंगल मील प्लान',
        'badge': 'BUDGET FRIENDLY',
        'desc': 'Single meal: Lunch or Dinner',
        'fixedMeals': <String>[],
        'hasChoice': true,
        'choiceSlots': ['noon', 'night'],
        'choiceDesc': 'Student picks 1: Lunch or Dinner',
        'monthlyFee': 1500.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': false,
      });
    } else if (activeSlots.length == 3 && hasMorning && hasNoon && hasNight) {
      newConfigs.add({
        'id': 'full_3',
        'name': 'Full 3-Meal Plan',
        'nameHi': 'तीनों वक्त का खाना',
        'badge': 'MOST POPULAR',
        'desc': 'Breakfast + Lunch + Dinner',
        'fixedMeals': ['morning', 'noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 3000.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'core_2',
        'name': 'Lunch & Dinner Plan',
        'nameHi': 'दोपहर + रात का खाना',
        'badge': 'POPULAR CHOICE',
        'desc': 'Lunch and dinner daily',
        'fixedMeals': ['noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 2400.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'choice_morning_or_noon',
        'name': 'Flexi Choice Plan',
        'nameHi': 'फ्लेक्सी चॉइस प्लान',
        'badge': 'FLEXI CHOICE',
        'desc': 'Guaranteed Dinner + choice of Breakfast or Lunch',
        'fixedMeals': ['night'],
        'hasChoice': true,
        'choiceSlots': ['morning', 'noon'],
        'choiceDesc': 'Student picks 1: Breakfast or Lunch',
        'monthlyFee': 2200.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'single_choice',
        'name': 'Single Meal Choice Plan',
        'nameHi': 'सिंगल मील प्लान',
        'badge': 'BUDGET FRIENDLY',
        'desc': 'Single meal: Lunch or Dinner',
        'fixedMeals': <String>[],
        'hasChoice': true,
        'choiceSlots': ['noon', 'night'],
        'choiceDesc': 'Student picks 1: Lunch or Dinner',
        'monthlyFee': 1500.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': false,
      });
    } else if (activeSlots.length == 2) {
      newConfigs.add({
        'id': 'full_2',
        'name':
            '${_timings[activeSlots[0]]!['slotNameEn']} + ${_timings[activeSlots[1]]!['slotNameEn']} Plan',
        'nameHi':
            '${_timings[activeSlots[0]]!['slotName']} + ${_timings[activeSlots[1]]!['slotName']} प्लान',
        'badge': 'MOST POPULAR',
        'desc': 'Both meals daily',
        'fixedMeals': List<String>.from(activeSlots),
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 2500.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'single_choice_2',
        'name': 'Single Meal Choice Plan',
        'nameHi': 'सिंगल मील प्लान',
        'badge': 'BUDGET FRIENDLY',
        'desc': 'Single meal daily',
        'fixedMeals': <String>[],
        'hasChoice': true,
        'choiceSlots': List<String>.from(activeSlots),
        'choiceDesc':
            'Student picks 1: ${_timings[activeSlots[0]]!['slotNameEn']} or ${_timings[activeSlots[1]]!['slotNameEn']}',
        'monthlyFee': 1400.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': true,
      });
    } else {
      newConfigs.add({
        'id': 'solo_1',
        'name':
            '${_timings[activeSlots.first]!['slotNameEn']} Only Plan',
        'nameHi':
            'केवल ${_timings[activeSlots.first]!['slotName']} प्लान',
        'badge': 'STANDARD PLAN',
        'desc': 'Single daily meal',
        'fixedMeals': [activeSlots.first],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'monthlyFee': 1600.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': true,
      });
    }

    for (final p in newConfigs) {
      final pid = p['id'] as String;
      final prev = existingState[pid];
      if (prev != null) {
        p['feeCtrl'] = TextEditingController(
            text: prev['fee'] ?? (p['monthlyFee'] as double).toInt().toString());
        p['skipCtrl'] = TextEditingController(
            text: prev['skip'] ?? (p['skipRefund'] as double).toInt().toString());
        p['maxSkip'] = prev['maxSkip'] ?? p['maxSkip'];
        p['enabled'] = prev['enabled'] ?? p['enabled'];
      } else {
        p['feeCtrl'] = TextEditingController(
            text: (p['monthlyFee'] as double).toInt().toString());
        p['skipCtrl'] = TextEditingController(
            text: (p['skipRefund'] as double).toInt().toString());
      }
    }

    setState(() => _planConfigs = newConfigs);
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _adjustCtrl(TextEditingController ctrl, double delta) {
    final current = double.tryParse(ctrl.text) ?? 0.0;
    final next = (current + delta).clamp(0.0, 99999.0);
    ctrl.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
    setState(() {});
  }

  Future<void> _finishSetup() async {
    final messName = _messNameCtrl.text.trim();
    final ownerName = _ownerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (messName.isEmpty || ownerName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कृपया सभी अनिवार्य फ़ील्ड्स (मेस का नाम, अपना नाम, मोबाइल नंबर) भरें।'
              : 'Please fill all required fields (Mess Name, Owner Name, Phone).'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length != 10 || !RegExp(r'^[6-9]').hasMatch(phoneDigits)) {
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

    final enabledPlans = _planConfigs.where((p) => p['enabled'] == true).toList();
    if (enabledPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'कम से कम एक मील प्लान चालू रखना आवश्यक है।'
              : 'At least one meal plan must be enabled.'),
          backgroundColor: const Color(0xFFB93822),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appService = ref.read(appServiceProvider);
      final user = FirebaseAuth.instance.currentUser;
      final effectiveOwnerId =
          user?.uid ?? 'owner_${DateTime.now().millisecondsSinceEpoch}';

      final adminConfig = await AdminService().getGlobalConfig();
      final trialDays = adminConfig.defaultTrialDays;
      final trialStart = DateTime.now();
      final trialExpiry = trialStart.add(Duration(days: trialDays));

      final messId = 'mess_${DateTime.now().millisecondsSinceEpoch}';
      final messCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

      final timingsMap = <String, Map<String, String>>{};
      for (final entry in _timings.entries) {
        timingsMap[entry.key] = {
          'enabled': entry.value['enabled'].toString(),
          'start': entry.value['start'].toString(),
          'end': entry.value['end'].toString(),
          'name': entry.value['name'].toString(),
        };
      }

      final firstPlan = enabledPlans.first;
      final defaultMonthlyFee =
          double.tryParse((firstPlan['feeCtrl'] as TextEditingController).text) ??
              3000.0;
      final defaultSkipRefund =
          double.tryParse((firstPlan['skipCtrl'] as TextEditingController).text) ??
              40.0;

      final newMess = MessModel(
        messId: messId,
        name: messName,
        ownerId: effectiveOwnerId,
        ownerName: ownerName.isEmpty ? 'Owner' : ownerName,
        ownerPhone: phone,
        gpsLat: 0.0,
        gpsLng: 0.0,
        messCode: messCode,
        monthlyFee: defaultMonthlyFee,
        perMealRate: defaultSkipRefund,
        mealTimings: timingsMap,
        cutoffHours: _cutoffLeadHours,
        foodType: _foodType,
        capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 50,
        trialStartDate: trialStart,
        trialExpiresAt: trialExpiry,
        subscriptionStatus:
            adminConfig.globalTrialEnabled ? 'trial_active' : 'active',
      );

      await appService.createMess(newMess);

      if (adminConfig.globalTrialEnabled) {
        try {
          await NotificationService.sendStudentNotification(
            studentId: effectiveOwnerId,
            title: '🎉 Welcome to MessMate!',
            message:
                'Aapka 180 Days (6 Months) Free VIP Partner Access shuru ho gaya hai!',
          );
        } catch (_) {}
      }

      for (final planConfig in enabledPlans) {
        final planId = '${messId}_${planConfig['id']}';
        final choiceGroups = <ChoiceGroupModel>[];

        if (planConfig['hasChoice'] as bool) {
          final choiceSlots =
              List<String>.from(planConfig['choiceSlots'] as List);
          choiceGroups.add(
            ChoiceGroupModel(
              groupId: 'cg_${planConfig['id']}',
              name: isHindi
                  ? (planConfig['choiceDescHi'] as String? ??
                      planConfig['choiceDesc'] as String? ??
                      'Meal Choice')
                  : (planConfig['choiceDesc'] as String? ?? 'Meal Choice'),
              availableMeals: choiceSlots,
              minSelectable: 1,
              maxSelectable: 1,
            ),
          );
        }

        final fee = double.tryParse(
                (planConfig['feeCtrl'] as TextEditingController).text) ??
            defaultMonthlyFee;
        final refund = double.tryParse(
                (planConfig['skipCtrl'] as TextEditingController).text) ??
            defaultSkipRefund;

        final mealPlan = MealPlanModel(
          planId: planId,
          messId: messId,
          name: isHindi
              ? (planConfig['nameHi'] as String? ?? planConfig['name'] as String)
              : (planConfig['name'] as String),
          monthlyFee: fee,
          extraMealRate: refund,
          fixedMeals: List<String>.from(planConfig['fixedMeals'] as List),
          choiceGroups: choiceGroups,
          deductionPolicy: DeductionPolicyModel(
            policyType: 'flat_fixed_rate',
            flatRate: refund,
            maxSkipsPerMonth: planConfig['maxSkip'] as int?,
          ),
        );

        await appService.saveMealPlan(mealPlan);
      }

      ref
          .read(authProvider.notifier)
          .setDemoUser(userId: effectiveOwnerId, role: AuthRole.owner);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OwnerMainPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHindi
                ? 'मेस सेटअप करने में त्रुटि: $e'
                : 'Error setting up mess: $e'),
            backgroundColor: const Color(0xFFB93822),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar with Back Button & Serif Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: _currentStep > 0
                        ? _prevPage
                        : () => Navigator.pop(context),
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
                    isHindi ? 'मेस सेटअप' : 'Mess setup',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ],
              ),
            ),

            // Stepper Indicator (1 Timings, 2 Plans, 3 Profile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Row(
                children: [
                  _buildStepBubble(0, isHindi ? 'समय' : 'Timings'),
                  _buildStepDivider(0),
                  _buildStepBubble(1, isHindi ? 'प्लान्स' : 'Plans'),
                  _buildStepDivider(1),
                  _buildStepBubble(2, isHindi ? 'प्रोफाइल' : 'Profile'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0Timings(),
                  _buildStep1Plans(),
                  _buildStep2Profile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(int stepIndex, String title) {
    final isDone = _currentStep > stepIndex;
    final isActive = _currentStep == stepIndex;

    Color bg = const Color(0xFFCBD6C7);
    Color fg = const Color(0xFF7A7971);

    if (isActive) {
      bg = const Color(0xFFF09E38);
      fg = const Color(0xFF231A14);
    } else if (isDone) {
      bg = const Color(0xFF4E654F);
      fg = Colors.white;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: fg,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? const Color(0xFF231A14)
                : const Color(0xFF7A7971),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 20),
        color: isDone ? const Color(0xFF4E654F) : const Color(0x2B2D231C),
      ),
    );
  }

  // ============================================================
  // STEP 0: Set Meal Timings
  // Matching WhatsApp Image 2026-10-21 at 17.01.05 (2).jpeg
  // ============================================================
  Widget _buildStep0Timings() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1 of 3 Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE3BF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isHindi ? 'चरण 1 / 3' : 'Step 1 of 3',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8F4700),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Headline
          Text(
            isHindi ? 'भोजन का समय तय करें' : 'Set meal timings',
            style: GoogleFonts.newsreader(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF231A14),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            isHindi
                ? 'आप कौन-से भोजन परोसते हैं? सक्रिय स्लॉट चालू करें और दैनिक समय निर्धारित करें।'
                : 'Which meals do you serve? Enable the active slots and set daily timings.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7A7971),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // 4 Meal Slot Cards
          ..._timings.entries.map((entry) {
            final key = entry.key;
            final data = entry.value;
            final isEnabled = data['enabled'] as bool;
            final color = data['color'] as Color;
            final name = isHindi ? (data['nameHi'] as String) : (data['name'] as String);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F3),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isEnabled
                      ? const Color(0x2B2D231C)
                      : const Color(0x142D231C),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF231A14),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEnabled
                                  ? (isHindi ? 'सक्रिय' : 'Active')
                                  : (isHindi ? 'निष्क्रिय' : 'Disabled'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isEnabled
                                    ? const Color(0xFF4E654F)
                                    : const Color(0xFF9E9A90),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isEnabled,
                        activeTrackColor: const Color(0xFF4E654F),
                        activeThumbColor: const Color(0xFFFAF8F3),
                        onChanged: (val) {
                          setState(() => data['enabled'] = val);
                          _syncPlansToActiveSlots();
                        },
                      ),
                    ],
                  ),

                  if (isEnabled) ...[
                    const SizedBox(height: 14),
                    Text(
                      isHindi ? 'समय बदलने के लिए टैप करें' : 'Tap to change time',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF7A7971),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(key, true),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0x1A2D231C)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHindi ? 'से' : 'From',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF7A7971),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime12(data['start'] as String),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF231A14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            isHindi ? 'से' : 'to',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF7A7971),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(key, false),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0x1A2D231C)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHindi ? 'तक' : 'To',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF7A7971),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime12(data['end'] as String),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF231A14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Cut-Off Notice Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F3),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x1A2D231C)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'कट-ऑफ नोटिस' : 'Cut-off notice',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHindi
                            ? 'भोजन शुरू होने से कितने घंटे पहले छात्र स्किप कर सकता है'
                            : 'Hours before a meal starts that a student can skip',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7A7971),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    _buildRoundStepBtn('-', () {
                      if (_cutoffLeadHours > 1) {
                        setState(() => _cutoffLeadHours--);
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_cutoffLeadHours h',
                        style: GoogleFonts.newsreader(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
                    ),
                    _buildRoundStepBtn('+', () {
                      if (_cutoffLeadHours < 6) {
                        setState(() => _cutoffLeadHours++);
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Next Button
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
              onPressed: _nextPage,
              child: Text(
                isHindi ? 'आगे: मील प्लान्स →' : 'Next: meal plans →',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF231A14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 1: Plans & Pricing
  // Matching WhatsApp Image 2026-10-21 at 17.01.06 (2).jpeg
  // ============================================================
  Widget _buildStep1Plans() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 2 of 3 Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE3BF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isHindi ? 'चरण 2 / 3' : 'Step 2 of 3',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8F4700),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Headline
          Text(
            isHindi ? 'प्लान्स और शुल्क' : 'Plans & pricing',
            style: GoogleFonts.newsreader(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF231A14),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            isHindi
                ? 'आपके समय के अनुसार प्लान तैयार हैं। जो आप ऑफर करना चाहते हैं उन्हें चालू रखें।'
                : 'Plans are ready from your timings. Keep the ones you want active.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7A7971),
            ),
          ),

          const SizedBox(height: 18),

          // Plan Cards
          ..._planConfigs.map((plan) {
            final isEnabled = plan['enabled'] as bool;
            final feeCtrl = plan['feeCtrl'] as TextEditingController;
            final skipCtrl = plan['skipCtrl'] as TextEditingController;
            final fixedMeals = List<String>.from(plan['fixedMeals'] as List);
            final hasChoice = plan['hasChoice'] as bool;
            final choiceDesc = plan['choiceDesc'] as String? ?? '';
            final badge = plan['badge'] as String? ?? 'POPULAR';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F3),
                borderRadius: BorderRadius.circular(22),
                border: Border(
                  left: BorderSide(
                    color: isEnabled
                        ? const Color(0xFFF09E38)
                        : const Color(0x142D231C),
                    width: 5,
                  ),
                  top: const BorderSide(color: Color(0x142D231C)),
                  right: const BorderSide(color: Color(0x142D231C)),
                  bottom: const BorderSide(color: Color(0x142D231C)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Badge & Switch
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                badge,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: const Color(0xFF4E654F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isHindi
                                    ? (plan['nameHi'] as String? ??
                                        plan['name'] as String)
                                    : (plan['name'] as String),
                                style: GoogleFonts.newsreader(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF231A14),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                plan['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7971),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isEnabled,
                          activeTrackColor: const Color(0xFF4E654F),
                          activeThumbColor: const Color(0xFFFAF8F3),
                          onChanged: (val) {
                            setState(() => plan['enabled'] = val);
                          },
                        ),
                      ],
                    ),

                    if (isEnabled) ...[
                      const SizedBox(height: 12),

                      // Meal Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ...fixedMeals.map((m) {
                            final slotName =
                                _timings[m]?['slotNameEn'] ?? m;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8DE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                slotName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2B3B2C),
                                ),
                              ),
                            );
                          }),
                          if (hasChoice && choiceDesc.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8DE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                choiceDesc,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2B3B2C),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0x142D231C)),
                      const SizedBox(height: 14),

                      // Monthly Fee Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'महीने का शुल्क' : 'Monthly fee',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF231A14),
                                ),
                              ),
                              Text(
                                isHindi ? 'प्रति छात्र' : 'per student',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF7A7971),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildRoundStepBtn('-', () => _adjustCtrl(feeCtrl, -100)),
                              Container(
                                width: 85,
                                height: 38,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0x1A2D231C)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '₹${feeCtrl.text}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF231A14),
                                  ),
                                ),
                              ),
                              _buildRoundStepBtn('+', () => _adjustCtrl(feeCtrl, 100)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Skip Refund Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'स्किप रिफंड' : 'Skip refund',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF231A14),
                                ),
                              ),
                              Text(
                                isHindi ? 'प्रति वैध स्किप' : 'per valid skip',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF7A7971),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildRoundStepBtn('-', () => _adjustCtrl(skipCtrl, -5)),
                              Container(
                                width: 85,
                                height: 38,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0x1A2D231C)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '₹${skipCtrl.text}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF231A14),
                                  ),
                                ),
                              ),
                              _buildRoundStepBtn('+', () => _adjustCtrl(skipCtrl, 5)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Max Skips Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'अधिकतम स्किप' : 'Max skips',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF231A14),
                                ),
                              ),
                              Text(
                                isHindi ? 'प्रति माह' : 'per month',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF7A7971),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if ((plan['maxSkip'] as int) != -1) ...[
                                _buildRoundStepBtn('-', () {
                                  final cur = plan['maxSkip'] as int;
                                  if (cur > 1) setState(() => plan['maxSkip'] = cur - 1);
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Text(
                                    '${plan['maxSkip']} meals',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF231A14),
                                    ),
                                  ),
                                ),
                                _buildRoundStepBtn('+', () {
                                  final cur = plan['maxSkip'] as int;
                                  if (cur < 30) setState(() => plan['maxSkip'] = cur + 1);
                                }),
                                const SizedBox(width: 8),
                              ],
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if ((plan['maxSkip'] as int) == -1) {
                                      plan['maxSkip'] = 6;
                                    } else {
                                      plan['maxSkip'] = -1;
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (plan['maxSkip'] as int) == -1
                                        ? const Color(0xFFFCE3BF)
                                        : const Color(0xFFE2E8DE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isHindi ? 'असीमित' : 'Unlimited',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: (plan['maxSkip'] as int) == -1
                                          ? const Color(0xFF8F4700)
                                          : const Color(0xFF2B3B2C),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Next Button
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
              onPressed: _nextPage,
              child: Text(
                isHindi ? 'आगे: मेस प्रोफाइल →' : 'Next: mess profile →',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF231A14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: _prevPage,
              child: Text(
                isHindi ? '← समय पर वापस जाएं' : '← Back to timings',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7A7971),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2: Mess Profile
  // Matching WhatsApp Image 2026-10-21 at 17.01.06 (1).jpeg
  // ============================================================
  Widget _buildStep2Profile() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 3 of 3 Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE3BF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isHindi ? 'चरण 3 / 3' : 'Step 3 of 3',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8F4700),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Headline
          Text(
            isHindi ? 'मेस प्रोफाइल' : 'Mess profile',
            style: GoogleFonts.newsreader(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF231A14),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            isHindi
                ? 'अंतिम चरण: मेस का नाम, अपना नाम और संपर्क विवरण भरें।'
                : 'Final step: mess name, owner and contact details.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7A7971),
            ),
          ),

          const SizedBox(height: 20),

          // MESS NAME *
          _buildFieldLabel(isHindi ? 'मेस का नाम *' : 'MESS NAME *'),
          const SizedBox(height: 8),
          _buildInputBox(
            controller: _messNameCtrl,
            hint: isHindi ? 'जैसे: श्री अन्नपूर्णा मेस' : 'e.g. Annapurna Mess',
          ),

          const SizedBox(height: 18),

          // OWNER NAME *
          _buildFieldLabel(isHindi ? 'संचालक का नाम *' : 'OWNER NAME *'),
          const SizedBox(height: 8),
          _buildInputBox(
            controller: _ownerNameCtrl,
            hint: isHindi ? 'जैसे: रोहित शर्मा' : 'e.g. Rohit Sharma',
          ),

          const SizedBox(height: 18),

          // PHONE NUMBER *
          _buildFieldLabel(isHindi ? 'फोन नंबर *' : 'PHONE NUMBER *'),
          const SizedBox(height: 8),
          _buildInputBox(
            controller: _phoneCtrl,
            hint: '9876543210',
            keyboardType: TextInputType.phone,
            prefixText: '+91 ',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),

          const SizedBox(height: 18),

          // SEATING CAPACITY
          _buildFieldLabel(isHindi ? 'बैठने की क्षमता' : 'SEATING CAPACITY'),
          const SizedBox(height: 8),
          _buildInputBox(
            controller: _capacityCtrl,
            hint: '50',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 18),

          // FOOD TYPE
          _buildFieldLabel(isHindi ? 'भोजन प्रकार' : 'FOOD TYPE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _foodType = 'pure_veg'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _foodType == 'pure_veg'
                          ? const Color(0xFFE2E8DE)
                          : const Color(0xFFFAF8F3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _foodType == 'pure_veg'
                            ? const Color(0xFF4E654F)
                            : const Color(0x142D231C),
                        width: _foodType == 'pure_veg' ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _foodType == 'pure_veg'
                            ? (isHindi ? '✓ शुद्ध शाकाहारी' : '✓ Pure veg')
                            : (isHindi ? 'शुद्ध शाकाहारी' : 'Pure veg'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: _foodType == 'pure_veg'
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _foodType == 'pure_veg'
                              ? const Color(0xFF2B3B2C)
                              : const Color(0xFF231A14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _foodType = 'both'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _foodType == 'both'
                          ? const Color(0xFFE2E8DE)
                          : const Color(0xFFFAF8F3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _foodType == 'both'
                            ? const Color(0xFF4E654F)
                            : const Color(0x142D231C),
                        width: _foodType == 'both' ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _foodType == 'both'
                            ? (isHindi ? '✓ वेज व नॉन-वेज' : '✓ Both veg & non-veg')
                            : (isHindi ? 'वेज व नॉन-वेज' : 'Both veg & non-veg'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: _foodType == 'both'
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _foodType == 'both'
                              ? const Color(0xFF2B3B2C)
                              : const Color(0xFF231A14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ready Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8DE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF4E654F),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi
                            ? 'अपनी मेस लॉन्च करने के लिए तैयार'
                            : 'Ready to launch your mess',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2B3B2C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHindi
                            ? 'आप सेटिंग्स में कभी भी समय और प्लान्स बदल सकते हैं।'
                            : 'You can adjust timings and plans anytime in Settings.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4E654F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Launch Mess Button
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
              onPressed: _isSubmitting ? null : _finishSetup,
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
                          isHindi ? 'मेस शुरू करें →' : 'Launch mess →',
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

          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: _prevPage,
              child: Text(
                isHindi ? '← प्लान्स पर वापस जाएं' : '← Back to plans',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7A7971),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
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

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1A2D231C),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF231A14),
        ),
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
    );
  }

  Widget _buildRoundStepBtn(String symbol, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFE2E8DE),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B3B2C),
            ),
          ),
        ),
      ),
    );
  }
}