import '../application/ports/rhythm_start_capability.dart';
import '../application/rhythm_status_snapshot.dart';

enum RhythmOperation {
  idle,
  starting,
  pausing,
  resuming,
  stopping,
  reconciling,
}

enum RhythmAnnouncement { running, paused, resumed, stoppedForToday }

final class RhythmViewState {
  const RhythmViewState({
    required this.snapshot,
    this.operation = RhythmOperation.idle,
    this.startFailure,
    this.announcement,
    this.announcementSequence = 0,
    this.commandFailed = false,
  });

  final RhythmStatusSnapshot snapshot;
  final RhythmOperation operation;
  final RhythmStartFailure? startFailure;
  final RhythmAnnouncement? announcement;
  final int announcementSequence;
  final bool commandFailed;

  bool get isBusy => operation != RhythmOperation.idle;

  RhythmViewState copyWith({
    RhythmStatusSnapshot? snapshot,
    RhythmOperation? operation,
    RhythmStartFailure? startFailure,
    bool clearStartFailure = false,
    RhythmAnnouncement? announcement,
    int? announcementSequence,
    bool? commandFailed,
  }) {
    return RhythmViewState(
      snapshot: snapshot ?? this.snapshot,
      operation: operation ?? this.operation,
      startFailure: clearStartFailure
          ? null
          : startFailure ?? this.startFailure,
      announcement: announcement ?? this.announcement,
      announcementSequence: announcementSequence ?? this.announcementSequence,
      commandFailed: commandFailed ?? this.commandFailed,
    );
  }
}
