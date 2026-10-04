import 'package:clock_rhythm/contexts/rhythm/application/evaluate_rhythm_event_delivery.dart';
import 'package:clock_rhythm/contexts/rhythm/application/ports/event_sound_port.dart';
import 'package:clock_rhythm/contexts/rhythm/application/ports/notification_port.dart';
import 'package:clock_rhythm/contexts/rhythm/application/ports/rhythm_status_sink.dart';
import 'package:clock_rhythm/contexts/rhythm/application/rhythm_status_snapshot.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_session.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/timer/timer_rhythm_delivery_adapter.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/windows/windows_notification_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses one stable Windows replacement ID, tag, group, and route',
    () async {
      final FakeWindowsNotificationPlugin plugin =
          FakeWindowsNotificationPlugin();
      final List<String> activations = <String>[];
      final WindowsNotificationAdapter adapter = WindowsNotificationAdapter(
        identity: _identity,
        onActivated: (String payload) async => activations.add(payload),
        plugin: plugin,
      );
      await adapter.initialize();

      await adapter.show(
        RhythmNotification(
          event: _event(RhythmEventKind.focusEnds),
          title: 'Take a break',
          body: 'Focus time ended.',
        ),
      );
      await adapter.show(
        RhythmNotification(
          event: _event(RhythmEventKind.restEnds),
          title: 'Focus again',
          body: 'Rest time ended.',
        ),
      );
      await plugin.activate('/clock');

      expect(plugin.requests, hasLength(2));
      expect(
        plugin.requests.map((WindowsNotificationRequest request) => request.id),
        everyElement(WindowsNotificationAdapter.activeRhythmNotificationId),
      );
      expect(
        plugin.requests.map(
          (WindowsNotificationRequest request) => request.replacementTag,
        ),
        everyElement(WindowsNotificationAdapter.activeRhythmReplacementTag),
      );
      expect(
        plugin.requests.map(
          (WindowsNotificationRequest request) => request.groupId,
        ),
        everyElement(WindowsNotificationAdapter.rhythmNotificationGroupId),
      );
      expect(
        plugin.requests.map(
          (WindowsNotificationRequest request) => request.payload,
        ),
        everyElement(WindowsNotificationAdapter.clockRoutePayload),
      );
      expect(plugin.requests.last.title, 'Focus again');
      expect(activations, <String>['/clock']);
      await adapter.dispose();
    },
  );

  test(
    'initialization failure is typed and prevents notification use',
    () async {
      final FakeWindowsNotificationPlugin plugin =
          FakeWindowsNotificationPlugin()..initializes = false;
      final WindowsNotificationAdapter adapter = WindowsNotificationAdapter(
        identity: _identity,
        onActivated: (String _) async {},
        plugin: plugin,
      );

      await expectLater(
        adapter.initialize(),
        throwsA(
          isA<WindowsNotificationFailure>().having(
            (WindowsNotificationFailure failure) => failure.code,
            'code',
            WindowsNotificationFailureCode.initializationFailed,
          ),
        ),
      );
      await expectLater(
        adapter.show(
          RhythmNotification(
            event: _event(RhythmEventKind.focusEnds),
            title: 'Title',
            body: 'Body',
          ),
        ),
        throwsA(isA<WindowsNotificationFailure>()),
      );
    },
  );

  test(
    'delivery reads the latest payload and sound at the due instant',
    () async {
      final RecordingNotificationPort notification =
          RecordingNotificationPort();
      final RecordingEventSoundPort sound = RecordingEventSoundPort();
      final FakeRhythmTimerFactory timers = FakeRhythmTimerFactory();
      final List<RhythmEvent> evaluated = <RhythmEvent>[];
      final List<EventSoundPlaybackResult> soundResults =
          <EventSoundPlaybackResult>[];
      final List<TimerRhythmDeliveryFailure> failures =
          <TimerRhythmDeliveryFailure>[];
      RhythmDeliveryContext current = RhythmDeliveryContext(
        notification: RhythmNotification(
          event: _event(RhythmEventKind.focusEnds),
          title: 'Old title',
          body: 'Old body',
        ),
        sound: EventSoundSelection.bundledDefault(volume: 1),
      );
      final TimerRhythmDeliveryAdapter delivery = TimerRhythmDeliveryAdapter(
        notification: notification,
        sound: sound,
        loadContext: (RhythmEvent _) async => current,
        evaluateEvent: (RhythmEvent event, DateTime observedAt) async {
          evaluated.add(event);
          return _deliveryDecision(event, observedAt: observedAt);
        },
        onSoundResult: soundResults.add,
        onFailure: failures.add,
        now: () => DateTime(2026, 8, 23, 5),
        timerFactory: timers.create,
      );
      final RhythmEvent event = _event(RhythmEventKind.focusEnds);
      await delivery.schedule(event);
      current = RhythmDeliveryContext(
        notification: RhythmNotification(
          event: event,
          title: '최신 제목',
          body: '최신 본문',
        ),
        sound: EventSoundSelection.custom(
          privateSource: r'C:\private\latest.mp3',
          volume: 0.2,
        ),
      );

      await timers.operations.single.fire();

      expect(notification.notifications.single.title, '최신 제목');
      expect(sound.selections.single.privateSource, r'C:\private\latest.mp3');
      expect(sound.selections.single.volume, 0.2);
      expect(evaluated, <RhythmEvent>[event]);
      expect(soundResults, hasLength(1));
      expect(failures, isEmpty);
      await delivery.dispose();
    },
  );

  test(
    'Mute suppresses sound only and keeps the visible notification',
    () async {
      final DeliveryHarness harness = DeliveryHarness(
        soundSelection: EventSoundSelection.muted(volume: 0.7),
      );

      await harness.delivery.schedule(harness.event);
      await harness.timers.operations.single.fire();

      expect(harness.notification.notifications, hasLength(1));
      expect(
        harness.sound.selections.single.mode,
        EventSoundSelectionMode.muted,
      );
      expect(harness.soundResults.single.source, EventSoundPlaybackSource.none);
      await harness.delivery.dispose();
    },
  );

  test(
    'zero volume reaches sound delivery and notification remains visible',
    () async {
      final DeliveryHarness harness = DeliveryHarness(
        soundSelection: EventSoundSelection.bundledDefault(volume: 0),
      );

      await harness.delivery.schedule(harness.event);
      await harness.timers.operations.single.fire();

      expect(harness.notification.notifications, hasLength(1));
      expect(harness.sound.selections.single.volume, 0);
      await harness.delivery.dispose();
    },
  );

  test(
    'replacement cancels the old timer and delivers only the new event',
    () async {
      final DeliveryHarness harness = DeliveryHarness(
        soundSelection: EventSoundSelection.bundledDefault(volume: 1),
      );
      final RhythmEvent replacement = RhythmEvent(
        kind: RhythmEventKind.restEnds,
        occursAt: DateTime(2026, 8, 23, 6),
        windowStartsAt: DateTime(2026, 8, 23, 5),
      );

      await harness.delivery.schedule(harness.event);
      await harness.delivery.schedule(replacement);
      await harness.timers.operations.first.fire();
      await harness.timers.operations.last.fire();

      expect(harness.timers.operations.first.cancelled, isTrue);
      expect(harness.elapsed, <RhythmEvent>[replacement]);
      expect(harness.notification.notifications, hasLength(1));
      await harness.delivery.dispose();
    },
  );

  test('completed delivery releases its scheduled timer ownership', () async {
    final DeliveryHarness harness = DeliveryHarness(
      soundSelection: EventSoundSelection.bundledDefault(volume: 1),
    );

    await harness.delivery.schedule(harness.event);
    final FakeScheduledRhythmOperation completed =
        harness.timers.operations.single;
    await completed.fire();
    await harness.delivery.cancelScheduledEvent();

    expect(completed.cancelled, isFalse);
    expect(harness.notification.notifications, hasLength(1));
    await harness.delivery.dispose();
  });

  test(
    'arming the following event does not stop current one-shot audio',
    () async {
      final RecordingNotificationPort notification =
          RecordingNotificationPort();
      final RecordingEventSoundPort sound = RecordingEventSoundPort();
      final FakeRhythmTimerFactory timers = FakeRhythmTimerFactory();
      final RhythmEvent event = _event(RhythmEventKind.focusEnds);
      final RhythmEvent nextEvent = RhythmEvent(
        kind: RhythmEventKind.restEnds,
        occursAt: DateTime(2026, 8, 23, 6),
        windowStartsAt: DateTime(2026, 8, 23, 5),
      );
      final TimerRhythmDeliveryAdapter delivery = TimerRhythmDeliveryAdapter(
        notification: notification,
        sound: sound,
        loadContext: (RhythmEvent current) async => RhythmDeliveryContext(
          notification: RhythmNotification(
            event: current,
            title: 'Title',
            body: 'Body',
          ),
          sound: EventSoundSelection.bundledDefault(volume: 1),
        ),
        evaluateEvent: (RhythmEvent current, DateTime observedAt) async {
          return _deliveryDecision(
            current,
            observedAt: observedAt,
            nextEvent: nextEvent,
          );
        },
        onSoundResult: (EventSoundPlaybackResult _) {},
        onFailure: (TimerRhythmDeliveryFailure _) {},
        now: () => DateTime(2026, 8, 23, 5, 50),
        timerFactory: timers.create,
      );

      await delivery.schedule(event);
      await timers.operations.single.fire();

      expect(sound.selections, hasLength(1));
      expect(sound.stops, 0);
      expect(timers.operations, hasLength(2));
      expect(timers.operations.last.delay, const Duration(minutes: 10));
      await delivery.dispose();
    },
  );

  test('delivery skips an event after its following Rhythm boundary', () async {
    final RhythmSession session = RhythmSession.idle(
      configuration: RhythmConfiguration.defaults(),
    )..start(RhythmConfiguration.defaults());
    final RecordingRhythmStatusSink statusSink = RecordingRhythmStatusSink();
    final EvaluateRhythmEventDelivery evaluator = EvaluateRhythmEventDelivery(
      session: session,
      statusSink: statusSink,
    );
    final RecordingNotificationPort notification = RecordingNotificationPort();
    final RecordingEventSoundPort sound = RecordingEventSoundPort();
    final FakeRhythmTimerFactory timers = FakeRhythmTimerFactory();
    int contextLoads = 0;
    final TimerRhythmDeliveryAdapter delivery = TimerRhythmDeliveryAdapter(
      notification: notification,
      sound: sound,
      loadContext: (RhythmEvent event) async {
        contextLoads += 1;
        return RhythmDeliveryContext(
          notification: RhythmNotification(
            event: event,
            title: 'Stale',
            body: 'Must not be delivered',
          ),
          sound: EventSoundSelection.bundledDefault(volume: 1),
        );
      },
      evaluateEvent: (RhythmEvent event, DateTime observedAt) =>
          evaluator.execute(event, observedAt: observedAt),
      onSoundResult: (EventSoundPlaybackResult _) {},
      onFailure: (TimerRhythmDeliveryFailure _) {},
      now: () => DateTime(2026, 8, 23, 6, 1),
      timerFactory: timers.create,
    );

    await delivery.schedule(_event(RhythmEventKind.focusEnds));
    await timers.operations.single.fire();

    expect(contextLoads, 0);
    expect(notification.notifications, isEmpty);
    expect(sound.selections, isEmpty);
    expect(
      statusSink.snapshots.single.nextEvent?.occursAt,
      DateTime(2026, 8, 23, 6, 50),
    );
    expect(timers.operations, hasLength(2));
    expect(timers.operations.last.delay, const Duration(minutes: 49));
    await delivery.dispose();
  });

  test(
    'delivery evaluation rejects duplicate event watermark claims',
    () async {
      final RhythmSession session = RhythmSession.idle(
        configuration: RhythmConfiguration.defaults(),
      )..start(RhythmConfiguration.defaults());
      final RecordingRhythmStatusSink statusSink = RecordingRhythmStatusSink();
      final EvaluateRhythmEventDelivery evaluator = EvaluateRhythmEventDelivery(
        session: session,
        statusSink: statusSink,
      );
      final RhythmEvent event = _event(RhythmEventKind.focusEnds);

      final RhythmEventDeliveryDecision first = await evaluator.execute(
        event,
        observedAt: event.occursAt,
      );
      final RhythmEventDeliveryDecision duplicate = await evaluator.execute(
        event,
        observedAt: event.occursAt.add(const Duration(seconds: 1)),
      );

      expect(first.shouldDeliver, isTrue);
      expect(duplicate.shouldDeliver, isFalse);
      expect(statusSink.snapshots, hasLength(2));
    },
  );

  test(
    'delivery evaluation defers an event after the wall clock moves back',
    () async {
      final RhythmSession session = RhythmSession.idle(
        configuration: RhythmConfiguration.defaults(),
      )..start(RhythmConfiguration.defaults());
      final EvaluateRhythmEventDelivery evaluator = EvaluateRhythmEventDelivery(
        session: session,
        statusSink: RecordingRhythmStatusSink(),
      );
      final RhythmEvent event = _event(RhythmEventKind.focusEnds);

      final RhythmEventDeliveryDecision decision = await evaluator.execute(
        event,
        observedAt: DateTime(2026, 8, 23, 5, 40),
      );

      expect(decision.shouldDeliver, isFalse);
      expect(decision.nextEvent, event);
    },
  );
}

