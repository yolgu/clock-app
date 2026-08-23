import 'package:clock_rhythm/contexts/rhythm/application/pause_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/application/ports/clock.dart';
import 'package:clock_rhythm/contexts/rhythm/application/ports/rhythm_delivery_port.dart';
import 'package:clock_rhythm/contexts/rhythm/application/ports/rhythm_status_sink.dart';
import 'package:clock_rhythm/contexts/rhythm/application/reconcile_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/application/reschedule_running_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/application/resume_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/application/rhythm_status_snapshot.dart';
import 'package:clock_rhythm/contexts/rhythm/application/start_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/application/stop_rhythm_for_today.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Start enters Running and schedules the anchored Focus boundary',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime(2026, 6, 2, 5, 10),
      );

      final RhythmStatusSnapshot snapshot = await harness.start.execute(
        RhythmConfiguration.defaults(),
      );

      expect(snapshot.status, RhythmSessionStatus.running);
      expect(snapshot.nextEvent?.kind, RhythmEventKind.focusEnds);
      expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 2, 5, 50));
      expect(harness.calls, <String>['cancel', 'schedule', 'publish']);
      expect(harness.statusSink.snapshots.single, snapshot);
    },
  );

  test('Start schedules a one-minute late-night Rhythm', () async {
    final RhythmHarness harness = RhythmHarness(now: DateTime(2026, 6, 2, 23));
    final RhythmConfiguration configuration = _configuration(
      start: '23:00',
      end: '23:55',
      focusMinutes: 1,
      restMinutes: 1,
    );

    final RhythmStatusSnapshot snapshot = await harness.start.execute(
      configuration,
    );

    expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 2, 23, 1));
  });

  test('Start outside the window arms the next Daily Rhythm', () async {
    final RhythmHarness harness = RhythmHarness(
      now: DateTime(2026, 6, 2, 18, 1),
    );

    final RhythmStatusSnapshot snapshot = await harness.start.execute(
      RhythmConfiguration.defaults(),
    );

    expect(snapshot.status, RhythmSessionStatus.running);
    expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 3, 5, 50));
  });

  test(
    'Start delivery failure restores Idle and clears registration',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime(2026, 6, 2, 5, 10),
      );
      harness.delivery.scheduleFailure = StateError('delivery unavailable');

      await expectLater(
        harness.start.execute(RhythmConfiguration.defaults()),
        throwsA(
          isA<RhythmSynchronizationFailure>().having(
            (RhythmSynchronizationFailure failure) => failure.cause,
            'cause',
            isA<StateError>(),
          ),
        ),
      );

      expect(harness.session.status, RhythmSessionStatus.idle);
      expect(harness.calls, <String>[
        'cancel',
        'schedule',
        'cancel',
        'publish',
      ]);
    },
  );

  test(
    'Pause delivery failure converges domain and snapshot to Idle',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime(2026, 6, 2, 5, 10),
      );
      await harness.start.execute(RhythmConfiguration.defaults());
      harness.delivery.clear();
      harness.delivery.cancelFailuresRemaining = 1;

      await expectLater(
        harness.pause.execute(),
        throwsA(
          isA<RhythmSynchronizationFailure>().having(
            (RhythmSynchronizationFailure failure) =>
                failure.safeSnapshot.status,
            'safe status',
            RhythmSessionStatus.idle,
          ),
        ),
      );

      expect(harness.session.status, RhythmSessionStatus.idle);
      expect(harness.calls, <String>['cancel', 'cancel', 'publish']);
    },
  );

  test(
    'Resume delivery failure converges domain and snapshot to Idle',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime(2026, 6, 2, 5, 10),
      );
      await harness.start.execute(RhythmConfiguration.defaults());
      await harness.pause.execute();
      harness.delivery.clear();
      harness.delivery.scheduleFailure = StateError('schedule failed');

      await expectLater(
        harness.resume.execute(),
        throwsA(
          isA<RhythmSynchronizationFailure>().having(
            (RhythmSynchronizationFailure failure) =>
                failure.safeSnapshot.status,
            'safe status',
            RhythmSessionStatus.idle,
          ),
        ),
      );

      expect(harness.session.status, RhythmSessionStatus.idle);
    },
  );

  test('Stop delivery failure converges domain and snapshot to Idle', () async {
    final RhythmHarness harness = RhythmHarness(
      now: DateTime(2026, 6, 2, 5, 10),
    );
    await harness.start.execute(RhythmConfiguration.defaults());
    harness.delivery.clear();
    harness.delivery.scheduleFailure = StateError('schedule failed');

    await expectLater(
      harness.stopForToday.execute(),
      throwsA(
        isA<RhythmSynchronizationFailure>().having(
          (RhythmSynchronizationFailure failure) => failure.safeSnapshot.status,
          'safe status',
          RhythmSessionStatus.idle,
        ),
      ),
    );

    expect(harness.session.status, RhythmSessionStatus.idle);
  });

  test(
    'rejects a Clock that crosses the local-time boundary with UTC',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime.utc(2026, 6, 2),
      );

      await expectLater(
        harness.start.execute(RhythmConfiguration.defaults()),
        throwsArgumentError,
      );
      expect(harness.calls, isEmpty);
    },
  );

  test('Resume from Idle does not register a delivery', () async {
    final RhythmHarness harness = RhythmHarness(
      now: DateTime(2026, 6, 2, 5, 10),
    );

    final RhythmStatusSnapshot snapshot = await harness.resume.execute();

    expect(snapshot.status, RhythmSessionStatus.idle);
    expect(snapshot.nextEvent, isNull);
    expect(harness.calls, <String>['cancel', 'publish']);
  });

  test('Pause cancels delivery and Resume skips a missed boundary', () async {
    final RhythmHarness harness = RhythmHarness(
      now: DateTime(2026, 6, 2, 5, 10),
    );
    await harness.start.execute(RhythmConfiguration.defaults());
    harness.delivery.clear();

    final RhythmStatusSnapshot paused = await harness.pause.execute();

    expect(paused.status, RhythmSessionStatus.paused);
    expect(paused.nextEvent, isNull);
    expect(harness.calls, <String>['cancel', 'publish']);

    harness.clock.current = DateTime(2026, 6, 2, 5, 50, 1);
    harness.delivery.clear();
    final RhythmStatusSnapshot resumed = await harness.resume.execute();

    expect(resumed.status, RhythmSessionStatus.running);
    expect(resumed.nextEvent?.kind, RhythmEventKind.restEnds);
    expect(resumed.nextEvent?.occursAt, DateTime(2026, 6, 2, 6));
    expect(harness.calls, <String>['cancel', 'schedule', 'publish']);
  });

  test('Stop suppresses the current cross-midnight window only', () async {
    final RhythmConfiguration configuration = _configuration(
      start: '22:00',
      end: '02:00',
      focusMinutes: 50,
      restMinutes: 10,
    );
    final RhythmHarness harness = RhythmHarness(
      now: DateTime(2026, 6, 3, 0, 30),
      configuration: configuration,
    );
    await harness.start.execute(configuration);
    harness.delivery.clear();

    final RhythmStatusSnapshot stopped = await harness.stopForToday.execute();

    expect(stopped.status, RhythmSessionStatus.stoppedForToday);
    expect(stopped.resumesAt, DateTime(2026, 6, 3, 22));
    expect(stopped.nextEvent?.occursAt, DateTime(2026, 6, 3, 22, 50));
    expect(harness.calls, <String>['cancel', 'schedule', 'publish']);
  });

  test(
    'Reconcile skips every missed event and schedules one future event',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime(2026, 6, 2, 5, 10),
      );
      await harness.start.execute(RhythmConfiguration.defaults());
      harness.clock.current = DateTime(2026, 6, 2, 6, 1);
      harness.delivery.clear();

      final RhythmStatusSnapshot snapshot = await harness.reconcile.execute();

      expect(snapshot.nextEvent?.kind, RhythmEventKind.focusEnds);
      expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 2, 6, 50));
      expect(harness.calls, <String>['cancel', 'schedule', 'publish']);
    },
  );

  test('Reconcile automatically rolls Stop over at the next start', () async {
    final RhythmHarness harness = RhythmHarness(now: DateTime(2026, 6, 2, 9));
    await harness.start.execute(RhythmConfiguration.defaults());
    await harness.stopForToday.execute();
    harness.clock.current = DateTime(2026, 6, 3, 5);
    harness.delivery.clear();

    final RhythmStatusSnapshot snapshot = await harness.reconcile.execute();

    expect(snapshot.status, RhythmSessionStatus.running);
    expect(snapshot.resumesAt, isNull);
    expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 3, 5, 50));
  });

  test('Pause applies after an unobserved Stop rollover', () async {
    final RhythmHarness harness = RhythmHarness(now: DateTime(2026, 6, 2, 9));
    await harness.start.execute(RhythmConfiguration.defaults());
    await harness.stopForToday.execute();
    harness.clock.current = DateTime(2026, 6, 3, 5);
    harness.delivery.clear();

    final RhythmStatusSnapshot snapshot = await harness.pause.execute();

    expect(snapshot.status, RhythmSessionStatus.paused);
    expect(snapshot.nextEvent, isNull);
    expect(harness.calls, <String>['cancel', 'publish']);
  });

  test('Stop applies to the new window after an unobserved rollover', () async {
    final RhythmHarness harness = RhythmHarness(now: DateTime(2026, 6, 2, 9));
    await harness.start.execute(RhythmConfiguration.defaults());
    await harness.stopForToday.execute();
    harness.clock.current = DateTime(2026, 6, 3, 5);
    harness.delivery.clear();

    final RhythmStatusSnapshot snapshot = await harness.stopForToday.execute();

    expect(snapshot.status, RhythmSessionStatus.stoppedForToday);
    expect(snapshot.resumesAt, DateTime(2026, 6, 4, 5));
    expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 4, 5, 50));
  });

  test('Reschedule replaces a Running delivery from the new anchor', () async {
    final RhythmHarness harness = RhythmHarness(
      now: DateTime(2026, 6, 2, 5, 10),
    );
    await harness.start.execute(RhythmConfiguration.defaults());
    harness.delivery.clear();
    final RhythmConfiguration changed = _configuration(
      start: '05:00',
      end: '18:00',
      focusMinutes: 20,
      restMinutes: 5,
    );

    final RhythmStatusSnapshot snapshot = await harness.reschedule.execute(
      changed,
    );

    expect(snapshot.status, RhythmSessionStatus.running);
    expect(snapshot.configuration, changed);
    expect(snapshot.focusMinutes, 20);
    expect(snapshot.restMinutes, 5);
    expect(snapshot.dailyStart, '05:00');
    expect(snapshot.dailyEnd, '18:00');
    expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 2, 5, 20));
    expect(harness.calls, <String>['cancel', 'schedule', 'publish']);
  });

  test(
    'Reschedule preserves Paused and leaves no delivery registered',
    () async {
      final RhythmHarness harness = RhythmHarness(
        now: DateTime(2026, 6, 2, 5, 10),
      );
      await harness.start.execute(RhythmConfiguration.defaults());
      await harness.pause.execute();
      harness.delivery.clear();

      final RhythmStatusSnapshot snapshot = await harness.reschedule.execute(
        _configuration(
          start: '06:00',
          end: '18:00',
          focusMinutes: 20,
          restMinutes: 5,
        ),
      );

      expect(snapshot.status, RhythmSessionStatus.paused);
      expect(snapshot.nextEvent, isNull);
      expect(harness.calls, <String>['cancel', 'publish']);
    },
  );

  test(
    'Reschedule preserves Stop until the new configuration next start',
    () async {
      final RhythmHarness harness = RhythmHarness(now: DateTime(2026, 6, 2, 9));
      await harness.start.execute(RhythmConfiguration.defaults());
      await harness.stopForToday.execute();
      harness.clock.current = DateTime(2026, 6, 2, 10);
      harness.delivery.clear();

      final RhythmStatusSnapshot snapshot = await harness.reschedule.execute(
        _configuration(
          start: '11:00',
          end: '18:00',
          focusMinutes: 20,
          restMinutes: 5,
        ),
      );

      expect(snapshot.status, RhythmSessionStatus.stoppedForToday);
      expect(snapshot.resumesAt, DateTime(2026, 6, 2, 11));
      expect(snapshot.nextEvent?.occursAt, DateTime(2026, 6, 2, 11, 20));
      expect(harness.calls, <String>['cancel', 'schedule', 'publish']);
    },
  );
}

