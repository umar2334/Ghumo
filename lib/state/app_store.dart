import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/destinations.dart';
import '../models/models.dart';
import 'storage.dart';

/// Single source of truth for user data. Every change is saved on the device.
class AppStore extends ChangeNotifier {
  AppStore._(this._storage);

  final AppStorage _storage;
  final List<Trip> _trips = [];
  final Set<String> _savedIds = {};
  final List<ChecklistItem> _checklist = [];
  String? _activeTripId;
  bool _onboarded = false;
  int _idCounter = 0;
  Future<void> _lastWrite = Future.value();

  static Future<AppStore> load(AppStorage storage) async {
    final store = AppStore._(storage);
    String? raw;
    try {
      raw = await storage.read();
    } catch (e) {
      debugPrint('Could not read saved data: $e');
    }
    store._restore(raw);
    return store;
  }

  void _restore(String? raw) {
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final trips = (json['trips'] as List? ?? [])
            .map((t) => Trip.fromJson(t as Map<String, dynamic>))
            .toList();
        final checklist = (json['checklist'] as List?)
            ?.map((c) => ChecklistItem.fromJson(c as Map<String, dynamic>))
            .toList();
        _trips.addAll(trips);
        _savedIds.addAll((json['savedIds'] as List? ?? []).cast<String>());
        _activeTripId = json['activeTripId'] as String?;
        _onboarded = json['onboarded'] as bool? ?? false;
        if (checklist != null) {
          _checklist.addAll(checklist);
          return;
        }
      } catch (e) {
        // Corrupt data must not stop the app from opening.
        debugPrint('Ignoring unreadable saved data: $e');
        _trips.clear();
        _savedIds.clear();
        _activeTripId = null;
      }
    }
    _seedChecklist();
  }

  void _seedChecklist() {
    _checklist
      ..clear()
      ..addAll(defaultChecklist.map((l) => ChecklistItem(id: _newId(), label: l)));
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  Map<String, dynamic> toJson() => {
        'trips': _trips.map((t) => t.toJson()).toList(),
        'savedIds': _savedIds.toList(),
        'checklist': _checklist.map((c) => c.toJson()).toList(),
        'activeTripId': _activeTripId,
        'onboarded': _onboarded,
      };

  void _commit() {
    notifyListeners();
    final data = jsonEncode(toJson());
    _lastWrite = _lastWrite.then((_) => _storage.write(data)).catchError((Object e) {
      debugPrint('Could not save data: $e');
    });
  }

  /// Completes when all pending changes have been written.
  Future<void> flush() => _lastWrite;

  // ─── Onboarding ───────────────────────────────────────────────────────────

  bool get onboarded => _onboarded;

  void completeOnboarding() {
    _onboarded = true;
    _commit();
  }

  // ─── Saved places ─────────────────────────────────────────────────────────

  bool isSaved(String destinationId) => _savedIds.contains(destinationId);

  List<Destination> get savedDestinations =>
      destinations.where((d) => _savedIds.contains(d.id)).toList();

  void toggleSaved(String destinationId) {
    if (!_savedIds.remove(destinationId)) _savedIds.add(destinationId);
    _commit();
  }

  // ─── Trips ────────────────────────────────────────────────────────────────

  List<Trip> get trips => List.unmodifiable(_trips);

  Trip? get activeTrip {
    for (final t in _trips) {
      if (t.id == _activeTripId) return t;
    }
    return _trips.isEmpty ? null : _trips.first;
  }

  Trip createTrip({required String name, double budget = 0, String? destinationId}) {
    final trip = Trip(id: _newId(), name: name, budget: budget, destinationId: destinationId);
    _trips.add(trip);
    _activeTripId = trip.id;
    _commit();
    return trip;
  }

  /// Adds a clearly labelled demo trip for people who want to try the app.
  Trip createSampleTrip() {
    final now = DateTime.now();
    final trip = Trip(
      id: _newId(),
      name: 'Sample: Hunza in a week',
      budget: 150000,
      destinationId: 'hunza',
      isSample: true,
      stops: [
        TripStop(id: _newId(), name: 'Gilgit', day: 1, destinationId: 'gilgit', notes: 'Fly in from Islamabad and restock supplies.'),
        TripStop(id: _newId(), name: 'Hunza Valley', day: 2, destinationId: 'hunza', notes: 'Visit Baltit and Altit forts.'),
        TripStop(id: _newId(), name: 'Attabad Lake', day: 4, destinationId: 'attabad'),
        TripStop(id: _newId(), name: 'Passu', day: 5, destinationId: 'passu', notes: 'Hussaini bridge and the Passu Cones.'),
        TripStop(id: _newId(), name: 'Khunjerab Pass', day: 6, destinationId: 'khunjerab', notes: 'Take warm layers and go slowly at altitude.'),
      ],
      expenses: [
        Expense(id: _newId(), title: 'Sample: Flight to Gilgit', amount: 28000, category: ExpenseCategory.transport, date: now),
        Expense(id: _newId(), title: 'Sample: Guesthouse in Karimabad', amount: 12000, category: ExpenseCategory.stay, date: now),
        Expense(id: _newId(), title: 'Sample: Dinner', amount: 2500, category: ExpenseCategory.food, date: now),
      ],
    );
    _trips.add(trip);
    _activeTripId = trip.id;
    _commit();
    return trip;
  }

  void updateTrip(Trip trip, {required String name, required double budget, String? destinationId}) {
    trip
      ..name = name
      ..budget = budget
      ..destinationId = destinationId;
    _commit();
  }

  void deleteTrip(Trip trip) {
    _trips.removeWhere((t) => t.id == trip.id);
    if (_activeTripId == trip.id) {
      _activeTripId = _trips.isEmpty ? null : _trips.last.id;
    }
    _commit();
  }

  void setActiveTrip(Trip trip) {
    _activeTripId = trip.id;
    _commit();
  }

  // ─── Stops ────────────────────────────────────────────────────────────────

  TripStop addStop(Trip trip, {required String name, int? day, String? notes, String? destinationId}) {
    final stop = TripStop(id: _newId(), name: name, day: day, notes: notes, destinationId: destinationId);
    trip.stops.add(stop);
    _commit();
    return stop;
  }

  void updateStop(TripStop stop, {required String name, int? day, String? notes}) {
    stop
      ..name = name
      ..day = day
      ..notes = notes;
    _commit();
  }

  void toggleStop(TripStop stop) {
    stop.done = !stop.done;
    _commit();
  }

  void removeStop(Trip trip, TripStop stop) {
    trip.stops.removeWhere((s) => s.id == stop.id);
    _commit();
  }

  /// Moves a stop up (-1) or down (+1). Out-of-range moves are ignored.
  void moveStop(Trip trip, TripStop stop, int delta) {
    final from = trip.stops.indexWhere((s) => s.id == stop.id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= trip.stops.length) return;
    trip.stops.insert(to, trip.stops.removeAt(from));
    _commit();
  }

  // ─── Expenses ─────────────────────────────────────────────────────────────

  Expense addExpense(Trip trip, {required String title, required double amount, required ExpenseCategory category, DateTime? date}) {
    final expense = Expense(id: _newId(), title: title, amount: amount, category: category, date: date ?? DateTime.now());
    trip.expenses.add(expense);
    _commit();
    return expense;
  }

  void updateExpense(Expense expense, {required String title, required double amount, required ExpenseCategory category, required DateTime date}) {
    expense
      ..title = title
      ..amount = amount
      ..category = category
      ..date = date;
    _commit();
  }

  void removeExpense(Trip trip, Expense expense) {
    trip.expenses.removeWhere((e) => e.id == expense.id);
    _commit();
  }

  void restoreExpense(Trip trip, Expense expense) {
    trip.expenses.add(expense);
    _commit();
  }

  // ─── Checklist ────────────────────────────────────────────────────────────

  List<ChecklistItem> get checklist => List.unmodifiable(_checklist);

  void toggleChecklist(ChecklistItem item) {
    item.checked = !item.checked;
    _commit();
  }

  void addChecklistItem(String label) {
    _checklist.add(ChecklistItem(id: _newId(), label: label));
    _commit();
  }

  void removeChecklistItem(ChecklistItem item) {
    _checklist.removeWhere((c) => c.id == item.id);
    _commit();
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  void resetAll() {
    _trips.clear();
    _savedIds.clear();
    _activeTripId = null;
    _seedChecklist();
    _commit();
  }
}