const WindowsNotificationIdentity _identity = WindowsNotificationIdentity(
  appName: 'Clock Rhythm Beta',
  appUserModelId: 'dev.wndls.ClockRhythm.Beta',
  activationGuid: '7f607663-1b5d-4ce8-9178-9ac3b9b55819',
);

RhythmEvent _event(RhythmEventKind kind) {
  return RhythmEvent(
    kind: kind,
    occursAt: DateTime(2026, 8, 23, 5, 50),
    windowStartsAt: DateTime(2026, 8, 23, 5),
  );
}

final class FakeWindowsNotificationPlugin implements WindowsNotificationPlugin {
  bool initializes = true;
  WindowsNotificationActivation? activation;
  final List<WindowsNotificationRequest> requests =
      <WindowsNotificationRequest>[];

  Future<void> activate(String payload) async {
    await activation?.call(payload);
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> initialize({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
  }) async {
    activation = onActivated;
    return initializes;
  }

  @override
  Future<void> show(WindowsNotificationRequest request) async {
    requests.add(request);
  }
}

final class RecordingNotificationPort implements NotificationPort {
  final List<RhythmNotification> notifications = <RhythmNotification>[];

  @override
  Future<void> show(RhythmNotification notification) async {
    notifications.add(notification);
  }
}

final class RecordingEventSoundPort implements EventSoundPort {
  final List<EventSoundSelection> selections = <EventSoundSelection>[];
  int stops = 0;

