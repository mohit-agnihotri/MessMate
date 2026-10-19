import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../services/localization_service.dart';
import '../../../../viewmodels/all_viewmodels.dart';

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
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview() async {
    final review = widget.existingReview;
    if (review == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Review?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove your review for ${widget.mess.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
          const SnackBar(
            content: Text('Review deleted successfully.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
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
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHindi
                            ? 'खाने का स्वाद, सफाई और सर्विस का अनुभव शेयर करें'
                            : 'Share your experience with food quality, hygiene & service',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
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
                    iconSize: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  _getRatingLabel(_selectedRating, isHindi),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Tags
            Text(
              isHindi ? 'क्विक टैग्स (टैप करके जोड़ें):' : 'Quick Tags (tap to add):',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isContained ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isContained ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isContained ? FontWeight.w700 : FontWeight.w500,
                        color: isContained ? const Color(0xFF15803D) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Comment Box
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isHindi
                    ? 'खाने का स्वाद, स्वच्छता, बैठने की जगह और टाइमिंग के बारे में लिखें (वैकल्पिक)...'
                    : 'Describe how meals taste, seating, hygiene, timings, etc. (optional)...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF22C55E)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                if (isEditing) ...[
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _deleteReview,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: Text(
                      isHindi ? 'डिलीट' : 'Delete',
                      style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
