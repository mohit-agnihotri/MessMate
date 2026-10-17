import '../../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';

/// Owner Plan Builder Page:
/// Allows mess owners to view, create, edit, toggle, and delete meal plans
/// with strict disjoint slot validation and live meal preview.
class OwnerPlanBuilderPage extends ConsumerStatefulWidget {
  const OwnerPlanBuilderPage({super.key});

  @override
  ConsumerState<OwnerPlanBuilderPage> createState() => _OwnerPlanBuilderPageState();
}

class _OwnerPlanBuilderPageState extends ConsumerState<OwnerPlanBuilderPage> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(ownerSettingsProvider);
    final mess = settingsState.mess;

    if (mess == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('Meal Plans', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    final appService = ref.watch(appServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Meal Plans Builder',
          style: GoogleFonts.inter(
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text('Create Plan', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        onPressed: () => _openPlanEditor(context, mess),
      ),
      body: StreamBuilder<List<MealPlanModel>>(
        stream: appService.streamMealPlans(mess.messId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Custom Plans Yet',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students currently follow default mess settings (₹${mess.monthlyFee.toInt()}/mo, ${mess.mealsIncludedPerDay} meals/day).\n\nTap "+ Create Plan" below to offer flexible 1-meal, 2-meal, or choice options.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final plan = plans[i];
              return _buildPlanCard(context, mess, plan);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, MessModel mess, MealPlanModel plan) {
    final appService = ref.read(appServiceProvider);
    final hasChoice = plan.choiceGroups.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: plan.isActive
              ? (hasChoice ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0))
              : const Color(0xFFE2E8F0),
          width: plan.isActive ? 1.5 : 1,
        ),
        boxShadow: plan.isActive
            ? const [
                BoxShadow(
                  color: Color(0x0C0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x040F172A),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (hasChoice)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ref.watch(localizationProvider) == 'hi' ? '🎯 पसंद का खाना' : '🎯 Meal Choice (Flexi)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ref.watch(localizationProvider) == 'hi' ? '${plan.mealsIncludedPerDay} टाइम खाना' : '${plan.mealsIncludedPerDay} meals/day',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.name,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: plan.isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref.watch(localizationProvider) == 'hi' ? '₹${plan.monthlyFee.toInt()} / महीना  •  ${plan.mealsIncludedPerDay} भोजन प्रतिदिन' : '₹${plan.monthlyFee.toInt()} / month  •  ${plan.mealsIncludedPerDay} meals/day',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: plan.isActive,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) {
                  appService.toggleMealPlanActive(mess.messId, plan.planId, val);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Meal Structure Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.fixedMeals.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(localizationProvider) == 'hi' ? 'पक्का खाना: ' : 'Fixed Meal: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          plan.fixedMeals.map((m) => _slotDisplayName(m, ref.watch(localizationProvider) == 'hi')).join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (hasChoice) ...[
                  if (plan.fixedMeals.isNotEmpty) const SizedBox(height: 8),
                  ...plan.choiceGroups.map((g) {
                    final isHi = ref.watch(localizationProvider) == 'hi';
                    final choices = g.availableMeals.map((m) => _slotDisplayName(m, isHi)).join(isHi ? ' या ' : ' or ');
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.watch(localizationProvider) == 'hi' ? 'पसंद का विकल्प: ' : 'Choice Option: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ref.watch(localizationProvider) == 'hi' ? '$choices (छात्र 1 चुनेगा)' : '$choices (Student picks 1)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Deduction Policy Pill & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.deductionPolicy.policyType == 'none'
                      ? (ref.watch(localizationProvider) == 'hi' ? 'छुट्टी पर कोई कटौती नहीं' : 'No skip rebate')
                      : plan.deductionPolicy.policyType == 'flat_fixed_rate'
                          ? (ref.watch(localizationProvider) == 'hi' ? 'छुट्टी वापसी: ₹${plan.deductionPolicy.flatRate?.toInt() ?? 0} / मील' : 'Skip refund: ₹${plan.deductionPolicy.flatRate?.toInt() ?? 0} / meal')
                          : 'Dynamic Prorated Rebate',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF475569)),
                    onPressed: () => _openPlanEditor(context, mess, existingPlan: plan),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                    onPressed: () => _confirmDelete(context, mess, plan),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MessModel mess, MealPlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Plan', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'Are you sure you want to delete "${plan.name}"?\n\nExisting enrolled members will continue on their snapshot until assigned a new plan.',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(appServiceProvider).deleteMealPlan(mess.messId, plan.planId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openPlanEditor(BuildContext context, MessModel mess, {MealPlanModel? existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlanEditorModal(mess: mess, existingPlan: existingPlan),
    );
  }

  String _slotDisplayName(String slot, [bool isHi = false]) {
    if (isHi) {
      switch (slot) {
        case 'morning':
          return 'नाश्ता';
        case 'noon':
          return 'दोपहर खाना';
        case 'evening':
          return 'शाम नाश्ता';
        case 'night':
          return 'रात खाना';
        default:
          return slot;
      }
    }
    switch (slot) {
      case 'morning':
        return 'Breakfast';
      case 'noon':
        return 'Lunch';
      case 'evening':
        return 'Evening Snacks';
      case 'night':
        return 'Dinner';
      default:
        return slot;
    }
  }
}

/// Modal Editor for Creating / Editing a Meal Plan with Disjoint Invariant Guard
class _PlanEditorModal extends ConsumerStatefulWidget {
  final MessModel mess;
  final MealPlanModel? existingPlan;

  const _PlanEditorModal({required this.mess, this.existingPlan});

  @override
  ConsumerState<_PlanEditorModal> createState() => _PlanEditorModalState();
}

class _PlanEditorModalState extends ConsumerState<_PlanEditorModal> {
  final _nameCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _extraRateCtrl = TextEditingController();
  final _flatRateCtrl = TextEditingController();

  List<String> _enabledSlots = [];
  Set<String> _fixedMeals = {};
  List<_EditableChoiceGroup> _choiceGroups = [];
  String _policyType = 'dynamic_prorated'; // 'dynamic_prorated', 'none', 'flat_fixed_rate'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Filter mess meal timings where enabled == 'true'
    _enabledSlots = widget.mess.mealTimings.entries
        .where((e) => e.value['enabled'] == 'true')
        .map((e) => e.key)
        .toList();
    if (_enabledSlots.isEmpty) {
      _enabledSlots = ['morning', 'noon', 'night'];
    }

    if (widget.existingPlan != null) {
      final p = widget.existingPlan!;
      _nameCtrl.text = p.name;
      _feeCtrl.text = p.monthlyFee.toStringAsFixed(0);
      if (p.extraMealRate != null) {
        _extraRateCtrl.text = p.extraMealRate!.toStringAsFixed(0);
      }
      _fixedMeals = p.fixedMeals.toSet();
      _choiceGroups = p.choiceGroups.map((g) {
        return _EditableChoiceGroup(
          groupId: g.groupId,
          name: g.name,
          availableMeals: g.availableMeals.toSet(),
          minSelectable: g.minSelectable,
          maxSelectable: g.maxSelectable,
        );
      }).toList();
      _policyType = p.deductionPolicy.policyType;
      if (p.deductionPolicy.flatRate != null) {
        _flatRateCtrl.text = p.deductionPolicy.flatRate!.toStringAsFixed(0);
      }
    } else {
      _feeCtrl.text = widget.mess.monthlyFee.toStringAsFixed(0);
      // Default: fixed meals is night, choice group is morning vs noon
      if (_enabledSlots.contains('night')) {
        _fixedMeals.add('night');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _feeCtrl.dispose();
    _extraRateCtrl.dispose();
    _flatRateCtrl.dispose();
    super.dispose();
  }

  // Set of all slots currently assigned to Choice Groups (excluding a given group index)
  Set<String> _getAssignedChoiceSlots({int? excludeGroupIndex}) {
    Set<String> set = {};
    for (int i = 0; i < _choiceGroups.length; i++) {
      if (excludeGroupIndex != null && i == excludeGroupIndex) continue;
      set.addAll(_choiceGroups[i].availableMeals);
    }
    return set;
  }

  int get _computedDailyMeals {
    int sum = _fixedMeals.length;
    for (var g in _choiceGroups) {
      sum += g.maxSelectable;
    }
    return sum;
  }

  Future<void> _savePlan() async {
    final name = _nameCtrl.text.trim();
    final fee = double.tryParse(_feeCtrl.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    if (fee == null || fee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly fee')),
      );
      return;
    }

    if (_fixedMeals.isEmpty && _choiceGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure at least one fixed meal or choice group')),
      );
      return;
    }

    // Disjoint invariant validation:
    final seen = <String>{};
    for (var slot in _fixedMeals) {
      if (!seen.add(slot)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Slot $slot appears multiple times')),
        );
        return;
      }
    }
    for (var g in _choiceGroups) {
      if (g.availableMeals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Choice group "${g.name}" has no meals selected')),
        );
        return;
      }
      for (var slot in g.availableMeals) {
        if (!seen.add(slot)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conflict: Slot "$slot" cannot appear in multiple groups or fixed meals')),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final planId = widget.existingPlan?.planId ??
          'plan_${DateTime.now().millisecondsSinceEpoch}';

      final List<ChoiceGroupModel> groups = _choiceGroups.map((g) {
        return ChoiceGroupModel(
          groupId: g.groupId.isNotEmpty
              ? g.groupId
              : 'grp_${DateTime.now().millisecondsSinceEpoch}_${g.name.hashCode}',
          name: g.name.trim().isNotEmpty ? g.name.trim() : 'Meal Choice',
          availableMeals: g.availableMeals.toList(),
          minSelectable: g.minSelectable,
          maxSelectable: g.maxSelectable,
        );
      }).toList();

      final policy = DeductionPolicyModel(
        policyType: _policyType,
        flatRate: _policyType == 'flat_fixed_rate'
            ? double.tryParse(_flatRateCtrl.text.trim()) ?? widget.mess.perMealRate
            : null,
      );

      final plan = MealPlanModel(
        planId: planId,
        messId: widget.mess.messId,
        name: name,
        monthlyFee: fee,
        fixedMeals: _fixedMeals.toList(),
        choiceGroups: groups,
        deductionPolicy: policy,
        extraMealRate: double.tryParse(_extraRateCtrl.text.trim()),
        isActive: widget.existingPlan?.isActive ?? true,
      );

      await ref.read(appServiceProvider).saveMealPlan(plan);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meal Plan "$name" saved successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existingPlan != null ? 'Edit Meal Plan' : 'Create Meal Plan',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Name
                  _buildInputLabel('Plan Name'),
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.inter(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. 2-Meal Flexible Plan',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monthly Fee & Extra Meal Rate
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Monthly Fee (₹)'),
                            TextField(
                              controller: _feeCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 15),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '2700',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Extra Meal (₹) [Opt]'),
                            TextField(
                              controller: _extraRateCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: widget.mess.perMealRate.toInt().toString(),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Fixed Meals (Disjoint Guard: disabled if used in any choice group)
                  _buildInputLabel('Fixed Meals (Always Included)'),
                  Text(
                    'Slots guaranteed every day for diners on this plan.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _enabledSlots.map((slot) {
                      final isSelected = _fixedMeals.contains(slot);
                      final isUsedInChoice = _getAssignedChoiceSlots().contains(slot);
                      return FilterChip(
                        label: Text(_slotTitle(slot)),
                        selected: isSelected,
                        onSelected: isUsedInChoice
                            ? null // Disabled because slot is in a choice group
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _fixedMeals.add(slot);
                                  } else {
                                    _fixedMeals.remove(slot);
                                  }
                                });
                              },
                        selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF10B981),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isUsedInChoice
                              ? const Color(0xFFCBD5E1)
                              : isSelected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF334155),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Choice Groups Builder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Choice Groups (Alternatives)'),
                          Text(
                            'e.g. Choose between Morning or Noon',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Group'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                        onPressed: () {
                          setState(() {
                            _choiceGroups.add(_EditableChoiceGroup(
                              groupId: '',
                              name: 'Meal Choice ${_choiceGroups.length + 1}',
                              availableMeals: {},
                              minSelectable: 1,
                              maxSelectable: 1,
                            ));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...List.generate(_choiceGroups.length, (idx) {
                    final group = _choiceGroups[idx];
                    return _buildChoiceGroupCard(idx, group);
                  }),

                  const SizedBox(height: 24),

                  // Deduction Policy
                  _buildInputLabel('Deduction Policy (For Skips)'),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('Dynamic Prorated (Recommended)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Rebate based on actual monthly fee / total meals', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          value: 'dynamic_prorated',
                          groupValue: _policyType,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _policyType = val!),
                        ),
                        RadioListTile<String>(
                          title: Text('Flat Rate Rebate', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Fixed ₹ amount per skipped meal', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          value: 'flat_fixed_rate',
                          groupValue: _policyType,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _policyType = val!),
                        ),
                        if (_policyType == 'flat_fixed_rate')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: TextField(
                              controller: _flatRateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Rebate Amount per Skip (₹)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        RadioListTile<String>(
                          title: Text('No Skip Refunds', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Fixed rate plan without skip deductions', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          value: 'none',
                          groupValue: _policyType,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _policyType = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Live Preview Card
                  _buildLivePreviewCard(),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving ? null : _savePlan,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : Text('Save Meal Plan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceGroupCard(int groupIndex, _EditableChoiceGroup group) {
    // Other assigned slots in fixed meals or other choice groups
    final otherAssignedSlots = {..._fixedMeals, ..._getAssignedChoiceSlots(excludeGroupIndex: groupIndex)};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: group.name,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    hintText: 'Group Name (e.g. Lunch vs Dinner)',
                  ),
                  onChanged: (val) => group.name = val,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                onPressed: () {
                  setState(() => _choiceGroups.removeAt(groupIndex));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select Alternative Slots:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _enabledSlots.map((slot) {
              final isSelected = group.availableMeals.contains(slot);
              final isAssignedElsewhere = otherAssignedSlots.contains(slot);

              return FilterChip(
                label: Text(_slotTitle(slot)),
                selected: isSelected,
                onSelected: isAssignedElsewhere
                    ? null
                    : (selected) {
                        setState(() {
                          if (selected) {
                            group.availableMeals.add(slot);
                          } else {
                            group.availableMeals.remove(slot);
                          }
                          // Clamp maxSelectable
                          if (group.maxSelectable > group.availableMeals.length && group.availableMeals.isNotEmpty) {
                            group.maxSelectable = group.availableMeals.length;
                          }
                        });
                      },
                selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF3B82F6),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAssignedElsewhere
                      ? const Color(0xFFCBD5E1)
                      : isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF334155),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Limit Selector
          Row(
            children: [
              Text('Diner picks at most: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: group.maxSelectable,
                isDense: true,
                items: List.generate(
                  group.availableMeals.isEmpty ? 1 : group.availableMeals.length,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} meal${i > 0 ? "s" : ""}')),
                ),
                onChanged: (val) {
                  if (val != null) setState(() => group.maxSelectable = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final daily = _computedDailyMeals;
    final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;
    final monthlyMeals = daily * 30;
    final perMeal = monthlyMeals > 0 ? (fee / monthlyMeals).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                'Plan Live Preview',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Included Meals/Day:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
              Text('$daily meals', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Estimated Meals (30d):', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
              Text('$monthlyMeals meals', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Effective Per-Meal Cost:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
              Text('₹$perMeal / meal', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  String _slotTitle(String slot) {
    switch (slot) {
      case 'morning':
        return 'Morning';
      case 'noon':
        return 'Noon';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      default:
        return slot;
    }
  }
}

class _EditableChoiceGroup {
  String groupId;
  String name;
  Set<String> availableMeals;
  int minSelectable;
  int maxSelectable;

  _EditableChoiceGroup({
    required this.groupId,
    required this.name,
    required this.availableMeals,
    required this.minSelectable,
    required this.maxSelectable,
  });
}