  @override
  Future<EventSoundPlaybackResult> play(EventSoundSelection selection) async {
    selections.add(selection);
    return switch (selection.mode) {
      EventSoundSelectionMode.muted => EventSoundPlaybackResult.muted,
      EventSoundSelectionMode.bundledDefault => const EventSoundPlaybackResult(
        source: EventSoundPlaybackSource.bundledDefault,
        customRepairRequired: false,
      ),
      EventSoundSelectionMode.custom => const EventSoundPlaybackResult(
        source: EventSoundPlaybackSource.custom,
        customRepairRequired: false,
      ),
    };
  }

  @override
  Future<void> stop() async {
    stops += 1;
  }
}

final class RecordingRhythmStatusSink implements RhythmStatusSink {
  final List<RhythmStatusSnapshot> snapshots = <RhythmStatusSnapshot>[];

  @override
  Future<void> publish(RhythmStatusSnapshot snapshot) async {
    snapshots.add(snapshot);
  }
}

final class FakeRhythmTimerFactory {
  final List<FakeScheduledRhythmOperation> operations =
      <FakeScheduledRhythmOperation>[];

  ScheduledRhythmOperation create(
    Duration delay,
    Future<void> Function() operation,
  ) {
    final FakeScheduledRhythmOperation scheduled = FakeScheduledRhythmOperation(
      delay,
      operation,
    );
    operations.add(scheduled);
    return scheduled;
  }
}

final class FakeScheduledRhythmOperation implements ScheduledRhythmOperation {
  FakeScheduledRhythmOperation(this.delay, this._operation);

