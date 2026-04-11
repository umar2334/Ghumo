import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/weather_service.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  WeatherData? _weather;

  @override
  void initState() {
    super.initState();
    // Listen for state changes
    AppState.stops.addListener(_onStopsChanged);
    AppState.expenses.addListener(_onExpensesChanged);
    // Fetch weather for Hunza (current expedition)
    WeatherService.fetchWeather(36.3167, 74.6500).then((w) {
      if (mounted) setState(() => _weather = w);
    });
  }

  void _onStopsChanged() => setState(() {});
  void _onExpensesChanged() => setState(() {});

  @override
  void dispose() {
    AppState.stops.removeListener(_onStopsChanged);
    AppState.expenses.removeListener(_onExpensesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStopDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Text('GHUMO',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      )),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showOptionsMenu(context),
                    icon: const Icon(Icons.more_horiz_rounded,
                        color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              ),
            ),

            // Expedition header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('CURRENT EXPEDITION',
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2)),
                      const Spacer(),
                      if (_weather != null) ...[
                        Text(_weather!.icon,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(_weather!.tempStr,
                            style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: 'HUNZA ',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        TextSpan(
                            text: 'VALLEY',
                            style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Managing your 7-day northern odyssey\nthrough the Karakoram.',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Budget tracker
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _BudgetCard(onEditBudget: () => _showEditBudgetDialog(context)),
              ),
            ),

            // Timeline header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trip Timeline',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    Text(
                        '${AppState.stops.value.where((s) => s.isCompleted).length}/${AppState.stops.value.length} done',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),

            // Timeline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: List.generate(AppState.stops.value.length, (i) {
                    final stop = AppState.stops.value[i];
                    return _TimelineStop(
                      stop: stop,
                      isLast: i == AppState.stops.value.length - 1,
                      onToggle: () {
                        AppState.toggleComplete(i);
                      },
                    );
                  }),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showAddStopDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPhase = tripPhases[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Add Trip Stop',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Phase selector
            Row(children: [
              Text('Phase',
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
                      value: selectedPhase,
                      dropdownColor: AppColors.card,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      items: tripPhases
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p)))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedPhase = v!),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Stop name (e.g. Passu Cones)',
                prefixIcon: Icon(Icons.place_rounded,
                    color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded,
                    color: AppColors.textMuted),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  AppState.addStop(TripStop(
                    number: 0,
                    phase: selectedPhase,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.add_rounded),
                label: Text('Add to Timeline',
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

  void _showEditBudgetDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: AppState.totalBudget.value.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Budget',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: GoogleFonts.inter(
                color: AppColors.primary, fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          autofocus: true,
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
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
          _OptionTile(Icons.share_rounded, 'Share Itinerary', () => Navigator.pop(context)),
          _OptionTile(Icons.picture_as_pdf_rounded, 'Export as PDF', () => Navigator.pop(context)),
          _OptionTile(Icons.delete_outline_rounded, 'Clear Completed', () {
            final list = AppState.stops.value
                .where((s) => !s.isCompleted)
                .toList();
            AppState.stops.value = list;
            Navigator.pop(context);
          }, color: AppColors.danger),
        ]),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _OptionTile(this.icon, this.label, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label,
          style: GoogleFonts.inter(color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ─── Budget Card ─────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final VoidCallback onEditBudget;
  const _BudgetCard({required this.onEditBudget});

  @override
  Widget build(BuildContext context) {
    final spent = AppState.totalSpent;
    final budget = AppState.totalBudget.value;
    final pct = AppState.budgetPercent;
    final remaining = AppState.remaining;
    final overBudget = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('BUDGET TRACKER',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
          GestureDetector(
            onTap: onEditBudget,
            child: Row(children: [
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.inter(
                      color: overBudget ? AppColors.danger : AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded,
                  color: AppColors.textMuted, size: 14),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
                overBudget ? AppColors.danger : AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SPENT',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1)),
              Text('\$${spent.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(overBudget ? 'OVER BUDGET' : 'REMAINING',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1)),
              Text(
                '\$${remaining.abs().toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                    color: overBudget ? AppColors.danger : AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BUDGET',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1)),
              Text('\$${budget.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ]),
    );
  }
}

// ─── Timeline ────────────────────────────────────────────────────────────────

class _TimelineStop extends StatelessWidget {
  final TripStop stop;
  final bool isLast;
  final VoidCallback onToggle;

  const _TimelineStop(
      {required this.stop, required this.isLast, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final dotColor = stop.isCompleted
        ? AppColors.primary
        : stop.isInProgress
            ? AppColors.primary
            : AppColors.textMuted;

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Dot + line
        SizedBox(
          width: 32,
          child: Column(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: stop.isCompleted ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: dotColor,
                    width: stop.isCompleted ? 0 : 2),
              ),
              child: stop.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.black, size: 8)
                  : null,
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 1,
                  color: stop.isCompleted
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.divider,
                ),
              ),
          ]),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('0${stop.number}',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Text(stop.phase,
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5)),
                const Spacer(),
                // Toggle complete checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: stop.isCompleted
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: stop.isCompleted
                            ? AppColors.primary
                            : AppColors.textMuted,
                        width: 1.5,
                      ),
                    ),
                    child: stop.isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.black, size: 16)
                        : null,
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              if (stop.isCompleted && stop.temperature != null)
                _CompletedCard(stop: stop)
              else if (stop.isInProgress)
                _InProgressCard(stop: stop)
              else
                _PendingCard(stop: stop),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final TripStop stop;
  const _CompletedCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkSlate.withOpacity(0.4),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkSlate, AppColors.surface],
            ),
          ),
          child: Stack(children: [
            Center(
              child: Icon(Icons.water_rounded,
                  color: AppColors.primary.withOpacity(0.2), size: 80),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(stop.temperature ?? '',
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.5))),
                child: Text('✓ DONE',
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(stop.name,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            if (stop.hotel != null) ...[
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CHECK-IN',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 1)),
                Text(stop.hotel!,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(width: 20),
            ],
            if (stop.activity != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ACTIVITY',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 1)),
                Text(stop.activity!,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text('DETAILS',
                  style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _InProgressCard extends StatelessWidget {
  final TripStop stop;
  const _InProgressCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surface,
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Stack(children: [
          Center(child: Icon(Icons.terrain_rounded,
              color: AppColors.textMuted, size: 50)),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('● IN PROGRESS',
                  style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(stop.name,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        const Icon(Icons.more_vert_rounded,
            color: AppColors.textMuted, size: 18),
      ]),
      if (stop.description != null) ...[
        const SizedBox(height: 4),
        Text(stop.description!,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
      ],
      if (stop.tags != null && stop.tags!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: stop.tags!.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(tag,
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          const Icon(Icons.add_circle_outline_rounded,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text('Add an afternoon activity...',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('SUGGESTED: HOPPER GLACIER',
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ),
        ]),
      ),
    ]);
  }
}

class _PendingCard extends StatelessWidget {
  final TripStop stop;
  const _PendingCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.lock_clock_rounded,
            color: AppColors.textMuted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            stop.description ?? 'Planning in progress for ${stop.name}',
            style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
        ),
      ]),
    );
  }
}
