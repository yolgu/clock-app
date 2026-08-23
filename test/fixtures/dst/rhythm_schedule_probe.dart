import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_schedule.dart';

void main() {
  _verifySpringGap();
  _verifyAutumnFold();
}

void _verifySpringGap() {
  final RhythmSchedule schedule = _schedule(
    start: '01:30',
    end: '05:30',
    focusMinutes: 60,
    restMinutes: 60,
  );
  final List<RhythmEvent> events = schedule.eventsForWindow(
    schedule.configuration.dailyRhythm.windowStartingOn(DateTime(2026, 3, 8)),
  );

  _require(events.length == 3, 'spring gap must omit one boundary');
  _require(
    events.first.kind == RhythmEventKind.restEnds,
    'the first valid post-gap boundary must preserve cadence',
  );
  _require(
    _hasLocalTime(
      events.first.occursAt,
      year: 2026,
      month: 3,
      day: 8,
      hour: 3,
      minute: 30,
    ),
    'the normalized 02:30 boundary must be treated as missed',
  );
  _require(
    schedule.nextEventAfter(DateTime(2026, 3, 8, 3, 20)) == events.first,
    'reconciliation must select the first strictly future valid boundary',
  );
}

void _verifyAutumnFold() {
  final RhythmSchedule schedule = _schedule(
    start: '00:30',
    end: '04:30',
    focusMinutes: 60,
    restMinutes: 60,
  );
  final List<RhythmEvent> events = schedule.eventsForWindow(
    schedule.configuration.dailyRhythm.windowStartingOn(DateTime(2026, 11, 1)),
  );

  _require(events.length == 4, 'autumn fold must not duplicate a boundary');
  _require(
    _hasLocalTime(
      events.first.occursAt,
      year: 2026,
      month: 11,
      day: 1,
      hour: 1,
      minute: 30,
    ),
    'the repeated 01:30 boundary must use the runtime-selected occurrence',
  );
  _require(
    events
            .map((RhythmEvent event) => event.occursAt.microsecondsSinceEpoch)
            .toSet()
            .length ==
        events.length,
    'autumn fold occurrences must remain unique instants',
  );
  _require(
    events.every(
      (RhythmEvent event) => event.occursAt.isAfter(event.windowStartsAt),
    ),
    'every fold boundary must advance beyond the window anchor',
  );
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

bool _hasLocalTime(
  DateTime value, {
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
}) {
  return value.year == year &&
      value.month == month &&
      value.day == day &&
      value.hour == hour &&
      value.minute == minute;
}

void _require(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}
