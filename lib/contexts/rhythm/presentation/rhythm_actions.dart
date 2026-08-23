import '../application/pause_rhythm.dart';
import '../application/ports/rhythm_start_capability.dart';
import '../application/reconcile_rhythm.dart';
import '../application/resume_rhythm.dart';
import '../application/rhythm_status_snapshot.dart';
import '../application/start_rhythm.dart';
import '../application/stop_rhythm_for_today.dart';
import '../domain/rhythm_configuration.dart';

final class RhythmStartResult {
  const RhythmStartResult._({
    required this.snapshot,
    required this.failure,
    required this.didStart,
  });

  const RhythmStartResult.started(RhythmStatusSnapshot snapshot)
    : this._(snapshot: snapshot, failure: null, didStart: true);

  const RhythmStartResult.blocked(
    RhythmStartFailure failure, {
    RhythmStatusSnapshot? safeSnapshot,
  }) : this._(snapshot: safeSnapshot, failure: failure, didStart: false);

  final RhythmStatusSnapshot? snapshot;
  final RhythmStartFailure? failure;

  final bool didStart;
}

abstract interface class RhythmActions {
  Future<RhythmStatusSnapshot> load();

  Future<RhythmStartResult> start(RhythmConfiguration configuration);

  Future<RhythmStatusSnapshot> pause();

  Future<RhythmStatusSnapshot> resume();

  Future<RhythmStatusSnapshot> stopForToday();

  Future<RhythmStatusSnapshot> reconcile();

  Future<void> openStartFailureSettings(RhythmStartFailure failure);
}

final class ApplicationRhythmActions implements RhythmActions {
  factory ApplicationRhythmActions({
    required StartRhythm start,
    required PauseRhythm pause,
    required ResumeRhythm resume,
    required StopRhythmForToday stopForToday,
    required ReconcileRhythm reconcile,
    required RhythmStartCapability startCapability,
    RhythmStatusSnapshot? initialSnapshot,
    bool initialRecoveryRequired = false,
  }) {
    if (initialRecoveryRequired && initialSnapshot == null) {
      throw ArgumentError(
        'An initial recovery failure requires a safe Rhythm snapshot.',
      );
    }
    return ApplicationRhythmActions._(
      start,
      pause,
      resume,
      stopForToday,
      reconcile,
      startCapability,
      initialSnapshot,
      initialRecoveryRequired,
    );
  }

  ApplicationRhythmActions._(
    this._start,
    this._pause,
    this._resume,
    this._stopForToday,
    this._reconcile,
    this._startCapability,
    this._initialSnapshot,
    this._initialRecoveryRequired,
  );

  final StartRhythm _start;
  final PauseRhythm _pause;
  final ResumeRhythm _resume;
  final StopRhythmForToday _stopForToday;
  final ReconcileRhythm _reconcile;
  final RhythmStartCapability _startCapability;
  RhythmStatusSnapshot? _initialSnapshot;
  bool _initialRecoveryRequired;

  @override
  Future<RhythmStatusSnapshot> load() {
    final RhythmStatusSnapshot? initialSnapshot = _initialSnapshot;
    if (initialSnapshot != null) {
      _initialSnapshot = null;
      final bool recoveryRequired = _initialRecoveryRequired;
      _initialRecoveryRequired = false;
      if (recoveryRequired) {
        return Future<RhythmStatusSnapshot>.error(
          RhythmSynchronizationFailure(
            safeSnapshot: initialSnapshot,
            cause: StateError('Explicit Rhythm delivery recovery is required.'),
          ),
        );
      }
      return Future<RhythmStatusSnapshot>.value(initialSnapshot);
    }
    return _reconcile.execute();
  }

  @override
  Future<RhythmStartResult> start(RhythmConfiguration configuration) async {
    final RhythmStartCapabilityResult capability = await _startCapability
        .requestForExplicitStart();
    final RhythmStartFailure? failure = capability.failure;
    if (failure != null) {
      return RhythmStartResult.blocked(failure);
    }
    try {
      return RhythmStartResult.started(await _start.execute(configuration));
    } on RhythmSynchronizationFailure catch (failure) {
      return RhythmStartResult.blocked(
        RhythmStartFailure.deliveryUnavailable,
        safeSnapshot: failure.safeSnapshot,
      );
    } on Object {
      return const RhythmStartResult.blocked(
        RhythmStartFailure.deliveryUnavailable,
      );
    }
  }

  @override
  Future<RhythmStatusSnapshot> pause() {
    return _pause.execute();
  }

  @override
  Future<RhythmStatusSnapshot> resume() {
    return _resume.execute();
  }

  @override
  Future<RhythmStatusSnapshot> stopForToday() {
    return _stopForToday.execute();
  }

  @override
  Future<RhythmStatusSnapshot> reconcile() {
    return _reconcile.execute();
  }

  @override
  Future<void> openStartFailureSettings(RhythmStartFailure failure) {
    return _startCapability.openSettings(failure);
  }
}
