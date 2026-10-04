import '../domain/rhythm_configuration.dart';
import '../domain/rhythm_event.dart';
import '../domain/rhythm_session.dart';
import 'ports/clock.dart';
import 'ports/rhythm_delivery_port.dart';
import 'ports/rhythm_status_sink.dart';
import 'rhythm_status_snapshot.dart';

final class RhythmSynchronizationFailure implements Exception {
  const RhythmSynchronizationFailure({
    required this.safeSnapshot,
    required this.cause,
  });

  final RhythmStatusSnapshot safeSnapshot;
  final Object cause;
}

final class RhythmService {
  const RhythmService({
    required RhythmSession session,
    required Clock clock,
    required RhythmDeliveryPort delivery,
    required RhythmStatusSink statusSink,
  }) : this._(session, clock, delivery, statusSink);
  const RhythmService._(
    this._session,
    this._clock,
    this._delivery,
    this._statusSink,
  );
  final RhythmSession _session;
  final Clock _clock;
  final RhythmDeliveryPort _delivery;
  final RhythmStatusSink _statusSink;

  Future<RhythmStatusSnapshot> start(RhythmConfiguration configuration) {
    return _synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.start(configuration);
      },
    );
  }

  Future<RhythmStatusSnapshot> pause() {
    return _synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.reconcile(observedAt);
        session.pause();
      },
    );
  }

  Future<RhythmStatusSnapshot> resume() {
    return _synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.reconcile(observedAt);
        session.resume();
      },
    );
  }

  Future<RhythmStatusSnapshot> stopForToday() {
    return _synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.reconcile(observedAt);
        session.stopForToday(observedAt);
      },
    );
  }

  Future<RhythmStatusSnapshot> reconcile() {
    return _synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.reconcile(observedAt);
      },
    );
  }

  Future<RhythmStatusSnapshot> reschedule(RhythmConfiguration configuration) {
    return _synchronize(
      transition: (RhythmSession session, DateTime observedAt) {
        session.replaceConfiguration(configuration, observedAt: observedAt);
      },
    );
  }

  Future<RhythmStatusSnapshot> _synchronize({
    required void Function(RhythmSession session, DateTime observedAt)
    transition,
  }) async {
    final DateTime observedAt = _clock.now();
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'Clock.now()',
        'must return a local DateTime',
      );
    }

    try {
      transition(_session, observedAt);
      _session.reconcile(observedAt);
      final RhythmEvent? nextEvent = _session.nextEventAfter(observedAt);

      await _delivery.cancelScheduledEvent();
      if (nextEvent != null) {
        await _delivery.schedule(nextEvent);
      }

      final RhythmStatusSnapshot snapshot = RhythmStatusSnapshot.capture(
        session: _session,
        observedAt: observedAt,
        nextEvent: nextEvent,
      );
      await _statusSink.publish(snapshot);
      return snapshot;
    } on RhythmSynchronizationFailure {
      rethrow;
    } on Object catch (error) {
      _session.resetToIdle();
      try {
        await _delivery.cancelScheduledEvent();
      } on Object {
        // Safe Idle remains the local truth even if platform cleanup needs recovery.
      }
      final RhythmStatusSnapshot safeSnapshot = RhythmStatusSnapshot.capture(
        session: _session,
        observedAt: observedAt,
        nextEvent: null,
      );
      try {
        await _statusSink.publish(safeSnapshot);
      } on Object {
        // The typed failure still carries the safe snapshot to presentation.
      }
      throw RhythmSynchronizationFailure(
        safeSnapshot: safeSnapshot,
        cause: error,
      );
    }
  }
}
