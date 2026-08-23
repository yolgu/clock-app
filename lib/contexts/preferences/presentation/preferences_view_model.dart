import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/preferences_changed_port.dart';
import '../application/ports/sound_preview_port.dart';
import '../application/preferences_command_result.dart';
import '../domain/language_preference.dart';
import '../domain/rhythm_settings_draft.dart';
import '../domain/theme_preference.dart';
import 'preferences_actions.dart';
import 'preferences_providers.dart';
import 'preferences_view_state.dart';

final class PreferencesViewModel extends AsyncNotifier<PreferencesViewState> {
  Future<void> _draftWriteTail = Future<void>.value();
  StreamSubscription<Set<PreferencesRepairNeed>>? _repairNeedsSubscription;
  Set<PreferencesRepairNeed> _latestRepairNeeds = <PreferencesRepairNeed>{};
  int _draftWriteGeneration = 0;
  int _previewGeneration = 0;
  bool _disposalRegistered = false;

  PreferencesActions get _actions => ref.read(preferencesActionsProvider);

  @override
  Future<PreferencesViewState> build() async {
    _registerDisposal();
    await _repairNeedsSubscription?.cancel();
    final PreferencesInitialData initial = await _actions.load();
    _latestRepairNeeds = initial.repairNeeds;
    _repairNeedsSubscription = _actions.watchRepairNeeds().listen(
      _receiveRepairNeeds,
    );
    return PreferencesViewState(
      preferences: initial.preferences,
      draft: initial.draft,
      repairNeeds: _latestRepairNeeds,
    );
  }

