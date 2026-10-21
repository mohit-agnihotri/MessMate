import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';
import 'theme/owner_inspired_theme.dart';

class OwnerAboutMessPage extends ConsumerStatefulWidget {
  final String? initialDeltaJson;

  const OwnerAboutMessPage({super.key, this.initialDeltaJson});

  @override
  ConsumerState<OwnerAboutMessPage> createState() => _OwnerAboutMessPageState();
}

class _OwnerAboutMessPageState extends ConsumerState<OwnerAboutMessPage> {
  late QuillController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDeltaJson != null &&
        widget.initialDeltaJson!.isNotEmpty) {
      try {
        final doc = Document.fromJson(
          jsonDecode(widget.initialDeltaJson!) as List<dynamic>,
        );
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAttribute(Attribute attribute) {
    final isToggled =
        _controller.getSelectionStyle().containsKey(attribute.key);
    if (isToggled) {
      _controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      _controller.formatSelection(attribute);
    }
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final delta = _controller.document.toDelta();
    final json = jsonEncode(delta.toJson());
    final success = await ref
        .read(ownerSettingsProvider.notifier)
        .updateAboutContent(json);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description saved successfully!'),
          backgroundColor: OwnerColors.walnutDark,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _controller.getSelectionStyle();
    final isBold = style.containsKey(Attribute.bold.key);
    final isItalic = style.containsKey(Attribute.italic.key);
    final isBullet = style.containsKey(Attribute.ul.key);
    final isNumberList = style.containsKey(Attribute.ol.key);

    return Scaffold(
      backgroundColor: OwnerColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Circular Sage Back Button & Serif Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8DE), // Light sage
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'About my mess',
                    style: OwnerTypography.editorialSerif(
                      size: 28,
                      weight: FontWeight.w700,
                      color: OwnerColors.walnutDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Soft Warm Tip Banner (Matching Inspired Screenshot)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEADBCE), // warm sand/amber tint
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Tip: use headings, bullet points and emojis to make your description stand out to students.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: OwnerColors.walnutDark,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Formatting Toolbar Pills (Matching Inspired Screenshot)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDropdownPill(
                      label: 'Font ▾',
                      onSelected: (font) {
                        // Header styles
                        if (font == 'H1') {
                          _controller.formatSelection(Attribute.h1);
                        } else if (font == 'H2') {
                          _controller.formatSelection(Attribute.h2);
                        } else {
                          _controller.formatSelection(
                              Attribute.clone(Attribute.header, null));
                        }
                        setState(() {});
                      },
                      items: const ['Normal', 'H1', 'H2'],
                    ),
                    const SizedBox(width: 8),
                    _buildDropdownPill(
                      label: 'Size ▾',
                      onSelected: (size) {
                        if (size == 'Large') {
                          _controller.formatSelection(Attribute.h1);
                        } else if (size == 'Medium') {
                          _controller.formatSelection(Attribute.h2);
                        } else {
                          _controller.formatSelection(
                              Attribute.clone(Attribute.header, null));
                        }
                        setState(() {});
                      },
                      items: const ['Regular', 'Medium', 'Large'],
                    ),
                    const SizedBox(width: 8),
                    _buildCircleButton(
                      label: 'B',
                      isActive: isBold,
                      onTap: () => _toggleAttribute(Attribute.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleButton(
                      label: 'I',
                      isActive: isItalic,
                      fontStyle: FontStyle.italic,
                      onTap: () => _toggleAttribute(Attribute.italic),
                    ),
                    const SizedBox(width: 8),
                    _buildToolbarPill(
                      label: '• List',
                      isActive: isBullet,
                      onTap: () => _toggleAttribute(Attribute.ul),
                    ),
                    const SizedBox(width: 8),
                    _buildToolbarPill(
                      label: '1. List',
                      isActive: isNumberList,
                      onTap: () => _toggleAttribute(Attribute.ol),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Editor Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: OwnerColors.borderSubtle,
                    ),
                  ),
                  child: QuillEditor.basic(
                    controller: _controller,
                    config: QuillEditorConfig(
                      placeholder: 'Ghar jaisa swaad',
                      padding: const EdgeInsets.all(20),
                      expands: true,
                      scrollable: true,
                      autoFocus: false,
                      customStyles: DefaultStyles(
                        paragraph: DefaultTextBlockStyle(
                          GoogleFonts.inter(
                            fontSize: 16,
                            color: OwnerColors.walnutDark,
                            height: 1.6,
                          ),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(0, 4),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                        h1: DefaultTextBlockStyle(
                          OwnerTypography.editorialSerif(
                            size: 22,
                            weight: FontWeight.w700,
                            color: OwnerColors.walnutDark,
                          ),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(8, 4),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                        h2: DefaultTextBlockStyle(
                          OwnerTypography.editorialSerif(
                            size: 18,
                            weight: FontWeight.w600,
                            color: OwnerColors.walnutDark,
                          ),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(6, 2),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save Description Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwnerColors.amberGlow,
                    foregroundColor: OwnerColors.textDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: OwnerColors.textDark,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Save description',
                          style: GoogleFonts.inter(
                            fontSize: 16,
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
    );
  }

  Widget _buildDropdownPill({
    required String label,
    required void Function(String) onSelected,
    required List<String> items,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (ctx) => items
          .map((i) => PopupMenuItem(
                value: i,
                child: Text(
                  i,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: OwnerColors.walnutDark,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8DE), // light sage
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E2D),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? OwnerColors.walnutDark
              : const Color(0xFF382C24), // walnut dark circle
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontStyle: fontStyle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? OwnerColors.walnutDark
              : const Color(0xFFE2E8DE), // sage
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF2C3E2D),
          ),
        ),
      ),
    );
  }
}
