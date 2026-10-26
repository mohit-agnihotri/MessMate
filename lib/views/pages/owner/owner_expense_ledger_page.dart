import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'widgets/add_expense_sheet.dart';

class OwnerExpenseLedgerPage extends ConsumerStatefulWidget {
  const OwnerExpenseLedgerPage({super.key});

  @override
  ConsumerState<OwnerExpenseLedgerPage> createState() =>
      _OwnerExpenseLedgerPageState();
}

class _OwnerExpenseLedgerPageState extends ConsumerState<OwnerExpenseLedgerPage> {
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final Map<String, Map<String, dynamic>> _catMeta = {
    'vegetables': {
      'label': 'Sabzi & Mandi',
      'dotColor': Color(0xFF4A6B53),
    },
    'dairy': {
      'label': 'Doodh & Dairy',
      'dotColor': Color(0xFF7B9E87),
    },
    'groceries': {
      'label': 'Ration & Kirana',
      'dotColor': Color(0xFFEAA23E),
    },
    'fuel': {
      'label': 'LPG Gas',
      'dotColor': Color(0xFFBD5D38),
    },
    'staff': {
      'label': 'Cook & Staff',
      'dotColor': Color(0xFF6A1B9A),
    },
    'maintenance': {
      'label': 'Maintenance',
      'dotColor': Color(0xFF455A64),
    },
    'other': {
      'label': 'Miscellaneous',
      'dotColor': Color(0xFF6E645A),
    },
  };

  void _previousMonth(DateTime current) {
    HapticFeedback.selectionClick();
    final prev = DateTime(current.year, current.month - 1, 1);
    ref.read(ownerExpenseLedgerProvider.notifier).changeMonth(prev);
  }

  void _nextMonth(DateTime current) {
    HapticFeedback.selectionClick();
    final next = DateTime(current.year, current.month + 1, 1);
    ref.read(ownerExpenseLedgerProvider.notifier).changeMonth(next);
  }

