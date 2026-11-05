import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/models/models.dart';
import 'package:ghumo/state/app_store.dart';
import 'package:ghumo/state/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MemoryStorage storage;
  late AppStore store;

  Future<AppStore> reopen() async {
    await store.flush();
    return AppStore.load(MemoryStorage(storage.value));
  }

  setUp(() async {
    storage = MemoryStorage();
    store = await AppStore.load(storage);
  });

  group('expenses and budget', () {
    test('totals, remaining and over-budget are calculated', () {
      final trip = store.createTrip(name: 'North', budget: 1000);
      store.addExpense(trip, title: 'Hotel', amount: 600, category: ExpenseCategory.stay);
      store.addExpense(trip, title: 'Fuel', amount: 300, category: ExpenseCategory.transport);
      expect(trip.totalSpent, 900);
      expect(trip.remaining, 100);
      expect(trip.isOverBudget, isFalse);
      expect(trip.budgetUsed, closeTo(0.9, 0.001));

      store.addExpense(trip, title: 'Jeep', amount: 250, category: ExpenseCategory.transport);
      expect(trip.isOverBudget, isTrue);
      expect(trip.remaining, -150);
      expect(trip.budgetUsed, 1.0, reason: 'progress is clamped');
    });

    test('a zero budget does not divide by zero', () {
      final trip = store.createTrip(name: 'No budget');
      store.addExpense(trip, title: 'Tea', amount: 100, category: ExpenseCategory.food);
      expect(trip.budgetUsed, 0);
    });

    test('spending by category is sorted, largest first', () {
      final trip = store.createTrip(name: 'T');
      store.addExpense(trip, title: 'a', amount: 10, category: ExpenseCategory.food);
      store.addExpense(trip, title: 'b', amount: 50, category: ExpenseCategory.stay);
      store.addExpense(trip, title: 'c', amount: 15, category: ExpenseCategory.food);
      expect(trip.spendByCategory.map((e) => e.key), [ExpenseCategory.stay, ExpenseCategory.food]);
      expect(trip.spendByCategory.last.value, 25);
    });

    test('expenses sort newest first; edit, delete and undo work', () {
      final trip = store.createTrip(name: 'T');
      final old = store.addExpense(trip, title: 'old', amount: 1, category: ExpenseCategory.food, date: DateTime(2026, 1, 1));
      final recent = store.addExpense(trip, title: 'new', amount: 2, category: ExpenseCategory.food, date: DateTime(2026, 2, 1));
      expect(trip.expensesByDate.first, recent);

      store.updateExpense(old, title: 'older', amount: 5, category: ExpenseCategory.other, date: DateTime(2026, 3, 1));
      expect(trip.expensesByDate.first.title, 'older');

      store.removeExpense(trip, old);
      expect(trip.expenses, hasLength(1));
      store.restoreExpense(trip, old);
      expect(trip.expenses, hasLength(2));
    });
  });

  group('trips and stops', () {
    test('a new trip becomes active; deleting falls back to another', () {
      final a = store.createTrip(name: 'A');
      final b = store.createTrip(name: 'B');
      expect(store.activeTrip, b);
      store.setActiveTrip(a);
      expect(store.activeTrip, a);
      store.deleteTrip(a);
      expect(store.activeTrip, b);
      store.deleteTrip(b);
      expect(store.activeTrip, isNull);
    });

    test('stops move within bounds and toggle', () {
      final trip = store.createTrip(name: 'T');
      final one = store.addStop(trip, name: '1');
      final two = store.addStop(trip, name: '2');
      store.moveStop(trip, two, -1);
      expect(trip.stops.first, two);
      store.moveStop(trip, two, -1);
      expect(trip.stops.first, two, reason: 'moving past the top is ignored');
      store.toggleStop(one);
      expect(trip.completedStops, 1);
      store.removeStop(trip, one);
      expect(trip.stops, [two]);
    });

    test('the sample trip is labelled as a sample', () {
      final trip = store.createSampleTrip();
      expect(trip.isSample, isTrue);
      expect(trip.name, startsWith('Sample'));
      expect(trip.expenses.every((e) => e.title.startsWith('Sample')), isTrue);
    });
  });

  group('persistence', () {
    test('everything survives a restart', () async {
      final trip = store.createTrip(name: 'North', budget: 5000, destinationId: 'hunza');
      store.addStop(trip, name: 'Passu', day: 3, notes: 'Bridge', destinationId: 'passu');
      store.toggleStop(trip.stops.first);
      store.addExpense(trip, title: 'Hotel', amount: 1200.5, category: ExpenseCategory.stay, date: DateTime(2026, 5, 1));
      store.toggleSaved('skardu');
      store.addChecklistItem('Trekking poles');
      store.toggleChecklist(store.checklist.first);
      store.completeOnboarding();

      final again = await reopen();
      final t = again.activeTrip!;
      expect(t.name, 'North');
      expect(t.budget, 5000);
      expect(t.destinationId, 'hunza');
      expect(t.stops.single.day, 3);
      expect(t.stops.single.notes, 'Bridge');
      expect(t.stops.single.done, isTrue);
      expect(t.expenses.single.amount, 1200.5);
      expect(t.expenses.single.category, ExpenseCategory.stay);
      expect(t.expenses.single.date, DateTime(2026, 5, 1));
      expect(again.isSaved('skardu'), isTrue);
      expect(again.checklist.last.label, 'Trekking poles');
      expect(again.checklist.first.checked, isTrue);
      expect(again.onboarded, isTrue);
    });

    test('the active trip is remembered', () async {
      final a = store.createTrip(name: 'A');
      store.createTrip(name: 'B');
      store.setActiveTrip(a);
      expect((await reopen()).activeTrip!.name, 'A');
    });

    test('corrupt saved data does not crash the app', () async {
      for (final bad in ['not json', '{"trips": 5}', '{"trips":[{"id":1}]}']) {
        final s = await AppStore.load(MemoryStorage(bad));
        expect(s.trips, isEmpty, reason: bad);
        expect(s.checklist, isNotEmpty, reason: 'defaults are restored for: $bad');
      }
    });

    test('an unknown expense category falls back to Other', () {
      expect(ExpenseCategory.fromName('removed-category'), ExpenseCategory.other);
    });

    test('reset erases user data', () async {
      store.createSampleTrip();
      store.toggleSaved('hunza');
      store.resetAll();
      final again = await reopen();
      expect(again.trips, isEmpty);
      expect(again.isSaved('hunza'), isFalse);
      expect(again.checklist, isNotEmpty);
    });

    test('works through the real SharedPreferences storage', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppStore.load(SharedPrefsStorage());
      first.createTrip(name: 'Prefs trip');
      await first.flush();
      final second = await AppStore.load(SharedPrefsStorage());
      expect(second.activeTrip!.name, 'Prefs trip');
    });
  });
}
