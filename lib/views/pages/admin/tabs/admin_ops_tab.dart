import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/admin_service.dart';
import '../admin_cyber_theme.dart';

/// Ops Deck: Master Remote Toggles, Security Vault, and Targeted Push Broadcaster.
/// Redesigned with the exact Executive Dark Luxury Obsidian & Warm Gold aesthetic
/// from Inspired UI (Screenshot 5).
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

  String _broadcastTarget = 'all_students'; // 'all_students' | 'all_owners' | 'one_mess'
  bool _isPinRevealed = false;
  bool _isSavingPin = false;
  bool _isSavingUpi = false;
  bool _isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    _broadcastTitleCtrl.addListener(() => setState(() {}));
    _broadcastBodyCtrl.addListener(() => setState(() {}));
  }

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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ops deck
          Text(
            'Ops deck',
            style: AdminCyberTheme.serifTitle(fontSize: 27),
          ),
          const SizedBox(height: 18),

          // Card 1: Master Remote Config
          CyberCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MASTER REMOTE CONFIG',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminCyberTheme.textMuted,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle 1: 6-month trial
                _buildSwitchRow(
                  title: '6-month auto-trial for new messes',
                  subtitle: 'New messes get 180 days free VIP',
                  value: config.globalTrialEnabled,
                  onChanged: (val) {
                    adminService.updateGlobalToggles(globalTrialEnabled: val);
                  },
                ),
                const Divider(color: Color(0xFF261F18), height: 24),

                // Toggle 2: ₹19 fee
                _buildSwitchRow(
                  title: '₹19 student platform fee',
                  subtitle: 'Adds a ₹19 line to monthly bills',
                  value: config.platformFeeEnabled,
                  onChanged: (val) {
                    adminService.updateGlobalToggles(platformFeeEnabled: val);
                  },
                ),
                const Divider(color: Color(0xFF261F18), height: 24),

                // Toggle 3: Maintenance Banner
                _buildSwitchRow(
                  title: 'Emergency maintenance banner',
                  subtitle: 'Red alert across all student & owner screens',
                  value: config.emergencyBannerEnabled,
                  onChanged: (val) {
                    adminService.updateGlobalToggles(emergencyBannerEnabled: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Security Vault
          CyberCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY VAULT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminCyberTheme.textMuted,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 14),

                // Master PIN row with Reveal button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'MASTER PIN  •  ',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.neonAmber,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          _isPinRevealed ? config.masterPin : '••••••',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AdminCyberTheme.neonAmber,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => setState(() => _isPinRevealed = !_isPinRevealed),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241D17),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF382F25)),
                        ),
                        child: Text(
                          _isPinRevealed ? 'Hide' : 'Reveal',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFAF7F2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Changing it updates Google login 2FA and the 5-tap stealth gate together.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminCyberTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // PIN Input + Update Button Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'New PIN',
                          hintStyle: GoogleFonts.inter(
                            color: AdminCyberTheme.textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF14110E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E261E)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E261E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFF59E0B),
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
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF140F09),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSavingPin
                          ? null
                          : () async {
                              final pin = _newPinCtrl.text.trim();
                              if (pin.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PIN must be at least 4 digits'),
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
                                      content: Text('Master PIN updated globally! 🔒'),
                                      backgroundColor: Color(0xFF1B1612),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isSavingPin = false);
                              }
                            },
                      child: _isSavingPin
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF140F09),
                              ),
                            )
                          : Text(
                              'Update PIN',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Remittance UPI Row
                Row(
                  children: [
                    Text(
                      'REMITTANCE UPI  •  ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminCyberTheme.neonAmber,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        config.developerUpiId,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFAF7F2),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // UPI Input + Update Button Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newUpiCtrl,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'name@bank',
                          hintStyle: GoogleFonts.jetBrainsMono(
                            color: AdminCyberTheme.textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF14110E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E261E)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E261E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFF59E0B),
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
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF140F09),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSavingUpi
                          ? null
                          : () async {
                              final upi = _newUpiCtrl.text.trim();
                              if (!upi.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid UPI ID format'),
                                  ),
                                );
                                return;
                              }
                              setState(() => _isSavingUpi = true);
                              try {
                                await adminService.updateDeveloperUpiId(upi);
                                _newUpiCtrl.clear();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Updated Remittance UPI to $upi! 💳'),
                                      backgroundColor: const Color(0xFF1B1612),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isSavingUpi = false);
                              }
                            },
                      child: _isSavingUpi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF140F09),
                              ),
                            )
                          : Text(
                              'Update UPI',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 3: Targeted Push Broadcaster
          CyberCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TARGETED PUSH BROADCASTER',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminCyberTheme.textMuted,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 14),

                // Audience Selector Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTargetPill('All students', 'all_students'),
                      const SizedBox(width: 8),
                      _buildTargetPill('All mess owners', 'all_owners'),
                      const SizedBox(width: 8),
                      _buildTargetPill('One mess', 'one_mess'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Broadcast Title Field
                TextField(
                  controller: _broadcastTitleCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Title, e.g. Festival wishes / Maintenance',
                    hintStyle: GoogleFonts.inter(
                      color: AdminCyberTheme.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF14110E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E261E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E261E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),

                // Broadcast Body Field
                TextField(
                  controller: _broadcastBodyCtrl,
                  maxLines: 4,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Message body...',
                    hintStyle: GoogleFonts.inter(
                      color: AdminCyberTheme.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF14110E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E261E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E261E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 14),

                // Live Notification Preview Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14110E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E261E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREVIEW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AdminCyberTheme.textMuted,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _broadcastTitleCtrl.text.trim().isEmpty
                            ? 'Title appears here'
                            : _broadcastTitleCtrl.text.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFAF7F2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _broadcastBodyCtrl.text.trim().isEmpty
                            ? 'Body text appears here'
                            : _broadcastBodyCtrl.text.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AdminCyberTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Schedule + Dispatch Button Row
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scheduled broadcasts will dispatch automatically.'),
                            backgroundColor: Color(0xFF1B1612),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241D17),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF382F25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Color(0xFFFAF7F2)),
                            const SizedBox(width: 6),
                            Text(
                              'Schedule',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFAF7F2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF140F09),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _isBroadcasting
                              ? null
                              : () async {
                                  final title = _broadcastTitleCtrl.text.trim();
                                  final body = _broadcastBodyCtrl.text.trim();
                                  if (title.isEmpty || body.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter title & body for broadcast'),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isBroadcasting = true);
                                  try {
                                    await adminService.broadcastNotification(
                                      title: title,
                                      body: body,
                                      targetAudience: _broadcastTarget,
                                    );
                                    _broadcastTitleCtrl.clear();
                                    _broadcastBodyCtrl.clear();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Mass push notification dispatched! 🚀'),
                                          backgroundColor: Color(0xFF1B1612),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isBroadcasting = false);
                                  }
                                },
                          child: _isBroadcasting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF140F09),
                                  ),
                                )
                              : Text(
                                  'Dispatch broadcast',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFAF7F2),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminCyberTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF4E654F),
            inactiveThumbColor: Colors.white60,
            inactiveTrackColor: const Color(0xFF261F18),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetPill(String label, String value) {
    final isSelected = _broadcastTarget == value;
    return InkWell(
      onTap: () => setState(() => _broadcastTarget = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF221C16),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF382F25), width: 1.0),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF140F09) : const Color(0xFFFAF7F2),
          ),
        ),
      ),
    );
  }
}