  Future<void> updateDraft(RhythmSettingsDraft draft) async {
    final PreferencesViewState? current = state.value;
    if (current == null ||
        (current.isBusy &&
            current.operation != PreferencesOperation.storingDraft) ||
        draft == current.draft) {
      return;
    }
    final int generation = ++_draftWriteGeneration;
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        draft: draft,
        operation: PreferencesOperation.storingDraft,
        feedback: PreferencesFeedback.none,
        failure: PreferencesFailure.none,
      ),
    );
    final Future<void> write = _draftWriteTail.then(
      (_) => _actions.storeDraft(draft),
    );
    _draftWriteTail = write.onError((Object _, StackTrace _) {});
    try {
      await write;
      if (generation == _draftWriteGeneration) {
        state = AsyncData<PreferencesViewState>(
          state.requireValue.copyWith(operation: PreferencesOperation.idle),
        );
      }
    } on Object {
      if (generation == _draftWriteGeneration) {
        state = AsyncData<PreferencesViewState>(
          state.requireValue.copyWith(
            operation: PreferencesOperation.idle,
            feedback: PreferencesFeedback.failed,
            failure: PreferencesFailure.draftStore,
          ),
        );
      }
    }
  }

  Future<void> discardDraft() async {
    final PreferencesViewState? current = state.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        operation: PreferencesOperation.storingDraft,
        feedback: PreferencesFeedback.none,
        failure: PreferencesFailure.none,
      ),
    );
    try {
      final RhythmSettingsDraft clean = await _actions.discardDraft();
      state = AsyncData<PreferencesViewState>(
        state.requireValue.copyWith(
          draft: clean,
          operation: PreferencesOperation.idle,
          feedback: PreferencesFeedback.discarded,
        ),
      );
    } on Object {
      _finishWithFailure(PreferencesFailure.draftStore);
    }
  }

  Future<void> saveRhythm() async {
    final PreferencesViewState? current = state.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        operation: PreferencesOperation.savingRhythm,
        feedback: PreferencesFeedback.none,
        failure: PreferencesFailure.none,
      ),
    );
    try {
      final PreferencesCommandResult result = await _actions.saveRhythm(
        current.draft,
      );
      state = AsyncData<PreferencesViewState>(
        PreferencesViewState(
          preferences: result.preferences,
          draft: RhythmSettingsDraft.fromPreferences(result.preferences),
          feedback: PreferencesFeedback.saved,
          repairNeeds: _mergeRepairNeeds(
            current.repairNeeds,
            result.repairNeeds,
            resolves: const <PreferencesRepairNeed>{
              PreferencesRepairNeed.rhythmSchedule,
              PreferencesRepairNeed.autoStart,
              PreferencesRepairNeed.draft,
            },
          ),
        ),
      );
    } on Object {
      await _recoverDurablePreferences(current);
    }
  }

  Future<void> repairDraftStore() async {
    final PreferencesViewState? current = state.value;
    if (current == null ||
        current.isBusy ||
        !current.repairNeeds.contains(PreferencesRepairNeed.draft)) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        operation: PreferencesOperation.storingDraft,
        failure: PreferencesFailure.none,
      ),
    );
    try {
      await _actions.storeDraft(
        RhythmSettingsDraft.fromPreferences(current.preferences),
      );
      state = AsyncData<PreferencesViewState>(
        state.requireValue.copyWith(
          operation: PreferencesOperation.idle,
          repairNeeds: <PreferencesRepairNeed>{...current.repairNeeds}
            ..remove(PreferencesRepairNeed.draft),
          failure: PreferencesFailure.none,
        ),
      );
    } on Object {
      state = AsyncData<PreferencesViewState>(
        state.requireValue.copyWith(
          operation: PreferencesOperation.idle,
          feedback: PreferencesFeedback.failed,
          failure: PreferencesFailure.draftStore,
        ),
      );
    }
  }

  Future<void> changeLanguage(LanguagePreference language) {
    return _runImmediate(
      () => _actions.changeLanguage(language),
      failure: PreferencesFailure.language,
      resolves: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  Future<void> changeTheme(ThemePreference theme) {
    return _runImmediate(
      () => _actions.changeTheme(theme),
      failure: PreferencesFailure.theme,
      resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.visual},
    );
  }

  Future<void> useBundledSound() {
    return _runImmediate(
      _actions.useBundledSound,
      failure: PreferencesFailure.sound,
      resolves: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
      previewStops: true,
    );
  }

  Future<void> chooseCustomSound() {
    return _runImmediate(
      _actions.chooseCustomSound,
      failure: PreferencesFailure.sound,
      resolves: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
      previewStops: true,
    );
  }

  Future<void> changeVolume(double volume) {
    return _runImmediate(
      () => _actions.changeVolume(volume),
      failure: PreferencesFailure.volume,
      resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
    );
  }

  Future<void> toggleMute() {
    return _runImmediate(
      _actions.toggleMute,
      failure: PreferencesFailure.sound,
      resolves: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
      previewStops: true,
    );
  }

  Future<void> previewSound() async {
    final PreferencesViewState? current = state.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        operation: PreferencesOperation.previewingSound,
        feedback: PreferencesFeedback.none,
        failure: PreferencesFailure.none,
      ),
    );
    try {
      final int generation = ++_previewGeneration;
      final SoundPreviewPlayback playback = await _actions.previewSound();
      state = AsyncData<PreferencesViewState>(
        state.requireValue.copyWith(
          operation: PreferencesOperation.idle,
          isSoundPreviewing: true,
        ),
      );
      unawaited(
        playback.completed.then(
          (_) => _completePreview(generation),
          onError: (Object error, StackTrace stackTrace) {
            _completePreview(generation, failed: true);
          },
        ),
      );
    } on Object {
      _finishWithFailure(PreferencesFailure.preview, isSoundPreviewing: false);
    }
  }

  Future<void> stopSoundPreview() async {
    final PreferencesViewState? current = state.value;
    if (current == null || current.isBusy || !current.isSoundPreviewing) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        operation: PreferencesOperation.stoppingSoundPreview,
        failure: PreferencesFailure.none,
      ),
    );
    _previewGeneration += 1;
    try {
      await _actions.stopSoundPreview();
      state = AsyncData<PreferencesViewState>(
        state.requireValue.copyWith(
          operation: PreferencesOperation.idle,
          isSoundPreviewing: false,
          failure: PreferencesFailure.none,
        ),
      );
    } on Object {
      _finishWithFailure(PreferencesFailure.preview);
    }
  }

  Future<void> _runImmediate(
    Future<PreferencesCommandResult> Function() command, {
    required PreferencesFailure failure,
    required Set<PreferencesRepairNeed> resolves,
    bool previewStops = false,
  }) async {
    final PreferencesViewState? current = state.value;
    if (current == null || current.isBusy) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        operation: PreferencesOperation.changingImmediateSetting,
        feedback: PreferencesFeedback.none,
        failure: PreferencesFailure.none,
      ),
    );
    try {
      final PreferencesCommandResult result = await command();
      if (previewStops) {
        _previewGeneration += 1;
      }
      state = AsyncData<PreferencesViewState>(
        state.requireValue.copyWith(
          preferences: result.preferences,
          operation: PreferencesOperation.idle,
          isSoundPreviewing: previewStops
              ? false
              : state.requireValue.isSoundPreviewing,
          repairNeeds: _mergeRepairNeeds(
            current.repairNeeds,
            result.repairNeeds,
            resolves: resolves,
          ),
        ),
      );
    } on Object {
      _finishWithFailure(failure, isSoundPreviewing: current.isSoundPreviewing);
    }
  }

  Future<void> repairEffect(PreferencesRepairNeed need) {
    final PreferencesChangeImpact impact = switch (need) {
      PreferencesRepairNeed.visual => PreferencesChangeImpact.visual,
      PreferencesRepairNeed.sound => PreferencesChangeImpact.sound,
      PreferencesRepairNeed.notificationPayload =>
        PreferencesChangeImpact.notificationPayload,
      PreferencesRepairNeed.rhythmSchedule =>
        PreferencesChangeImpact.rhythmSchedule,
      PreferencesRepairNeed.autoStart || PreferencesRepairNeed.draft =>
        throw ArgumentError.value(need, 'need', 'uses a dedicated repair path'),
    };
    return _runImmediate(
      () => _actions.repairEffect(impact),
      failure: need == PreferencesRepairNeed.visual
          ? PreferencesFailure.theme
          : PreferencesFailure.sound,
      resolves: <PreferencesRepairNeed>{need},
    );
  }

  Future<void> repairAutoStart() {
    return _runImmediate(
      _actions.repairAutoStart,
      failure: PreferencesFailure.rhythmSave,
      resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.autoStart},
    );
  }

  Set<PreferencesRepairNeed> _mergeRepairNeeds(
    Set<PreferencesRepairNeed> current,
    Set<PreferencesRepairNeed> reported, {
    required Set<PreferencesRepairNeed> resolves,
  }) {
    return <PreferencesRepairNeed>{
      ...current.where(
        (PreferencesRepairNeed need) => !resolves.contains(need),
      ),
      ...reported,
    };
  }

  void _completePreview(int generation, {bool failed = false}) {
    if (generation != _previewGeneration) {
      return;
    }
    final PreferencesViewState? current = state.value;
    if (current == null || !current.isSoundPreviewing) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(
        isSoundPreviewing: false,
        feedback: failed ? PreferencesFeedback.failed : current.feedback,
        failure: failed ? PreferencesFailure.preview : current.failure,
      ),
    );
  }

  Future<void> _recoverDurablePreferences(
    PreferencesViewState beforeSave,
  ) async {
    try {
      final PreferencesInitialData loaded = await _actions.load();
      state = AsyncData<PreferencesViewState>(
        PreferencesViewState(
          preferences: loaded.preferences,
          draft: beforeSave.draft,
          feedback: PreferencesFeedback.failed,
          failure: PreferencesFailure.rhythmSave,
          repairNeeds: loaded.repairNeeds,
        ),
      );
    } on Object {
      state = AsyncData<PreferencesViewState>(
        beforeSave.copyWith(
          operation: PreferencesOperation.idle,
          feedback: PreferencesFeedback.failed,
          failure: PreferencesFailure.rhythmSave,
        ),
      );
    }
  }

  void _finishWithFailure(
    PreferencesFailure failure, {
    bool? isSoundPreviewing,
  }) {
    state = AsyncData<PreferencesViewState>(
      state.requireValue.copyWith(
        operation: PreferencesOperation.idle,
        feedback: PreferencesFeedback.failed,
        failure: failure,
        isSoundPreviewing: isSoundPreviewing,
      ),
    );
  }

  void _receiveRepairNeeds(Set<PreferencesRepairNeed> repairNeeds) {
    _latestRepairNeeds = Set<PreferencesRepairNeed>.of(repairNeeds);
    final PreferencesViewState? current = state.value;
    if (current == null || _sameRepairNeeds(current.repairNeeds, repairNeeds)) {
      return;
    }
    state = AsyncData<PreferencesViewState>(
      current.copyWith(repairNeeds: repairNeeds),
    );
  }

  void _registerDisposal() {
    if (_disposalRegistered) {
      return;
    }
    _disposalRegistered = true;
    ref.onDispose(() {
      final StreamSubscription<Set<PreferencesRepairNeed>>? subscription =
          _repairNeedsSubscription;
      _repairNeedsSubscription = null;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    });
  }

  bool _sameRepairNeeds(
    Set<PreferencesRepairNeed> left,
    Set<PreferencesRepairNeed> right,
  ) {
    return left.length == right.length && left.containsAll(right);
  }
}
