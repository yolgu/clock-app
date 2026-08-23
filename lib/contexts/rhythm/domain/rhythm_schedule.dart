import 'daily_rhythm.dart';
import 'rhythm_configuration.dart';
import 'rhythm_event.dart';

final class RhythmSchedule {
  const RhythmSchedule({required this.configuration});

  final RhythmConfiguration configuration;

  RhythmEvent nextEventAfter(DateTime moment) {
    if (moment.isUtc) {
      throw ArgumentError.value(moment, 'moment', 'must be a local DateTime');
    }

    DailyRhythmWindow window = configuration.dailyRhythm.windowAtOrAfter(
      moment,
    );
    while (true) {
      for (final RhythmEvent event in eventsForWindow(window)) {
        if (event.occursAt.isAfter(moment)) {
          return event;
        }
      }
      window = configuration.dailyRhythm.nextWindowAfter(window);
    }
  }

  List<RhythmEvent> eventsForWindow(DailyRhythmWindow window) {
    final List<RhythmEvent> events = <RhythmEvent>[];
    RhythmEventKind kind = RhythmEventKind.focusEnds;
    int elapsedWallClockMinutes = configuration.focusDuration.minutes;
    DateTime? previousOccurrence;

    while (elapsedWallClockMinutes <=
        configuration.dailyRhythm.durationInMinutes) {
      final DateTime? occursAt = _wallClockOccurrence(
        window: window,
        elapsedMinutes: elapsedWallClockMinutes,
      );
      if (occursAt != null &&
          !occursAt.isAfter(window.endsAt) &&
          (previousOccurrence == null ||
              occursAt.isAfter(previousOccurrence))) {
        events.add(
          RhythmEvent(
            kind: kind,
            occursAt: occursAt,
            windowStartsAt: window.startsAt,
          ),
        );
        previousOccurrence = occursAt;
      }
      final int nextDuration = kind == RhythmEventKind.focusEnds
          ? configuration.restDuration.minutes
          : configuration.focusDuration.minutes;
      elapsedWallClockMinutes += nextDuration;
      kind = kind.next;
    }
    return List<RhythmEvent>.unmodifiable(events);
  }

  DateTime? _wallClockOccurrence({
    required DailyRhythmWindow window,
    required int elapsedMinutes,
  }) {
    final int totalMinutes =
        window.startsAt.hour * Duration.minutesPerHour +
        window.startsAt.minute +
        elapsedMinutes;
    final int dayOffset = totalMinutes ~/ Duration.minutesPerDay;
    final int minuteOfDay = totalMinutes % Duration.minutesPerDay;
    final int expectedHour = minuteOfDay ~/ Duration.minutesPerHour;
    final int expectedMinute = minuteOfDay % Duration.minutesPerHour;
    final DateTime expectedDate = DateTime(
      window.startsAt.year,
      window.startsAt.month,
      window.startsAt.day + dayOffset,
    );
    final DateTime occurrence = DateTime(
      expectedDate.year,
      expectedDate.month,
      expectedDate.day,
      expectedHour,
      expectedMinute,
    );

    final bool normalizedAcrossGap =
        occurrence.year != expectedDate.year ||
        occurrence.month != expectedDate.month ||
        occurrence.day != expectedDate.day ||
        occurrence.hour != expectedHour ||
        occurrence.minute != expectedMinute;
    return normalizedAcrossGap ? null : occurrence;
  }
}
