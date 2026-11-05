import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/data/destinations.dart';

void main() {
  test('ids are unique', () {
    expect(destinations.map((d) => d.id).toSet().length, destinations.length);
  });

  test('every destination is inside Pakistan\'s bounding box and fully described', () {
    for (final d in destinations) {
      expect(d.lat, inInclusiveRange(23.5, 37.2), reason: d.name);
      expect(d.lon, inInclusiveRange(60.8, 77.9), reason: d.name);
      expect(d.description, isNotEmpty, reason: d.name);
      expect(d.highlights, isNotEmpty, reason: d.name);
      expect(d.gettingThere, isNotEmpty, reason: d.name);
      expect(['Easy', 'Moderate', 'Challenging'], contains(d.difficulty), reason: d.name);
    }
  });

  test('search matches name, region and highlights, ignoring case', () {
    final hunza = destinationById('hunza')!;
    expect(hunza.matches('HUNZA'), isTrue);
    expect(hunza.matches('gilgit-baltistan'), isTrue);
    expect(hunza.matches('baltit'), isTrue);
    expect(hunza.matches('karachi'), isFalse);
    expect(hunza.matches('  '), isTrue);
  });

  test('destinationById handles unknown and null ids', () {
    expect(destinationById(null), isNull);
    expect(destinationById('nope'), isNull);
  });
}
