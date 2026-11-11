import '../../domain/daily_rhythm.dart';
import '../../domain/rhythm_configuration.dart';

/// One stretch of the timeline as fractions of the Daily Rhythm Window.
final class TimelineSpan {
  const TimelineSpan(this.start, this.end);

  final double start;
  final double end;

  @override
  bool operator ==(Object other) {
    return other is TimelineSpan && start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TimelineSpan($start, $end)';
}

/// The current (or next) Daily Rhythm Window laid out on a 0-1 line: where
/// each Focus Interval falls, and where the given moment sits when it is
/// inside the window. Focus Intervals repeat from the window start, the same
/// anchor the schedule uses for Rhythm Events.
final class DailyRhythmTimeline {
  const DailyRhythmTimeline._({
    required this.focusSpans,
    required this.momentFraction,
  });

  factory DailyRhythmTimeline.at({
    required RhythmConfiguration configuration,
    required DateTime moment,
  }) {
    final DailyRhythmWindow window = configuration.dailyRhythm.windowAtOrAfter(
      moment,
    );
    final int windowMinutes = window.endsAt
        .difference(window.startsAt)
        .inMinutes;
    final int focusMinutes = configuration.focusDuration.minutes;
    final int cycleMinutes = focusMinutes + configuration.restDuration.minutes;
    final List<TimelineSpan> focusSpans = <TimelineSpan>[
      for (int offset = 0; offset < windowMinutes; offset += cycleMinutes)
        TimelineSpan(
          offset / windowMinutes,
          (offset + focusMinutes).clamp(0, windowMinutes) / windowMinutes,
        ),
    ];
    final double? momentFraction = window.contains(moment)
        ? moment.difference(window.startsAt).inSeconds /
              window.endsAt.difference(window.startsAt).inSeconds
        : null;
    return DailyRhythmTimeline._(
      focusSpans: List<TimelineSpan>.unmodifiable(focusSpans),
      momentFraction: momentFraction,
    );
  }

  final List<TimelineSpan> focusSpans;

  /// Null while the moment is outside the Daily Rhythm Window.
  final double? momentFraction;
}
