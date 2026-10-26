import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final ExpenseModel? expenseToEdit;

  const AddExpenseSheet({super.key, this.expenseToEdit});

  static Future<void> show(BuildContext context, {ExpenseModel? expenseToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(expenseToEdit: expenseToEdit),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'vegetables';
  String _paymentMode = 'cash'; // 'cash' or 'upi'
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'vegetables',
      'label': 'Sabzi & Mandi',
      'dotColor': Color(0xFF4A6B53),
      'presets': ['Mandi Sabzi', 'Aalu & Pyaaz', 'Tamatar & Mirchi', 'Hari Sabziyan'],
    },
    {
      'id': 'dairy',
      'label': 'Doodh & Dairy',
      'dotColor': Color(0xFF7B9E87),
      'presets': ['Amul Doodh', 'Paneer & Dahi', 'Khoya & Butter', 'Fresh Milk'],
    },
    {
      'id': 'groceries',
      'label': 'Ration & Kirana',
      'dotColor': Color(0xFFEAA23E),
      'presets': ['Atta (Wheat)', 'Chawal (Rice)', 'Cooking Oil', 'Daal & Masale'],
    },
    {
      'id': 'fuel',
      'label': 'LPG Gas',
      'dotColor': Color(0xFFBD5D38),
      'presets': ['LPG cylinder', 'Commercial 19kg', 'Gas Refill'],
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _amountController.text = e.amount.toStringAsFixed(0);
      _titleController.text = e.title;
      _notesController.text = e.notes ?? '';
      _selectedCategory = e.category;
      _paymentMode = e.paymentMode;
      _selectedDate = e.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _currentPresets {
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return cat['presets'] as List<String>;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D231C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF231A14),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final amtText = _amountController.text.trim();
    final amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount (₹)'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    String title = _titleController.text.trim();
    if (title.isEmpty) {
      final cat = _categories.firstWhere((c) => c['id'] == _selectedCategory);
      title = cat['label'] as String;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final notifier = ref.read(ownerExpenseLedgerProvider.notifier);
      if (widget.expenseToEdit != null) {
        final updated = widget.expenseToEdit!.copyWith(
          amount: amount,
          category: _selectedCategory,
          title: title,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          date: _selectedDate,
          paymentMode: _paymentMode,
        );
        await notifier.updateExpense(updated);
      } else {
        await notifier.addExpense(
          amount: amount,
          category: _selectedCategory,
          title: title,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          date: _selectedDate,
          paymentMode: _paymentMode,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.expenseToEdit != null
                      ? 'Expense updated successfully! 💰'
                      : 'Kharcha saved in ledger! 💰',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2D231C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.expenseToEdit != null;
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
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
                  color: const Color(0xFFD8D0C7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title & Date Row (Screenshot 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit kitchen kharcha' : 'Log kitchen kharcha',
                        style: GoogleFonts.newsreader(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daily ration & kitchen ledger (खाता)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF6E645A),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EBE2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E5A36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Big Amount Input Card (Screenshot 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x182D231C)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '₹',
                    style: GoogleFonts.newsreader(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.newsreader(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.newsreader(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC7BCB3),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      autofocus: !isEdit,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Quick Add Pills: +₹100, +₹500, +₹1000, +₹2000 (Screenshot 3)
            Row(
              children: [100, 500, 1000, 2000].map((addVal) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final current = double.tryParse(_amountController.text) ?? 0.0;
                        _amountController.text = (current + addVal).toInt().toString();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2EBE2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+₹$addVal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E5A36),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // CATEGORY Section (Screenshot 3)
            Text(
              'CATEGORY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: const Color(0xFF4A684C),
              ),
            ),
            const SizedBox(height: 8),

            // 2x2 Grid of Category Tiles (Screenshot 3)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCategoryTile(_categories[0])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCategoryTile(_categories[1])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCategoryTile(_categories[2])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCategoryTile(_categories[3])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ITEM Section (Screenshot 3)
            Text(
              'ITEM',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: const Color(0xFF4A684C),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x182D231C)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'e.g. Mandi sabzi, Amul doodh',
                  hintStyle: TextStyle(color: Color(0xFFB0A8A0), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dynamic Preset Chips for the selected category (Screenshot 3)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _currentPresets.map((preset) {
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _titleController.text = preset;
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EBE2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E5A36),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Payment Mode Segmented Toggle: Cash vs Online / UPI (Screenshot 3)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2EBE2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _paymentMode = 'cash');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paymentMode == 'cash'
                              ? const Color(0xFF2D231C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cash',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _paymentMode == 'cash'
                                ? const Color(0xFFFAF7F2)
                                : const Color(0xFF2E5A36),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _paymentMode = 'upi');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paymentMode == 'upi'
                              ? const Color(0xFF2D231C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Online / UPI',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _paymentMode == 'upi'
                                ? const Color(0xFFFAF7F2)
                                : const Color(0xFF2E5A36),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Optional Notes (Screenshot 3)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x182D231C)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _notesController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Notes (optional): shopkeeper, bill no., quantity',
                  hintStyle: TextStyle(color: Color(0xFFB0A8A0), fontSize: 12.5),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Big Amber CTA Button (Screenshot 3)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA23E),
                  foregroundColor: const Color(0xFF231A14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Color(0xFF231A14),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update in kharcha ledger' : 'Save in kharcha ledger',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> cat) {
    final isSelected = cat['id'] == _selectedCategory;
    final dotColor = cat['dotColor'] as Color;
    final label = cat['label'] as String;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = cat['id'] as String;
          if (_titleController.text.isEmpty) {
            _titleController.text = (cat['presets'] as List<String>).first;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF231A14) : const Color(0x182D231C),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF231A14),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
