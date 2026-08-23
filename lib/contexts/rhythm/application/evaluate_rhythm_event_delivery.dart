import '../domain/rhythm_event.dart';
import '../domain/rhythm_schedule.dart';
import '../domain/rhythm_session.dart';
import 'ports/rhythm_status_sink.dart';
import 'rhythm_status_snapshot.dart';

final class RhythmEventDeliveryDecision {
  const RhythmEventDeliveryDecision({
    required this.shouldDeliver,
    required this.nextEvent,
    required this.snapshot,
  });

  final bool shouldDeliver;
  final RhythmEvent? nextEvent;
  final RhythmStatusSnapshot snapshot;
}

final class EvaluateRhythmEventDelivery {
  const EvaluateRhythmEventDelivery({
    required this.session,
    required this.statusSink,
  });

  final RhythmSession session;
  final RhythmStatusSink statusSink;

  Future<RhythmEventDeliveryDecision> execute(
    RhythmEvent event, {
    required DateTime observedAt,
  }) async {
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'observedAt',
        'must be a local DateTime',
      );
    }
    final RhythmSchedule schedule = RhythmSchedule(
      configuration: session.configuration,
    );
    final RhythmEvent expectedEvent = schedule.nextEventAfter(
      event.occursAt.subtract(const Duration(microseconds: 1)),
    );
    final RhythmEvent followingEvent = schedule.nextEventAfter(event.occursAt);
    final bool isCurrentBoundary =
        expectedEvent == event &&
        !observedAt.isBefore(event.occursAt) &&
        observedAt.isBefore(followingEvent.occursAt);
    final bool shouldDeliver =
        isCurrentBoundary &&
        session.recordDelivery(event, observedAt: observedAt);
    final RhythmEvent? nextEvent = session.nextEventAfter(observedAt);
    final RhythmStatusSnapshot snapshot = RhythmStatusSnapshot.capture(
      session: session,
      observedAt: observedAt,
      nextEvent: nextEvent,
    );
    await statusSink.publish(snapshot);
    return RhythmEventDeliveryDecision(
      shouldDeliver: shouldDeliver,
      nextEvent: nextEvent,
      snapshot: snapshot,
    );
  }
}
