import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    AppState.expenses.addListener(_onChanged);
    AppState.totalBudget.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    AppState.expenses.removeListener(_onChanged);
    AppState.totalBudget.removeListener(_onChanged);
    super.dispose();
  }

  // Category totals
  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final e in AppState.expenses.value) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // Top 4 categories for breakdown grid
  List<MapEntry<String, double>> get _topCategories {
    final entries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = AppState.expenses.value;
    final spent = AppState.totalSpent;
    final pct = AppState.budgetPercent;
    final remaining = AppState.remaining;
    final overBudget = remaining < 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('EXPENSES',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showOptionsMenu(context),
                    child: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ]),
              ),
            ),

            // Total + progress
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('TOTAL EXPEDITION SPENT',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(
                    '\$${spent.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          overBudget ? AppColors.danger : AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(overBudget ? 'OVER BUDGET' : 'REMAINING BUDGET',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              letterSpacing: 1)),
                      Text(
                        '\$${remaining.abs().toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            color: overBudget
                                ? AppColors.danger
                                : AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      Text('EFFICIENCY',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              letterSpacing: 1)),
                      Text('${(pct * 100).round()}%',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                ]),
              ),
            ),

            // Breakdown
            if (_topCategories.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Text('Breakdown',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: _topCategories.map((e) {
                      final color = _categoryColor(e.key);
                      return _BreakdownCard(
                        icon: _categoryIcon(e.key),
                        iconColor: color,
                        label: e.key,
                        amount: '\$${e.value.toStringAsFixed(2)}',
                        fraction: spent > 0 ? e.value / spent : 0,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Recent ledger
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('Recent Ledger',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  Text('${expenses.length} items',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 13)),
                ]),
              ),
            ),

            if (expenses.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('No expenses yet',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Tap + to add your first expense',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 12)),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = expenses[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.danger.withOpacity(0.3)),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded,
                            color: AppColors.danger, size: 24),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppColors.card,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text('Delete Expense?',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700)),
                                content: Text(
                                    'Remove "${item.title}" from your ledger?',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Cancel',
                                        style: GoogleFonts.inter(
                                            color: AppColors.textMuted)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.danger,
                                        foregroundColor: Colors.white),
                                    child: Text('Delete',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) => AppState.removeExpense(item.id),
                      child: _ExpenseItem(item: item),
                    );
                  },
                  childCount: expenses.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCat = expenseCategories[0];
    String selectedEmoji = categoryEmojis[expenseCategories[0]] ?? '📦';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Add Expense',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Category
            Row(children: [
              Text('Category',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCat,
                      dropdownColor: AppColors.card,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      items: expenseCategories
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(children: [
                                Text(categoryEmojis[c] ?? '📦'),
                                const SizedBox(width: 8),
                                Text(c),
                              ])))
                          .toList(),
                      onChanged: (v) => setModal(() {
                        selectedCat = v!;
                        selectedEmoji = categoryEmojis[v] ?? '📦';
                      }),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            TextField(
              controller: titleCtrl,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Title (e.g. Karakoram Hotel)',
                prefixIcon:
                    Icon(Icons.label_outline_rounded, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text);
                  if (title.isEmpty || amount == null || amount <= 0) return;

                  final now = DateTime.now();
                  final months = [
                    'JAN','FEB','MAR','APR','MAY','JUN',
                    'JUL','AUG','SEP','OCT','NOV','DEC',
                  ];
                  final dateStr =
                      '${now.day} ${months[now.month - 1]}, ${now.year}';

                  AppState.addExpense(ExpenseItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    date: dateStr,
                    category: selectedCat,
                    amount: amount,
                    emoji: selectedEmoji,
                  ));
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.add_rounded),
                label: Text('Add Expense',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
            title: Text('Edit Budget',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              _showEditBudgetDialog(context);
            },
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            title: Text('Clear All Expenses',
                style: GoogleFonts.inter(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500)),
            onTap: () {
              AppState.expenses.value = [];
              Navigator.pop(context);
            },
            contentPadding: EdgeInsets.zero,
          ),
        ]),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: AppState.totalBudget.value.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Budget',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) AppState.updateBudget(v);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            child: Text('Save',
                style:
                    GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'ACCOMMODATION': return const Color(0xFFFF8855);
      case 'TRANSPORT': return const Color(0xFF4488FF);
      case 'FOOD & DRINK': return AppColors.primary;
      case 'ACTIVITIES': return const Color(0xFF44CC88);
      case 'SOUVENIRS': return const Color(0xFFCC88FF);
      case 'SHOPPING': return const Color(0xFFFF4499);
      case 'MEDICAL': return const Color(0xFF44CCCC);
      default: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'ACCOMMODATION': return Icons.hotel_rounded;
      case 'TRANSPORT': return Icons.local_gas_station_rounded;
      case 'FOOD & DRINK': return Icons.restaurant_rounded;
      case 'ACTIVITIES': return Icons.hiking_rounded;
      case 'SOUVENIRS': return Icons.card_giftcard_rounded;
      case 'SHOPPING': return Icons.shopping_bag_rounded;
      case 'MEDICAL': return Icons.medical_services_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}

// ─── Breakdown Card ───────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;
  final double fraction;

  const _BreakdownCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: iconColor, size: 22),
            Text('${(fraction * 100).round()}%',
                style: GoogleFonts.inter(
                    color: iconColor.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            Text(amount,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

// ─── Expense List Item ────────────────────────────────────────────────────────

class _ExpenseItem extends StatelessWidget {
  final ExpenseItem item;
  const _ExpenseItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child:
                Text(item.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(item.title,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text('${item.date} • ${item.category}',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.3)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '\$${item.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.chevron_left_rounded,
              color: AppColors.textMuted, size: 14),
        ]),
      ]),
    );
  }
}