final class RhythmHarness {
  RhythmHarness({required DateTime now, RhythmConfiguration? configuration})
    : clock = FakeClock(now),
      session = RhythmSession.idle(
        configuration: configuration ?? RhythmConfiguration.defaults(),
      ) {
    delivery = FakeRhythmDeliveryPort(calls);
    statusSink = FakeRhythmStatusSink(calls);
    start = StartRhythm(
      session: session,
      clock: clock,
      delivery: delivery,
      statusSink: statusSink,
    );
    pause = PauseRhythm(
      session: session,
      clock: clock,
      delivery: delivery,
      statusSink: statusSink,
    );
    resume = ResumeRhythm(
      session: session,
      clock: clock,
      delivery: delivery,
      statusSink: statusSink,
    );
    stopForToday = StopRhythmForToday(
      session: session,
      clock: clock,
      delivery: delivery,
      statusSink: statusSink,
    );
    reconcile = ReconcileRhythm(
      session: session,
      clock: clock,
      delivery: delivery,
      statusSink: statusSink,
    );
    reschedule = RescheduleRunningRhythm(
      session: session,
      clock: clock,
      delivery: delivery,
      statusSink: statusSink,
    );
  }

  final RhythmSession session;
  final FakeClock clock;
  final List<String> calls = <String>[];
  late final FakeRhythmDeliveryPort delivery;
  late final FakeRhythmStatusSink statusSink;
  late final StartRhythm start;
  late final PauseRhythm pause;
  late final ResumeRhythm resume;
  late final StopRhythmForToday stopForToday;
  late final ReconcileRhythm reconcile;
  late final RescheduleRunningRhythm reschedule;
}

