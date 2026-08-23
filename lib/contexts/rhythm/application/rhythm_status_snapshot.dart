import '../domain/rhythm_configuration.dart';
import '../domain/rhythm_event.dart';
import '../domain/rhythm_session.dart';

final class RhythmStatusSnapshot {
  const RhythmStatusSnapshot._({
    required this.status,
    required this.configuration,
    required this.observedAt,
    required this.nextEvent,
    required this.resumesAt,
  });

  final RhythmSessionStatus status;
  final RhythmConfiguration configuration;
  final DateTime observedAt;
  final RhythmEvent? nextEvent;
  final DateTime? resumesAt;

  int get focusMinutes => configuration.focusDuration.minutes;

  int get restMinutes => configuration.restDuration.minutes;

  String get dailyStart => configuration.dailyRhythm.start.text;

  String get dailyEnd => configuration.dailyRhythm.end.text;

  factory RhythmStatusSnapshot.capture({
    required RhythmSession session,
    required DateTime observedAt,
    required RhythmEvent? nextEvent,
  }) {
    return RhythmStatusSnapshot._(
      status: session.status,
      configuration: session.configuration,
      observedAt: observedAt,
      nextEvent: nextEvent,
      resumesAt: session.resumesAt,
    );
  }
}
