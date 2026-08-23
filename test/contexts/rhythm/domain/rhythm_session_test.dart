import 'package:clock_rhythm/contexts/rhythm/domain/clock_time.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/daily_rhythm.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts, pauses, and resumes without moving the schedule anchor', () {
    final RhythmSession session = RhythmSession.idle(
      configuration: RhythmConfiguration.defaults(),
    );
    session.start(RhythmConfiguration.defaults());

    expect(session.status, RhythmSessionStatus.running);
    session.pause();
    expect(session.status, RhythmSessionStatus.paused);
    expect(session.nextEventAfter(DateTime(2026, 6, 2, 5, 10)), isNull);

    session.resume();
    final RhythmEvent? event = session.nextEventAfter(
      DateTime(2026, 6, 2, 5, 10),
    );

    expect(session.status, RhythmSessionStatus.running);
    expect(event?.occursAt, DateTime(2026, 6, 2, 5, 50));
  });

  test('ignores transitions that are invalid for the current state', () {
    final RhythmSession session = RhythmSession.idle(
      configuration: RhythmConfiguration.defaults(),
    );

    session.pause();
    session.resume();
    session.stopForToday(DateTime(2026, 6, 2, 9));

    expect(session.status, RhythmSessionStatus.idle);
    expect(session.nextEventAfter(DateTime(2026, 6, 2, 9)), isNull);
  });

  test('records one occurrence only once by instant and event kind', () {
    final RhythmSession session = _runningSession(
      RhythmConfiguration.defaults(),
    );
    final RhythmEvent event = RhythmEvent(
      kind: RhythmEventKind.focusEnds,
      occursAt: DateTime(2026, 6, 2, 5, 50),
      windowStartsAt: DateTime(2026, 6, 2, 5),
    );

    expect(session.canDeliver(event, observedAt: event.occursAt), isTrue);
    expect(session.recordDelivery(event, observedAt: event.occursAt), isTrue);
    expect(session.canDeliver(event, observedAt: event.occursAt), isFalse);
    expect(session.recordDelivery(event, observedAt: event.occursAt), isFalse);
  });

  test('allows equal wall-clock text when the occurrence instant differs', () {
    final RhythmSession session = _runningSession(
      RhythmConfiguration.defaults(),
    );
    final RhythmEvent first = RhythmEvent(
      kind: RhythmEventKind.focusEnds,
      occursAt: DateTime(2026, 6, 2, 5, 50),
      windowStartsAt: DateTime(2026, 6, 2, 5),
    );
    final RhythmEvent nextDay = RhythmEvent(
      kind: RhythmEventKind.focusEnds,
      occursAt: DateTime(2026, 6, 3, 5, 50),
      windowStartsAt: DateTime(2026, 6, 3, 5),
    );

    session.recordDelivery(first, observedAt: first.occursAt);

    expect(session.canDeliver(nextDay, observedAt: nextDay.occursAt), isTrue);
  });

  test('rejects an older occurrence after a newer event was delivered', () {
    final RhythmSession session = _runningSession(
      RhythmConfiguration.defaults(),
    );
    final RhythmEvent first = RhythmEvent(
      kind: RhythmEventKind.focusEnds,
      occursAt: DateTime(2026, 6, 2, 5, 50),
      windowStartsAt: DateTime(2026, 6, 2, 5),
    );
    final RhythmEvent second = RhythmEvent(
      kind: RhythmEventKind.restEnds,
      occursAt: DateTime(2026, 6, 2, 6),
      windowStartsAt: DateTime(2026, 6, 2, 5),
    );
    session
      ..recordDelivery(first, observedAt: first.occursAt)
      ..recordDelivery(second, observedAt: second.occursAt);

    expect(session.canDeliver(first, observedAt: second.occursAt), isFalse);
    expect(session.recordDelivery(first, observedAt: second.occursAt), isFalse);
  });

  test('keys Stop for Today to the cross-midnight window start', () {
    final RhythmConfiguration configuration = _configuration(
      start: '22:00',
      end: '02:00',
      focusMinutes: 50,
    );
    final RhythmSession session = _runningSession(configuration);

    session.stopForToday(DateTime(2026, 6, 3, 0, 30));

    expect(session.status, RhythmSessionStatus.stoppedForToday);
    expect(session.stoppedWindowStartsAt, DateTime(2026, 6, 2, 22));
    expect(session.resumesAt, DateTime(2026, 6, 3, 22));
    final RhythmEvent? nextEvent = session.nextEventAfter(
      DateTime(2026, 6, 3, 1),
    );
    expect(nextEvent?.occursAt, DateTime(2026, 6, 3, 22, 50));
  });

  test('automatically resumes exactly at the next Daily Rhythm start', () {
    final RhythmSession session = _runningSession(
      RhythmConfiguration.defaults(),
    );
    session.stopForToday(DateTime(2026, 6, 2, 9));

    session.reconcile(DateTime(2026, 6, 3, 4, 59, 59));
    expect(session.status, RhythmSessionStatus.stoppedForToday);

    session.reconcile(DateTime(2026, 6, 3, 5));
    expect(session.status, RhythmSessionStatus.running);
    expect(session.resumesAt, isNull);
  });

  test(
    'rescheduling preserves Paused and uses the new anchor after Resume',
    () {
      final RhythmSession session = _runningSession(
        RhythmConfiguration.defaults(),
      );
      session.pause();
      session.replaceConfiguration(
        _configuration(start: '06:00', end: '18:00', focusMinutes: 20),
        observedAt: DateTime(2026, 6, 2, 5, 10),
      );

      expect(session.status, RhythmSessionStatus.paused);
      expect(session.nextEventAfter(DateTime(2026, 6, 2, 5, 10)), isNull);

      session.resume();
      expect(
        session.nextEventAfter(DateTime(2026, 6, 2, 5, 10))?.occursAt,
        DateTime(2026, 6, 2, 6, 20),
      );
    },
  );

  test(
    'rescheduling preserves Stop until the new configuration next start',
    () {
      final RhythmSession session = _runningSession(
        RhythmConfiguration.defaults(),
      );
      session.stopForToday(DateTime(2026, 6, 2, 9));

      session.replaceConfiguration(
        _configuration(start: '11:00', end: '18:00', focusMinutes: 20),
        observedAt: DateTime(2026, 6, 2, 10),
      );

      expect(session.status, RhythmSessionStatus.stoppedForToday);
      expect(session.resumesAt, DateTime(2026, 6, 2, 11));
      expect(
        session.nextEventAfter(DateTime(2026, 6, 2, 10))?.occursAt,
        DateTime(2026, 6, 2, 11, 20),
      );
    },
  );

  test('rescheduling a stale Stop uses the new configuration next start', () {
    final RhythmSession session = _runningSession(
      RhythmConfiguration.defaults(),
    );
    session.stopForToday(DateTime(2026, 6, 2, 9));

    session.replaceConfiguration(
      _configuration(start: '11:00', end: '18:00', focusMinutes: 20),
      observedAt: DateTime(2026, 6, 3, 10),
    );

    expect(session.status, RhythmSessionStatus.stoppedForToday);
    expect(session.resumesAt, DateTime(2026, 6, 3, 11));
    expect(
      session.nextEventAfter(DateTime(2026, 6, 3, 10))?.occursAt,
      DateTime(2026, 6, 3, 11, 20),
    );
  });

  test('rejects UTC observations in every Session state', () {
    final RhythmSession running = _runningSession(
      RhythmConfiguration.defaults(),
    );
    final RhythmSession paused = _runningSession(RhythmConfiguration.defaults())
      ..pause();

    expect(
      () => running.reconcile(DateTime.utc(2026, 6, 2)),
      throwsArgumentError,
    );
    expect(
      () => paused.replaceConfiguration(
        RhythmConfiguration.defaults(),
        observedAt: DateTime.utc(2026, 6, 2),
      ),
      throwsArgumentError,
    );
  });
}

RhythmSession _runningSession(RhythmConfiguration configuration) {
  final RhythmSession session = RhythmSession.idle(
    configuration: configuration,
  );
  session.start(configuration);
  return session;
}

RhythmConfiguration _configuration({
  required String start,
  required String end,
  required int focusMinutes,
}) {
  return RhythmConfiguration(
    dailyRhythm: DailyRhythm(
      start: ClockTime.parse(start),
      end: ClockTime.parse(end),
    ),
    focusDuration: DurationMinutes.focus(focusMinutes),
    restDuration: DurationMinutes.rest(10),
  );
}
