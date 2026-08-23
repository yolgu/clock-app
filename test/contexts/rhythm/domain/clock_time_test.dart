import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and formats an exact 24-hour clock value', () {
    final ClockTime time = ClockTime.parse('05:07');

    expect(time.hour, 5);
    expect(time.minute, 7);
    expect(time.totalMinutes, 307);
    expect(time.text, '05:07');
    expect(time.toString(), '05:07');
  });

  test('supports the first and last minute of a day', () {
    expect(ClockTime.parse('00:00').totalMinutes, 0);
    expect(ClockTime.parse('23:59').totalMinutes, 1439);
  });

  test('builds an equivalent value from hour and minute components', () {
    expect(
      ClockTime.fromComponents(hour: 22, minute: 30),
      ClockTime.parse('22:30'),
    );
  });

  for (final String invalidText in <String>[
    '5:00',
    '05:0',
    '24:00',
    '12:60',
    '12:30:00',
    'not-a-time',
  ]) {
    test('rejects ambiguous or invalid clock text "$invalidText"', () {
      expect(() => ClockTime.parse(invalidText), throwsArgumentError);
    });
  }

  test('rejects out-of-range numeric components', () {
    expect(
      () => ClockTime.fromComponents(hour: -1, minute: 0),
      throwsArgumentError,
    );
    expect(
      () => ClockTime.fromComponents(hour: 23, minute: 60),
      throwsArgumentError,
    );
  });
}
