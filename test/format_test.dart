import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/utils/format.dart';

void main() {
  test('formatPkr groups thousands and handles negatives', () {
    expect(formatPkr(0), 'Rs 0');
    expect(formatPkr(950), 'Rs 950');
    expect(formatPkr(12500), 'Rs 12,500');
    expect(formatPkr(1234567.4), 'Rs 1,234,567');
    expect(formatPkr(-2500), '-Rs 2,500');
  });

  test('parseAmount accepts positive numbers only', () {
    expect(parseAmount('1,500'), 1500);
    expect(parseAmount(' 99.5 '), 99.5);
    expect(parseAmount('0'), isNull);
    expect(parseAmount('-5'), isNull);
    expect(parseAmount('abc'), isNull);
    expect(parseAmount(''), isNull);
  });

  test('formatDuration and formatDistance', () {
    expect(formatDuration(600), '10 min');
    expect(formatDuration(3600), '1 h');
    expect(formatDuration(5400), '1 h 30 min');
    expect(formatDistance(0.4), '400 m');
    expect(formatDistance(96.78), '96.8 km');
    expect(formatDistance(612.2), '612 km');
  });

  test('formatDate', () => expect(formatDate(DateTime(2026, 3, 9)), '9 Mar 2026'));
}
