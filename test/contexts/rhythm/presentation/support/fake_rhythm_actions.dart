import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';

final class FakeRhythmActions implements RhythmActions {
  FakeRhythmActions({RhythmSessionStatus status = RhythmSessionStatus.idle})
    : current = rhythmSnapshot(status);

  RhythmStatusSnapshot current;
  RhythmStartFailure? startFailure;
  Object? commandFailure;
  final List<String> calls = <String>[];

  @override
  Future<RhythmStatusSnapshot> load() async {
    calls.add('load');
    return current;
  }

  @override
  Future<RhythmStartResult> start(RhythmConfiguration configuration) async {
    calls.add('start');
    final RhythmStartFailure? failure = startFailure;
    if (failure != null) {
      return RhythmStartResult.blocked(failure);
    }
    _throwCommandFailure();
    current = rhythmSnapshot(RhythmSessionStatus.running);
    return RhythmStartResult.started(current);
  }

  @override
  Future<RhythmStatusSnapshot> pause() async {
    calls.add('pause');
    _throwCommandFailure();
    current = rhythmSnapshot(RhythmSessionStatus.paused);
    return current;
  }

  @override
  Future<RhythmStatusSnapshot> resume() async {
    calls.add('resume');
    _throwCommandFailure();
    current = rhythmSnapshot(RhythmSessionStatus.running);
    return current;
  }

  @override
  Future<RhythmStatusSnapshot> stopForToday() async {
    calls.add('stop');
    _throwCommandFailure();
    current = rhythmSnapshot(RhythmSessionStatus.stoppedForToday);
    return current;
  }

  @override
  Future<RhythmStatusSnapshot> reconcile() async {
    calls.add('reconcile');
    _throwCommandFailure();
    return current;
  }

  @override
  Future<void> openStartFailureSettings(RhythmStartFailure failure) async {
    calls.add('settings:${failure.name}');
  }

  void _throwCommandFailure() {
    final Object? failure = commandFailure;
    if (failure != null) {
      throw failure;
    }
  }
}

RhythmStatusSnapshot rhythmSnapshot(RhythmSessionStatus status) {
  final RhythmConfiguration configuration = RhythmConfiguration.defaults();
  final DateTime observedAt = DateTime(2026, 8, 23, 6, 7);
  final RhythmSession session = RhythmSession.idle(
    configuration: configuration,
  );
  switch (status) {
    case RhythmSessionStatus.idle:
      break;
    case RhythmSessionStatus.running:
      session.start(configuration);
    case RhythmSessionStatus.paused:
      session.start(configuration);
      session.pause();
    case RhythmSessionStatus.stoppedForToday:
      session.start(configuration);
      session.stopForToday(observedAt);
  }
  return RhythmStatusSnapshot.capture(
    session: session,
    observedAt: observedAt,
    nextEvent: session.nextEventAfter(observedAt),
  );
}
