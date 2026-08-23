import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../application/evaluate_rhythm_event_delivery.dart';
import '../../application/ports/event_sound_port.dart';
import '../../application/ports/notification_port.dart';
import '../../application/ports/rhythm_delivery_port.dart';
import '../../domain/rhythm_event.dart';

final class WindowsNotificationIdentity {
  const WindowsNotificationIdentity({
    required this.appName,
    required this.appUserModelId,
    required this.activationGuid,
  });

  final String appName;
  final String appUserModelId;
  final String activationGuid;
}

final class WindowsNotificationRequest {
  const WindowsNotificationRequest({
    required this.id,
    required this.groupId,
    required this.groupTitle,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String groupId;
  final String groupTitle;
  final String title;
  final String body;
  final String payload;

  String get replacementTag => id.toString();
}

typedef WindowsNotificationActivation = Future<void> Function(String payload);

abstract interface class WindowsNotificationPlugin {
  Future<bool> initialize({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
  });

  Future<void> show(WindowsNotificationRequest request);

  Future<void> dispose();
}

final class FlutterLocalNotificationsWindowsPlugin
    implements WindowsNotificationPlugin {
  FlutterLocalNotificationsWindowsPlugin({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool> initialize({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
  }) async {
    final bool? initialized = await _plugin.initialize(
      settings: InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: identity.appName,
          appUserModelId: identity.appUserModelId,
          guid: identity.activationGuid,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null) {
          unawaited(onActivated(payload));
        }
      },
    );
    return initialized ?? false;
  }

  @override
  Future<void> show(WindowsNotificationRequest request) {
    // flutter_local_notifications_windows assigns this ID to the native
    // ToastNotification.Tag. WindowsNotificationDetails has no separate tag.
    return _plugin.show(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      notificationDetails: NotificationDetails(
        windows: WindowsNotificationDetails(
          audio: WindowsNotificationAudio.silent(),
          header: WindowsHeader(
            id: request.groupId,
            title: request.groupTitle,
            arguments: request.payload,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _plugin
        .resolvePlatformSpecificImplementation<
          FlutterLocalNotificationsWindows
        >()
        ?.dispose();
  }
}

enum WindowsNotificationFailureCode { notInitialized, initializationFailed }

final class WindowsNotificationFailure implements Exception {
  const WindowsNotificationFailure({required this.code});

  final WindowsNotificationFailureCode code;

  @override
  String toString() => 'WindowsNotificationFailure(${code.name})';
}

final class WindowsNotificationAdapter implements NotificationPort {
  factory WindowsNotificationAdapter({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
    WindowsNotificationPlugin? plugin,
  }) {
    return WindowsNotificationAdapter._(
      identity,
      onActivated,
      plugin ?? FlutterLocalNotificationsWindowsPlugin(),
    );
  }

  WindowsNotificationAdapter._(this.identity, this._onActivated, this._plugin);

  static const int activeRhythmNotificationId = 41001;
  static const String activeRhythmReplacementTag =
      '$activeRhythmNotificationId';
  static const String rhythmNotificationGroupId = 'clock-rhythm.rhythm';
  static const String clockRoutePayload = '/clock';

  final WindowsNotificationIdentity identity;
  final WindowsNotificationActivation _onActivated;
  final WindowsNotificationPlugin _plugin;
  bool _initialized = false;
  bool _disposed = false;

  Future<void> initialize() async {
    if (_disposed) {
      throw StateError('A disposed notification adapter cannot initialize.');
    }
    if (_initialized) {
      return;
    }
    final bool initialized = await _plugin.initialize(
      identity: identity,
      onActivated: _onActivated,
    );
    if (!initialized) {
      throw const WindowsNotificationFailure(
        code: WindowsNotificationFailureCode.initializationFailed,
      );
    }
    _initialized = true;
  }

  @override
  Future<void> show(RhythmNotification notification) {
    if (!_initialized || _disposed) {
      return Future<void>.error(
        const WindowsNotificationFailure(
          code: WindowsNotificationFailureCode.notInitialized,
        ),
      );
    }
    return _plugin.show(
      WindowsNotificationRequest(
        id: activeRhythmNotificationId,
        groupId: rhythmNotificationGroupId,
        groupTitle: identity.appName,
        title: notification.title,
        body: notification.body,
        payload: clockRoutePayload,
      ),
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_initialized) {
      await _plugin.dispose();
    }
    _initialized = false;
  }
}

final class WindowsRhythmDeliveryContext {
  const WindowsRhythmDeliveryContext({
    required this.notification,
    required this.sound,
  });

  final RhythmNotification notification;
  final EventSoundSelection sound;
}

typedef WindowsRhythmDeliveryContextLoader =
    Future<WindowsRhythmDeliveryContext> Function(RhythmEvent event);
typedef WindowsRhythmEventEvaluator =
    Future<RhythmEventDeliveryDecision> Function(
      RhythmEvent event,
      DateTime observedAt,
    );
typedef WindowsEventSoundResultSink =
    void Function(EventSoundPlaybackResult result);
typedef WindowsRhythmDeliveryFailureSink =
    void Function(WindowsRhythmDeliveryFailure failure);

enum WindowsRhythmDeliveryFailureCode {
  contextUnavailable,
  notificationUnavailable,
  soundUnavailable,
  progressionUnavailable,
}

final class WindowsRhythmDeliveryFailure implements Exception {
  const WindowsRhythmDeliveryFailure({
    required this.code,
    required this.event,
    required this.cause,
  });

  final WindowsRhythmDeliveryFailureCode code;
  final RhythmEvent event;
  final Object cause;

  @override
  String toString() => 'WindowsRhythmDeliveryFailure(${code.name})';
}

abstract interface class WindowsScheduledRhythmOperation {
  void cancel();
}

typedef WindowsRhythmTimerFactory =
    WindowsScheduledRhythmOperation Function(
      Duration delay,
      Future<void> Function() operation,
    );
typedef WindowsLocalNow = DateTime Function();

final class WindowsRhythmDeliveryAdapter implements RhythmDeliveryPort {
  factory WindowsRhythmDeliveryAdapter({
    required NotificationPort notification,
    required EventSoundPort sound,
    required WindowsRhythmDeliveryContextLoader loadContext,
    required WindowsRhythmEventEvaluator evaluateEvent,
    required WindowsEventSoundResultSink onSoundResult,
    required WindowsRhythmDeliveryFailureSink onFailure,
    WindowsLocalNow now = _localNow,
    WindowsRhythmTimerFactory timerFactory = _createTimer,
  }) {
    return WindowsRhythmDeliveryAdapter._(
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

  WindowsRhythmDeliveryAdapter._(
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
  final WindowsRhythmDeliveryContextLoader _loadContext;
  final WindowsRhythmEventEvaluator _evaluateEvent;
  final WindowsEventSoundResultSink _onSoundResult;
  final WindowsRhythmDeliveryFailureSink _onFailure;
  final WindowsLocalNow _now;
  final WindowsRhythmTimerFactory _timerFactory;
  WindowsScheduledRhythmOperation? _scheduled;
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
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.progressionUnavailable,
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
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.progressionUnavailable,
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

    final WindowsRhythmDeliveryContext context;
    try {
      context = await _loadContext(event);
    } on Object catch (error) {
      _report(
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.contextUnavailable,
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
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.contextUnavailable,
          event: event,
          cause: StateError(
            'Windows delivery context belongs to another Rhythm Event.',
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
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.notificationUnavailable,
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
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.soundUnavailable,
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
        WindowsRhythmDeliveryFailure(
          code: WindowsRhythmDeliveryFailureCode.progressionUnavailable,
          event: deliveredEvent,
          cause: error,
        ),
      );
    }
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  void _report(WindowsRhythmDeliveryFailure failure) {
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
      throw StateError('WindowsRhythmDeliveryAdapter is disposed.');
    }
  }
}

final class _TimerScheduledRhythmOperation
    implements WindowsScheduledRhythmOperation {
  const _TimerScheduledRhythmOperation(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

WindowsScheduledRhythmOperation _createTimer(
  Duration delay,
  Future<void> Function() operation,
) {
  return _TimerScheduledRhythmOperation(
    Timer(delay, () => unawaited(operation())),
  );
}

DateTime _localNow() => DateTime.now();