  final Duration delay;
  final Future<void> Function() _operation;
  bool cancelled = false;

  Future<void> fire() async {
    if (!cancelled) {
      await _operation();
    }
  }

  @override
  void cancel() {
    cancelled = true;
  }
}

final class DeliveryHarness {
  DeliveryHarness({required EventSoundSelection soundSelection})
    : event = _event(RhythmEventKind.focusEnds),
      notification = RecordingNotificationPort(),
      sound = RecordingEventSoundPort(),
      timers = FakeRhythmTimerFactory() {
    delivery = TimerRhythmDeliveryAdapter(
      notification: notification,
      sound: sound,
      loadContext: (RhythmEvent event) async => RhythmDeliveryContext(
        notification: RhythmNotification(
          event: event,
          title: 'Title',
          body: 'Body',
        ),
        sound: soundSelection,
      ),
      evaluateEvent: (RhythmEvent event, DateTime observedAt) async {
        elapsed.add(event);
        return _deliveryDecision(event, observedAt: observedAt);
      },
      onSoundResult: soundResults.add,
      onFailure: failures.add,
      now: () => DateTime(2026, 8, 23, 5),
      timerFactory: timers.create,
    );
  }

  final RhythmEvent event;
  final RecordingNotificationPort notification;
  final RecordingEventSoundPort sound;
  final FakeRhythmTimerFactory timers;
  final List<RhythmEvent> elapsed = <RhythmEvent>[];
  final List<EventSoundPlaybackResult> soundResults =
      <EventSoundPlaybackResult>[];
  final List<TimerRhythmDeliveryFailure> failures =
      <TimerRhythmDeliveryFailure>[];
  late final TimerRhythmDeliveryAdapter delivery;
}

RhythmEventDeliveryDecision _deliveryDecision(
  RhythmEvent event, {
  required DateTime observedAt,
  RhythmEvent? nextEvent,
}) {
  final RhythmSession session = RhythmSession.idle(
    configuration: RhythmConfiguration.defaults(),
  )..start(RhythmConfiguration.defaults());
  return RhythmEventDeliveryDecision(
    shouldDeliver: true,
    nextEvent: nextEvent,
    snapshot: RhythmStatusSnapshot.capture(
      session: session,
      observedAt: observedAt,
      nextEvent: nextEvent,
    ),
  );
}
