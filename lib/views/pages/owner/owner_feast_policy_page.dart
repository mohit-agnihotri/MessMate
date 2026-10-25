import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';

class OwnerFeastPolicyPage extends ConsumerStatefulWidget {
  final MessModel mess;

  const OwnerFeastPolicyPage({super.key, required this.mess});

  static Future<void> navigate(BuildContext context, MessModel mess) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerFeastPolicyPage(mess: mess),
      ),
    );
  }

  @override
  ConsumerState<OwnerFeastPolicyPage> createState() =>
      _OwnerFeastPolicyPageState();
}

class _OwnerFeastPolicyPageState extends ConsumerState<OwnerFeastPolicyPage> {
  late bool _enabled;
  late List<String> _days;
  late List<String> _cookedSlots;
  late String _specialSlot;
  late TextEditingController _customRateCtrl;
  late TextEditingController _extendMealsCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.mess.specialMealEnabled;
    _days = widget.mess.specialMealDays.isNotEmpty
        ? List<String>.from(widget.mess.specialMealDays)
        : ['Sunday'];
    _cookedSlots = widget.mess.specialMealCookedSlots.isNotEmpty
        ? List<String>.from(widget.mess.specialMealCookedSlots)
        : ['noon', 'night'];
    _specialSlot = widget.mess.specialMealSlot.isNotEmpty
        ? widget.mess.specialMealSlot
        : (_cookedSlots.contains('night') ? 'night' : _cookedSlots.first);

    final initialRate = widget.mess.specialMealFlatRate != null &&
            widget.mess.specialMealFlatRate! > 0
        ? widget.mess.specialMealFlatRate!.toInt()
        : 90;
    _customRateCtrl = TextEditingController(text: initialRate.toString());

