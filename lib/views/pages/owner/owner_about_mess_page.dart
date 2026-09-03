import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../viewmodels/all_viewmodels.dart';

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
          content: Text('Saved successfully!'),
          backgroundColor: Color(0xFF22C55E),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'More About My Mess',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Hint banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF0FDF4),
            child: Text(
              'Tip: Use H1/H2 for section headings, bullet points for lists, and emojis like 🍽 ⭐ ⚠️ to make your description look great for students.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF166534),
              ),
            ),
          ),
          // Formatting toolbar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: false,
                showStrikeThrough: false,
                showListBullets: true,
                showListNumbers: true,
                showHeaderStyle: true,
                showIndent: false,
                showLink: false,
                showUndo: true,
                showRedo: true,
                showClearFormat: false,
                showCodeBlock: false,
                showQuote: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showAlignmentButtons: false,
                showDirection: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showDividers: true,
              ),
            ),
          ),
          // Editor
          Expanded(
            child: QuillEditor.basic(
              controller: _controller,
              config: QuillEditorConfig(
                placeholder: 'Write about your mess here... (e.g. 🍽 About Our Mess)',
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                expands: true,
                scrollable: true,
                autoFocus: false,
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF111827),
                      height: 1.6,
                    ),
                    const HorizontalSpacing(0, 0),
                    const VerticalSpacing(0, 4),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  h1: DefaultTextBlockStyle(
                    GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                    const HorizontalSpacing(0, 0),
                    const VerticalSpacing(8, 4),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  h2: DefaultTextBlockStyle(
                    GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
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
        ],
      ),
    );
  }
}
