import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ports/sound_preview_port.dart';
import '../../application/preferences_command_result.dart';
import '../preferences_actions.dart';
import '../preferences_data_controller.dart';
import '../preferences_dependencies.dart';

final NotifierProvider<SoundPreviewController, bool>
soundPreviewControllerProvider = NotifierProvider<SoundPreviewController, bool>(
  SoundPreviewController.new,
);

final class SoundPreviewController extends Notifier<bool> {
  int _generation = 0;
  PreferencesActions get _actions => ref.read(preferencesActionsProvider);
  PreferencesDataController get _data =>
      ref.read(preferencesDataControllerProvider.notifier);

  @override
  bool build() {
    ref.onDispose(() {
      _generation += 1;
    });
    return false;
  }

  Future<void> previewSound() async {
    if (_data.beginOperation(PreferencesOperation.previewingSound) == null) {
      return;
    }
    final int generation = ++_generation;
    try {
      final SoundPreviewPlayback playback = await _actions.previewSound();
      if (!ref.mounted) {
        return;
      }
      state = true;
      _data.finishOperation();
      unawaited(
        playback.completed.then(
          (_) => _completePreview(generation),
          onError: (Object error, StackTrace stackTrace) {
            _completePreview(generation, failed: true);
          },
        ),
      );
    } on Object {
      if (ref.mounted) {
        state = false;
        _data.reportFailure(PreferencesFailure.preview);
      }
    }
  }

  Future<void> stopSoundPreview() async {
    if (!state ||
        _data.beginOperation(
              PreferencesOperation.stoppingSoundPreview,
              preserveFeedback: true,
            ) ==
            null) {
      return;
    }
    _generation += 1;
    try {
      await _actions.stopSoundPreview();
      if (!ref.mounted) {
        return;
      }
      state = false;
      _data.finishOperation(failure: PreferencesFailure.none);
    } on Object {
      if (ref.mounted) {
        _data.reportFailure(PreferencesFailure.preview);
      }
    }
  }

  Future<void> useBundledSound() => _changeSound(_actions.useBundledSound);
  Future<void> chooseCustomSound() => _changeSound(_actions.chooseCustomSound);
  Future<void> toggleMute() => _changeSound(_actions.toggleMute);

  Future<void> changeVolume(double volume) async {
    await _data.applyImmediate(
      () => _actions.changeVolume(volume),
      failure: PreferencesFailure.volume,
      resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
    );
  }

  Future<void> _changeSound(
    Future<PreferencesCommandResult> Function() command,
  ) async {
    final bool succeeded = await _data.applyImmediate(
      command,
      failure: PreferencesFailure.sound,
      resolves: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
    if (succeeded && ref.mounted) {
      _generation += 1;
      state = false;
    }
  }

  void _completePreview(int generation, {bool failed = false}) {
    if (!ref.mounted || generation != _generation || !state) {
      return;
    }
    state = false;
    if (failed) {
      _data.reportBackgroundFailure(PreferencesFailure.preview);
    }
  }
}
