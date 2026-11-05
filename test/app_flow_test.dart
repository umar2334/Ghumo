import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/data/destinations.dart';
import 'package:ghumo/main.dart';
import 'package:ghumo/models/models.dart';
import 'package:ghumo/screens/expenses_screen.dart';
import 'package:ghumo/screens/planner_screen.dart';
import 'package:ghumo/state/app_scope.dart';
import 'package:ghumo/state/app_store.dart';
import 'package:ghumo/state/storage.dart';

import 'support/harness.dart';

void main() {
  Future<AppStore> pumpApp(WidgetTester tester, {bool onboarded = true, bool online = true, Size size = const Size(360, 780)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = await tester.runAsync(() => AppStore.load(MemoryStorage()));
    if (onboarded) store!.completeOnboarding();
    await tester.pumpWidget(GhumoApp(store: store!, services: fakeServices(online: online)));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows the welcome screen once', (tester) async {
    final store = await pumpApp(tester, onboarded: false);
    expect(find.text('Start exploring'), findsOneWidget);
    await tester.tap(find.text('Start exploring'));
    await tester.pumpAndSettle();
    expect(find.textContaining('explore next?', findRichText: true), findsOneWidget);
    expect(store.onboarded, isTrue);
  });

  testWidgets('search and category filters narrow destinations', (tester) async {
    await pumpApp(tester);
    expect(find.text('${destinations.length} destinations'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('explore-search')), 'mohenjo');
    await tester.pump();
    expect(find.text('1 destination'), findsOneWidget);
    expect(find.text('Mohenjo-daro'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('explore-search')), 'zzzz');
    await tester.pump();
    expect(find.text('Nothing matches your search'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    expect(find.text('${destinations.length} destinations'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Coast'),
      100,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(find.text('Coast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coast'));
    await tester.pumpAndSettle();
    expect(find.text('2 destinations'), findsOneWidget);
  });

  testWidgets('saving a place shows it in the Saved tab and can be removed', (tester) async {
    final store = await pumpApp(tester);
    await tester.tap(find.byTooltip('Save Hunza Valley'));
    await tester.pump();
    expect(store.isSaved('hunza'), isTrue);

    await openTab(tester, 'Saved');
    expect(find.text('Hunza Valley'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Hunza Valley from saved'));
    await tester.pumpAndSettle();
    expect(find.text('No saved places yet'), findsOneWidget);
  });

  testWidgets('destination details show the forecast and add to a new trip', (tester) async {
    final store = await pumpApp(tester);
    await tester.tap(find.text('Hunza Valley'));
    await tester.pumpAndSettle();
    expect(find.text('Baltit Fort'), findsOneWidget);
    expect(find.text('8°C'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('add-to-trip')), 200);
    await tester.tap(find.byKey(const Key('add-to-trip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trip-save')));
    await tester.pumpAndSettle();
    expect(store.activeTrip!.name, 'Hunza Valley trip');
    expect(store.activeTrip!.stops.single.destinationId, 'hunza');
    expect(find.text('Added to "Hunza Valley trip"'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-trip')));
    await tester.pump();
    expect(store.activeTrip!.stops, hasLength(1), reason: 'duplicates are not added');
  });

  testWidgets('weather failure shows an error with a working retry', (tester) async {
    await pumpApp(tester, online: false);
    await tester.tap(find.text('Hunza Valley'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load weather. Check your connection.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('create a trip with validation, then add and tick a stop', (tester) async {
    final store = await pumpApp(tester);
    await openTab(tester, 'Planner');
    expect(find.text('Plan your first trip'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-trip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trip-save')));
    await tester.pump();
    expect(find.text('Give your trip a name'), findsOneWidget);
    expect(store.trips, isEmpty);

    await tester.enterText(find.byKey(const Key('trip-name')), 'Skardu 2027');
    await tester.enterText(find.byKey(const Key('trip-budget')), '50,000');
    await tester.tap(find.byKey(const Key('trip-save')));
    await tester.pumpAndSettle();
    expect(find.text('Skardu 2027'), findsOneWidget);
    expect(store.activeTrip!.budget, 50000);

    await tester.tap(find.byKey(const Key('add-stop')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('stop-name')), 'Deosai');
    await tester.tap(find.byKey(const Key('stop-save')));
    await tester.pumpAndSettle();
    expect(find.text('Deosai'), findsOneWidget);
    expect(find.text('0/1 done'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(find.text('1/1 done'), findsOneWidget);
  });

  testWidgets('add, validate, total and swipe-delete with undo on expenses', (tester) async {
    final store = await pumpApp(tester);
    store.createTrip(name: 'Trip', budget: 1000);
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-title')), 'Jeep hire');
    await tester.enterText(find.byKey(const Key('expense-amount')), '-5');
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pump();
    expect(find.text('Enter an amount above zero'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('expense-amount')), '1,500');
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('total-spent'))).data, 'Rs 1,500');
    expect(find.text('Rs 500 over your Rs 1,000 budget'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Jeep hire'), 100);
    await tester.drag(find.text('Jeep hire'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(store.activeTrip!.expenses, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.activeTrip!.expenses, hasLength(1));
  });

  testWidgets('expenses explain that a trip is needed when there is none', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('No trip yet'), findsOneWidget);
  });

  testWidgets('checklist items can be added, ticked and removed', (tester) async {
    final store = await pumpApp(tester);
    await openTab(tester, 'Saved');
    await tester.tap(find.text('Packing'));
    await tester.pumpAndSettle();
    final start = store.checklist.length;

    await tester.enterText(find.byKey(const Key('checklist-input')), 'Trekking poles');
    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();
    expect(store.checklist.length, start + 1);

    await tester.tap(find.text('Power bank'));
    await tester.pumpAndSettle();
    expect(find.text('1 of ${start + 1} packed'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Power bank'));
    await tester.pumpAndSettle();
    expect(find.text('Power bank'), findsNothing);
  });

  testWidgets('show on map switches to the map tab', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('explore-search')), 'skardu');
    await tester.pump();
    await tester.tap(find.text('Skardu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Show on map'), 200);
    await tester.tap(find.text('Show on map'));
    await tester.pumpAndSettle();
    final nav = AppScope.nav(tester.element(find.byType(Scaffold).first));
    expect(nav.tab.value, AppNavigation.mapTab);
    expect(nav.mapTarget.value, isNull, reason: 'the target was consumed by the map');
    expect(find.text('Baltistan, Gilgit-Baltistan'), findsWidgets);
  });

  testWidgets('every main screen fits a small phone without overflow', (tester) async {
    final store = await pumpApp(tester, size: const Size(320, 568));
    store.createSampleTrip();
    await tester.pumpAndSettle();
    for (final tab in ['Map', 'Planner', 'Saved', 'Explore']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('share text includes the real trip details', () async {
    final store = await AppStore.load(MemoryStorage());
    final trip = store.createTrip(name: 'Hunza', budget: 2000);
    store.addStop(trip, name: 'Passu', day: 2, notes: 'Bridge');
    store.addExpense(trip, title: 'Tea', amount: 200, category: ExpenseCategory.food);
    expect(itineraryText(trip), allOf(contains('Hunza'), contains('Day 2: Passu'), contains('Bridge'), contains('Rs 2,000')));
    expect(expenseSummaryText(trip), allOf(contains('Total: Rs 200'), contains('Food & drink: Rs 200'), contains('Tea')));
  });
}
