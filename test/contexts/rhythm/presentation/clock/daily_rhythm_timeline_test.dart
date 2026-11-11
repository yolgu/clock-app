import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/presentation/clock/daily_rhythm_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RhythmConfiguration configuration({
    required String start,
    required String end,
    required int focus,
    required int rest,
  }) {
    return RhythmConfiguration(
      dailyRhythm: DailyRhythm(
        start: ClockTime.parse(start),
        end: ClockTime.parse(end),
      ),
      focusDuration: DurationMinutes.focus(focus),
      restDuration: DurationMinutes.rest(rest),
    );
  }

  test('repeats focus spans from the window start and clips the last', () {
    final DailyRhythmTimeline timeline = DailyRhythmTimeline.at(
      configuration: configuration(
        start: '09:00',
        end: '11:30',
        focus: 50,
        rest: 10,
      ),
      moment: DateTime(2026, 11, 7, 10, 15),
    );

    expect(timeline.focusSpans, <TimelineSpan>[
      const TimelineSpan(0, 50 / 150),
      const TimelineSpan(60 / 150, 110 / 150),
      const TimelineSpan(120 / 150, 1),
    ]);
    expect(timeline.momentFraction, closeTo(75 / 150, 1e-9));
  });

  test('places a moment after midnight inside a window that crosses it', () {
    final DailyRhythmTimeline timeline = DailyRhythmTimeline.at(
      configuration: configuration(
        start: '22:00',
        end: '02:00',
        focus: 25,
        rest: 5,
      ),
      moment: DateTime(2026, 11, 8, 1),
    );

    expect(timeline.momentFraction, closeTo(3 / 4, 1e-9));
    expect(timeline.focusSpans, hasLength(8));
  });

  test('shows the next window without a marker outside the window', () {
    final DailyRhythmTimeline timeline = DailyRhythmTimeline.at(
      configuration: configuration(
        start: '05:00',
        end: '23:00',
        focus: 50,
        rest: 10,
      ),
      moment: DateTime(2026, 11, 7, 23, 30),
    );

    expect(timeline.momentFraction, isNull);
    expect(timeline.focusSpans.first, const TimelineSpan(0, 50 / 1080));
  });
}
