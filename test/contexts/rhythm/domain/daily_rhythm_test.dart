import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the agreed 05:00 through 18:00 defaults', () {
    final DailyRhythm rhythm = DailyRhythm.defaults();

    expect(rhythm.start, ClockTime.parse('05:00'));
    expect(rhythm.end, ClockTime.parse('18:00'));
    expect(rhythm.durationInMinutes, 780);
    expect(rhythm.crossesMidnight, isFalse);
  });

  test('rejects an equal start and end', () {
    expect(
      () => DailyRhythm(
        start: ClockTime.parse('05:00'),
        end: ClockTime.parse('05:00'),
      ),
      throwsArgumentError,
    );
  });

  test('anchors a same-day window to the local calendar date', () {
    final DailyRhythmWindow window = DailyRhythm.defaults().windowAtOrAfter(
      DateTime(2026, 6, 2, 9),
    );

    expect(window.startsAt, DateTime(2026, 6, 2, 5));
    expect(window.endsAt, DateTime(2026, 6, 2, 18));
    expect(window.contains(DateTime(2026, 6, 2, 18)), isTrue);
  });

  test(
    'anchors an after-midnight moment to the prior cross-midnight window',
    () {
      final DailyRhythm rhythm = DailyRhythm(
        start: ClockTime.parse('22:00'),
        end: ClockTime.parse('02:00'),
      );

      final DailyRhythmWindow? window = rhythm.windowContaining(
        DateTime(2026, 6, 3, 0, 30),
      );

      expect(window, isNotNull);
      expect(window!.startsAt, DateTime(2026, 6, 2, 22));
      expect(window.endsAt, DateTime(2026, 6, 3, 2));
      expect(rhythm.durationInMinutes, 240);
      expect(rhythm.crossesMidnight, isTrue);
    },
  );

  test('uses calendar construction across month and year boundaries', () {
    final DailyRhythm rhythm = DailyRhythm(
      start: ClockTime.parse('22:00'),
      end: ClockTime.parse('02:00'),
    );

    final DailyRhythmWindow window = rhythm.windowStartingOn(
      DateTime(2026, 12, 31),
    );
    final DailyRhythmWindow nextWindow = rhythm.nextWindowAfter(window);

    expect(window.startsAt, DateTime(2026, 12, 31, 22));
    expect(window.endsAt, DateTime(2027, 1, 1, 2));
    expect(nextWindow.startsAt, DateTime(2027, 1, 1, 22));
  });

  test('uses the Gregorian leap day when a window crosses February', () {
    final DailyRhythm rhythm = DailyRhythm(
      start: ClockTime.parse('22:00'),
      end: ClockTime.parse('02:00'),
    );

    final DailyRhythmWindow window = rhythm.windowStartingOn(
      DateTime(2028, 2, 28),
    );

    expect(window.endsAt, DateTime(2028, 2, 29, 2));
  });

  test('finds the next start strictly after a local moment', () {
    final DailyRhythm rhythm = DailyRhythm.defaults();

    expect(
      rhythm.nextStartAfter(DateTime(2026, 6, 2, 4)),
      DateTime(2026, 6, 2, 5),
    );
    expect(
      rhythm.nextStartAfter(DateTime(2026, 6, 2, 5)),
      DateTime(2026, 6, 3, 5),
    );
  });

  test('rejects UTC input instead of mixing time bases', () {
    expect(
      () => DailyRhythm.defaults().windowAtOrAfter(DateTime.utc(2026, 6, 2)),
      throwsArgumentError,
    );
  });
}
