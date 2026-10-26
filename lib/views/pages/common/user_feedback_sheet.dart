import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/admin_service.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../owner/theme/owner_inspired_theme.dart';

/// User-facing In-App Feedback, Bug Report, & Feature Suggestion Sheet.
/// Allows students and mess owners to report issues, attach screenshots, or send suggestions.
class UserFeedbackSheet extends ConsumerStatefulWidget {
  final String userRole; // 'student' | 'owner'
  final String messId;
  final String messName;

  const UserFeedbackSheet({
    super.key,
    required this.userRole,
    this.messId = '',
    this.messName = '',
  });

  @override
  ConsumerState<UserFeedbackSheet> createState() => _UserFeedbackSheetState();
}

class _UserFeedbackSheetState extends ConsumerState<UserFeedbackSheet> {
  String _category = 'bug';
  final TextEditingController _msgCtrl = TextEditingController();
  bool _isSubmitting = false;

  XFile? _selectedScreenshot;
  Uint8List? _screenshotBytes;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedScreenshot = picked;
          _screenshotBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('[UserFeedbackSheet] Error picking screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _removeScreenshot() {
    setState(() {
      _selectedScreenshot = null;
      _screenshotBytes = null;
    });
  }

  Future<void> _submitFeedback() async {
    final isHi = ref.read(localizationProvider) == 'hi';
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? 'कृपया अपनी समस्या या सुझाव का विवरण लिखें।'
                : 'Please write your message or issue description.',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.userId ??
          await ref.read(appServiceProvider).getCurrentUserId() ??
          'anonymous';
      String resolvedName =
          widget.userRole == 'owner' ? 'Mess Owner' : 'Student User';
      String resolvedPhone = '';
      String resolvedMess = widget.messName;

      if (widget.userRole == 'owner') {
        final ownerState = ref.read(ownerSettingsProvider);
        if (ownerState.mess != null) {
          if (ownerState.mess!.ownerName.isNotEmpty) {
            resolvedName = ownerState.mess!.ownerName;
          }
          resolvedPhone = ownerState.mess!.ownerPhone;
          if (resolvedMess.isEmpty) resolvedMess = ownerState.mess!.name;
        }
      } else {
        final studentProfile = ref.read(studentProfileProvider);
        if (studentProfile.student != null) {
          if (studentProfile.student!.name.isNotEmpty) {
            resolvedName = studentProfile.student!.name;
          }
          resolvedPhone = studentProfile.student!.phone;
        }
      }

      // Upload screenshot to Cloudinary if selected
      String? uploadedScreenshotUrl;
      if (_screenshotBytes != null && _selectedScreenshot != null) {
        final ext = _selectedScreenshot!.name.split('.').last.toLowerCase();
        try {
          uploadedScreenshotUrl = await ref.read(appServiceProvider).uploadImage(
                'support_tickets',
                _screenshotBytes!,
                ext.isEmpty ? 'jpg' : ext,
              );
        } catch (uploadError) {
          debugPrint('[UserFeedbackSheet] Screenshot upload warning: $uploadError');
          // Proceed even if screenshot upload fails gracefully
        }
      }

      final ticket = SupportTicketModel(
        ticketId: '',
        userId: userId,
        userName: resolvedName,
        userPhone: resolvedPhone,
        userRole: widget.userRole,
        messId: widget.messId,
        messName: resolvedMess,
        category: _category,
        message: text,
        screenshotUrl: uploadedScreenshotUrl,
        deviceModel: defaultTargetPlatform.name.toUpperCase(),
        osVersion: 'Flutter ${defaultTargetPlatform.name}',
        appVersion: 'v1.0.4',
        createdAt: DateTime.now(),
      );

      await ref.read(adminServiceProvider).submitSupportTicket(ticket);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: OwnerColors.walnutDark,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: OwnerColors.amberGlow, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isHi
                      ? 'आपकी शिकायत/सुझाव सफलतापूर्वक दर्ज हो गया है!'
                      : 'Your feedback has been submitted successfully!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHi = ref.watch(localizationProvider) == 'hi';

    return Container(
      decoration: const BoxDecoration(
        color: OwnerColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OwnerColors.walnutMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  isHi ? 'सहायता एवं प्रतिक्रिया' : 'Help & Feedback',
                  style: OwnerTypography.editorialSerif(
                    size: 24,
                    weight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHi
                      ? 'शिकायतें, सुझाव या बिलिंग संबंधी समस्याएं सीधे दर्ज करें।'
                      : 'Send complaints, suggestions, or billing issues directly.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: OwnerColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Category Selector (matching inspired screenshot pills)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                          isHi ? '🐛 बग रिपोर्ट' : 'Bug report', 'bug'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                          isHi ? '💡 सुझाव' : 'Suggestion', 'suggestion'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                          isHi ? '🍽️ मेस समस्या' : 'Mess issue', 'mess_issue'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                          isHi ? '💳 बिल विवाद' : 'Bill dispute',
                          'billing_dispute'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Message input box
                TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    color: OwnerColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: isHi
                        ? 'अपनी समस्या या सुझाव का विवरण विस्तार से लिखें...'
                        : 'Describe your issue or suggestion in detail...',
                    hintStyle: GoogleFonts.inter(
                      color: OwnerColors.textMuted,
                      fontSize: 13,
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
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 14),

                // Screenshot Attachment Button & Preview
                if (_screenshotBytes != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OwnerColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _screenshotBytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHi
                                    ? 'स्क्रीनशॉट संलग्न है'
                                    : 'Screenshot Attached',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: OwnerColors.textPrimary,
                                ),
                              ),
                              Text(
                                isHi
                                    ? 'शिकायत के साथ अपलोड होगा'
                                    : 'Ready to upload with ticket',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: OwnerColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFFEF4444)),
                          onPressed: _removeScreenshot,
                          tooltip: isHi ? 'हटाएं' : 'Remove',
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: _pickScreenshot,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: OwnerColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 20,
                            color: OwnerColors.walnutDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHi
                                ? 'स्क्रीनशॉट जोड़ें (वैकल्पिक)'
                                : 'Attach Screenshot (Optional)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: OwnerColors.walnutDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.amberGlow,
                      foregroundColor: OwnerColors.textDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: OwnerColors.textDark,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isHi ? 'शिकायत दर्ज करें (Submit)' : 'Submit Ticket',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: OwnerColors.textDark,
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

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _category == value;
    return InkWell(
      onTap: () => setState(() => _category = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? OwnerColors.walnutDark
              : const Color(0xFFE2E8DE), // light sage
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : const Color(0xFF2C3E2D), // dark sage text
          ),
        ),
      ),
    );
  }
}
