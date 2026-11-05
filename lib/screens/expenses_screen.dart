import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/trip_form.dart';

/// Plain-text trip spending summary, used for sharing.
String expenseSummaryText(Trip trip) {
  final b = StringBuffer('${trip.name}: expenses\nTotal: ${formatPkr(trip.totalSpent)}\n');
  for (final entry in trip.spendByCategory) {
    b.write('${entry.key.label}: ${formatPkr(entry.value)}\n');
  }
  b.write('\n');
  for (final e in trip.expensesByDate) {
    b.write('${formatDate(e.date)}  ${e.title}  ${formatPkr(e.amount)}\n');
  }
  return b.toString();
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = AppScope.store(context).activeTrip;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Expenses', style: txt(18, weight: 700)),
        actions: [
          if (trip != null && trip.expenses.isNotEmpty)
            IconButton(
              tooltip: 'Share summary',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => Share.share(expenseSummaryText(trip), subject: trip.name),
            ),
          if (trip != null)
            IconButton(
              tooltip: 'Edit budget',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => showTripForm(context, trip: trip),
            ),
        ],
      ),
      floatingActionButton: trip == null
          ? null
          : FloatingActionButton(
              key: const Key('add-expense'),
              tooltip: 'Add expense',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              onPressed: () => showAppSheet<void>(context, builder: (_) => _ExpenseForm(trip: trip)),
              child: const Icon(Icons.add_rounded),
            ),
      body: trip == null
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No trip yet',
                  message: 'Expenses belong to a trip. Create one to start tracking your spending.',
                  actions: [
                    ElevatedButton(
                      onPressed: () => showTripForm(context),
                      child: Text('Create a trip', style: txt(15, weight: 700, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            )
          : _ExpenseList(trip: trip),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final expenses = trip.expensesByDate;
    final total = trip.totalSpent;
    final over = trip.isOverBudget;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 96), children: [
      Text(trip.name, style: txt(13, weight: 600, color: AppColors.primary)),
      const SizedBox(height: 6),
      Text(formatPkr(total), key: const Key('total-spent'), style: txt(38, weight: 800)),
      const SizedBox(height: 10),
      if (trip.budget > 0) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: trip.budgetUsed,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            color: over ? AppColors.danger : AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          over
              ? '${formatPkr(-trip.remaining)} over your ${formatPkr(trip.budget)} budget'
              : '${formatPkr(trip.remaining)} left of ${formatPkr(trip.budget)}',
          style: txt(13, color: over ? AppColors.danger : AppColors.textSecondary),
        ),
      ],
      if (expenses.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('By category', style: txt(16, weight: 600)),
        const SizedBox(height: 12),
        for (final entry in trip.spendByCategory)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(children: [
              Row(children: [
                Icon(entry.key.icon, color: entry.key.color, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.key.label, style: txt(13))),
                Text(formatPkr(entry.value), style: txt(13, weight: 600)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: total > 0 ? entry.value / total : 0,
                  minHeight: 4,
                  backgroundColor: AppColors.divider,
                  color: entry.key.color,
                ),
              ),
            ]),
          ),
      ],
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('All expenses', style: txt(16, weight: 600)),
        Text('${expenses.length}', style: txt(13, color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 10),
      if (expenses.isEmpty)
        const EmptyState(icon: Icons.receipt_long_rounded, title: 'Nothing spent yet', message: 'Tap + to add your first expense.'),
      for (final e in expenses)
        Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_rounded, color: AppColors.danger),
          ),
          onDismissed: (_) {
            final store = AppScope.read(context);
            store.removeExpense(trip, e);
            showMessage(
              context,
              'Removed "${e.title}"',
              action: SnackBarAction(label: 'Undo', onPressed: () => store.restoreExpense(trip, e)),
            );
          },
          child: _ExpenseTile(trip: trip, expense: e),
        ),
    ]);
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.trip, required this.expense});
  final Trip trip;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showAppSheet<void>(context, builder: (_) => _ExpenseForm(trip: trip, expense: e)),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: e.category.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(11)),
              child: Icon(e.category.icon, color: e.category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: txt(14, weight: 600)),
                const SizedBox(height: 2),
                Text('${formatDate(e.date)} · ${e.category.label}', style: txt(11, color: AppColors.textMuted)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(formatPkr(e.amount), style: txt(14, weight: 700)),
          ]),
        ),
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({required this.trip, this.expense});
  final Trip trip;
  final Expense? expense;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.expense?.title);
  late final _amount = TextEditingController(
    text: widget.expense == null ? '' : widget.expense!.amount.toStringAsFixed(widget.expense!.amount % 1 == 0 ? 0 : 2),
  );
  late ExpenseCategory _category = widget.expense?.category ?? ExpenseCategory.food;
  late DateTime _date = widget.expense?.date ?? DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.read(context);
    final amount = parseAmount(_amount.text)!;
    final title = _title.text.trim();
    if (widget.expense == null) {
      store.addExpense(widget.trip, title: title, amount: amount, category: _category, date: _date);
    } else {
      store.updateExpense(widget.expense!, title: title, amount: amount, category: _category, date: _date);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetTitle(widget.expense == null ? 'Add expense' : 'Edit expense'),
        TextFormField(
          key: const Key('expense-title'),
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What was it for?'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('expense-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs '),
          validator: (v) => parseAmount(v ?? '') == null ? 'Enter an amount above zero' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ExpenseCategory>(
          initialValue: _category,
          isExpanded: true,
          dropdownColor: AppColors.card,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final c in ExpenseCategory.values)
              DropdownMenuItem(
                value: c,
                child: Row(children: [Icon(c.icon, color: c.color, size: 18), const SizedBox(width: 10), Text(c.label)]),
              ),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 4),
        ActionTile(icon: Icons.calendar_today_rounded, label: formatDate(_date), color: AppColors.textSecondary, onTap: _pickDate),
        const SizedBox(height: 12),
        ElevatedButton(
          key: const Key('expense-save'),
          onPressed: _save,
          child: Text(widget.expense == null ? 'Add expense' : 'Save changes', style: txt(15, weight: 700, color: Colors.black)),
        ),
      ]),
    );
  }
}
