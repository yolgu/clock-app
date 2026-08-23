import 'daily_rhythm.dart';
import 'rhythm_configuration.dart';
import 'rhythm_event.dart';
import 'rhythm_schedule.dart';

enum RhythmSessionStatus { idle, running, paused, stoppedForToday }

final class RhythmSession {
  RhythmSession._(this._configuration, this._status);

  factory RhythmSession.idle({required RhythmConfiguration configuration}) {
    return RhythmSession._(configuration, RhythmSessionStatus.idle);
  }

  RhythmConfiguration _configuration;
  RhythmSessionStatus _status;
  DateTime? _stoppedWindowStartsAt;
  DateTime? _resumesAt;
  DateTime? _latestDeliveredAt;
  final Set<RhythmEventKind> _deliveredKindsAtLatestInstant =
      <RhythmEventKind>{};

  RhythmConfiguration get configuration => _configuration;

  RhythmSessionStatus get status => _status;

  DateTime? get stoppedWindowStartsAt => _stoppedWindowStartsAt;

  DateTime? get resumesAt => _resumesAt;

  void start(RhythmConfiguration configuration) {
    _configuration = configuration;
    _status = RhythmSessionStatus.running;
    _stoppedWindowStartsAt = null;
    _resumesAt = null;
    _latestDeliveredAt = null;
    _deliveredKindsAtLatestInstant.clear();
  }

  void resetToIdle() {
    _status = RhythmSessionStatus.idle;
    _stoppedWindowStartsAt = null;
    _resumesAt = null;
    _latestDeliveredAt = null;
    _deliveredKindsAtLatestInstant.clear();
  }

  void pause() {
    if (_status == RhythmSessionStatus.running) {
      _status = RhythmSessionStatus.paused;
    }
  }

  void resume() {
    if (_status == RhythmSessionStatus.paused) {
      _status = RhythmSessionStatus.running;
    }
  }

  void stopForToday(DateTime observedAt) {
    _requireLocal(observedAt);
    if (_status != RhythmSessionStatus.running &&
        _status != RhythmSessionStatus.paused) {
      return;
    }

    final DailyRhythmWindow stoppedWindow =
        _configuration.dailyRhythm.windowContaining(observedAt) ??
        _configuration.dailyRhythm.windowAtOrAfter(observedAt);
    _status = RhythmSessionStatus.stoppedForToday;
    _stoppedWindowStartsAt = stoppedWindow.startsAt;
    _resumesAt = _configuration.dailyRhythm.nextStartAfter(observedAt);
  }

  void reconcile(DateTime observedAt) {
    _requireLocal(observedAt);
    if (_status != RhythmSessionStatus.stoppedForToday) {
      return;
    }
    final DateTime resumesAt = _resumesAt!;
    if (observedAt.isBefore(resumesAt)) {
      return;
    }

    _status = RhythmSessionStatus.running;
    _stoppedWindowStartsAt = null;
    _resumesAt = null;
  }

  void replaceConfiguration(
    RhythmConfiguration configuration, {
    required DateTime observedAt,
  }) {
    _requireLocal(observedAt);
    final bool preserveStoppedState =
        _status == RhythmSessionStatus.stoppedForToday;
    _configuration = configuration;
    if (!preserveStoppedState) {
      return;
    }

    final DateTime newResumeAt = configuration.dailyRhythm.nextStartAtOrAfter(
      observedAt,
    );
    if (!observedAt.isBefore(newResumeAt)) {
      _status = RhythmSessionStatus.running;
      _stoppedWindowStartsAt = null;
      _resumesAt = null;
      return;
    }

    _stoppedWindowStartsAt = configuration.dailyRhythm
        .windowAtOrAfter(observedAt)
        .startsAt;
    _resumesAt = newResumeAt;
  }

  RhythmEvent? nextEventAfter(DateTime observedAt) {
    _requireLocal(observedAt);
    reconcile(observedAt);
    final RhythmSchedule schedule = RhythmSchedule(
      configuration: _configuration,
    );
    return switch (_status) {
      RhythmSessionStatus.running => schedule.nextEventAfter(observedAt),
      RhythmSessionStatus.stoppedForToday => schedule.nextEventAfter(
        _resumesAt!,
      ),
      RhythmSessionStatus.idle || RhythmSessionStatus.paused => null,
    };
  }

  bool canDeliver(RhythmEvent event, {required DateTime observedAt}) {
    _requireLocal(observedAt);
    reconcile(observedAt);
    if (_status != RhythmSessionStatus.running) {
      return false;
    }

    final DateTime? latestDeliveredAt = _latestDeliveredAt;
    if (latestDeliveredAt == null ||
        event.occursAt.isAfter(latestDeliveredAt)) {
      return true;
    }
    if (event.occursAt.isBefore(latestDeliveredAt)) {
      return false;
    }
    return !_deliveredKindsAtLatestInstant.contains(event.kind);
  }

  bool recordDelivery(RhythmEvent event, {required DateTime observedAt}) {
    if (!canDeliver(event, observedAt: observedAt)) {
      return false;
    }
    if (_latestDeliveredAt == null ||
        event.occursAt.isAfter(_latestDeliveredAt!)) {
      _latestDeliveredAt = event.occursAt;
      _deliveredKindsAtLatestInstant.clear();
    }
    _deliveredKindsAtLatestInstant.add(event.kind);
    return true;
  }

  void _requireLocal(DateTime observedAt) {
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'observedAt',
        'must be a local DateTime',
      );
    }
  }
}
