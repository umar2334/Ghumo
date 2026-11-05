import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Creates or edits a trip. Returns the trip when saved.
Future<Trip?> showTripForm(BuildContext context, {Trip? trip, String? destinationId}) {
  return showAppSheet<Trip>(
    context,
    builder: (_) => _TripForm(trip: trip, destinationId: destinationId ?? trip?.destinationId),
  );
}

class _TripForm extends StatefulWidget {
  const _TripForm({this.trip, this.destinationId});
  final Trip? trip;
  final String? destinationId;

  @override
  State<_TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<_TripForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.trip?.name ?? (destinationById(widget.destinationId) == null ? '' : '${destinationById(widget.destinationId)!.name} trip'),
  );
  late final _budget = TextEditingController(
    text: (widget.trip?.budget ?? 0) > 0 ? widget.trip!.budget.round().toString() : '',
  );
  late String? _destinationId = widget.destinationId;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.read(context);
    final budget = parseAmount(_budget.text) ?? 0;
    final trip = widget.trip;
    if (trip == null) {
      Navigator.pop(context, store.createTrip(name: _name.text.trim(), budget: budget, destinationId: _destinationId));
    } else {
      store.updateTrip(trip, name: _name.text.trim(), budget: budget, destinationId: _destinationId);
      Navigator.pop(context, trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetTitle(widget.trip == null ? 'New trip' : 'Edit trip'),
        TextFormField(
          key: const Key('trip-name'),
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Trip name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Give your trip a name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('trip-budget'),
          controller: _budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Budget (optional)', prefixText: 'Rs '),
          validator: (v) => (v ?? '').trim().isNotEmpty && parseAmount(v!) == null ? 'Enter a valid amount' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _destinationId,
          isExpanded: true,
          dropdownColor: AppColors.card,
          decoration: const InputDecoration(labelText: 'Main destination (optional)'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('None')),
            for (final d in destinations) DropdownMenuItem(value: d.id, child: Text(d.name)),
          ],
          onChanged: (v) => setState(() => _destinationId = v),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('trip-save'),
          onPressed: _save,
          child: Text(widget.trip == null ? 'Create trip' : 'Save changes', style: txt(15, weight: 700, color: Colors.black)),
        ),
      ]),
    );
  }
}