  Future<void> _shareReport(ExpenseLedgerState state) async {
    final mName = _months[state.selectedMonth.month - 1];
    final year = state.selectedMonth.year;

    final buffer = StringBuffer();
    buffer.writeln("📊 *MEZZO KHAATA REPORT • $mName $year*");
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");
    buffer.writeln("🟢 *Total Fees Collected:* ₹${state.totalCollectedFees.toInt()} (${state.paidStudentsCount} paid)");
    buffer.writeln("🔴 *Total Kharcha (Expenses):* ₹${state.totalExpenses.toInt()} (${state.expenses.length} entries)");
    buffer.writeln("💰 *Net Cash In-Hand Profit:* ${state.netCashProfit >= 0 ? '+' : ''}₹${state.netCashProfit.toInt()}");
    if (state.totalPendingFees > 0) {
      buffer.writeln("⏳ *Pending Fees:* ₹${state.totalPendingFees.toInt()} (${state.pendingStudentsCount} unpaid)");
      buffer.writeln("📈 *Projected Profit at 100% Collection:* ₹${state.projectedProfit.toInt()}");
    }
    if (state.totalActiveStudents > 0) {
      buffer.writeln("👥 *Cost per Active Student:* ₹${state.perStudentCost.toInt()}");
    }
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");
    buffer.writeln("📋 *Category Breakdown:*");
    state.categoryBreakdown.forEach((cat, amt) {
      final label = _catMeta[cat]?['label'] ?? cat;
      buffer.writeln("  • $label: ₹${amt.toInt()}");
    });
    buffer.writeln("\n_Generated via Mezzo Khaata & P&L_");

    final encoded = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse("whatsapp://send?text=$encoded");
    final webUrl = Uri.parse("https://api.whatsapp.com/send?text=$encoded");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: buffer.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report copied to clipboard! 📋'),
            backgroundColor: Color(0xFF2D231C),
          ),
        );
      }
    }
  }

  void _showExpenseOptions(ExpenseModel exp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D0C7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              exp.title,
              style: GoogleFonts.newsreader(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF231A14),
              ),
            ),
            Text(
              '₹${exp.amount.toInt()} · ${_catMeta[exp.category]?['label'] ?? exp.category}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6E645A),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_rounded, color: Color(0xFF2D231C)),
              title: Text(
                'Edit Expense',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                AddExpenseSheet.show(context, expenseToEdit: exp);
              },
            ),
            const Divider(height: 1, color: Color(0x182D231C)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
              title: Text(
                'Delete Expense',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteExpense(exp);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpense(ExpenseModel exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Kharcha?',
          style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${exp.title}" (₹${exp.amount.toInt()}) from your ledger?',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF231A14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF6E645A)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(ownerExpenseLedgerProvider.notifier).deleteExpense(exp.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted from ledger.'),
                    backgroundColor: Color(0xFF2D231C),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerExpenseLedgerProvider);
    final selectedMonth = state.selectedMonth;
    final monthName = _months[selectedMonth.month - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFE6),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header (Screenshots 1 & 2)
            _buildAppBar(context, state),

            // Month Switcher Floating Pill (Screenshots 1 & 2)
            _buildMonthSwitcher(selectedMonth, monthName),

            // Main Content Area
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2D231C)),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF2D231C),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await ref
                            .read(ownerExpenseLedgerProvider.notifier)
                            .changeMonth(selectedMonth);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                        children: [
                          // 1. Hero Card: NET CASH PROFIT · THIS MONTH (Screenshots 1 & 2)
                          _buildNetCashProfitHeroCard(state),
                          const SizedBox(height: 14),

                          // 2. Projections Card: IF EVERY STUDENT PAYS (Screenshots 1 & 2)
                          _buildProjectionsCard(state),
                          const SizedBox(height: 16),

                          // 3. Category Breakdown: WHERE THE MONEY GOES (Screenshots 1 & 2)
                          _buildWhereTheMoneyGoesSection(state),
                          const SizedBox(height: 18),

                          // 4. Expense Entries Header Row (Screenshots 1 & 2)
                          _buildExpenseEntriesHeader(state),
                          const SizedBox(height: 10),

                          // 5. Entries List or Empty State (Screenshots 1 & 2)
                          if (state.expenses.isEmpty)
                            _buildEmptyState()
                          else
                            _buildExpenseItemsList(state),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      // Bottom Floating CTA Button: "+ Log kitchen kharcha" (Screenshots 1 & 2)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => AddExpenseSheet.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAA23E),
              foregroundColor: const Color(0xFF231A14),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF231A14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFFEAA23E),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Log kitchen kharcha',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF231A14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top App Bar (Screenshots 1 & 2) ──────────────────────────────
  Widget _buildAppBar(BuildContext context, ExpenseLedgerState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE5DFD3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Color(0xFF231A14),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khaata & P&L',
                  style: GoogleFonts.newsreader(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF231A14),
                    height: 1.15,
                  ),
                ),
                Text(
                  'Daily ration & kitchen expense',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6E645A),
                  ),
                ),
              ],
            ),
          ),

          // Share Report Pill Button (Screenshots 1 & 2)
          GestureDetector(
            onTap: () => _shareReport(state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE2EBE2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.north_east_rounded,
                    size: 13,
                    color: Color(0xFF2E5A36),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Share report',
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
    );
  }

  // ── 2. Month Switcher Bar (Screenshots 1 & 2) ───────────────────────
  Widget _buildMonthSwitcher(DateTime selectedMonth, String monthName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x182D231C)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left < Button
          GestureDetector(
            onTap: () => _previousMonth(selectedMonth),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE5DFD3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: Color(0xFF231A14),
              ),
            ),
          ),

          // Middle Month Text: 📅 October 2026
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📅', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '$monthName ${selectedMonth.year}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF231A14),
                ),
              ),
            ],
          ),

          // Right > Button
          GestureDetector(
            onTap: () => _nextMonth(selectedMonth),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE5DFD3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF231A14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Net Cash Profit Hero Card (Screenshots 1 & 2) ────────────────
  Widget _buildNetCashProfitHeroCard(ExpenseLedgerState state) {
    final isProfitable = state.netCashProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38291F), Color(0xFF211914)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overline Row: NET CASH PROFIT · THIS MONTH
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET CASH PROFIT · THIS MONTH',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: const Color(0xFFE8B676),
                ),
              ),
              if (state.expenses.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Live khaata',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Big Serif Number: +₹3630
          Text(
            '${isProfitable ? '+' : ''}₹${state.netCashProfit.toInt()}',
            style: GoogleFonts.newsreader(
              fontSize: 46,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF6E8CE),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),

          // Embedded Equation Box (Screenshots 1 & 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Fees collected
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fees collected',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${state.totalCollectedFees.toInt()}',
                        style: GoogleFonts.newsreader(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7FB069),
                        ),
                      ),
                      Text(
                        '${state.paidStudentsCount} paid',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),

                // Minus Sign
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '—',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Kitchen kharcha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kitchen kharcha',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${state.totalExpenses.toInt()}',
                        style: GoogleFonts.newsreader(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE57373),
                        ),
                      ),
                      Text(
                        '${state.expenses.length} entries',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),

                // Equals Sign
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '=',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),

                // In-hand
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'In-hand',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isProfitable ? '+' : ''}₹${state.netCashProfit.toInt()}',
                        style: GoogleFonts.newsreader(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF6E8CE),
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
    );
  }

  // ── 4. Projections Card: IF EVERY STUDENT PAYS (Screenshots 1 & 2) ──
  Widget _buildProjectionsCard(ExpenseLedgerState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x182D231C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overline: IF EVERY STUDENT PAYS
          Text(
            'IF EVERY STUDENT PAYS',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF4A684C),
            ),
          ),
          const SizedBox(height: 12),

          // 3 Columns: Pending fees | Projected profit | Cost / student
          Row(
            children: [
              // Pending fees
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending fees',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${state.totalPendingFees.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.pendingStudentsCount} student${state.pendingStudentsCount == 1 ? '' : 's'} unpaid',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                  ],
                ),
              ),

              // Projected profit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projected profit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${state.projectedProfit.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'at 100% collection',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                  ],
                ),
              ),

              // Cost / student
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost / student',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${state.perStudentCost.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.totalActiveStudents} active members',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. Category Breakdown: WHERE THE MONEY GOES (Screenshots 1 & 2) ─
  Widget _buildWhereTheMoneyGoesSection(ExpenseLedgerState state) {
    final breakdown = state.categoryBreakdown;
    final total = state.totalExpenses;

    final mandiAmt = breakdown['vegetables'] ?? 0.0;
    final dairyAmt = breakdown['dairy'] ?? 0.0;
    final kiranaAmt = breakdown['groceries'] ?? 0.0;
    final lpgAmt = breakdown['fuel'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: WHERE THE MONEY GOES + Pill "All kharcha ₹..."
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WHERE THE MONEY GOES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: const Color(0xFF4A684C),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2D231C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'All kharcha ₹${total.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAF7F2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2x2 Grid of Category Cards (Screenshots 1 & 2)
        Row(
          children: [
            Expanded(
              child: _buildCategoryProgressCard(
                label: 'Sabzi & Mandi',
                amount: mandiAmt,
                total: total,
                dotColor: const Color(0xFF4A6B53),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryProgressCard(
                label: 'Doodh & Dairy',
                amount: dairyAmt,
                total: total,
                dotColor: const Color(0xFF7B9E87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCategoryProgressCard(
                label: 'Ration & Kirana',
                amount: kiranaAmt,
                total: total,
                dotColor: const Color(0xFFEAA23E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryProgressCard(
                label: 'LPG Gas',
                amount: lpgAmt,
                total: total,
                dotColor: const Color(0xFFBD5D38),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryProgressCard({
    required String label,
    required double amount,
    required double total,
    required Color dotColor,
  }) {
    final double fraction = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x182D231C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + Category Label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF231A14),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Amount in Serif
          Text(
            '₹${amount.toInt()}',
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF231A14),
            ),
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: const Color(0xFFE5DFD3),
              valueColor: AlwaysStoppedAnimation<Color>(dotColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Expense Entries Header Row (Screenshots 1 & 2) ───────────────
  Widget _buildExpenseEntriesHeader(ExpenseLedgerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'EXPENSE ENTRIES (${state.expenses.length})',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: const Color(0xFF4A684C),
          ),
        ),
        Text(
          'Today\'s spent: ₹${state.todayExpenses.toInt()}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF231A14),
          ),
        ),
      ],
    );
  }

  // ── 7. Empty State (Screenshot 1) ──────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x182D231C)),
      ),
      child: Column(
        children: [
          // Icon Circle
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEFE8DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF8C7E72),
              size: 26,
            ),
          ),
          const SizedBox(height: 16),

          // Headline
          Text(
            'No kharcha logged yet',
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF231A14),
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'Log mandi sabzi, milk, ration or gas to see your real monthly profit and loss.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6E645A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Log First Expense Pill
          GestureDetector(
            onTap: () => AddExpenseSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF3CE92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+ Log first expense',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5A3805),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. Expense Items List (Screenshot 2) ───────────────────────────
  Widget _buildExpenseItemsList(ExpenseLedgerState state) {
    return Column(
      children: state.expenses.map((exp) {
        final meta = _catMeta[exp.category] ?? _catMeta['other']!;
        final dotColor = meta['dotColor'] as Color;
        final categoryLabel = meta['label'] as String;

        return GestureDetector(
          onTap: () => _showExpenseOptions(exp),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x142D231C)),
            ),
            child: Row(
              children: [
                // Squircle Category Color Block (Screenshot 2)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),

                // Item Title & Category Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoryLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6E645A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Payment Mode (Screenshot 2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${exp.amount.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp.paymentMode.toUpperCase() == 'UPI' ? 'UPI' : 'Cash',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E645A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
