import '../../contexts/rhythm/public.dart'
    show
        Clock,
        RhythmDeliveryPort,
        RhythmSession,
        RhythmStatusSink,
        RhythmStatusSnapshot;
import '../../features/data_transfer/public.dart' show RhythmSafetyPort;

typedef ActiveAudioStop = Future<void> Function();

final class RhythmImportSafetyAdapter implements RhythmSafetyPort {
  const RhythmImportSafetyAdapter({
    required this._session,
    required this._delivery,
    required this._statusSink,
    required this._clock,
    required this._stopActiveAudio,
  });

  final RhythmSession _session;
  final RhythmDeliveryPort _delivery;
  final RhythmStatusSink _statusSink;
  final Clock _clock;
  final ActiveAudioStop _stopActiveAudio;

  @override
  Future<void> stopForImport() async {
    await _delivery.cancelScheduledEvent();
    await _stopActiveAudio();
    _session.resetToIdle();
    final DateTime observedAt = _clock.now();
    await _statusSink.publish(
      RhythmStatusSnapshot.capture(
        session: _session,
        observedAt: observedAt,
        nextEvent: null,
      ),
    );
  }
}
