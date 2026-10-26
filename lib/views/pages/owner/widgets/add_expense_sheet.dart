import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/app_models.dart';
import '../../../../viewmodels/all_viewmodels.dart';
import '../theme/owner_inspired_theme.dart';

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
      'icon': Icons.eco_rounded,
      'color': Color(0xFF2E7D32),
      'presets': ['Mandi Sabzi', 'Aalu & Pyaaz', 'Tamatar & Mirchi', 'Hari Sabziyan'],
    },
    {
      'id': 'dairy',
      'label': 'Doodh & Dairy',
      'icon': Icons.local_drink_rounded,
      'color': Color(0xFF0288D1),
      'presets': ['Amul Doodh (10L)', 'Paneer & Dahi', 'Khoya & Butter', 'Fresh Milk'],
    },
    {
      'id': 'groceries',
      'label': 'Ration & Kirana',
      'icon': Icons.shopping_basket_rounded,
      'color': Color(0xFFE65100),
      'presets': ['Atta (50kg)', 'Basmati Rice', 'Dal & Pulses', 'Cooking Oil (15L)', 'Spices & Masala'],
    },
    {
      'id': 'fuel',
      'label': 'LPG Gas',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFD32F2F),
      'presets': ['Commercial Cylinder 19kg', 'LPG Refill', 'Stove Repair'],
    },
    {
      'id': 'staff',
      'label': 'Cook & Staff',
      'icon': Icons.badge_rounded,
      'color': Color(0xFF6A1B9A),
      'presets': ['Maharaj Advance', 'Cook Salary', 'Helper Wages', 'Dishwasher Payment'],
    },
    {
      'id': 'maintenance',
      'label': 'Maintenance',
      'icon': Icons.build_rounded,
      'color': Color(0xFF455A64),
      'presets': ['Vessel & Bartan', 'Plumbing & Tap', 'RO Filter Service', 'Cleaning Detergent'],
    },
    {
      'id': 'other',
      'label': 'Miscellaneous',
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFF616161),
      'presets': ['Disposables / Dona-Pattal', 'Packaging Poly', 'Electricity Bill'],
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
              primary: OwnerColors.walnut,
              onPrimary: Colors.white,
              onSurface: OwnerColors.textDark,
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
                const SizedBox(width: 10),
                Text(
                  widget.expenseToEdit != null
                      ? 'Expense updated successfully!'
                      : '₹${amount.toInt()} logged in Kharcha!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
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

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 20),
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

            // Sheet Title & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Kharcha' : 'Log Kitchen Kharcha',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.textDark,
                      ),
                    ),
                    Text(
                      'Daily Ration & Kitchen Ledger (खाता)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OwnerColors.textMuted,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OwnerColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: OwnerColors.walnut,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: OwnerColors.walnut,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Big Amount Input Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OwnerColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '₹',
                    style: GoogleFonts.newsreader(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.walnut,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: OwnerColors.textDark,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Color(0xFFC7BCB3)),
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

            // Quick Amount Adder Pills
            Wrap(
              spacing: 8,
              children: [100, 500, 1000, 2000].map((addVal) {
                return ActionChip(
                  label: Text('+₹$addVal'),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OwnerColors.walnut,
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: OwnerColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final current = double.tryParse(_amountController.text) ?? 0.0;
                    _amountController.text = (current + addVal).toInt().toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Category Picker
            Text(
              'CATEGORY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: OwnerColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = cat['id'] == _selectedCategory;
                  final color = cat['color'] as Color;

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
                      duration: const Duration(milliseconds: 180),
                      width: 86,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? OwnerColors.walnut : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? OwnerColors.walnut : OwnerColors.borderSubtle,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: OwnerColors.walnut.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 24,
                            color: isSelected ? OwnerColors.amber : color,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['label'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : OwnerColors.textDark,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Item Title & Smart Preset Chips
            Text(
              'ITEM / DESCRIPTION',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: OwnerColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OwnerColors.borderSubtle),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'e.g. Mandi Sabzi, Amul Doodh',
                  hintStyle: TextStyle(color: Color(0xFFB0A8A0), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quick suggestion chips for the selected category
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _currentPresets.map((preset) {
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _titleController.text = preset;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EBE1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Payment Mode Toggle: Cash vs UPI
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENT MODE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: OwnerColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8DE),
                          borderRadius: BorderRadius.circular(14),
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
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _paymentMode == 'cash'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _paymentMode == 'cash'
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                            )
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.payments_outlined, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cash',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
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
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _paymentMode == 'upi'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _paymentMode == 'upi'
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                            )
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Online / UPI',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Optional Notes
            Text(
              'NOTES (OPTIONAL)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: OwnerColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OwnerColors.borderSubtle),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _notesController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Shopkeeper name, bill no., quantity etc.',
                  hintStyle: TextStyle(color: Color(0xFFB0A8A0), fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwnerColors.walnut,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'Update Kharcha' : 'Save in Kharcha Ledger',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
