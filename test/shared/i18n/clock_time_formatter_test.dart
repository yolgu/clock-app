import 'package:clock_rhythm/contexts/rhythm/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ClockTimeFormatter formatter = ClockTimeFormatter();

  test('formats clock components as locale-independent HH:mm', () {
    expect(formatter.formatComponents(hour: 0, minute: 0), '00:00');
    expect(formatter.formatComponents(hour: 5, minute: 7), '05:07');
    expect(formatter.formatComponents(hour: 23, minute: 59), '23:59');
    expect(formatter.formatLocalDateTime(DateTime(2026, 6, 2, 5, 7)), '05:07');
  });

  test('parses only the exact 24-hour HH:mm representation', () {
    expect(formatter.parse('05:07'), (hour: 5, minute: 7));

    for (final String invalidText in <String>[
      '5:07',
      '05:7',
      ' 05:07',
      '05:07 ',
      '17:00:00',
      '5:07 PM',
      '24:00',
      '12:60',
    ]) {
      expect(
        () => formatter.parse(invalidText),
        throwsFormatException,
        reason: '$invalidText must not be normalized silently',
      );
    }
  });

  test('matches the persisted Daily Rhythm and Todo Time contracts', () {
    final ClockTime rhythmTime = ClockTime.parse('05:07');
    final String formatted = formatter.formatComponents(
      hour: rhythmTime.hour,
      minute: rhythmTime.minute,
    );
    final TodoTime todoTime = TodoTime.parse(formatted);

    expect(formatted, rhythmTime.text);
    expect(todoTime.text, rhythmTime.text);
  });

  test('rejects out-of-range components instead of wrapping them', () {
    expect(
      () => formatter.formatComponents(hour: -1, minute: 0),
      throwsRangeError,
    );
    expect(
      () => formatter.formatComponents(hour: 23, minute: 60),
      throwsRangeError,
    );
    expect(
      () => formatter.formatLocalDateTime(DateTime.utc(2026, 6, 2, 5, 7)),
      throwsArgumentError,
    );
  });
}
