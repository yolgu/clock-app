import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/rhythm_settings_draft.dart';
import 'preferences_data_controller.dart';
import 'preferences_view_state.dart';
import 'settings/rhythm_settings_editor.dart';
import 'sound/sound_preview_controller.dart';
export 'preferences_data_controller.dart'
    show
        PreferencesDataController,
        PreferencesDataState,
        preferencesDataControllerProvider;
export 'preferences_dependencies.dart';
export 'settings/rhythm_settings_editor.dart'
    show RhythmSettingsEditor, rhythmSettingsEditorProvider;
export 'sound/sound_preview_controller.dart'
    show SoundPreviewController, soundPreviewControllerProvider;

final Provider<AsyncValue<PreferencesViewState>> preferencesViewStateProvider =
    Provider<AsyncValue<PreferencesViewState>>((Ref ref) {
      final AsyncValue<PreferencesDataState> data = ref.watch(
        preferencesDataControllerProvider,
      );
      final AsyncValue<RhythmSettingsDraft> draft = ref.watch(
        rhythmSettingsEditorProvider,
      );
      final bool previewing = ref.watch(soundPreviewControllerProvider);
      return data.when<AsyncValue<PreferencesViewState>>(
        data: (PreferencesDataState value) => draft.whenData(
          (RhythmSettingsDraft input) => PreferencesViewState(
            preferences: value.preferences,
            draft: input,
            operation: value.operation,
            feedback: value.feedback,
            failure: value.failure,
            repairNeeds: value.repairNeeds,
            isSoundPreviewing: previewing,
          ),
        ),
        loading: () => const AsyncLoading<PreferencesViewState>(),
        error: (Object error, StackTrace stackTrace) =>
            AsyncError<PreferencesViewState>(error, stackTrace),
      );
    });
