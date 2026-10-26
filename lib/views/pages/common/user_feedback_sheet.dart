import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/app_models.dart';
import '../../../services/admin_service.dart';
import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';

/// Redesigned User-facing Help & Feedback Bottom Sheet matching Screenshot 2.
/// Features category pills (Bug report, Suggestion, Mess issue, Bill dispute),
/// multiline detail input, optional screenshot attachment, and warm amber submission CTA.
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
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        appVersion: 'v1.0.5',
        createdAt: DateTime.now(),
      );

      await ref.read(adminServiceProvider).submitSupportTicket(ticket);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF241A14),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFFEAA23E), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isHi
                      ? 'आपकी शिकायत/सुझाव सफलतापूर्वक दर्ज हो गया है!'
                      : 'Your feedback has been submitted successfully!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 13,
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
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top grab handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8D1C5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title & Subtitle
                Text(
                  'Help & feedback',
                  style: GoogleFonts.newsreader(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF241A14),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Send complaints, suggestions or billing issues directly. Replies appear under My complaints.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B6662),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Category Pills (Wrap layout matching Screenshot 2)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryPill('Bug report', 'bug'),
                    _buildCategoryPill('Suggestion', 'suggestion'),
                    _buildCategoryPill('Mess issue', 'mess_issue'),
                    _buildCategoryPill('Bill dispute', 'billing_dispute'),
                  ],
                ),
                const SizedBox(height: 18),

                // Multiline Message Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8E0D4)),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 5,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF241A14),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or suggestion in detail...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF8A8480),
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Attach screenshot toggle / preview
                if (_screenshotBytes != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDFE6DB)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _screenshotBytes!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Screenshot attached',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF241A14),
                                ),
                              ),
                              Text(
                                _selectedScreenshot?.name ?? 'image.jpg',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF7A7571),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF7A7571)),
                          onPressed: _removeScreenshot,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Center(
                    child: InkWell(
                      onTap: _pickScreenshot,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.crop_square_rounded,
                              size: 18,
                              color: Color(0xFF241A14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Attach screenshot (optional)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF241A14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Primary Submit CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAA23E),
                      foregroundColor: const Color(0xFF241A14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF241A14),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit ticket',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF241A14),
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

  Widget _buildCategoryPill(String label, String value) {
    final isSelected = _category == value;
    return GestureDetector(
      onTap: () => setState(() => _category = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2018) : const Color(0xFFDFE7DC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C2018) : const Color(0xFFD4DEC8),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFFFAF8F5) : const Color(0xFF2D3C2F),
          ),
        ),
      ),
    );
  }
}
