import '../../domain/rhythm_event.dart';

abstract interface class RhythmDeliveryPort {
  Future<void> cancelScheduledEvent();

  Future<void> schedule(RhythmEvent event);
}
