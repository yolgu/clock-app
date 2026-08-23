import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anchors the first Focus end to 05:50 instead of Start time', () {
    final RhythmEvent event = _defaultSchedule().nextEventAfter(
      DateTime(2026, 6, 2, 5, 10),
    );

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 2, 5, 50));
    expect(event.windowStartsAt, DateTime(2026, 6, 2, 5));
  });

  test('skips a missed Focus end and selects the next Rest end', () {
    final RhythmEvent event = _defaultSchedule().nextEventAfter(
      DateTime(2026, 6, 2, 5, 50, 1),
    );

    expect(event.kind, RhythmEventKind.restEnds);
    expect(event.occursAt, DateTime(2026, 6, 2, 6));
  });

  test('keeps a later Start aligned to the Daily Rhythm sequence', () {
    final RhythmEvent event = _defaultSchedule().nextEventAfter(
      DateTime(2026, 6, 2, 6, 7),
    );

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 2, 6, 50));
  });

  test('arms the next active day after the Daily Rhythm ends', () {
    final RhythmEvent event = _defaultSchedule().nextEventAfter(
      DateTime(2026, 6, 2, 18, 0, 1),
    );

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 3, 5, 50));
  });

  test('schedules a one-minute late-night Focus boundary', () {
    final RhythmSchedule schedule = _schedule(
      start: '23:00',
      end: '23:55',
      focusMinutes: 1,
      restMinutes: 1,
    );

    final RhythmEvent event = schedule.nextEventAfter(DateTime(2026, 6, 2, 23));

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 2, 23, 1));
  });

  test('uses the prior-day anchor inside a cross-midnight window', () {
    final RhythmSchedule schedule = _schedule(
      start: '22:00',
      end: '02:00',
      focusMinutes: 50,
      restMinutes: 10,
    );

    final RhythmEvent event = schedule.nextEventAfter(
      DateTime(2026, 6, 3, 0, 30),
    );

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 3, 0, 50));
    expect(event.windowStartsAt, DateTime(2026, 6, 2, 22));
  });

  test('moves to the next cross-midnight window after its end', () {
    final RhythmSchedule schedule = _schedule(
      start: '22:00',
      end: '02:00',
      focusMinutes: 50,
      restMinutes: 10,
    );

    final RhythmEvent event = schedule.nextEventAfter(
      DateTime(2026, 6, 3, 2, 0, 1),
    );

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 3, 22, 50));
  });

  test('includes an event exactly at the window end', () {
    final RhythmSchedule schedule = _schedule(
      start: '05:00',
      end: '05:50',
      focusMinutes: 50,
      restMinutes: 10,
    );

    final RhythmEvent event = schedule.nextEventAfter(
      DateTime(2026, 6, 2, 5, 49, 59),
    );

    expect(event.kind, RhythmEventKind.focusEnds);
    expect(event.occursAt, DateTime(2026, 6, 2, 5, 50));
  });

  test('selects the next window when queried exactly at its final event', () {
    final RhythmSchedule schedule = _schedule(
      start: '05:00',
      end: '05:50',
      focusMinutes: 50,
      restMinutes: 10,
    );

    final RhythmEvent event = schedule.nextEventAfter(
      DateTime(2026, 6, 2, 5, 50),
    );

    expect(event.occursAt, DateTime(2026, 6, 3, 5, 50));
  });

  test('never creates an event beyond the window end', () {
    final RhythmSchedule schedule = _schedule(
      start: '05:00',
      end: '05:51',
      focusMinutes: 50,
      restMinutes: 10,
    );
    final DailyRhythmWindow window = schedule.configuration.dailyRhythm
        .windowStartingOn(DateTime(2026, 6, 2));

    final List<RhythmEvent> events = schedule.eventsForWindow(window);

    expect(events, hasLength(1));
    expect(events.single.occursAt, DateTime(2026, 6, 2, 5, 50));
  });

  test('supports the maximum Focus and Rest duration values', () {
    final RhythmSchedule schedule = _schedule(
      start: '05:00',
      end: '12:00',
      focusMinutes: 180,
      restMinutes: 60,
    );

    final List<RhythmEvent> events = schedule.eventsForWindow(
      schedule.configuration.dailyRhythm.windowStartingOn(DateTime(2026, 6, 2)),
    );

    expect(events.first.occursAt, DateTime(2026, 6, 2, 8));
    expect(events.first.kind, RhythmEventKind.focusEnds);
    expect(events[1].occursAt, DateTime(2026, 6, 2, 9));
    expect(events[1].kind, RhythmEventKind.restEnds);
  });

  test('rejects UTC input instead of silently changing the anchor', () {
    expect(
      () => _defaultSchedule().nextEventAfter(DateTime.utc(2026, 6, 2, 5)),
      throwsArgumentError,
    );
  });
}

RhythmSchedule _defaultSchedule() {
  return RhythmSchedule(configuration: RhythmConfiguration.defaults());
}

RhythmSchedule _schedule({
  required String start,
  required String end,
  required int focusMinutes,
  required int restMinutes,
}) {
  return RhythmSchedule(
    configuration: RhythmConfiguration(
      dailyRhythm: DailyRhythm(
        start: ClockTime.parse(start),
        end: ClockTime.parse(end),
      ),
      focusDuration: DurationMinutes.focus(focusMinutes),
      restDuration: DurationMinutes.rest(restMinutes),
    ),
  );
}
