@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/main.dart';
import 'package:ghumo/state/app_store.dart';
import 'package:ghumo/state/storage.dart';

import 'support/harness.dart';

/// Renders the README screenshots with the real fonts and sample weather.
void main() {
  testWidgets('screenshots', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = await tester.runAsync(() => AppStore.load(MemoryStorage()));
    store!.completeOnboarding();
    store.createSampleTrip();
    store.toggleSaved('skardu');
    store.toggleSaved('hunza');
    await tester.pumpWidget(GhumoApp(store: store, services: fakeServices()));
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../docs/screenshots/$name.png'));
    }

    await shot('explore');
    await tester.tap(find.text('Hunza Valley'));
    await tester.pumpAndSettle();
    await shot('destination');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planner'));
    await tester.pumpAndSettle();
    await shot('planner');
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Safety'));
    await tester.pumpAndSettle();
    await shot('safety');
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    await shot('expenses');
  });
}
