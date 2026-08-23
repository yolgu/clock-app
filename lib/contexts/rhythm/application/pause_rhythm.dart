import '../domain/rhythm_session.dart';
import 'ports/clock.dart';
import 'ports/rhythm_delivery_port.dart';
import 'ports/rhythm_status_sink.dart';
import 'reconcile_rhythm.dart';
import 'rhythm_status_snapshot.dart';

final class PauseRhythm {
  PauseRhythm({
    required RhythmSession session,
    required Clock clock,
    required RhythmDeliveryPort delivery,
    required RhythmStatusSink statusSink,
  }) : _synchronizer = RhythmSynchronizer(session, clock, delivery, statusSink);

  final RhythmSynchronizer _synchronizer;

  Future<RhythmStatusSnapshot> execute() {
    return _synchronizer.synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.reconcile(observedAt);
        session.pause();
      },
    );
  }
}
