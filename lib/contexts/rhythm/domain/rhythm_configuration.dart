import 'daily_rhythm.dart';
import 'duration_minutes.dart';

final class RhythmConfiguration {
  factory RhythmConfiguration({
    required DailyRhythm dailyRhythm,
    required DurationMinutes focusDuration,
    required DurationMinutes restDuration,
  }) {
    if (focusDuration.minutes > DurationMinutes.maximumFocus) {
      throw ArgumentError.value(
        focusDuration,
        'focusDuration',
        'must not exceed ${DurationMinutes.maximumFocus} minutes',
      );
    }
    if (restDuration.minutes > DurationMinutes.maximumRest) {
      throw ArgumentError.value(
        restDuration,
        'restDuration',
        'must not exceed ${DurationMinutes.maximumRest} minutes',
      );
    }
    if (focusDuration.minutes > dailyRhythm.durationInMinutes) {
      throw ArgumentError.value(
        focusDuration,
        'focusDuration',
        'the first Focus interval must fit inside the Daily Rhythm',
      );
    }
    return RhythmConfiguration._(
      dailyRhythm: dailyRhythm,
      focusDuration: focusDuration,
      restDuration: restDuration,
    );
  }

  const RhythmConfiguration._({
    required this.dailyRhythm,
    required this.focusDuration,
    required this.restDuration,
  });

  final DailyRhythm dailyRhythm;
  final DurationMinutes focusDuration;
  final DurationMinutes restDuration;

  factory RhythmConfiguration.defaults() {
    return RhythmConfiguration(
      dailyRhythm: DailyRhythm.defaults(),
      focusDuration: DurationMinutes.focus(50),
      restDuration: DurationMinutes.rest(10),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RhythmConfiguration &&
            dailyRhythm == other.dailyRhythm &&
            focusDuration == other.focusDuration &&
            restDuration == other.restDuration;
  }

  @override
  int get hashCode => Object.hash(dailyRhythm, focusDuration, restDuration);
}
