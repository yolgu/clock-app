import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/preferences_command_result.dart';
import '../../domain/rhythm_settings_draft.dart';
import '../preferences_actions.dart';
import '../preferences_data_controller.dart';
import '../preferences_dependencies.dart';

final AsyncNotifierProvider<RhythmSettingsEditor, RhythmSettingsDraft>
rhythmSettingsEditorProvider =
    AsyncNotifierProvider<RhythmSettingsEditor, RhythmSettingsDraft>(
      RhythmSettingsEditor.new,
    );

final class RhythmSettingsEditor extends AsyncNotifier<RhythmSettingsDraft> {
  Future<void> _draftWriteTail = Future<void>.value();
  int _generation = 0;
  PreferencesActions get _actions => ref.read(preferencesActionsProvider);
  PreferencesDataController get _data =>
      ref.read(preferencesDataControllerProvider.notifier);

  @override
  Future<RhythmSettingsDraft> build() async {
    final PreferencesInitialData initial = await ref.watch(
      preferencesInitialDataProvider.future,
    );
    await ref.read(preferencesDataControllerProvider.future);
    return initial.draft;
  }

  Future<void> updateDraft(RhythmSettingsDraft draft) async {
    if (state.value == null ||
        state.value == draft ||
        _data.beginOperation(PreferencesOperation.storingDraft) == null) {
      return;
    }
    final int generation = ++_generation;
    state = AsyncData<RhythmSettingsDraft>(draft);
    final Future<void> write = _draftWriteTail.then(
      (_) => _actions.storeDraft(draft),
    );
    _draftWriteTail = write.onError((Object _, StackTrace _) {});
    try {
      await write;
      if (ref.mounted && generation == _generation) {
        _data.finishOperation();
      }
    } on Object {
      if (ref.mounted && generation == _generation) {
        _data.reportFailure(PreferencesFailure.draftStore);
      }
    }
  }

  Future<void> discardDraft() async {
    final PreferencesDataState? current = ref
        .read(preferencesDataControllerProvider)
        .value;
    if (current == null ||
        current.isBusy ||
        _data.beginOperation(PreferencesOperation.storingDraft) == null) {
      return;
    }
    try {
      final RhythmSettingsDraft clean = await _actions.discardDraft();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<RhythmSettingsDraft>(clean);
      _data.finishOperation(feedback: PreferencesFeedback.discarded);
    } on Object {
      if (ref.mounted) {
        _data.reportFailure(PreferencesFailure.draftStore);
      }
    }
  }

  Future<void> saveRhythm() async {
    final RhythmSettingsDraft? draft = state.value;
    if (draft == null) {
      return;
    }
    final PreferencesDataState? beforeSave = _data.beginOperation(
      PreferencesOperation.savingRhythm,
    );
    if (beforeSave == null) {
      return;
    }
    try {
      final PreferencesCommandResult result = await _actions.saveRhythm(draft);
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<RhythmSettingsDraft>(
        RhythmSettingsDraft.fromPreferences(result.preferences),
      );
      _data.acceptCommand(
        result,
        resolves: const <PreferencesRepairNeed>{
          PreferencesRepairNeed.rhythmSchedule,
          PreferencesRepairNeed.autoStart,
          PreferencesRepairNeed.draft,
        },
        feedback: PreferencesFeedback.saved,
        failure: PreferencesFailure.none,
      );
    } on Object {
      if (ref.mounted) {
        await _data.recoverFailedSave(beforeSave);
      }
    }
  }

  Future<void> repairDraftStore() async {
    final PreferencesDataState? current = ref
        .read(preferencesDataControllerProvider)
        .value;
    if (current == null ||
        current.isBusy ||
        !current.repairNeeds.contains(PreferencesRepairNeed.draft)) {
      return;
    }
    if (_data.beginOperation(
          PreferencesOperation.storingDraft,
          preserveFeedback: true,
        ) ==
        null) {
      return;
    }
    final RhythmSettingsDraft clean = RhythmSettingsDraft.fromPreferences(
      current.preferences,
    );
    try {
      await _actions.storeDraft(clean);
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<RhythmSettingsDraft>(clean);
      _data.acceptCommand(
        PreferencesCommandResult(preferences: current.preferences),
        resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.draft},
        failure: PreferencesFailure.none,
      );
    } on Object {
      if (ref.mounted) {
        _data.reportFailure(PreferencesFailure.draftStore);
      }
    }
  }
}
