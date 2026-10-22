import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../auth/login_page.dart';
import '../common/user_feedback_sheet.dart';
import 'owner_about_mess_page.dart';
import 'owner_plan_builder_page.dart';
import 'theme/owner_inspired_theme.dart';
import 'widgets/owner_drawer.dart';
import 'widgets/owner_launch_partner_sheet.dart';

class OwnerSettingsPage extends ConsumerWidget {
  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerSettingsProvider);
    final MessModel? mess = state.mess;
    final isHi = ref.watch(localizationProvider) == 'hi';
    final messName = mess?.name ?? 'Mahakal';

    return Scaffold(
      backgroundColor: OwnerColors.canvasWarm,
      endDrawer: const OwnerDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, messName, isHi),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: OwnerColors.sageGreen,
                      ),
                    )
                  : RefreshIndicator(
                      color: OwnerColors.sageGreen,
                      backgroundColor: OwnerColors.surfaceLight,
                      onRefresh: () async {
                        ref.invalidate(ownerSettingsProvider);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          _buildMessInfoCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildMealPlansCard(context, ref, mess, isHi),
                          const SizedBox(height: 18),
                          _buildMessTimingsCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildToggleCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildSkipPolicyCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildSpecialMealCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildMessPhotosCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildAboutMessCard(context, ref, mess),
                          const SizedBox(height: 18),
                          _buildActionsCard(context, ref, mess, isHi),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header (Screenshot 6) ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String messName, bool isHi) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: const BoxDecoration(
        color: OwnerColors.canvasWarm,
        border: Border(
          bottom: BorderSide(color: OwnerColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'MESS PROFILE',
                style: OwnerTypography.overline(color: OwnerColors.walnutMuted),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OwnerColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OwnerColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$messName · Settings',
                        style: OwnerTypography.regular(
                          size: 12,
                          color: OwnerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: OwnerColors.walnutMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: OwnerColors.walnutDark,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isHi ? 'सेटिंग्स' : 'Settings',
                style: OwnerTypography.editorialSerif(
                  size: 28,
                  weight: FontWeight.w700,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mess Info Hero Card (Screenshot 6) ───────────────────────────────────
  Widget _buildMessInfoCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (mess?.ownerPhotoUrl != null &&
                  mess!.ownerPhotoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    mess.ownerPhotoUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildDefaultMessAvatar(mess),
                  ),
                )
              else
                _buildDefaultMessAvatar(mess),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mess?.name ?? 'Loading...',
                      style: OwnerTypography.editorialSerif(
                        size: 18,
                        weight: FontWeight.w700,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mess?.ownerName ?? 'Owner',
                      style: OwnerTypography.regular(
                        size: 13,
                        color: OwnerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showEditDialog(context, ref, mess),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: OwnerColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OwnerColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: OwnerColors.walnutDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: OwnerTypography.bold(
                          size: 11,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: OwnerColors.borderSubtle),
          _buildInfoRow(
            'Food Type',
            mess?.foodType == 'non_veg'
                ? '🍗 Non-Veg'
                : mess?.foodType == 'both'
                    ? '🍃 Both (Veg & Non-Veg)'
                    : '🌱 Pure Veg',
          ),
          _buildInfoRow('Monthly Fee', '₹${mess?.monthlyFee.toInt() ?? 0}'),
          _buildInfoRow(
            'Plan Includes',
            '${mess?.mealsIncludedPerDay ?? 3} meals daily',
          ),
          _buildInfoRow(
            'Per Meal Rate',
            '₹${mess?.perMealRate.toInt() ?? 0}',
          ),
          _buildInfoRow('Capacity', '${mess?.capacity ?? 0} students'),
          _buildInfoRow('Mess Join Code', mess?.messCode ?? 'N/A'),
          _buildInfoRow(
            'Cutoff Hours',
            '${mess?.cutoffHours ?? 0} hours before meal',
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultMessAvatar(MessModel? mess) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: OwnerColors.amberGlow.withValues(alpha: 0.18),
      child: Text(
        (mess?.name.isNotEmpty == true) ? mess!.name[0].toUpperCase() : 'M',
        style: OwnerTypography.editorialSerif(
          size: 20,
          weight: FontWeight.w700,
          color: OwnerColors.walnutDark,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: OwnerTypography.regular(
              size: 13,
              color: OwnerColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: OwnerTypography.bold(
                size: 13,
                color: OwnerColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Meal Plans Card ───────────────────────────────────────────────────────
  Widget _buildMealPlansCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
    bool isHi,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: OwnerColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: OwnerColors.sageDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHi ? 'खाने के प्लान' : 'Meal Plans & Pricing',
                      style: OwnerTypography.bold(
                        size: 15,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHi
                          ? 'महीने की फीस और प्लान की दरें बदलें'
                          : 'Manage fees, custom plans & pricing tiers',
                      style: OwnerTypography.regular(
                        size: 12,
                        color: OwnerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerColors.sageGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: Text(
                isHi ? 'प्लान बिल्डर खोलें' : 'Open Plan Builder',
                style: OwnerTypography.bold(size: 13, color: Colors.white),
              ),
              onPressed: () {
                if (mess != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerPlanBuilderPage(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mess Timings Section (Screenshot 10) ──────────────────────────────────
  Widget _buildMessTimingsCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    if (mess == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Mess Timings',
            style: OwnerTypography.editorialSerif(
              size: 20,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: OwnerColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OwnerColors.borderSubtle),
            boxShadow: OwnerShadows.card,
          ),
          child: Column(
            children: [
              _buildTimingSlot(context, ref, mess, 'Morning', 'morning'),
              const Divider(height: 28, color: OwnerColors.borderSubtle),
              _buildTimingSlot(context, ref, mess, 'Noon', 'noon'),
              const Divider(height: 28, color: OwnerColors.borderSubtle),
              _buildTimingSlot(context, ref, mess, 'Evening', 'evening'),
              const Divider(height: 28, color: OwnerColors.borderSubtle),
              _buildTimingSlot(context, ref, mess, 'Night', 'night'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimingSlot(
    BuildContext context,
    WidgetRef ref,
    MessModel mess,
    String label,
    String slotKey,
  ) {
    final timings = mess.mealTimings[slotKey];
    final bool isEnabled = timings?['enabled'] == 'true';
    final String start = timings?['start'] ?? '00:00';
    final String end = timings?['end'] ?? '00:00';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: OwnerTypography.bold(
                size: 15,
                color: isEnabled
                    ? OwnerColors.textPrimary
                    : OwnerColors.walnutMuted,
              ),
            ),
            CupertinoSwitch(
              value: isEnabled,
              activeTrackColor: OwnerColors.sageGreen,
              onChanged: (val) {
                final newTimings = Map<String, Map<String, String>>.from(
                  mess.mealTimings,
                );
                newTimings[slotKey] = Map<String, String>.from(
                  newTimings[slotKey] ?? {},
                );
                newTimings[slotKey]!['enabled'] = val ? 'true' : 'false';
                ref
                    .read(ownerSettingsProvider.notifier)
                    .save(mess.copyWith(mealTimings: newTimings));
              },
            ),
          ],
        ),
        if (isEnabled) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _pickTime(context, ref, mess, slotKey, 'start', start),
                  child: _buildTimeDisplay('Start Time', start),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: OwnerColors.walnutMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _pickTime(context, ref, mess, slotKey, 'end', end),
                  child: _buildTimeDisplay('End Time', end),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeDisplay(String label, String time24) {
    final parts = time24.split(':');
    int h = int.tryParse(parts[0]) ?? 0;
    String m = parts.length > 1 ? parts[1] : '00';
    String period = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    String time12 = '${h12.toString().padLeft(2, '0')}:$m $period';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: OwnerTypography.regular(
              size: 11,
              color: OwnerColors.walnutMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: OwnerColors.sageGreen,
              ),
              const SizedBox(width: 5),
              Text(
                time12,
                style: OwnerTypography.bold(
                  size: 13,
                  color: OwnerColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    MessModel mess,
    String slotKey,
    String field,
    String currentTime,
  ) async {
    final parts = currentTime.split(':');
    TimeOfDay initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: OwnerColors.sageGreen,
              onPrimary: Colors.white,
              surface: OwnerColors.surfaceLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      final newTime =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
      final newTimings = Map<String, Map<String, String>>.from(
        mess.mealTimings,
      );
      newTimings[slotKey] =
          Map<String, String>.from(newTimings[slotKey] ?? {});
      newTimings[slotKey]![field] = newTime;
      ref
          .read(ownerSettingsProvider.notifier)
          .save(mess.copyWith(mealTimings: newTimings));
    }
  }

  // ─── Visibility & Notifications Toggles ───────────────────────────────────
  Widget _buildToggleCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibility & Discovery',
            style: OwnerTypography.editorialSerif(
              size: 16,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
          const SizedBox(height: 10),
          _buildToggle('Listed on Discovery Map', mess?.isListedOnMap ?? true, (
            val,
          ) {
            if (mess != null) {
              ref
                  .read(ownerSettingsProvider.notifier)
                  .save(mess.copyWith(isListedOnMap: val));
            }
          }),
          _buildToggle(
            'Show Menu to Outsiders',
            mess?.showMenuToOutsiders ?? true,
            (val) {
              if (mess != null) {
                ref
                    .read(ownerSettingsProvider.notifier)
                    .save(mess.copyWith(showMenuToOutsiders: val));
              }
            },
          ),
          _buildToggle(
            'Show Menu to Students',
            mess?.showMenuToStudents ?? true,
            (val) {
              if (mess != null) {
                ref
                    .read(ownerSettingsProvider.notifier)
                    .save(mess.copyWith(showMenuToStudents: val));
              }
            },
          ),
          const Divider(height: 24, color: OwnerColors.borderSubtle),
          Text(
            'Push Notifications',
            style: OwnerTypography.editorialSerif(
              size: 16,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
          const SizedBox(height: 10),
          _buildToggle(
            'Skip Alert (near cutoff)',
            mess?.ownerNotificationPrefs['skipAlert'] ?? true,
            (val) => ref
                .read(ownerSettingsProvider.notifier)
                .toggleOwnerNotification('skipAlert', val),
          ),
          _buildToggle(
            'New Join Request Alert',
            mess?.ownerNotificationPrefs['joinRequest'] ?? true,
            (val) => ref
                .read(ownerSettingsProvider.notifier)
                .toggleOwnerNotification('joinRequest', val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: OwnerTypography.regular(
                size: 13,
                color: OwnerColors.textPrimary,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: OwnerColors.sageGreen,
          ),
        ],
      ),
    );
  }

  // ─── Skip Policy Card ─────────────────────────────────────────────────────
  Widget _buildSkipPolicyCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    if (mess == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Skipping Policy',
            style: OwnerTypography.editorialSerif(
              size: 16,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
          const SizedBox(height: 10),
          _buildToggle(
            'Allow Students to Skip Meals',
            mess.allowMealSkipping,
            (val) => ref
                .read(ownerSettingsProvider.notifier)
                .save(mess.copyWith(allowMealSkipping: val)),
          ),
        ],
      ),
    );
  }

  // ─── Special Meal Settings Card ──────────────────────────────────────────
  Widget _buildSpecialMealCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    if (mess == null) return const SizedBox.shrink();
    final notifier = ref.read(ownerSettingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Special Feast Policy (2x Rebate)',
                  style: OwnerTypography.editorialSerif(
                    size: 16,
                    weight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure your feast days (e.g. Sunday), cooked meal slots, and skip deduction multiplier.',
            style: OwnerTypography.regular(
              size: 12,
              color: OwnerColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            'Enable Special Meals',
            mess.specialMealEnabled,
            (val) => notifier.save(mess.copyWith(specialMealEnabled: val)),
          ),
          if (mess.specialMealEnabled) ...[
            const Divider(height: 24, color: OwnerColors.borderSubtle),
            Text(
              'SPECIAL FEAST DAYS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: OwnerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ].map((day) {
                final isSelected = mess.specialMealDays.contains(day);
                final shortName = day.substring(0, 3);
                return InkWell(
                  onTap: () {
                    final updatedDays = List<String>.from(mess.specialMealDays);
                    if (isSelected) {
                      if (updatedDays.length > 1) {
                        updatedDays.remove(day);
                        notifier.save(mess.copyWith(specialMealDays: updatedDays));
                      }
                    } else {
                      updatedDays.add(day);
                      notifier.save(mess.copyWith(specialMealDays: updatedDays));
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? OwnerColors.sageGreen.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? OwnerColors.sageGreen : OwnerColors.borderSubtle,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      isSelected ? '✓ $shortName' : shortName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? OwnerColors.walnutDark : OwnerColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'DESIGNATED SPECIAL SLOT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: OwnerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['morning', 'noon', 'night'].map((slot) {
                final isSelected = mess.specialMealSlot == slot;
                final label = slot == 'morning'
                    ? 'Breakfast'
                    : slot == 'noon'
                        ? 'Lunch'
                        : 'Dinner';
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => notifier.save(mess.copyWith(specialMealSlot: slot)),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFDF8EE) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? OwnerColors.amberGlow : OwnerColors.borderSubtle,
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isSelected ? '★ $label' : label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? OwnerColors.walnutDark : OwnerColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'SKIP DEDUCTION VALUE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: OwnerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => notifier.save(
                      mess.copyWith(
                        specialMealMultiplier: 2.0,
                        specialMealFlatRate: null,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: mess.specialMealMultiplier == 2.0 && mess.specialMealFlatRate == null
                            ? const Color(0xFFFDF8EE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: mess.specialMealMultiplier == 2.0 && mess.specialMealFlatRate == null
                              ? OwnerColors.amberGlow
                              : OwnerColors.borderSubtle,
                          width: mess.specialMealMultiplier == 2.0 && mess.specialMealFlatRate == null ? 1.6 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '2x Value (Double)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.walnutDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => notifier.save(
                      mess.copyWith(
                        specialMealMultiplier: 1.0,
                        specialMealFlatRate: null,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: mess.specialMealMultiplier == 1.0 && mess.specialMealFlatRate == null
                            ? const Color(0xFFFDF8EE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: mess.specialMealMultiplier == 1.0 && mess.specialMealFlatRate == null
                              ? OwnerColors.amberGlow
                              : OwnerColors.borderSubtle,
                          width: mess.specialMealMultiplier == 1.0 && mess.specialMealFlatRate == null ? 1.6 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '1x (Normal Rate)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: OwnerColors.walnutDark,
                          ),
                        ),
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
  }

  // ─── Mess Gallery Card ────────────────────────────────────────────────────
  Widget _buildMessPhotosCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    if (mess == null) return const SizedBox.shrink();
    final photos = mess.messPhotos;
    final canAdd = photos.length < 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Mess Gallery',
            style: OwnerTypography.editorialSerif(
              size: 20,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: OwnerColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OwnerColors.borderSubtle),
            boxShadow: OwnerShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add up to 4 photos of your dining hall, kitchen & meals.',
                style: OwnerTypography.regular(
                  size: 12,
                  color: OwnerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...photos.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                url,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: OwnerColors.surfaceWarm,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    color: OwnerColors.walnutMuted,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () async {
                                  final newPhotos = List<String>.from(photos)
                                    ..removeAt(idx);
                                  await ref
                                      .read(ownerSettingsProvider.notifier)
                                      .save(
                                        mess.copyWith(messPhotos: newPhotos),
                                      );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (canAdd)
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (file == null) return;
                          final bytes = await file.readAsBytes();
                          final ext = file.name.split('.').last;
                          try {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Uploading photo...'),
                                duration: Duration(seconds: 10),
                              ),
                            );
                            final url = await ref
                                .read(appServiceProvider)
                                .uploadImage('mess_photos', bytes, ext);
                            final newPhotos = List<String>.from(photos)
                              ..add(url);
                            await ref
                                .read(ownerSettingsProvider.notifier)
                                .save(mess.copyWith(messPhotos: newPhotos));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Photo added! ✅'),
                                  backgroundColor: OwnerColors.sageGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: OwnerColors.sageLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: OwnerColors.sageGreen.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: OwnerColors.sageDark,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: OwnerTypography.bold(
                                  size: 10,
                                  color: OwnerColors.sageDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${photos.length}/4 photos added',
                    style: OwnerTypography.regular(
                      size: 11,
                      color: OwnerColors.walnutMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Mess Description Card ────────────────────────────────────────────────
  Widget _buildAboutMessCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
  ) {
    final hasContent =
        mess?.aboutContent != null && mess!.aboutContent!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Mess Description',
            style: OwnerTypography.editorialSerif(
              size: 20,
              weight: FontWeight.w700,
              color: OwnerColors.walnutDark,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: OwnerColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OwnerColors.borderSubtle),
            boxShadow: OwnerShadows.card,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: OwnerColors.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_rounded,
                color: OwnerColors.sageDark,
                size: 20,
              ),
            ),
            title: Text(
              'More About My Mess',
              style: OwnerTypography.bold(
                size: 14,
                color: OwnerColors.walnutDark,
              ),
            ),
            subtitle: Text(
              hasContent
                  ? 'Tap to edit rich text description'
                  : 'Add rules, food specials & details',
              style: OwnerTypography.regular(
                size: 11,
                color: OwnerColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasContent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: OwnerColors.sageLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Added ✓',
                      style: OwnerTypography.bold(
                        size: 10,
                        color: OwnerColors.sageDark,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: OwnerColors.walnutMuted,
                  size: 20,
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerAboutMessPage(
                    initialDeltaJson: mess?.aboutContent,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Actions Card ─────────────────────────────────────────────────────────
  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    MessModel? mess,
    bool isHi,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: OwnerColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwnerColors.borderSubtle),
        boxShadow: OwnerShadows.card,
      ),
      child: Column(
        children: [
          if (mess != null) ...[
            _buildActionTile(
              Icons.star_rounded,
              'My VIP Launch Partner Benefits',
              OwnerColors.amberGlow,
              () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => OwnerLaunchPartnerSheet(mess: mess),
                );
              },
            ),
            const Divider(height: 1, indent: 52, color: OwnerColors.borderSubtle),
          ],
          _buildActionTile(
            Icons.location_on_rounded,
            'Update Mess Location (GPS)',
            const Color(0xFF2563EB),
            () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: OwnerColors.canvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  title: Text(
                    'Update location',
                    style: OwnerTypography.editorialSerif(
                      size: 22,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                  content: Text(
                    'Are you standing inside your mess right now? This instantly updates your mess coordinates on the map.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: OwnerColors.textSecondary,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 16),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: OwnerColors.walnutDark,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OwnerColors.amberGlow,
                        foregroundColor: OwnerColors.walnutDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Yes, I'm at the mess",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fetching GPS...')),
                );
                final success = await ref
                    .read(ownerSettingsProvider.notifier)
                    .updateGpsLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'GPS Coordinates updated successfully!'
                            : 'Failed to update GPS. Check permissions.',
                      ),
                      backgroundColor:
                          success ? OwnerColors.sageGreen : Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1, indent: 52, color: OwnerColors.borderSubtle),
          _buildActionTile(
            Icons.language_rounded,
            isHi ? 'भाषा (Language)' : 'Language',
            OwnerColors.sageDark,
            () => _showLanguageModal(context, ref),
            trailing: Text(
              isHi ? 'हिंदी (Hindi)' : 'English',
              style: OwnerTypography.bold(
                size: 12,
                color: OwnerColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1, indent: 52, color: OwnerColors.borderSubtle),
          _buildActionTile(
            Icons.support_agent_rounded,
            isHi
                ? 'सहायता और शिकायत (Help & Support)'
                : 'Help & Feedback',
            const Color(0xFF06B6D4),
            () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => UserFeedbackSheet(
                  userRole: 'owner',
                  messId: mess?.messId ?? '',
                  messName: mess?.name ?? '',
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 52, color: OwnerColors.borderSubtle),
          _buildActionTile(
            Icons.logout_rounded,
            isHi ? 'लॉगआउट' : 'Sign Out',
            Colors.red,
            () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: OwnerTypography.bold(
          size: 14,
          color: OwnerColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: OwnerColors.walnutMuted,
            size: 18,
          ),
      onTap: onTap,
    );
  }

  // ─── Edit Mess Dialog / Sheet (Screenshot 11) ─────────────────────────────
  void _showEditDialog(BuildContext context, WidgetRef ref, MessModel? mess) {
    if (mess == null) return;
    final nameCtrl = TextEditingController(text: mess.name);
    final ownerNameCtrl = TextEditingController(text: mess.ownerName);
    final feeCtrl = TextEditingController(
      text: mess.monthlyFee.toStringAsFixed(0),
    );
    final rateCtrl = TextEditingController(
      text: mess.perMealRate.toStringAsFixed(0),
    );
    final cutoffCtrl = TextEditingController(text: mess.cutoffHours.toString());

    int selectedMealsIncluded = mess.mealsIncludedPerDay;
    String selectedFoodType = mess.foodType;
    Uint8List? selectedImageBytes;
    String? imageExtension;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: OwnerColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'Edit Mess Profile',
              style: OwnerTypography.editorialSerif(
                size: 20,
                weight: FontWeight.w700,
                color: OwnerColors.walnutDark,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setState(() {
                          selectedImageBytes = bytes;
                          imageExtension = file.name.split('.').last;
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: OwnerColors.surfaceWarm,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OwnerColors.borderSubtle,
                          width: 2,
                        ),
                        image: selectedImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(selectedImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : (mess.ownerPhotoUrl != null &&
                                  mess.ownerPhotoUrl!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(mess.ownerPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (selectedImageBytes == null &&
                              (mess.ownerPhotoUrl == null ||
                                  mess.ownerPhotoUrl!.isEmpty))
                          ? const Icon(
                              Icons.add_a_photo,
                              color: OwnerColors.walnutMuted,
                              size: 26,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: OwnerTypography.regular(size: 13),
                    decoration: InputDecoration(
                      labelText: 'Mess Name',
                      labelStyle: OwnerTypography.regular(size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ownerNameCtrl,
                    style: OwnerTypography.regular(size: 13),
                    decoration: InputDecoration(
                      labelText: 'Owner Name',
                      labelStyle: OwnerTypography.regular(size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feeCtrl,
                    style: OwnerTypography.regular(size: 13),
                    decoration: InputDecoration(
                      labelText: 'Monthly Base Fee (₹)',
                      labelStyle: OwnerTypography.regular(size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Meals Included in Fee',
                      labelStyle: OwnerTypography.regular(size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedMealsIncluded,
                        isDense: true,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 4, child: Text('4 meals')),
                          DropdownMenuItem(value: 3, child: Text('3 meals')),
                          DropdownMenuItem(value: 2, child: Text('2 meals')),
                          DropdownMenuItem(value: 1, child: Text('1 meal')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedMealsIncluded = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateCtrl,
                    style: OwnerTypography.regular(size: 13),
                    decoration: InputDecoration(
                      labelText: 'Per Meal Deduction Rate (₹)',
                      labelStyle: OwnerTypography.regular(size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cutoffCtrl,
                    style: OwnerTypography.regular(size: 13),
                    decoration: InputDecoration(
                      labelText: 'Cut-off Time (hours before meal)',
                      labelStyle: OwnerTypography.regular(size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => isUploading = true);
                        try {
                          String? newPhotoUrl = mess.ownerPhotoUrl;

                          if (selectedImageBytes != null &&
                              imageExtension != null) {
                            newPhotoUrl = await ref
                                .read(appServiceProvider)
                                .uploadImage(
                                  'profiles',
                                  selectedImageBytes!,
                                  imageExtension!,
                                );
                          }

                          final updated = MessModel(
                            messId: mess.messId,
                            name: nameCtrl.text.trim().isEmpty
                                ? mess.name
                                : nameCtrl.text.trim(),
                            ownerId: mess.ownerId,
                            ownerName: ownerNameCtrl.text.trim().isEmpty
                                ? mess.ownerName
                                : ownerNameCtrl.text.trim(),
                            ownerPhone: mess.ownerPhone,
                            ownerPhotoUrl: newPhotoUrl,
                            messPhotos: mess.messPhotos,
                            gpsLat: mess.gpsLat,
                            gpsLng: mess.gpsLng,
                            capacity: mess.capacity,
                            messCode: mess.messCode,
                            isListedOnMap: mess.isListedOnMap,
                            showMenuToOutsiders: mess.showMenuToOutsiders,
                            showMenuToStudents: mess.showMenuToStudents,
                            language: mess.language,
                            monthlyFee: double.tryParse(feeCtrl.text) ??
                                mess.monthlyFee,
                            mealsIncludedPerDay: selectedMealsIncluded,
                            perMealRate: double.tryParse(rateCtrl.text) ??
                                mess.perMealRate,
                            cutoffHours: int.tryParse(cutoffCtrl.text) ??
                                mess.cutoffHours,
                            foodType: selectedFoodType,
                            mealTimings: mess.mealTimings,
                            ownerNotificationPrefs: mess.ownerNotificationPrefs,
                          );
                          ref
                              .read(ownerSettingsProvider.notifier)
                              .save(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() => isUploading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.sageGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Language Modal ───────────────────────────────────────────────────────
  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(localizationProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: OwnerColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    currentLang == 'hi' ? 'भाषा चुनें' : 'Choose Language',
                    style: OwnerTypography.editorialSerif(
                      size: 20,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                  title: Text(
                    'English',
                    style: OwnerTypography.bold(size: 14),
                  ),
                  subtitle: Text(
                    'Clean & simple English',
                    style: OwnerTypography.regular(
                      size: 11,
                      color: OwnerColors.textSecondary,
                    ),
                  ),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check_circle,
                          color: OwnerColors.sageGreen)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    ref.read(localizationProvider.notifier).toggleLanguage('en');
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language switched to English'),
                          backgroundColor: OwnerColors.sageGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                  title: Text(
                    'हिंदी (Hindi)',
                    style: OwnerTypography.bold(size: 14),
                  ),
                  subtitle: Text(
                    'सरल एवं आसान बोलचाल की हिंदी',
                    style: OwnerTypography.regular(
                      size: 11,
                      color: OwnerColors.textSecondary,
                    ),
                  ),
                  trailing: currentLang == 'hi'
                      ? const Icon(Icons.check_circle,
                          color: OwnerColors.sageGreen)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    ref.read(localizationProvider.notifier).toggleLanguage('hi');
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('भाषा बदलकर हिंदी कर दी गई है'),
                          backgroundColor: OwnerColors.sageGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