final class FakeClock implements Clock {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

final class FakeRhythmDeliveryPort implements RhythmDeliveryPort {
  FakeRhythmDeliveryPort(this.calls);

  final List<String> calls;
  final List<RhythmEvent> scheduledEvents = <RhythmEvent>[];
  Object? scheduleFailure;
  int cancelFailuresRemaining = 0;

  @override
  Future<void> cancelScheduledEvent() async {
    calls.add('cancel');
    if (cancelFailuresRemaining > 0) {
      cancelFailuresRemaining -= 1;
      throw StateError('cancel failed');
    }
  }

  @override
  Future<void> schedule(RhythmEvent event) async {
    calls.add('schedule');
    final Object? failure = scheduleFailure;
    if (failure != null) {
      throw failure;
    }
    scheduledEvents.add(event);
  }

  void clear() {
    calls.clear();
    scheduledEvents.clear();
  }
}

final class FakeRhythmStatusSink implements RhythmStatusSink {
  FakeRhythmStatusSink(this.calls);

  final List<String> calls;
  final List<RhythmStatusSnapshot> snapshots = <RhythmStatusSnapshot>[];

  @override
  Future<void> publish(RhythmStatusSnapshot snapshot) async {
    calls.add('publish');
    snapshots.add(snapshot);
  }
}

RhythmConfiguration _configuration({
  required String start,
  required String end,
  required int focusMinutes,
  required int restMinutes,
}) {
  return RhythmConfiguration(
    dailyRhythm: DailyRhythm(
      start: ClockTime.parse(start),
      end: ClockTime.parse(end),
    ),
    focusDuration: DurationMinutes.focus(focusMinutes),
    restDuration: DurationMinutes.rest(restMinutes),
  );
}
