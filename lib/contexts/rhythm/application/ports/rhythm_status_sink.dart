import '../rhythm_status_snapshot.dart';

abstract interface class RhythmStatusSink {
  Future<void> publish(RhythmStatusSnapshot snapshot);
}
