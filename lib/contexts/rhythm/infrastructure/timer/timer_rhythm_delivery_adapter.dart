import 'dart:async';

import '../../application/evaluate_rhythm_event_delivery.dart';
import '../../application/ports/event_sound_port.dart';
import '../../application/ports/notification_port.dart';
import '../../application/ports/rhythm_delivery_port.dart';
import '../../domain/rhythm_event.dart';

final class RhythmDeliveryContext {
  const RhythmDeliveryContext({
    required this.notification,
    required this.sound,
  });

  final RhythmNotification notification;
  final EventSoundSelection sound;
}

typedef RhythmDeliveryContextLoader =
    Future<RhythmDeliveryContext> Function(RhythmEvent event);
typedef RhythmEventEvaluator =
    Future<RhythmEventDeliveryDecision> Function(
      RhythmEvent event,
      DateTime observedAt,
    );
typedef EventSoundResultSink = void Function(EventSoundPlaybackResult result);
typedef RhythmDeliveryFailureSink =
    void Function(TimerRhythmDeliveryFailure failure);

enum TimerRhythmDeliveryFailureCode {
  contextUnavailable,
  notificationUnavailable,
  soundUnavailable,
  progressionUnavailable,
}

final class TimerRhythmDeliveryFailure implements Exception {
  const TimerRhythmDeliveryFailure({
    required this.code,
    required this.event,
    required this.cause,
  });

  final TimerRhythmDeliveryFailureCode code;
  final RhythmEvent event;
  final Object cause;

  @override
  String toString() => 'TimerRhythmDeliveryFailure(${code.name})';
}

abstract interface class ScheduledRhythmOperation {
  void cancel();
}

typedef RhythmTimerFactory =
    ScheduledRhythmOperation Function(
      Duration delay,
      Future<void> Function() operation,
    );
typedef LocalNow = DateTime Function();

final class TimerRhythmDeliveryAdapter implements RhythmDeliveryPort {
  factory TimerRhythmDeliveryAdapter({
    required NotificationPort notification,
    required EventSoundPort sound,
    required RhythmDeliveryContextLoader loadContext,
    required RhythmEventEvaluator evaluateEvent,
    required EventSoundResultSink onSoundResult,
    required RhythmDeliveryFailureSink onFailure,
    LocalNow now = _localNow,
    RhythmTimerFactory timerFactory = _createTimer,
  }) {
    return TimerRhythmDeliveryAdapter._(
      notification,
      sound,
      loadContext,
      evaluateEvent,
      onSoundResult,
      onFailure,
      now,
      timerFactory,
    );
  }

  TimerRhythmDeliveryAdapter._(
    this._notification,
    this._sound,
    this._loadContext,
    this._evaluateEvent,
    this._onSoundResult,
    this._onFailure,
    this._now,
    this._timerFactory,
  );

  final NotificationPort _notification;
  final EventSoundPort _sound;
  final RhythmDeliveryContextLoader _loadContext;
  final RhythmEventEvaluator _evaluateEvent;
  final EventSoundResultSink _onSoundResult;
  final RhythmDeliveryFailureSink _onFailure;
  final LocalNow _now;
  final RhythmTimerFactory _timerFactory;
  ScheduledRhythmOperation? _scheduled;
  int _generation = 0;
  bool _disposed = false;

  @override
  Future<void> cancelScheduledEvent() async {
    _requireActive();
    _generation += 1;
    _scheduled?.cancel();
    _scheduled = null;
    await _sound.stop();
  }

  @override
  Future<void> schedule(RhythmEvent event) async {
    _requireActive();
    _generation += 1;
    _scheduled?.cancel();
    final int generation = _generation;
    final DateTime observedAt = _now();
    if (observedAt.isUtc) {
      throw ArgumentError.value(observedAt, 'now', 'must be a local DateTime');
    }
    final Duration delay = event.occursAt.isAfter(observedAt)
        ? event.occursAt.difference(observedAt)
        : Duration.zero;
    _scheduled = _timerFactory(
      delay,
      () => _deliver(event: event, generation: generation),
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _generation += 1;
    _scheduled?.cancel();
    _scheduled = null;
    _disposed = true;
    await _sound.stop();
  }

  Future<void> _deliver({
    required RhythmEvent event,
    required int generation,
  }) async {
    if (!_isCurrent(generation)) {
      return;
    }
    _scheduled = null;
    final DateTime observedAt = _now();
    if (observedAt.isUtc) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.progressionUnavailable,
          event: event,
          cause: ArgumentError.value(
            observedAt,
            'now',
            'must be a local DateTime',
          ),
        ),
      );
      return;
    }
    final RhythmEventDeliveryDecision decision;
    try {
      decision = await _evaluateEvent(event, observedAt);
    } on Object catch (error) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.progressionUnavailable,
          event: event,
          cause: error,
        ),
      );
      return;
    }
    if (!_isCurrent(generation)) {
      return;
    }
    if (!decision.shouldDeliver) {
      await _scheduleNext(event, decision.nextEvent, generation);
      return;
    }

    final RhythmDeliveryContext context;
    try {
      context = await _loadContext(event);
    } on Object catch (error) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.contextUnavailable,
          event: event,
          cause: error,
        ),
      );
      await _scheduleNext(event, decision.nextEvent, generation);
      return;
    }
    if (!_isCurrent(generation)) {
      return;
    }
    if (context.notification.event != event) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.contextUnavailable,
          event: event,
          cause: StateError(
            'Timer delivery context belongs to another Rhythm Event.',
          ),
        ),
      );
      await _scheduleNext(event, decision.nextEvent, generation);
      return;
    }

    try {
      await _notification.show(context.notification);
    } on Object catch (error) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.notificationUnavailable,
          event: event,
          cause: error,
        ),
      );
    }
    if (!_isCurrent(generation)) {
      return;
    }

    try {
      final EventSoundPlaybackResult result = await _sound.play(context.sound);
      _onSoundResult(result);
    } on Object catch (error) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.soundUnavailable,
          event: event,
          cause: error,
        ),
      );
    }
    await _scheduleNext(event, decision.nextEvent, generation);
  }

  Future<void> _scheduleNext(
    RhythmEvent deliveredEvent,
    RhythmEvent? nextEvent,
    int generation,
  ) async {
    if (!_isCurrent(generation) || nextEvent == null) {
      return;
    }
    try {
      await schedule(nextEvent);
    } on Object catch (error) {
      _report(
        TimerRhythmDeliveryFailure(
          code: TimerRhythmDeliveryFailureCode.progressionUnavailable,
          event: deliveredEvent,
          cause: error,
        ),
      );
    }
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  void _report(TimerRhythmDeliveryFailure failure) {
    if (!_disposed) {
      try {
        _onFailure(failure);
      } on Object {
        // A secondary reporting failure must not stop future Rhythm delivery.
      }
    }
  }

  void _requireActive() {
    if (_disposed) {
      throw StateError('TimerRhythmDeliveryAdapter is disposed.');
    }
  }
}

final class _TimerScheduledRhythmOperation implements ScheduledRhythmOperation {
  const _TimerScheduledRhythmOperation(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

ScheduledRhythmOperation _createTimer(
  Duration delay,
  Future<void> Function() operation,
) {
  return _TimerScheduledRhythmOperation(
    Timer(delay, () => unawaited(operation())),
  );
}

DateTime _localNow() => DateTime.now();
