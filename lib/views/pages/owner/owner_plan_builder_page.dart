import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/owner_inspired_theme.dart';

/// Owner Plan Builder Page:
/// Allows mess owners to view, create, edit, toggle, and delete meal plans
/// with strict disjoint slot validation and live meal preview.
/// Redesigned to match the inspired editorial walnut & sage theme.
class OwnerPlanBuilderPage extends ConsumerStatefulWidget {
  const OwnerPlanBuilderPage({super.key});

  @override
  ConsumerState<OwnerPlanBuilderPage> createState() =>
      _OwnerPlanBuilderPageState();
}

class _OwnerPlanBuilderPageState extends ConsumerState<OwnerPlanBuilderPage> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(ownerSettingsProvider);
    final mess = settingsState.mess;

    if (mess == null) {
      return Scaffold(
        backgroundColor: OwnerColors.canvas,
        appBar: AppBar(
          backgroundColor: OwnerColors.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: OwnerColors.walnutDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Meal plans',
            style: OwnerTypography.editorialSerif(
              size: 24,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: OwnerColors.sageGreen),
        ),
      );
    }

    final appService = ref.watch(appServiceProvider);

    return Scaffold(
      backgroundColor: OwnerColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: OwnerColors.sageLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Meal plans',
                    style: OwnerTypography.editorialSerif(
                      size: 28,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                ],
              ),
            ),

            // Plan List or Empty State
            Expanded(
              child: StreamBuilder<List<MealPlanModel>>(
                stream: appService.streamMealPlans(mess.messId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: OwnerColors.sageGreen,
                      ),
                    );
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
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                color: OwnerColors.sageLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: OwnerColors.sageGreen,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No Custom Plans Yet',
                              style: OwnerTypography.editorialSerif(
                                size: 22,
                                weight: FontWeight.w700,
                                color: OwnerColors.walnutDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Students follow your default mess settings (₹${mess.monthlyFee.toInt()}/mo, ${mess.mealsIncludedPerDay} meals/day).\n\nTap "+ Create plan" below to offer flexible 1-meal, 2-meal, or choice options.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: OwnerColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: plans.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final plan = plans[i];
                      return _buildPlanCard(context, mess, plan, i);
                    },
                  );
                },
              ),
            ),

            // Bottom "+ Create plan" button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              color: OwnerColors.canvas,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwnerColors.amberGlow,
                    foregroundColor: OwnerColors.walnutDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () => _openPlanEditor(context, mess),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 20,
                        color: OwnerColors.walnutDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Create plan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    MessModel mess,
    MealPlanModel plan,
    int index,
  ) {
    final appService = ref.read(appServiceProvider);
    final hasChoice = plan.choiceGroups.isNotEmpty;

    // Alternating colored accent borders matching inspired screenshot:
    final accentColors = [
      OwnerColors.sageGreen,
      OwnerColors.amberGlow,
      OwnerColors.walnutDark,
    ];
    final accentColor = accentColors[index % accentColors.length];

    // Summary line for fixed & choices
    final List<String> detailsParts = [];
    if (plan.fixedMeals.isNotEmpty) {
      final fixedStr = plan.fixedMeals
          .map((m) => _slotDisplayName(m))
          .join(', ');
      detailsParts.add('Fixed: $fixedStr');
    }
    if (hasChoice) {
      for (var g in plan.choiceGroups) {
        final choiceStr = g.availableMeals
            .map((m) => _slotDisplayName(m))
            .join(' or ');
        detailsParts.add('Choice: $choiceStr (student picks ${g.maxSelectable})');
      }
    }
    final summaryText = detailsParts.join(' · ');

    final refundAmount = plan.deductionPolicy.flatRate?.toInt() ??
        mess.perMealRate.toInt();

    return GestureDetector(
      onTap: () => _openPlanEditor(context, mess, existingPlan: plan),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: OwnerColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Overline + Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hasChoice
                            ? 'CHOICE · ${plan.mealsIncludedPerDay} MEALS/DAY'
                            : '${plan.mealsIncludedPerDay} MEALS/DAY',
                        style: OwnerTypography.overline(
                          size: 11,
                          spacing: 1.2,
                          color: OwnerColors.sageGreen,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch.adaptive(
                          value: plan.isActive,
                          activeTrackColor: OwnerColors.sageGreen,
                          activeThumbColor: Colors.white,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: OwnerColors.borderSubtle,
                          onChanged: (val) {
                            appService.toggleMealPlanActive(
                              mess.messId,
                              plan.planId,
                              val,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Plan Title
                  Text(
                    plan.name,
                    style: OwnerTypography.editorialSerif(
                      size: 21,
                      weight: FontWeight.w700,
                      color: plan.isActive
                          ? OwnerColors.walnutDark
                          : OwnerColors.walnutMuted,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price Row + Skip rebate pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${plan.monthlyFee.toInt()}',
                            style: OwnerTypography.editorialSerif(
                              size: 26,
                              weight: FontWeight.w700,
                              color: OwnerColors.walnutDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ month',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: OwnerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6EEDF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          plan.deductionPolicy.policyType == 'none'
                              ? 'No skip refund'
                              : 'Skip refund ₹$refundAmount',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.walnutDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (summaryText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      summaryText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OwnerColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Quick Actions: Edit & Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _openPlanEditor(context, mess, existingPlan: plan),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: OwnerColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: OwnerColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, mess, plan),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MessModel mess,
    MealPlanModel plan,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwnerColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Delete Plan',
          style: OwnerTypography.editorialSerif(
            size: 20,
            weight: FontWeight.w700,
            color: OwnerColors.walnutDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${plan.name}"?\n\nExisting enrolled members will continue on their snapshot until assigned a new plan.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: OwnerColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: OwnerColors.walnutDark,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(appServiceProvider)
                  .deleteMealPlan(mess.messId, plan.planId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openPlanEditor(
    BuildContext context,
    MessModel mess, {
    MealPlanModel? existingPlan,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlanEditorModal(
        mess: mess,
        existingPlan: existingPlan,
      ),
    );
  }

  String _slotDisplayName(String slot) {
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

/// Modal Editor for Creating / Editing a Meal Plan with Disjoint Invariant Guard
/// Designed to match WhatsApp Image 2026-10-20 at 16.27.29.jpeg
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
  String _policyType =
      'dynamic_prorated'; // 'dynamic_prorated', 'none', 'flat_fixed_rate'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
      _extraRateCtrl.text = widget.mess.perMealRate.toStringAsFixed(0);
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
        const SnackBar(
          content: Text('Please configure at least one fixed meal or choice group'),
        ),
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
          SnackBar(
            content: Text('Choice group "${g.name}" has no meals selected'),
          ),
        );
        return;
      }
      for (var slot in g.availableMeals) {
        if (!seen.add(slot)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conflict: Slot "$slot" cannot appear in multiple groups or fixed meals',
              ),
            ),
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
          SnackBar(
            content: Text('Meal Plan "$name" saved successfully!'),
            backgroundColor: OwnerColors.walnutDark,
          ),
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
    final daily = _computedDailyMeals;
    final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;
    final monthlyMeals = daily * 30;
    final perMeal =
        monthlyMeals > 0 ? (fee / monthlyMeals).toStringAsFixed(0) : '0';

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: OwnerColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar with Circular Back Button and Serif Title
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: OwnerColors.sageLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.existingPlan != null
                        ? 'Edit meal plan'
                        : 'Create meal plan',
                    style: OwnerTypography.editorialSerif(
                      size: 26,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  6,
                  18,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PLAN NAME
                    Text(
                      'PLAN NAME',
                      style: OwnerTypography.overline(
                        size: 11,
                        spacing: 1.2,
                        color: OwnerColors.sageGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: OwnerColors.walnutDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 2-Meal Flexible Plan',
                        hintStyle: GoogleFonts.inter(
                          color: OwnerColors.textMuted,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: OwnerColors.borderSubtle,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: OwnerColors.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: OwnerColors.amberGlow,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MONTHLY FEE & EXTRA MEAL
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MONTHLY FEE (₹)',
                                style: OwnerTypography.overline(
                                  size: 11,
                                  spacing: 1.2,
                                  color: OwnerColors.sageGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _feeCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: OwnerColors.walnutDark,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '3000',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: OwnerColors.borderSubtle,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: OwnerColors.borderSubtle,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: OwnerColors.amberGlow,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXTRA MEAL (₹)',
                                style: OwnerTypography.overline(
                                  size: 11,
                                  spacing: 1.2,
                                  color: OwnerColors.sageGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _extraRateCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: OwnerColors.walnutDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: '45',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: OwnerColors.borderSubtle,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: OwnerColors.borderSubtle,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: OwnerColors.amberGlow,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // FIXED MEALS · ALWAYS INCLUDED
                    Text(
                      'FIXED MEALS · ALWAYS INCLUDED',
                      style: OwnerTypography.overline(
                        size: 11,
                        spacing: 1.2,
                        color: OwnerColors.sageGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _enabledSlots.map((slot) {
                        final isSelected = _fixedMeals.contains(slot);
                        final isUsedInChoice =
                            _getAssignedChoiceSlots().contains(slot);

                        return GestureDetector(
                          onTap: isUsedInChoice
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _fixedMeals.remove(slot);
                                    } else {
                                      _fixedMeals.add(slot);
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isUsedInChoice
                                  ? const Color(0xFFE5E0D5).withValues(alpha: 0.5)
                                  : isSelected
                                      ? OwnerColors.walnutDark
                                      : OwnerColors.sageLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: OwnerColors.amberGlow,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _slotTitle(slot),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isUsedInChoice
                                        ? OwnerColors.walnutMuted
                                        : isSelected
                                            ? Colors.white
                                            : OwnerColors.walnutDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // CHOICE GROUPS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'CHOICE GROUPS',
                          style: OwnerTypography.overline(
                            size: 11,
                            spacing: 1.2,
                            color: OwnerColors.sageGreen,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _choiceGroups.add(
                                _EditableChoiceGroup(
                                  groupId: '',
                                  name:
                                      'Meal Choice ${_choiceGroups.length + 1}',
                                  availableMeals: {},
                                  minSelectable: 1,
                                  maxSelectable: 1,
                                ),
                              );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9E7CE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: OwnerColors.walnutDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add group',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: OwnerColors.walnutDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'e.g. choose between Morning or Noon',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OwnerColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Choice Groups Cards
                    ...List.generate(_choiceGroups.length, (idx) {
                      final group = _choiceGroups[idx];
                      return _buildChoiceGroupCard(idx, group);
                    }),

                    const SizedBox(height: 16),

                    // SKIP DEDUCTION
                    Text(
                      'SKIP DEDUCTION',
                      style: OwnerTypography.overline(
                        size: 11,
                        spacing: 1.2,
                        color: OwnerColors.sageGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: OwnerColors.borderSubtle,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildRadioChoice(
                            title: 'Dynamic prorated · recommended',
                            subtitle: 'Monthly fee ÷ total meals',
                            value: 'dynamic_prorated',
                          ),
                          const Divider(
                            height: 1,
                            indent: 52,
                            color: OwnerColors.borderSubtle,
                          ),
                          _buildRadioChoice(
                            title: 'Flat rate rebate',
                            subtitle: 'Fixed ₹ per skipped meal',
                            value: 'flat_fixed_rate',
                          ),
                          if (_policyType == 'flat_fixed_rate')
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(52, 0, 16, 12),
                              child: TextField(
                                controller: _flatRateCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Rebate amount (₹)',
                                  filled: true,
                                  fillColor: OwnerColors.canvas,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          const Divider(
                            height: 1,
                            indent: 52,
                            color: OwnerColors.borderSubtle,
                          ),
                          _buildRadioChoice(
                            title: 'No skip refunds',
                            subtitle: 'Fixed-rate plan',
                            value: 'none',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // LIVE PREVIEW HERO CARD (walnut card with amber display)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: OwnerColors.walnutDark,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE PREVIEW',
                            style: OwnerTypography.overline(
                              size: 11,
                              spacing: 1.5,
                              color: OwnerColors.amberGlow,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Meals per day',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD5CDC3),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '$daily',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Estimated meals · 30d',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD5CDC3),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '$monthlyMeals',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Per-meal cost',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD5CDC3),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '₹$perMeal',
                                style: OwnerTypography.editorialSerif(
                                  size: 28,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save meal plan button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OwnerColors.amberGlow,
                          foregroundColor: OwnerColors.walnutDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isSaving ? null : _savePlan,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: OwnerColors.walnutDark,
                                strokeWidth: 2.5,
                              )
                            : Text(
                                'Save meal plan',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: OwnerColors.walnutDark,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioChoice({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _policyType == value;
    return InkWell(
      onTap: () => setState(() => _policyType = value),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? OwnerColors.sageGreen
                      : OwnerColors.walnutMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: OwnerColors.sageGreen,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: OwnerColors.textSecondary,
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

  Widget _buildChoiceGroupCard(int groupIndex, _EditableChoiceGroup group) {
    final otherAssignedSlots = {
      ..._fixedMeals,
      ..._getAssignedChoiceSlots(excludeGroupIndex: groupIndex),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: group.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
                  ),
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
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
                onPressed: () {
                  setState(() => _choiceGroups.removeAt(groupIndex));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select Alternative Slots:',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: OwnerColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _enabledSlots.map((slot) {
              final isSelected = group.availableMeals.contains(slot);
              final isAssignedElsewhere = otherAssignedSlots.contains(slot);

              return GestureDetector(
                onTap: isAssignedElsewhere
                    ? null
                    : () {
                        setState(() {
                          if (isSelected) {
                            group.availableMeals.remove(slot);
                          } else {
                            group.availableMeals.add(slot);
                          }
                          if (group.maxSelectable >
                                  group.availableMeals.length &&
                              group.availableMeals.isNotEmpty) {
                            group.maxSelectable = group.availableMeals.length;
                          }
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAssignedElsewhere
                        ? const Color(0xFFE5E0D5).withValues(alpha: 0.5)
                        : isSelected
                            ? OwnerColors.walnutDark
                            : OwnerColors.sageLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check,
                          size: 12,
                          color: OwnerColors.amberGlow,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _slotTitle(slot),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAssignedElsewhere
                              ? OwnerColors.walnutMuted
                              : isSelected
                                  ? Colors.white
                                  : OwnerColors.walnutDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Diner picks at most: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: OwnerColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: group.maxSelectable,
                isDense: true,
                dropdownColor: Colors.white,
                items: List.generate(
                  group.availableMeals.isEmpty ? 1 : group.availableMeals.length,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      '${i + 1} meal${i > 0 ? "s" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                  ),
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
