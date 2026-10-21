import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/localization_service.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/student_inspired_theme.dart';

/// Interactive Bottom Sheet for Students/Diners to Rate and Review their Mess.
class RateMessSheet extends ConsumerStatefulWidget {
  final MessModel mess;
  final MessReviewModel? existingReview;

  const RateMessSheet({
    super.key,
    required this.mess,
    this.existingReview,
  });

  static Future<void> show(
    BuildContext context, {
    required MessModel mess,
    MessReviewModel? existingReview,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RateMessSheet(
        mess: mess,
        existingReview: existingReview,
      ),
    );
  }

  @override
  ConsumerState<RateMessSheet> createState() => _RateMessSheetState();
}

class _RateMessSheetState extends ConsumerState<RateMessSheet> {
  late double _selectedRating;
  late TextEditingController _commentCtrl;
  bool _isSubmitting = false;

  final List<String> _quickTags = [
    '🍱 Tasty Food',
    '🧼 Clean & Hygienic',
    '⏰ On-Time Meals',
    '👥 Courteous Staff',
    '💰 Value for Money',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingReview?.rating ?? 5.0;
    _commentCtrl = TextEditingController(text: widget.existingReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _getRatingLabel(double rating, bool isHindi) {
    if (rating >= 5.0) {
      return isHindi ? '⭐ 5.0 - उत्कृष्ट मेस (Exceptional)' : '⭐ 5.0 - Exceptional Mess';
    } else if (rating >= 4.0) {
      return isHindi ? '⭐ 4.0 - बहुत बढ़िया मेस (Very Good)' : '⭐ 4.0 - Very Good Mess';
    } else if (rating >= 3.0) {
      return isHindi ? '⭐ 3.0 - सामान्य अनुभव (Average)' : '⭐ 3.0 - Average Mess';
    } else if (rating >= 2.0) {
      return isHindi ? '⭐ 2.0 - सुधार की ज़रूरत (Below Expectations)' : '⭐ 2.0 - Below Expectations';
    } else {
      return isHindi ? '⭐ 1.0 - खराब अनुभव (Poor)' : '⭐ 1.0 - Poor Experience';
    }
  }

  Future<void> _submitReview() async {
    final currentStudent = ref.read(studentHomeProvider).student;
    final currentUid =
        currentStudent?.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final studentName = currentStudent?.name ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Diner';
    final studentPhoto = currentStudent?.photoUrl;

    if (currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final review = MessReviewModel(
        reviewId: widget.existingReview?.reviewId.isNotEmpty == true
            ? widget.existingReview!.reviewId
            : currentUid,
        messId: widget.mess.messId,
        studentId: currentUid,
        studentName: studentName,
        studentPhotoUrl: studentPhoto,
        rating: _selectedRating,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );

      await ref.read(appServiceProvider).submitOrUpdateMessReview(review);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReview != null
                  ? 'Review updated successfully!'
                  : 'Thanks for rating ${widget.mess.name}!',
            ),
            backgroundColor: StudentColors.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview() async {
    final review = widget.existingReview;
    if (review == null) return;

    final isHindi = ref.read(localizationProvider) == 'hi';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudentColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isHindi ? 'रिव्यू हटाएं?' : 'Delete Review?',
          style: StudentTypography.serifHeading(fontSize: 20),
        ),
        content: Text(
          isHindi
              ? 'क्या आप वाकई ${widget.mess.name} के लिए अपना रिव्यू हटाना चाहते हैं?'
              : 'Are you sure you want to remove your review for ${widget.mess.name}?',
          style: StudentTypography.body(fontSize: 14, color: StudentColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isHindi ? 'रद्द करें' : 'Cancel',
              style: StudentTypography.bold(fontSize: 13, color: StudentColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.brickRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isHindi ? 'हटाएं' : 'Delete',
              style: StudentTypography.bold(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(appServiceProvider).deleteMessReview(widget.mess.messId, review.reviewId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHindi ? 'रिव्यू हटा दिया गया है।' : 'Review deleted successfully.'),
            backgroundColor: StudentColors.brickRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localizationProvider) == 'hi';
    final isEditing = widget.existingReview != null;

    return Container(
      decoration: const BoxDecoration(
        color: StudentColors.canvasWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: StudentColors.borderSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: StudentColors.amberLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudentColors.amberPill),
                  ),
                  child: const Icon(Icons.star_rounded, color: StudentColors.amberDark, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? (isHindi ? 'अपना रिव्यू बदलें' : 'Edit Your Review')
                            : (isHindi ? '${widget.mess.name} को रेटिंग दें' : 'Rate ${widget.mess.name}'),
                        style: StudentTypography.serifHeading(
                          fontSize: 20,
                          color: StudentColors.walnut,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHindi
                            ? 'खाने का स्वाद, सफाई और सर्विस का अनुभव शेयर करें'
                            : 'Share your experience with food quality, hygiene & service',
                        style: StudentTypography.body(
                          fontSize: 12,
                          color: StudentColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Star Rating Row
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = (index + 1).toDouble();
                  final isSelected = starValue <= _selectedRating;
                  return IconButton(
                    iconSize: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: StudentColors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starValue;
                      });
                    },
                  );
                }),
              ),
            ),

            // Dynamic Description Label
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: StudentColors.amberLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StudentColors.amberPill),
                ),
                child: Text(
                  _getRatingLabel(_selectedRating, isHindi),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: StudentColors.amberText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Tags
            Text(
              isHindi ? 'क्विक टैग्स (टैप करके जोड़ें):' : 'Quick Tags (tap to add):',
              style: StudentTypography.bold(fontSize: 12, color: StudentColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTags.map((tag) {
                final isContained = _commentCtrl.text.contains(tag);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isContained) {
                        _commentCtrl.text = _commentCtrl.text.replaceAll('$tag ', '').replaceAll(tag, '').trim();
                      } else {
                        if (_commentCtrl.text.isEmpty) {
                          _commentCtrl.text = '$tag ';
                        } else {
                          _commentCtrl.text = '${_commentCtrl.text.trim()} $tag ';
                        }
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isContained ? StudentColors.sageLight : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isContained ? StudentColors.sage : StudentColors.borderSubtle,
                        width: isContained ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isContained ? FontWeight.w700 : FontWeight.w500,
                        color: isContained ? StudentColors.sageDark : StudentColors.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Comment Box
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: StudentTypography.body(fontSize: 13, color: StudentColors.textDark),
              decoration: InputDecoration(
                hintText: isHindi
                    ? 'खाने का स्वाद, स्वच्छता, बैठने की जगह और टाइमिंग के बारे में लिखें (वैकल्पिक)...'
                    : 'Describe how meals taste, seating, hygiene, timings, etc. (optional)...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: StudentColors.textMuted,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: StudentColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: StudentColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: StudentColors.amber, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                if (isEditing) ...[
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _deleteReview,
                    icon: const Icon(Icons.delete_outline, size: 18, color: StudentColors.brickRed),
                    label: Text(
                      isHindi ? 'हटाएं' : 'Delete',
                      style: GoogleFonts.inter(color: StudentColors.brickRed, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: StudentColors.brickRedBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.amber,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEditing
                                ? (isHindi ? 'रिव्यू अपडेट करें' : 'Update Review')
                                : (isHindi ? 'रिव्यू सबमिट करें' : 'Submit Review'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
