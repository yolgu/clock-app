import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only schedule-owned defaults', () {
    final RhythmConfiguration configuration = RhythmConfiguration.defaults();

    expect(configuration.dailyRhythm, DailyRhythm.defaults());
    expect(configuration.focusDuration, DurationMinutes.focus(50));
    expect(configuration.restDuration, DurationMinutes.rest(10));
  });

  test('rejects a first Focus interval longer than the active window', () {
    expect(
      () => RhythmConfiguration(
        dailyRhythm: DailyRhythm(
          start: ClockTime.parse('05:00'),
          end: ClockTime.parse('05:59'),
        ),
        focusDuration: DurationMinutes.focus(60),
        restDuration: DurationMinutes.rest(10),
      ),
      throwsArgumentError,
    );
  });

  test('allows the first Focus boundary exactly at the window end', () {
    final RhythmConfiguration configuration = RhythmConfiguration(
      dailyRhythm: DailyRhythm(
        start: ClockTime.parse('05:00'),
        end: ClockTime.parse('05:50'),
      ),
      focusDuration: DurationMinutes.focus(50),
      restDuration: DurationMinutes.rest(10),
    );

    expect(configuration.focusDuration.minutes, 50);
  });

  test('revalidates the Rest role when a longer Focus value is supplied', () {
    expect(
      () => RhythmConfiguration(
        dailyRhythm: DailyRhythm.defaults(),
        focusDuration: DurationMinutes.focus(50),
        restDuration: DurationMinutes.focus(61),
      ),
      throwsArgumentError,
    );
  });
}
