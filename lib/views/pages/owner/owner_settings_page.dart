import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../viewmodels/all_viewmodels.dart';
import '../../../models/app_models.dart';

class OwnerSettingsPage extends ConsumerWidget {
  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerSettingsProvider);
    final MessModel? mess = state.mess;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Settings',
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            )),
            if (state.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _buildMessInfoCard(context, ref, mess)),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildMessTimingsCard(context, ref, mess)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildToggleCard(context, ref, mess)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverToBoxAdapter(child: _buildActionsCard(context, ref)),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessInfoCard(BuildContext context, WidgetRef ref, MessModel? mess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (mess?.ownerPhotoUrl != null && mess!.ownerPhotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(mess.ownerPhotoUrl!, width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultMessIcon(),
              ),
            )
          else
            _buildDefaultMessIcon(),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mess?.name ?? 'Loading...',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            Text(mess?.ownerName ?? 'Loading...',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
          ])),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF6B7280), size: 20),
            onPressed: () => _showEditDialog(context, ref, mess),
          ),
        ]),
        const Divider(height: 24, color: Color(0xFFF3F4F6)),
        _buildInfoRow('Monthly Fee', 'Rs ${mess?.monthlyFee.toInt() ?? 0}'),
        _buildInfoRow('Per Meal Rate', 'Rs ${mess?.perMealRate.toInt() ?? 0}'),
        _buildInfoRow('Capacity', '${mess?.capacity ?? 0} students'),
        _buildInfoRow('Mess Code', mess?.messCode ?? 'N/A'),
        _buildInfoRow('Cutoff Hours', '${mess?.cutoffHours ?? 0} hours before meal'),
      ]),
    );
  }

  Widget _buildDefaultMessIcon() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.restaurant, color: Colors.white, size: 22),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
      ]),
    );
  }

  Widget _buildMessTimingsCard(BuildContext context, WidgetRef ref, MessModel? mess) {
    if (mess == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text('Mess Timings', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildTimingSlot(context, ref, mess, 'Morning', 'morning'),
              const Divider(height: 32, color: Color(0xFFF3F4F6)),
              _buildTimingSlot(context, ref, mess, 'Noon', 'noon'),
              const Divider(height: 32, color: Color(0xFFF3F4F6)),
              _buildTimingSlot(context, ref, mess, 'Evening', 'evening'),
              const Divider(height: 32, color: Color(0xFFF3F4F6)),
              _buildTimingSlot(context, ref, mess, 'Night', 'night'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimingSlot(BuildContext context, WidgetRef ref, MessModel mess, String label, String slotKey) {
    final timings = mess.mealTimings[slotKey];
    final bool isEnabled = timings?['enabled'] == 'true';
    final String start = timings?['start'] ?? '00:00';
    final String end = timings?['end'] ?? '00:00';

    return Column(
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isEnabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF))),
              CupertinoSwitch(
                value: isEnabled,
                activeTrackColor: const Color(0xFF22C55E),
                onChanged: (val) {
                  final newTimings = Map<String, Map<String, String>>.from(mess.mealTimings);
                  newTimings[slotKey] = Map<String, String>.from(newTimings[slotKey] ?? {});
                  newTimings[slotKey]!['enabled'] = val ? 'true' : 'false';
                  ref.read(ownerSettingsProvider.notifier).save(mess.copyWith(mealTimings: newTimings));
                },
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(height: 24, color: Color(0xFFF3F4F6)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(context, ref, mess, slotKey, 'start', start),
                    child: _buildTimeDisplay('Start Time', start),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('-', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(context, ref, mess, slotKey, 'end', end),
                    child: _buildTimeDisplay('End Time', end),
                  ),
                ),
              ],
            ),
          ]
        ],
    );
  }

  Widget _buildTimeDisplay(String label, String time24) {
    // Simple 24h to 12h formatting
    final parts = time24.split(':');
    int h = int.tryParse(parts[0]) ?? 0;
    String m = parts.length > 1 ? parts[1] : '00';
    String period = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    String time12 = '${h12.toString().padLeft(2, '0')}:$m $period';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF22C55E)),
            const SizedBox(width: 6),
            Text(time12, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref, MessModel mess, String slotKey, String field, String currentTime) async {
    final parts = currentTime.split(':');
    TimeOfDay initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF22C55E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      final newTime = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
      final newTimings = Map<String, Map<String, String>>.from(mess.mealTimings);
      newTimings[slotKey] = Map<String, String>.from(newTimings[slotKey] ?? {});
      newTimings[slotKey]![field] = newTime;
      ref.read(ownerSettingsProvider.notifier).save(mess.copyWith(mealTimings: newTimings));
    }
  }

  Widget _buildToggleCard(BuildContext context, WidgetRef ref, MessModel? mess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Visibility',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        _buildToggle('Listed on Discovery Map', mess?.isListedOnMap ?? true, (val) {
          if (mess != null) ref.read(ownerSettingsProvider.notifier).save(mess.copyWith(isListedOnMap: val));
        }),
        _buildToggle('Show Menu to Outsiders', mess?.showMenuToOutsiders ?? true, (val) {
          if (mess != null) ref.read(ownerSettingsProvider.notifier).save(mess.copyWith(showMenuToOutsiders: val));
        }),
        _buildToggle('Show Menu to Students', mess?.showMenuToStudents ?? true, (val) {
          if (mess != null) ref.read(ownerSettingsProvider.notifier).save(mess.copyWith(showMenuToStudents: val));
        }),
        const Divider(height: 24, color: Color(0xFFF3F4F6)),
        Text('Notifications',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        _buildToggle('Skip Alert (near cutoff)', true, (val) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences updated!')));
        }),
        _buildToggle('New Join Request Alert', true, (val) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences updated!')));
        }),
      ]),
    );
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151)))),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF22C55E),
        ),
      ]),
    );
  }

  Widget _buildActionsCard(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(children: [
          _buildActionTile(Icons.location_on_rounded, 'Update Mess Location (GPS)', const Color(0xFF2563EB), () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Update Location', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                content: Text('Are you currently standing inside your mess? This will instantly update your mess coordinates on the map.', style: GoogleFonts.inter()),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                    child: const Text('Yes, I am at the mess', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching GPS...')));
              final success = await ref.read(ownerSettingsProvider.notifier).updateGpsLocation();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS Coordinates updated successfully!'), backgroundColor: Color(0xFF22C55E)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update GPS. Please check permissions.'), backgroundColor: Color(0xFFEF4444)));
                }
              }
            }
          }),
          const Divider(height: 1, indent: 52, color: Color(0xFFF3F4F6)),
          _buildActionTile(Icons.help_outline_rounded, 'Help & Support', const Color(0xFF374151), () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support portal coming soon!')));
          }),
          const Divider(height: 1, indent: 52, color: Color(0xFFF3F4F6)),
          _buildActionTile(Icons.logout_rounded, 'Sign Out', const Color(0xFFEF4444), () {
            ref.read(authProvider.notifier).signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Logged Out. Please restart the app.')))));
          }),
        ]),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF111827))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, MessModel? mess) {
    if (mess == null) return;
    final nameCtrl = TextEditingController(text: mess.name);
    final ownerNameCtrl = TextEditingController(text: mess.ownerName);
    final feeCtrl = TextEditingController(text: mess.monthlyFee.toStringAsFixed(0));
    final rateCtrl = TextEditingController(text: mess.perMealRate.toStringAsFixed(0));
    final cutoffCtrl = TextEditingController(text: mess.cutoffHours.toString());
    
    Uint8List? selectedImageBytes;
    String? imageExtension;
    bool isUploading = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Edit Mess Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setState(() {
                      selectedImageBytes = bytes;
                      imageExtension = file.name.split('.').last;
                    });
                  }
                },
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                    image: selectedImageBytes != null
                      ? DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.cover)
                      : (mess.ownerPhotoUrl != null && mess.ownerPhotoUrl!.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(mess.ownerPhotoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (selectedImageBytes == null && (mess.ownerPhotoUrl == null || mess.ownerPhotoUrl!.isEmpty))
                    ? const Icon(Icons.add_a_photo, color: Color(0xFF9CA3AF), size: 28)
                    : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Mess Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              TextField(controller: feeCtrl, decoration: const InputDecoration(labelText: 'Monthly Base Fee (Rs)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Per Meal Deduction Rate (Rs)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: cutoffCtrl, decoration: const InputDecoration(labelText: 'Cut-off Time (hours before meal)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                setState(() => isUploading = true);
                try {
                  String? newPhotoUrl = mess.ownerPhotoUrl;
                  
                  if (selectedImageBytes != null && imageExtension != null) {
                    newPhotoUrl = await ref.read(appServiceProvider).uploadImage('profiles', selectedImageBytes!, imageExtension!);
                  }

                  final updated = MessModel(
                    messId: mess.messId, 
                    name: nameCtrl.text.trim().isEmpty ? mess.name : nameCtrl.text.trim(), 
                    ownerId: mess.ownerId, 
                    ownerName: ownerNameCtrl.text.trim().isEmpty ? mess.ownerName : ownerNameCtrl.text.trim(), 
                    ownerPhone: mess.ownerPhone, 
                    ownerPhotoUrl: newPhotoUrl,
                    gpsLat: mess.gpsLat, 
                    gpsLng: mess.gpsLng,
                    capacity: mess.capacity, messCode: mess.messCode, isListedOnMap: mess.isListedOnMap, showMenuToOutsiders: mess.showMenuToOutsiders, showMenuToStudents: mess.showMenuToStudents, language: mess.language,
                    monthlyFee: double.tryParse(feeCtrl.text) ?? mess.monthlyFee,
                    perMealRate: double.tryParse(rateCtrl.text) ?? mess.perMealRate,
                    cutoffHours: int.tryParse(cutoffCtrl.text) ?? mess.cutoffHours,
                  );
                  ref.read(ownerSettingsProvider.notifier).save(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setState(() => isUploading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                  }
                }
              },
              child: isUploading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
            ),
          ],
        );
      },
    ));
  }
}
