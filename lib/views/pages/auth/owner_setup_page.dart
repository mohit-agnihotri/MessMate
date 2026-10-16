import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
//
import '../../../viewmodels/all_viewmodels.dart';
import '../owner/owner_main_page.dart';

/// OwnerSetupPage:
/// 3-step setup wizard for mess owners.
/// Step 0: Meal Timings & Cut-off (Interactive TimePickers)
/// Step 1: Dynamic Meal Plans & Pricing (Adapts dynamically to enabled Step 0 slots, allows any decimal skip refund / monthly fee)
/// Step 2: Mess Profile & Launch
class OwnerSetupPage extends ConsumerStatefulWidget {
  const OwnerSetupPage({super.key});

  @override
  ConsumerState<OwnerSetupPage> createState() => _OwnerSetupPageState();
}

class _OwnerSetupPageState extends ConsumerState<OwnerSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // STEP 0: Meal Timings & Cutoff
  final Map<String, Map<String, dynamic>> _timings = {
    'morning': {
      'name': 'सुबह का नाश्ता (Breakfast)',
      'slotName': 'नाश्ता',
      'enabled': true,
      'start': '08:00',
      'end': '10:00',
      'time': 'सुबह 8:00 AM से 10:00 AM',
      'icon': '☀️',
      'color': const Color(0xFFF59E0B),
    },
    'noon': {
      'name': 'दोपहर का खाना (Lunch)',
      'slotName': 'दोपहर खाना',
      'enabled': true,
      'start': '12:30',
      'end': '14:30',
      'time': 'दोपहर 12:30 PM से 2:30 PM',
      'icon': '🍲',
      'color': const Color(0xFFEF4444),
    },
    'evening': {
      'name': 'शाम का चाय/नाश्ता (Evening Snacks)',
      'slotName': 'शाम नाश्ता',
      'enabled': false,
      'start': '17:00',
      'end': '18:30',
      'time': 'शाम 5:00 PM से 6:30 PM',
      'icon': '☕',
      'color': const Color(0xFFD97706),
    },
    'night': {
      'name': 'रात का खाना (Dinner)',
      'slotName': 'रात खाना',
      'enabled': true,
      'start': '19:30',
      'end': '22:00',
      'time': 'रात 7:30 PM से 10:00 PM',
      'icon': '🌙',
      'color': const Color(0xFF6366F1),
    },
  };
  int _cutoffLeadHours = 2;

  // STEP 1: Dynamically generated meal plans based on Step 0 enabled slots
  List<Map<String, dynamic>> _planConfigs = [];
  String _lastActiveSlotsKey = '';

  // STEP 2: Mess Profile
  final _messNameCtrl = TextEditingController(text: 'श्री अन्नपूर्णा मेस');
  final _ownerNameCtrl = TextEditingController(text: 'रोहित शर्मा');
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _capacityCtrl = TextEditingController(text: '50');
  String _foodType = 'pure_veg'; // pure_veg, both

  @override
  void initState() {
    super.initState();
    _syncPlansToActiveSlots(force: true);
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

  String _formatTimeOfDay24(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

  Future<void> _pickTime(String slotKey, bool isStart) async {
    final slot = _timings[slotKey];
    if (slot == null) return;
    final currentStr = (slot[isStart ? 'start' : 'end'] as String?) ?? '08:00';
    final initial = _parseTimeOfDay(currentStr);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: '${slot['slotName']} ${isStart ? 'शुरू होने का समय' : 'समाप्त होने का समय'}',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE11D48),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final time24 = _formatTimeOfDay24(picked);
        slot[isStart ? 'start' : 'end'] = time24;
        final s = _formatTime12(slot['start'] as String);
        final e = _formatTime12(slot['end'] as String);
        slot['time'] = '$s से $e';
      });
    }
  }

  void _adjustCtrl(TextEditingController ctrl, double delta, {double min = 0, double max = 100000}) {
    final current = double.tryParse(ctrl.text.trim()) ?? 0.0;
    final updated = (current + delta).clamp(min, max);
    if (updated == updated.roundToDouble()) {
      ctrl.text = updated.toInt().toString();
    } else {
      ctrl.text = updated.toStringAsFixed(1);
    }
    setState(() {});
  }
  void _syncPlansToActiveSlots({bool force = false}) {
    final activeSlots = _timings.entries
        .where((e) => e.value['enabled'] == true)
        .map((e) => e.key)
        .toList();
    final activeKey = activeSlots.join(',');

    if (!force && activeKey == _lastActiveSlotsKey) return;
    _lastActiveSlotsKey = activeKey;

    for (final p in _planConfigs) {
      (p['feeCtrl'] as TextEditingController?)?.dispose();
      (p['skipCtrl'] as TextEditingController?)?.dispose();
    }

    final List<Map<String, dynamic>> newConfigs = [];
    final hasMorning = activeSlots.contains('morning');
    final hasNoon = activeSlots.contains('noon');
    //
    final hasNight = activeSlots.contains('night');

    if (activeSlots.length == 4) {
      newConfigs.add({
        'id': 'full_4',
        'name': 'चारों वक्त का पूरा खाना (4-Meal Full Plan)',
        'badge': 'सर्वोत्तम व पूर्ण आहार',
        'desc': 'नाश्ता + दोपहर खाना + शाम नाश्ता + रात का खाना',
        'fixedMeals': ['morning', 'noon', 'evening', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 3800.0,
        'skipRefund': 35.0,
        'maxSkip': 8,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'regular_3',
        'name': 'तीनों वक्त का खाना (3-Meal Regular)',
        'badge': 'सबसे लोकप्रिय',
        'desc': 'नाश्ता + दोपहर का खाना + रात का खाना',
        'fixedMeals': ['morning', 'noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 3000.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'core_2',
        'name': 'दोपहर + रात का खाना (Lunch & Dinner)',
        'badge': 'छात्रों की पहली पसंद',
        'desc': 'दोपहर का भोजन और रात का भोजन',
        'fixedMeals': ['noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 2400.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'choice_flex',
        'name': 'फ्लेक्सिबल प्लान (नाश्ता या शाम नाश्ता + दोपहर व रात)',
        'badge': 'सुपर फ्लेक्सिबल',
        'desc': 'दोपहर व रात अनिवार्य, सुबह का नाश्ता या शाम का नाश्ता में से कोई 1',
        'fixedMeals': ['noon', 'night'],
        'hasChoice': true,
        'choiceSlots': ['morning', 'evening'],
        'choiceDesc': 'नाश्ता या शाम नाश्ता में से कोई 1',
        'monthlyFee': 2800.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'single_choice',
        'name': 'सिंगल मील प्लान (दोपहर या रात में से कोई 1)',
        'badge': 'किफायती प्लान',
        'desc': 'छात्र केवल दोपहर या रात का भोजन चुन सकते हैं',
        'fixedMeals': <String>[],
        'hasChoice': true,
        'choiceSlots': ['noon', 'night'],
        'choiceDesc': 'दोपहर या रात में से कोई 1',
        'monthlyFee': 1500.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': false,
      });
    } else if (activeSlots.length == 3 && hasMorning && hasNoon && hasNight) {
      newConfigs.add({
        'id': 'full_3',
        'name': 'तीनों वक्त का खाना (Full 3-Meal Plan)',
        'badge': 'सबसे लोकप्रिय',
        'desc': 'सुबह का नाश्ता + दोपहर का भोजन + रात का भोजन',
        'fixedMeals': ['morning', 'noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 3000.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'core_2',
        'name': 'दोपहर + रात का खाना (Lunch & Dinner)',
        'badge': 'छात्रों की पहली पसंद',
        'desc': 'दोपहर का भोजन और रात का भोजन',
        'fixedMeals': ['noon', 'night'],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 2400.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'choice_morning_or_noon',
        'name': 'फ्लेक्सी चॉइस प्लान (नाश्ता या दोपहर + रात)',
        'badge': 'फ्लेक्सी चॉइस',
        'desc': 'रात का खाना अनिवार्य + सुबह नाश्ता या दोपहर के खाने में से कोई 1',
        'fixedMeals': ['night'],
        'hasChoice': true,
        'choiceSlots': ['morning', 'noon'],
        'choiceDesc': 'सुबह का नाश्ता या दोपहर खाना में से कोई 1',
        'monthlyFee': 2200.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'single_choice',
        'name': 'सिंगल मील प्लान (दोपहर या रात में से कोई 1)',
        'badge': 'बजट फ्रेंडली',
        'desc': 'केवल एक वक्त का खाना (दोपहर या रात)',
        'fixedMeals': <String>[],
        'hasChoice': true,
        'choiceSlots': ['noon', 'night'],
        'choiceDesc': 'दोपहर या रात में से कोई 1',
        'monthlyFee': 1500.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': false,
      });
    } else if (activeSlots.length == 3) {
      newConfigs.add({
        'id': 'full_active_3',
        'name': 'तीनों वक्त का खाना (Full Plan)',
        'badge': 'फुल प्लान',
        'desc': activeSlots.map((s) => _timings[s]!['slotName']).join(' + '),
        'fixedMeals': List<String>.from(activeSlots),
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 3000.0,
        'skipRefund': 40.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'core_2_custom',
        'name': 'दो वक्त का खाना (2-Meal Plan)',
        'badge': 'पॉपुलर प्लान',
        'desc': '${_timings[activeSlots[1]]!['slotName']} + ${_timings[activeSlots[2]]!['slotName']}',
        'fixedMeals': [activeSlots[1], activeSlots[2]],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 2400.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'choice_custom',
        'name': 'फ्लेक्सी चॉइस प्लान',
        'badge': 'फ्लेक्सिबल',
        'desc': '${_timings[activeSlots.last]!['slotName']} + विकल्प',
        'fixedMeals': [activeSlots.last],
        'hasChoice': true,
        'choiceSlots': [activeSlots[0], activeSlots[1]],
        'choiceDesc': '${_timings[activeSlots[0]]!['slotName']} या ${_timings[activeSlots[1]]!['slotName']}',
        'monthlyFee': 2200.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });
    } else if (activeSlots.length == 2) {
      newConfigs.add({
        'id': 'full_2',
        'name': '${_timings[activeSlots[0]]!['slotName']} + ${_timings[activeSlots[1]]!['slotName']} (2-Meal Full)',
        'badge': 'फुल प्लान',
        'desc': 'दोनों वक्त का नियमित खाना',
        'fixedMeals': List<String>.from(activeSlots),
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 2500.0,
        'skipRefund': 45.0,
        'maxSkip': 6,
        'enabled': true,
      });

      newConfigs.add({
        'id': 'single_choice_2',
        'name': 'सिंगल मील प्लान (${_timings[activeSlots[0]]!['slotName']} या ${_timings[activeSlots[1]]!['slotName']})',
        'badge': 'सिंगल मील',
        'desc': 'केवल एक वक्त का भोजन',
        'fixedMeals': <String>[],
        'hasChoice': true,
        'choiceSlots': List<String>.from(activeSlots),
        'choiceDesc': '${_timings[activeSlots[0]]!['slotName']} या ${_timings[activeSlots[1]]!['slotName']}',
        'monthlyFee': 1500.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': true,
      });
    } else if (activeSlots.length == 1) {
      final slotKey = activeSlots.first;
      newConfigs.add({
        'id': 'single_only',
        'name': 'केवल ${_timings[slotKey]!['slotName']} (Single Meal Plan)',
        'badge': 'सिंगल मील',
        'desc': 'प्रतिदिन ${_timings[slotKey]!['slotName']}',
        'fixedMeals': [slotKey],
        'hasChoice': false,
        'choiceSlots': <String>[],
        'choiceDesc': '',
        'monthlyFee': 1500.0,
        'skipRefund': 50.0,
        'maxSkip': 4,
        'enabled': true,
      });
    }

    for (final p in newConfigs) {
      final fee = p['monthlyFee'] as double;
      final refund = p['skipRefund'] as double;
      p['feeCtrl'] = TextEditingController(text: fee.toInt().toString());
      p['skipCtrl'] = TextEditingController(
        text: refund == refund.roundToDouble() ? refund.toInt().toString() : refund.toString(),
      );
    }

    _planConfigs = newConfigs;
  }
  void _nextPage() {
    if (_currentStep == 0) {
      final activeSlots = _timings.entries.where((e) => e.value['enabled'] == true).toList();
      if (activeSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया कम से कम एक मील स्लॉट (नाश्ता, दोपहर या रात) चालू रखें।'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      _syncPlansToActiveSlots();
    } else if (_currentStep == 1) {
      final enabledPlans = _planConfigs.where((p) => p['enabled'] as bool).toList();
      if (enabledPlans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया कम से कम एक मील प्लान ऑन रखें।'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishSetup() async {
    final messName = _messNameCtrl.text.trim();
    if (messName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया मेस का नाम दर्ज करें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें।'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final effectiveOwnerId = currentUser?.uid ?? 'temp_owner';
      final appService = ref.read(appServiceProvider);

      final messId = 'mess_${effectiveOwnerId.substring(0, effectiveOwnerId.length > 8 ? 8 : effectiveOwnerId.length)}_${DateTime.now().millisecondsSinceEpoch % 10000}';
      final messCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

      final Map<String, Map<String, String>> mealTimingsMap = {};
      _timings.forEach((k, v) {
        mealTimingsMap[k] = {
          'start': v['start'] as String,
          'end': v['end'] as String,
          'enabled': (v['enabled'] as bool) ? 'true' : 'false',
        };
      });

      final enabledPlans = _planConfigs.where((p) => p['enabled'] as bool).toList();
      double baseFee = 3000.0;
      double perMealRefund = 40.0;

      if (enabledPlans.isNotEmpty) {
        final first = enabledPlans.first;
        baseFee = double.tryParse((first['feeCtrl'] as TextEditingController?)?.text ?? first['monthlyFee'].toString()) ?? 3000.0;
        perMealRefund = double.tryParse((first['skipCtrl'] as TextEditingController?)?.text ?? first['skipRefund'].toString()) ?? 40.0;
      }

      final newMess = MessModel(
        messId: messId,
        ownerId: effectiveOwnerId,
        name: messName,
        ownerName: _ownerNameCtrl.text.trim().isEmpty ? 'Owner' : _ownerNameCtrl.text.trim(),
        ownerPhone: phone,
        gpsLat: 0.0,
        gpsLng: 0.0,
        messCode: messCode,
        monthlyFee: baseFee,
        perMealRate: perMealRefund,
        mealTimings: mealTimingsMap,
        cutoffHours: _cutoffLeadHours,
        foodType: _foodType,
        capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 50,
      );

      await appService.createMess(newMess);

      for (final planConfig in enabledPlans) {
        final planId = '${messId}_${planConfig['id']}';
        final List<ChoiceGroupModel> choiceGroups = [];

        if (planConfig['hasChoice'] as bool) {
          final choiceSlots = List<String>.from(planConfig['choiceSlots'] as List);
          choiceGroups.add(
            ChoiceGroupModel(
              groupId: 'cg_${planConfig['id']}',
              name: planConfig['choiceDesc'] as String,
              availableMeals: choiceSlots,
              minSelectable: 1,
              maxSelectable: 1,
            ),
          );
        }

        final fee = double.tryParse((planConfig['feeCtrl'] as TextEditingController?)?.text ?? planConfig['monthlyFee'].toString()) ?? 3000.0;
        final refund = double.tryParse((planConfig['skipCtrl'] as TextEditingController?)?.text ?? planConfig['skipRefund'].toString()) ?? 40.0;

        final mealPlan = MealPlanModel(
          planId: planId,
          messId: messId,
          name: planConfig['name'] as String,
          monthlyFee: fee,
          extraMealRate: refund,
          fixedMeals: List<String>.from(planConfig['fixedMeals'] as List),
          choiceGroups: choiceGroups,
          deductionPolicy: DeductionPolicyModel(
            policyType: 'flat_fixed_rate',
            flatRate: refund,
          ),
        );

        await appService.saveMealPlan(mealPlan);
      }

      ref.read(authProvider.notifier).setDemoUser(userId: effectiveOwnerId, role: AuthRole.owner);

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
            content: Text('मेस सेटअप करने में त्रुटि: $e'),
            backgroundColor: const Color(0xFFEF4444),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'मेस सेटअप (Mess Setup)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        centerTitle: true,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: _prevPage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStepBubble(0, '1. समय (Timings)'),
                  _buildStepDivider(0),
                  _buildStepBubble(1, '2. प्लान्स (Plans)'),
                  _buildStepDivider(1),
                  _buildStepBubble(2, '3. प्रोफाइल (Profile)'),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

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

    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF64748B);

    if (isActive) {
      bg = const Color(0xFFE11D48);
      fg = Colors.white;
    } else if (isDone) {
      bg = const Color(0xFF10B981);
      fg = Colors.white;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: fg),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFFE11D48) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildStep0Timings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            1,
            'भोजन का समय तय करें (Meal Timings)',
            'आपकी मेस में कौन-कौन से वक्त खाना बनता है? चालू स्लॉट चुनें और समय पर क्लिक करके अपनी पसंद अनुसार समय सेट करें।',
          ),
          const SizedBox(height: 20),

          ..._timings.entries.map((entry) {
            final key = entry.key;
            final data = entry.value;
            final isEnabled = data['enabled'] as bool;
            final color = data['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled ? color.withOpacity(0.5) : const Color(0xFFE2E8F0),
                  width: isEnabled ? 1.5 : 1.0,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(data['icon'] as String, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEnabled ? 'चालू है (Active)' : 'बंद है (Disabled)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isEnabled,
                        activeColor: color,
                        onChanged: (val) {
                          setState(() {
                            data['enabled'] = val;
                          });
                        },
                      ),
                    ],
                  ),

                  if (isEnabled) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    Text(
                      'समय बदलें (Tap to change time):',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(key, true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('शुरू (From)', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                        Text(
                                          _formatTime12(data['start'] as String),
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit, size: 14, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('से', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(key, false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('समाप्त (To)', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                        Text(
                                          _formatTime12(data['end'] as String),
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit, size: 14, color: Color(0xFF94A3B8)),
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

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.timer_outlined, color: Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'कटऑफ समय (Cut-off Notice)',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'खाना शुरू होने से कितने घंटे पहले छात्र छुट्टी ले सकता है?',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniStepBtn('-', () {
                      if (_cutoffLeadHours > 1) {
                        setState(() => _cutoffLeadHours--);
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_cutoffLeadHours घंटे',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                    ),
                    _buildMiniStepBtn('+', () {
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
          _buildNextBtn(label: 'आगे बढ़ें (Next: Meal Plans)', onTap: _nextPage),
        ],
      ),
    );
  }
  Widget _buildStep1Plans() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            2,
            'मील प्लान और शुल्क (Plans & Pricing)',
            'आपके द्वारा चुने गए समय अनुसार प्लान तैयार हैं। जो प्लान ऑफर करना चाहते हैं उसे चालू रखें। फीस और रिफंड पर सीधे क्लिक करके कोई भी राशि (जैसे ₹45 या ₹41.2) दर्ज करें।',
          ),
          const SizedBox(height: 20),

          ..._planConfigs.map((plan) {
            final isEnabled = plan['enabled'] as bool;
            final feeCtrl = plan['feeCtrl'] as TextEditingController;
            final skipCtrl = plan['skipCtrl'] as TextEditingController;
            final fixedMeals = List<String>.from(plan['fixedMeals'] as List);
            final hasChoice = plan['hasChoice'] as bool;
            final choiceSlots = List<String>.from(plan['choiceSlots'] as List);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                  width: isEnabled ? 1.8 : 1.0,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      plan['name'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEnabled ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      plan['badge'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isEnabled ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan['desc'] as String,
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isEnabled,
                          activeColor: const Color(0xFFE11D48),
                          onChanged: (val) {
                            setState(() => plan['enabled'] = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (fixedMeals.isNotEmpty) ...[
                          _buildMealChipsRow(fixedMeals, active: isEnabled),
                          const SizedBox(height: 6),
                        ],
                        if (hasChoice) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isEnabled ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isEnabled ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 16,
                                  color: isEnabled ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'छात्र की पसंद: ${choiceSlots.map((s) => _timings[s]?['slotName'] ?? s).join(' या ')} (कोई 1)',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isEnabled ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),

                  if (isEnabled) ...[
                    const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'प्रति माह फीस (Monthly Fee)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('छात्र से मासिक शुल्क', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildMiniStepBtn('-', () => _adjustCtrl(feeCtrl, -100, min: 500)),
                                  Container(
                                    width: 88,
                                    height: 38,
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Center(
                                      child: TextField(
                                        controller: feeCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          prefixText: '₹',
                                          prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildMiniStepBtn('+', () => _adjustCtrl(feeCtrl, 100)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'छुट्टी रिफंड (Skip Refund / Meal)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('प्रति मील छूट (e.g. ₹45 या ₹41.2)', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildMiniStepBtn('-', () => _adjustCtrl(skipCtrl, -5, min: 0)),
                                  Container(
                                    width: 88,
                                    height: 38,
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Center(
                                      child: TextField(
                                        controller: skipCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          prefixText: '₹',
                                          prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildMiniStepBtn('+', () => _adjustCtrl(skipCtrl, 5)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'अधिकतम छुट्टी सीमा (Max Skips)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text('महीने में स्वीकार्य छुट्टियां', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildMiniStepBtn('-', () {
                                    final current = plan['maxSkip'] as int;
                                    if (current > 0) {
                                      setState(() => plan['maxSkip'] = current - 1);
                                    }
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '${plan['maxSkip']} मील',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                    ),
                                  ),
                                  _buildMiniStepBtn('+', () {
                                    final current = plan['maxSkip'] as int;
                                    if (current < 30) {
                                      setState(() => plan['maxSkip'] = current + 1);
                                    }
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
          _buildNextBtn(label: 'आगे बढ़ें (Next: Mess Profile)', onTap: _nextPage),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _prevPage,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text('समय बदलें (Back to Timings)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Profile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            3,
            'मेस की जानकारी (Mess Profile)',
            'अंतिम चरण: अपनी मेस का नाम, मालिक का नाम और संपर्क नंबर भरें। यह जानकारी छात्रों को दिखाई जाएगी।',
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  label: 'मेस का नाम (Mess Name) *',
                  hint: 'जैसे: श्री अन्नपूर्णा मेस',
                  ctrl: _messNameCtrl,
                  prefixIcon: Icons.storefront_rounded,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'मालिक का नाम (Owner Name) *',
                  hint: 'जैसे: रोहित शर्मा',
                  ctrl: _ownerNameCtrl,
                  prefixIcon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'मोबाइल नंबर (Phone Number) *',
                  hint: '10 अंकों का मोबाइल नंबर',
                  ctrl: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_rounded,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'बैठने की क्षमता (Seating Capacity)',
                  hint: 'जैसे: 50',
                  ctrl: _capacityCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.event_seat_rounded,
                ),
                const SizedBox(height: 20),

                Text(
                  'भोजन का प्रकार (Food Type)',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFoodOption(
                        'pure_veg',
                        Icons.eco_rounded,
                        const Color(0xFF10B981),
                        'शुद्ध शाकाहारी\n(Pure Veg)',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFoodOption(
                        'both',
                        Icons.restaurant_rounded,
                        const Color(0xFFF59E0B),
                        'शाकाहारी + मांसाहारी\n(Both Veg & Non-Veg)',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'मेस सेटअप पूरा होने को तैयार है',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'लांच के बाद आप कभी भी सेटिंग्स में जाकर समय या प्लान्स बदल सकते हैं।',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildNextBtn(
            label: 'मेस शुरू करें (Launch Mess)',
            onTap: _finishSetup,
            isLoading: _isSubmitting,
            color: const Color(0xFFE11D48),
          ),

          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _prevPage,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text('प्लान्स बदलें (Back to Plans)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(int step, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'चरण $step / 3 (Step $step of 3)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildMealChipsRow(List<String> meals, {bool active = true}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: meals.map((m) {
        final slot = _timings[m];
        final name = slot?['slotName'] ?? m;
        final icon = slot?['icon'] ?? '🍽️';
        final color = (slot?['color'] as Color?) ?? const Color(0xFFE11D48);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.12) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? color : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniStepBtn(String icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodOption(String type, IconData icon, Color color, String label) {
    final isSelected = _foodType == type;
    return InkWell(
      onTap: () => setState(() => _foodType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextBtn({
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFFE11D48),
          elevation: 2,
          shadowColor: (color ?? const Color(0xFFE11D48)).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}