import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'theme/owner_inspired_theme.dart';
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
      'icon': Icons.eco_rounded,
      'color': Color(0xFF2E7D32),
    },
    'dairy': {
      'label': 'Doodh & Dairy',
      'icon': Icons.local_drink_rounded,
      'color': Color(0xFF0288D1),
    },
    'groceries': {
      'label': 'Ration & Kirana',
      'icon': Icons.shopping_basket_rounded,
      'color': Color(0xFFE65100),
    },
    'fuel': {
      'label': 'LPG Gas',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFD32F2F),
    },
    'staff': {
      'label': 'Cook & Staff',
      'icon': Icons.badge_rounded,
      'color': Color(0xFF6A1B9A),
    },
    'maintenance': {
      'label': 'Maintenance',
      'icon': Icons.build_rounded,
      'color': Color(0xFF455A64),
    },
    'other': {
      'label': 'Miscellaneous',
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFF616161),
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

  Future<void> _shareWhatsAppReport(ExpenseLedgerState state) async {
    final mName = _months[state.selectedMonth.month - 1];
    final year = state.selectedMonth.year;

    final buffer = StringBuffer();
    buffer.writeln("📊 *MEZZO KHAATA REPORT • $mName $year*");
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");
    buffer.writeln("🟢 *Total Fees Collected:* ₹${state.totalCollectedFees.toInt()} (${state.paidStudentsCount} paid)");
    buffer.writeln("🔴 *Total Kharcha (Expenses):* ₹${state.totalExpenses.toInt()}");
    buffer.writeln("💰 *Net Cash In-Hand Profit:* ₹${state.netCashProfit.toInt()}");
    if (state.totalPendingFees > 0) {
      buffer.writeln("⏳ *Pending Fees:* ₹${state.totalPendingFees.toInt()} (${state.pendingStudentsCount} unpaid)");
      buffer.writeln("📈 *Projected Final Profit:* ₹${state.projectedProfit.toInt()}");
    }
    if (state.totalActiveStudents > 0) {
      buffer.writeln("👥 *Food Cost per Student:* ₹${state.perStudentCost.toInt()}");
    }
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");
    buffer.writeln("📋 *Category Breakdown:*");
    state.categoryBreakdown.forEach((cat, amt) {
      final label = _catMeta[cat]?['label'] ?? cat;
      buffer.writeln("  • $label: ₹${amt.toInt()}");
    });
    buffer.writeln("\n_Generated via Mezzo App_");

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
            content: Text('Report copied to clipboard!'),
            backgroundColor: OwnerColors.walnut,
          ),
        );
      }
    }
  }

  void _confirmDeleteExpense(ExpenseModel exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Kharcha?',
          style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${exp.title}" (₹${exp.amount.toInt()}) from your ledger?',
          style: GoogleFonts.inter(fontSize: 13, color: OwnerColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: OwnerColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(ownerExpenseLedgerProvider.notifier).deleteExpense(exp.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted from ledger.'),
                    backgroundColor: OwnerColors.textDark,
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
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, state),
            _buildMonthSwitcher(selectedMonth, monthName),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: OwnerColors.walnut),
                    )
                  : RefreshIndicator(
                      color: OwnerColors.walnut,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await ref
                            .read(ownerExpenseLedgerProvider.notifier)
                            .changeMonth(selectedMonth);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                        children: [
                          _buildProfitLossHeroCard(state),
                          const SizedBox(height: 16),
                          _buildCategoryBreakdownCarousel(state),
                          const SizedBox(height: 16),
                          _buildExpensesSectionHeader(state),
                          const SizedBox(height: 10),
                          if (state.filteredExpenses.isEmpty)
                            _buildEmptyState(state)
                          else
                            _buildGroupedExpenseList(state),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => AddExpenseSheet.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: OwnerColors.walnut,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: OwnerColors.walnut.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: OwnerColors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: OwnerColors.textDark, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Log Kitchen Kharcha (खर्चा जोड़ें)',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top App Bar ────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, ExpenseLedgerState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6F0),
        border: Border(bottom: BorderSide(color: OwnerColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: OwnerColors.textDark,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY RATION & EXPENSE',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: OwnerColors.textMuted,
                    ),
                  ),
                  Text(
                    'Khaata & P&L Ledger',
                    style: GoogleFonts.newsreader(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: OwnerColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => _shareWhatsAppReport(state),
            icon: const Icon(Icons.share_rounded, size: 20),
            color: OwnerColors.walnut,
            tooltip: 'Share Report on WhatsApp',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: OwnerColors.borderSubtle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Month Switcher Bar ─────────────────────────────────────────────────────
  Widget _buildMonthSwitcher(DateTime selectedMonth, String monthName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _previousMonth(selectedMonth),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            color: OwnerColors.walnut,
            visualDensity: VisualDensity.compact,
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: OwnerColors.amber),
              const SizedBox(width: 8),
              Text(
                '$monthName ${selectedMonth.year}',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: OwnerColors.walnutDark,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _nextMonth(selectedMonth),
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            color: OwnerColors.walnut,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Profit & Loss Hero Card ────────────────────────────────────────────────
  Widget _buildProfitLossHeroCard(ExpenseLedgerState state) {
    final isProfitable = state.netCashProfit >= 0;

    return Container(
      decoration: BoxDecoration(
        color: OwnerColors.walnutDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTHLY FINANCIAL HEALTH',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: const Color(0xFFC7BCB3),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfitable
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.25)
                      : const Color(0xFFC62828).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isProfitable ? const Color(0xFF81C784) : const Color(0xFFE57373),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 13,
                      color: isProfitable ? const Color(0xFF81C784) : const Color(0xFFE57373),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProfitable ? 'In-Hand Profit' : 'Cash Deficit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isProfitable ? const Color(0xFF81C784) : const Color(0xFFE57373),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Big Stat Pillars
          Row(
            children: [
              // Collected
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collected Fees',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFC7BCB3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${state.totalCollectedFees.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF81C784),
                      ),
                    ),
                    Text(
                      '${state.paidStudentsCount} paid',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),

              // Total Expenses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kharcha',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFC7BCB3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${state.totalExpenses.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF8A80),
                      ),
                    ),
                    Text(
                      '${state.expenses.length} entries',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),

              // Net Profit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Cash Profit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFC7BCB3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isProfitable ? '+' : ''}₹${state.netCashProfit.toInt()}',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: OwnerColors.amber,
                      ),
                    ),
                    Text(
                      'in-hand cash',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 14),

          // Secondary Sub-Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubMetric(
                label: 'Pending Fees',
                value: '₹${state.totalPendingFees.toInt()}',
                note: '${state.pendingStudentsCount} students unpaid',
              ),
              _buildSubMetric(
                label: 'Projected Profit',
                value: '₹${state.projectedProfit.toInt()}',
                note: 'upon 100% collection',
              ),
              _buildSubMetric(
                label: 'Cost / Student',
                value: '₹${state.perStudentCost.toInt()}',
                note: '${state.totalActiveStudents} active members',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required String label,
    required String value,
    required String note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFC7BCB3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          note,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            color: const Color(0xFF8D837B),
          ),
        ),
      ],
    );
  }

  // ── Category Breakdown Carousel & Filter Chips ─────────────────────────────
  Widget _buildCategoryBreakdownCarousel(ExpenseLedgerState state) {
    final activeFilter = state.selectedCategoryFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CATEGORY SPEND',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: OwnerColors.textMuted,
              ),
            ),
            if (activeFilter != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(ownerExpenseLedgerProvider.notifier)
                      .setCategoryFilter('all');
                },
                child: Text(
                  'Clear Filter',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.walnut,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 78,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // "All" chip
              _buildCategoryPill(
                id: 'all',
                label: 'All Kharcha',
                icon: Icons.dashboard_outlined,
                color: OwnerColors.walnut,
                amount: state.totalExpenses,
                isSelected: activeFilter == null || activeFilter == 'all',
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(ownerExpenseLedgerProvider.notifier)
                      .setCategoryFilter('all');
                },
              ),
              const SizedBox(width: 8),

              ..._catMeta.entries.map((entry) {
                final id = entry.key;
                final meta = entry.value;
                final amt = state.categoryBreakdown[id] ?? 0.0;
                final isSelected = activeFilter == id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryPill(
                    id: id,
                    label: meta['label'] as String,
                    icon: meta['icon'] as IconData,
                    color: meta['color'] as Color,
                    amount: amt,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(ownerExpenseLedgerProvider.notifier)
                          .setCategoryFilter(id);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required double amount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? OwnerColors.walnut : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? OwnerColors.walnut : OwnerColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? OwnerColors.amber : color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : OwnerColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '₹${amount.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? OwnerColors.amber : OwnerColors.walnutDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Expenses Section Header ────────────────────────────────────────────────
  Widget _buildExpensesSectionHeader(ExpenseLedgerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'EXPENSE ENTRIES (${state.filteredExpenses.length})',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: OwnerColors.textMuted,
          ),
        ),
        Text(
          'Today\'s Spent: ₹${state.todayExpenses.toInt()}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: OwnerColors.walnut,
          ),
        ),
      ],
    );
  }

  // ── Grouped Expense List by Date ───────────────────────────────────────────
  Widget _buildGroupedExpenseList(ExpenseLedgerState state) {
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final exp in state.filteredExpenses) {
      final dateKey = '${exp.date.year}-${exp.date.month.toString().padLeft(2, '0')}-${exp.date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(exp);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    return Column(
      children: sortedDates.map((dateKey) {
        final list = grouped[dateKey]!;
        final dayTotal = list.fold(0.0, (sum, i) => sum + i.amount);

        String headerTitle;
        if (dateKey == todayKey) {
          headerTitle = 'Today • ${list.first.date.day} ${_months[list.first.date.month - 1]}';
        } else if (dateKey == yesterdayKey) {
          headerTitle = 'Yesterday • ${list.first.date.day} ${_months[list.first.date.month - 1]}';
        } else {
          headerTitle = '${list.first.date.day} ${_months[list.first.date.month - 1]} ${list.first.date.year}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OwnerColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F3EB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                  border: Border(bottom: BorderSide(color: OwnerColors.borderSubtle)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      headerTitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                    Text(
                      'Day Total: ₹${dayTotal.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: OwnerColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Items
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 60,
                  color: OwnerColors.borderSubtle,
                ),
                itemBuilder: (context, i) {
                  final exp = list[i];
                  final meta = _catMeta[exp.category] ?? _catMeta['other']!;
                  final catColor = meta['color'] as Color;
                  final catIcon = meta['icon'] as IconData;

                  return InkWell(
                    onTap: () => AddExpenseSheet.show(context, expenseToEdit: exp),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Category Icon Box
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(catIcon, color: catColor, size: 20),
                          ),
                          const SizedBox(width: 12),

                          // Title and details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        exp.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: OwnerColors.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: exp.paymentMode == 'cash'
                                            ? const Color(0xFFECEFF1)
                                            : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        exp.paymentMode.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: exp.paymentMode == 'cash'
                                              ? const Color(0xFF546E7A)
                                              : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    exp.notes!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: OwnerColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Amount & More Action
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${exp.amount.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: OwnerColors.walnutDark,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFB0A8A0)),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteExpense(exp),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(ExpenseLedgerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwnerColors.borderSubtle),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4ECE1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 36,
                color: OwnerColors.walnut,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No kharcha logged yet',
              style: GoogleFonts.newsreader(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: OwnerColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log your daily Mandi sabzi, milk, ration, or gas expenses to see your real monthly profit & loss.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: OwnerColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => AddExpenseSheet.show(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log First Expense'),
              style: OutlinedButton.styleFrom(
                foregroundColor: OwnerColors.walnut,
                side: const BorderSide(color: OwnerColors.walnut),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
