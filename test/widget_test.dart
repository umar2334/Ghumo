import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GhumoApp());
    expect(find.byType(GhumoApp), findsOneWidget);
  });
}
