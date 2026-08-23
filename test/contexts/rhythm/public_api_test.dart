import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports the planned Rhythm model, ports, snapshots, and use cases', () {
    _acceptType<ClockTime>();
    _acceptType<DailyRhythm>();
    _acceptType<DailyRhythmWindow>();
    _acceptType<DurationMinutes>();
    _acceptType<RhythmConfiguration>();
    _acceptType<RhythmEvent>();
    _acceptType<RhythmEventKind>();
    _acceptType<RhythmSchedule>();
    _acceptType<RhythmSession>();
    _acceptType<RhythmSessionStatus>();
    _acceptType<Clock>();
    _acceptType<DeliveryRecoveryDisposition>();
    _acceptType<DeliveryRecoveryPort>();
    _acceptType<DeliveryRecoveryReason>();
    _acceptType<DeliveryRecoveryStatus>();
    _acceptType<RhythmDeliveryPort>();
    _acceptType<RhythmStatusSink>();
    _acceptType<RhythmStatusSnapshot>();
    _acceptType<StartRhythm>();
    _acceptType<PauseRhythm>();
    _acceptType<ResumeRhythm>();
    _acceptType<StopRhythmForToday>();
    _acceptType<ReconcileRhythm>();
    _acceptType<RescheduleRunningRhythm>();

    expect(RhythmConfiguration.defaults().focusDuration.minutes, 50);
  });
}

void _acceptType<T>() {}