    final initialExtendMeals = widget.mess.specialMealExtendMeals > 0
        ? widget.mess.specialMealExtendMeals
        : (widget.mess.specialMealMultiplier > 0
            ? widget.mess.specialMealMultiplier.round()
            : 1);
    _extendMealsCtrl =
        TextEditingController(text: initialExtendMeals.toString());
  }

  @override
  void dispose() {
    _customRateCtrl.dispose();
    _extendMealsCtrl.dispose();
    super.dispose();
  }

  String _formatSlotName(String slot) {
    switch (slot) {
      case 'morning':
        return 'Morning · Breakfast';
      case 'noon':
        return 'Noon · Lunch';
      case 'evening':
        return 'Evening · Snacks';
      case 'night':
      default:
        return 'Night · Dinner';
    }
  }

  String _getEffectiveRefundText() {
    final rate = double.tryParse(_customRateCtrl.text.trim()) ?? 90;
    return '₹${rate.toInt()}';
  }

  Future<void> _savePolicy() async {
    setState(() => _isSaving = true);
    final isHi = ref.read(localizationProvider) == 'hi';
    try {
      final double effectiveFlatRate =
          double.tryParse(_customRateCtrl.text.trim()) ?? 90.0;
      final int effectiveExtendMeals =
          int.tryParse(_extendMealsCtrl.text.trim()) ?? 1;

      final updated = widget.mess.copyWith(
        specialMealEnabled: _enabled,
        specialMealDays: _days,
        specialMealCookedSlots: _cookedSlots,
        specialMealSlot: _specialSlot,
        specialMealMultiplier: effectiveExtendMeals.toDouble(),
        specialMealFlatRate: effectiveFlatRate,
        specialMealExtendMeals: effectiveExtendMeals,
      );

      await ref.read(ownerSettingsProvider.notifier).save(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHi
                ? 'स्पेशल दावत नीति सफलतापूर्वक सेव हो गई!'
                : 'Special feast policy saved successfully!'),
            backgroundColor: const Color(0xFF2B2019),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHi
                ? 'दावत नीति सेव करने में त्रुटि: $e'
                : 'Error saving feast policy: $e'),
            backgroundColor: const Color(0xFFB93822),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHi = ref.watch(localizationProvider) == 'hi';
    const allDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const allSlots = ['morning', 'noon', 'evening', 'night'];

    final primaryDay = _days.isNotEmpty ? _days.first : 'Sunday';
    final slotDisplay = _formatSlotName(_specialSlot).toLowerCase();
    final refundDisplay = _getEffectiveRefundText();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
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
                    isHi ? 'दावत नीति (Feast policy)' : 'Feast policy',
                    style: GoogleFonts.newsreader(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                children: [
                  // Hero Dark Brown Gradient Card (Screenshot 3)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const RadialGradient(
                        center: Alignment(0.85, -0.75),
                        radius: 1.2,
                        colors: [
                          Color(0xFF6E431E),
                          Color(0xFF2B2019),
                          Color(0xFF1E1611),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: Color(0xFFF4B34C),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isHi
                                      ? 'विशेष दावत नीति'
                                      : 'SPECIAL FEAST POLICY',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFFF4B34C),
                                  ),
                                ),
                              ],
                            ),
                            Transform.scale(
                              scale: 0.85,
                              child: CupertinoSwitch(
                                value: _enabled,
                                activeTrackColor: const Color(0xFF4A684C),
                                onChanged: (val) =>
                                    setState(() => _enabled = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _days.length > 1
                              ? _days.map((d) => d.substring(0, 3)).join(', ')
                              : primaryDay,
                          style: GoogleFonts.newsreader(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFF4E4),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHi
                              ? '$slotDisplay दावत स्लॉट है · $refundDisplay रिफंड प्रति स्पेशल स्किप'
                              : '$slotDisplay is the feast · $refundDisplay refund per special skip',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFFD4C7BA),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_enabled) ...[
                    const SizedBox(height: 24),

                    // FEAST DAYS
                    Text(
                      isHi ? 'दावत के दिन (FEAST DAYS)' : 'FEAST DAYS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF6B6862),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: allDays.map((day) {
                        final isSelected = _days.contains(day);
                        final shortName = day.substring(0, 3);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_days.length > 1) {
                                  _days.remove(day);
                                }
                              } else {
                                _days.add(day);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF2B2019)
                                  : const Color(0xFFFAF7F2),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2B2019)
                                    : const Color(0x142D231C),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                shortName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF231A14),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 26),

                    // COOKED SPECIAL MEALS
                    Text(
                      isHi
                          ? 'किस समय स्पेशल खाना बनेगा (COOKED MEALS)'
                          : 'COOKED SPECIAL MEALS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF6B6862),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHi
                          ? 'जिस समय स्पेशल खाना बनता है उसे टिक करें और दावत स्लॉट चुनें।'
                          : 'Tick what you cook special that day, then star the feast slot.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF7A7971),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Slots list
                    ...allSlots.map((slot) {
                      final isCooked = _cookedSlots.contains(slot);
                      final isDesignatedFeast = _specialSlot == slot;
                      final title = _formatSlotName(slot);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (!isCooked) {
                              _cookedSlots.add(slot);
                            }
                            _specialSlot = slot;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDesignatedFeast
                                ? const Color(0xFFFFF9EE)
                                : const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDesignatedFeast
                                  ? const Color(0xFFE9963F)
                                  : const Color(0x142D231C),
                              width: isDesignatedFeast ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isCooked) {
                                      if (_cookedSlots.length > 1) {
                                        _cookedSlots.remove(slot);
                                        if (_specialSlot == slot) {
                                          _specialSlot = _cookedSlots.first;
                                        }
                                      }
                                    } else {
                                      _cookedSlots.add(slot);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isCooked
                                        ? const Color(0xFF4A684C)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isCooked
                                          ? const Color(0xFF4A684C)
                                          : const Color(0xFF9E9B95),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isCooked
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Meal Slot Name
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: isDesignatedFeast
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: const Color(0xFF231A14),
                                  ),
                                ),
                              ),

                              // Right-side badge or text
                              if (isDesignatedFeast)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2B2019),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFFF4B34C),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Feast slot',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF4B34C),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  'Not cooked special',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF8C8881),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // SKIP REFUND & VALIDITY EXTENSION
                    Text(
                      isHi
                          ? 'स्पेशल मील छूट और वैधता नियम'
                          : 'SKIP REFUND & VALIDITY EXTENSION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF6B6862),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHi
                          ? 'तय करें कि स्पेशल मील न खाने पर छात्र को कितना रिफंड मिलेगा या कितनी मील आगे बढ़ेगी।'
                          : 'What a student gets when they skip a special meal.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF7A7971),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 1: Fixed Rupee Rate
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0x142D231C),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2EBE0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.currency_rupee_rounded,
                                    size: 18,
                                    color: Color(0xFF4A684C),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHi
                                          ? 'स्पेशल मील छूट रिफंड राशि'
                                          : 'Special Meal Skip Refund',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF231A14),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isHi
                                          ? 'छात्र द्वारा फीस कटवाने पर बिल से कितने रुपये माइनस होंगे'
                                          : 'Amount deducted from bill if student opts for rebate',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF7A7971),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 130,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD6CEC5),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '₹ ',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF231A14),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _customRateCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onChanged: (_) => setState(() {}),
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF231A14),
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isHi ? '/ प्रति स्पेशल मील' : '/ special meal',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF4A684C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card 2: Validity Extension in Meals (Right below rate as requested!)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0x142D231C),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.update_rounded,
                                    size: 18,
                                    color: Color(0xFFE9963F),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHi
                                          ? 'अगर कोई न आए तो कितनी मील आगे बढ़ेगी'
                                          : 'Meals Extended If Skipped',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF231A14),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isHi
                                          ? 'वैधता बढ़ाते समय इसे कितनी सामान्य मील माना जाएगा'
                                          : 'Counts as how many regular meals towards validity extension',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF7A7971),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              // Quick preset chips
                              ...[1, 2, 3].map((count) {
                                final isSelected =
                                    _extendMealsCtrl.text.trim() ==
                                        count.toString();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(() =>
                                        _extendMealsCtrl.text =
                                            count.toString()),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2B2019)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2B2019)
                                              : const Color(0xFFD6CEC5),
                                        ),
                                      ),
                                      child: Text(
                                        '$count ${isHi ? "मील" : "meal${count > 1 ? "s" : ""}"}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF231A14),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              // Direct custom input
                              Container(
                                width: 56,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD6CEC5),
                                  ),
                                ),
                                child: TextField(
                                  controller: _extendMealsCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF231A14),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isHi
                                ? '💡 छात्र को या तो तय किए गए रुपये रिफंड होंगे या तय की गई मील आगे बढ़ेगी (दोनों में से कोई एक)।'
                                : '💡 Student will either receive the cash refund or the meal extension (either one).',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF8C8881),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Live flexibility note (Screenshot 3)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2EBE0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: Color(0xFF3F653E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: const Color(0xFF2B3B2C),
                                ),
                                children: [
                                  TextSpan(
                                    text: isHi
                                        ? 'लाइव सुविधा: '
                                        : 'Live flexibility. ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: isHi
                                        ? 'रविवार को डिनर के बजाय लंच में स्पेशल बनाया? मेनू डालते समय एक टैप में स्लॉट बदलें।'
                                        : 'Cooked special at lunch on a Sunday instead of dinner? Switch the slot in one tap while posting the menu.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // WHAT STUDENTS WILL SEE (Preview Card in Screenshot 3)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2019),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHi
                                ? 'छात्रों को क्या दिखेगा (PREVIEW)'
                                : 'WHAT STUDENTS WILL SEE',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFFB0A59A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$primaryDay · ${_formatSlotName(_specialSlot)}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: Color(0xFFF4B34C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isHi ? 'स्पेशल' : 'Special',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF4B34C),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHi
                                ? 'खाने से 1 घंटे पहले तक स्किप कर सकते हैं'
                                : 'Skip cut-off 1 hour before the meal',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF9E958C),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 1,
                            color: const Color(0x33FFFFFF),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                isHi ? 'स्पेशल रिफंड' : 'Skip refund',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFFD4C7BA),
                                ),
                              ),
                              Text(
                                refundDisplay,
                                style: GoogleFonts.newsreader(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Save feast policy Button (Bright Orange Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePolicy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF58410),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isHi
                                  ? 'दावत नीति सेव करें'
                                  : 'Save feast policy',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
    );
  }
}
