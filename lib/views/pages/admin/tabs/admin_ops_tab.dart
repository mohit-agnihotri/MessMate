import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../../../../services/notification_service.dart';
import '../admin_cyber_theme.dart';

/// Ops Deck: Master Remote Toggles, Dynamic Master PIN Manager, and Mass Push Broadcaster.
class AdminOpsTab extends ConsumerStatefulWidget {
  const AdminOpsTab({super.key});

  @override
  ConsumerState<AdminOpsTab> createState() => _AdminOpsTabState();
}

class _AdminOpsTabState extends ConsumerState<AdminOpsTab> {
  final TextEditingController _newPinCtrl = TextEditingController();
  final TextEditingController _newUpiCtrl = TextEditingController();
  final TextEditingController _broadcastTitleCtrl = TextEditingController();
  final TextEditingController _broadcastBodyCtrl = TextEditingController();

  String _broadcastTarget = 'all_students'; // 'all_students' | 'all_owners'
  bool _isSavingPin = false;
  bool _isSavingUpi = false;
  bool _isBroadcasting = false;

  @override
  void dispose() {
    _newPinCtrl.dispose();
    _newUpiCtrl.dispose();
    _broadcastTitleCtrl.dispose();
    _broadcastBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);
    final configAsync = ref.watch(adminConfigStreamProvider);
    final config = configAsync.value ?? const AdminGlobalConfigModel();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Master Remote Toggles
          Text(
            'MASTER REMOTE CONFIG TOGGLES',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          CyberCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildToggleRow(
                  title: '6-Month Auto-Trial for New Messes',
                  subtitle:
                      'When ON, newly registered messes automatically receive 180 days free VIP tier.',
                  value: config.globalTrialEnabled,
                  accentColor: AdminCyberTheme.neonEmerald,
                  onChanged: (val) {
                    adminService.updateGlobalToggles(globalTrialEnabled: val);
                  },
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildToggleRow(
                  title: '₹19 Student Platform Maintenance Fee',
                  subtitle:
                      'Automatically add ₹19 line item to monthly student bills collected by owner.',
                  value: config.platformFeeEnabled,
                  accentColor: AdminCyberTheme.neonCyan,
                  onChanged: (val) {
                    adminService.updateGlobalToggles(platformFeeEnabled: val);
                  },
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildToggleRow(
                  title: 'Emergency Maintenance Banner',
                  subtitle:
                      'Broadcast high-priority red alert banner across all student & owner screens.',
                  value: config.emergencyBannerEnabled,
                  accentColor: AdminCyberTheme.neonRose,
                  onChanged: (val) {
                    adminService.updateGlobalToggles(
                        emergencyBannerEnabled: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Master Security Passcode / PIN Manager
          Text(
            'MASTER SECURITY PASSCODE & VAULT',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          CyberCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AdminCyberTheme.neonViolet, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE MASTER PIN: ${config.masterPin}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AdminCyberTheme.neonViolet,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Change your master passcode below. This synchronizes both your Google Login 2FA verification code and the 5-tap Stealth Gate PIN instantly in Firestore.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminCyberTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Enter New PIN',
                          hintStyle: GoogleFonts.inter(
                              color: AdminCyberTheme.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0C1322),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AdminCyberTheme.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AdminCyberTheme.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AdminCyberTheme.neonViolet,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminCyberTheme.neonViolet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isSavingPin
                          ? null
                          : () async {
                              final pin = _newPinCtrl.text.trim();
                              if (pin.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('PIN must be at least 4 digits'),
                                    backgroundColor: AdminCyberTheme.neonRose,
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSavingPin = true);
                              try {
                                await adminService.updateMasterPin(pin);
                                _newPinCtrl.clear();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Master Security Passcode updated successfully! 🔒'),
                                      backgroundColor: Color(0xFF04202C),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSavingPin = false);
                                }
                              }
                            },
                      child: _isSavingPin
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'UPDATE PIN',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 26),
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        color: AdminCyberTheme.neonCyan, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'REMITTANCE UPI ID: ${config.developerUpiId}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AdminCyberTheme.neonCyan,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your direct remittance UPI ID globally. Mess owners will remit software subscription & platform fees to this address.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminCyberTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newUpiCtrl,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminCyberTheme.neonCyan,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. name@bank',
                          hintStyle: GoogleFonts.inter(
                              color: AdminCyberTheme.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0C1322),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AdminCyberTheme.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AdminCyberTheme.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AdminCyberTheme.neonCyan,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminCyberTheme.neonCyan,
                        foregroundColor: const Color(0xFF04202C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isSavingUpi
                          ? null
                          : () async {
                              final upi = _newUpiCtrl.text.trim();
                              if (upi.isEmpty || !upi.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please enter a valid UPI ID (e.g. name@bank)'),
                                    backgroundColor: AdminCyberTheme.neonRose,
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSavingUpi = true);
                              try {
                                await adminService.updateGlobalToggles(
                                    developerUpiId: upi);
                                _newUpiCtrl.clear();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Remittance UPI ID updated to $upi globally! 🚀'),
                                      backgroundColor: const Color(0xFF04202C),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSavingUpi = false);
                                }
                              }
                            },
                      child: _isSavingUpi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF04202C), strokeWidth: 2),
                            )
                          : Text(
                              'UPDATE UPI',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Mass Push Notification Broadcaster
          Text(
            'TARGETED MASS PUSH BROADCASTER',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          CyberCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAudienceChip('All Students', 'all_students'),
                    const SizedBox(width: 8),
                    _buildAudienceChip('All Mess Owners', 'all_owners'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _broadcastTitleCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Notification Title (e.g. Festival Wishes / Maintenance)',
                    hintStyle: GoogleFonts.inter(
                        color: AdminCyberTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0C1322),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AdminCyberTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AdminCyberTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AdminCyberTheme.neonCyan,
                        width: 1.5,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _broadcastBodyCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Notification Message body...',
                    hintStyle: GoogleFonts.inter(
                        color: AdminCyberTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0C1322),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AdminCyberTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AdminCyberTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AdminCyberTheme.neonCyan,
                        width: 1.5,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminCyberTheme.neonCyan,
                      foregroundColor: const Color(0xFF04202C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isBroadcasting
                        ? null
                        : () async {
                            final title = _broadcastTitleCtrl.text.trim();
                            final body = _broadcastBodyCtrl.text.trim();
                            if (title.isEmpty || body.isEmpty) return;

                            setState(() => _isBroadcasting = true);
                            try {
                              await NotificationService.sendBroadcastNotification(
                                title: title,
                                message: body,
                                targetRole: _broadcastTarget == 'all_students'
                                    ? 'student'
                                    : 'owner',
                              );

                              _broadcastTitleCtrl.clear();
                              _broadcastBodyCtrl.clear();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Mass push notification dispatched successfully! 📢'),
                                    backgroundColor: Color(0xFF04202C),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isBroadcasting = false);
                              }
                            }
                          },
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: Text(
                      'DISPATCH MASS BROADCAST',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AdminCyberTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          activeTrackColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAudienceChip(String label, String value) {
    final isSelected = _broadcastTarget == value;
    return InkWell(
      onTap: () => setState(() => _broadcastTarget = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AdminCyberTheme.neonCyan.withValues(alpha: 0.15)
              : AdminCyberTheme.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AdminCyberTheme.neonCyan
                : AdminCyberTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AdminCyberTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
