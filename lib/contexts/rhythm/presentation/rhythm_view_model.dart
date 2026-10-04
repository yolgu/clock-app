import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/rhythm_start_capability.dart';
import '../application/rhythm_service.dart';
import '../application/rhythm_status_snapshot.dart';
import '../domain/rhythm_session.dart';
import 'rhythm_actions.dart';
import 'rhythm_providers.dart';
import 'rhythm_view_state.dart';

final class RhythmViewModel extends AsyncNotifier<RhythmViewState> {
  RhythmActions get _actions => ref.read(rhythmActionsProvider);

  @override
  Future<RhythmViewState> build() async {
    try {
      return RhythmViewState(snapshot: await _actions.load());
    } on RhythmSynchronizationFailure catch (failure) {
      return RhythmViewState(
        snapshot: failure.safeSnapshot,
        commandFailed: true,
      );
    }
  }

  Future<void> start() async {
    final RhythmViewState? current = _begin(RhythmOperation.starting);
    if (current == null) {
      return;
    }
    final RhythmStartResult result;
    try {
      result = await _actions.start(current.snapshot.configuration);
    } on Object {
      state = AsyncData<RhythmViewState>(
        current.copyWith(
          operation: RhythmOperation.idle,
          startFailure: RhythmStartFailure.deliveryUnavailable,
          commandFailed: false,
        ),
      );
      return;
    }
    final RhythmStatusSnapshot? snapshot = result.snapshot;
    if (!result.didStart) {
      state = AsyncData<RhythmViewState>(
        current.copyWith(
          snapshot: snapshot,
          operation: RhythmOperation.idle,
          startFailure: result.failure,
          commandFailed: false,
        ),
      );
      return;
    }
    _finishTransition(current, snapshot!, RhythmAnnouncement.running);
  }

  Future<void> pause() {
    return _runTransition(
      operation: RhythmOperation.pausing,
      command: _actions.pause,
      announcement: RhythmAnnouncement.paused,
    );
  }

  Future<void> resume() {
    return _runTransition(
      operation: RhythmOperation.resuming,
      command: _actions.resume,
      announcement: RhythmAnnouncement.resumed,
    );
  }

  Future<void> stopForToday() {
    return _runTransition(
      operation: RhythmOperation.stopping,
      command: _actions.stopForToday,
      announcement: RhythmAnnouncement.stoppedForToday,
    );
  }

  Future<void> reconcile() {
    return _runTransition(
      operation: RhythmOperation.reconciling,
      command: _actions.reconcile,
    );
  }

  Future<void> openStartFailureSettings() async {
    final RhythmStartFailure? failure = state.value?.startFailure;
    if (failure != null) {
      await _actions.openStartFailureSettings(failure);
    }
  }

  RhythmViewState? _begin(RhythmOperation operation) {
    final RhythmViewState? current = state.value;
    if (current == null || current.isBusy) {
      return null;
    }
    state = AsyncData<RhythmViewState>(
      current.copyWith(
        operation: operation,
        clearStartFailure: true,
        commandFailed: false,
      ),
    );
    return current;
  }

  Future<void> _runTransition({
    required RhythmOperation operation,
    required Future<RhythmStatusSnapshot> Function() command,
    RhythmAnnouncement? announcement,
  }) async {
    final RhythmViewState? current = _begin(operation);
    if (current == null) {
      return;
    }
    try {
      final RhythmStatusSnapshot snapshot = await command();
      _finishTransition(current, snapshot, announcement);
    } on RhythmSynchronizationFailure catch (failure) {
      state = AsyncData<RhythmViewState>(
        current.copyWith(
          snapshot: failure.safeSnapshot,
          operation: RhythmOperation.idle,
          commandFailed: true,
        ),
      );
    } on Object {
      state = AsyncData<RhythmViewState>(
        current.copyWith(operation: RhythmOperation.idle, commandFailed: true),
      );
    }
  }

  void _finishTransition(
    RhythmViewState previous,
    RhythmStatusSnapshot snapshot,
    RhythmAnnouncement? requestedAnnouncement,
  ) {
    final bool changed = snapshot.status != previous.snapshot.status;
    final RhythmAnnouncement? effectiveAnnouncement = changed
        ? requestedAnnouncement ?? _announcementFor(snapshot.status)
        : null;
    state = AsyncData<RhythmViewState>(
      previous.copyWith(
        snapshot: snapshot,
        operation: RhythmOperation.idle,
        clearStartFailure: true,
        announcement: effectiveAnnouncement,
        announcementSequence: effectiveAnnouncement == null
            ? previous.announcementSequence
            : previous.announcementSequence + 1,
        commandFailed: false,
      ),
    );
  }

  RhythmAnnouncement? _announcementFor(RhythmSessionStatus status) {
    return switch (status) {
      RhythmSessionStatus.running => RhythmAnnouncement.running,
      RhythmSessionStatus.paused => RhythmAnnouncement.paused,
      RhythmSessionStatus.stoppedForToday => RhythmAnnouncement.stoppedForToday,
      RhythmSessionStatus.idle => null,
    };
  }
}
