import '../application/preferences_command_result.dart';
import '../domain/rhythm_settings_draft.dart';
import '../domain/user_preferences.dart';

enum PreferencesOperation {
  idle,
  storingDraft,
  savingRhythm,
  changingImmediateSetting,
  previewingSound,
  stoppingSoundPreview,
}

enum PreferencesFeedback { none, saved, discarded, failed }

enum PreferencesFailure {
  none,
  draftStore,
  rhythmSave,
  language,
  theme,
  sound,
  volume,
  preview,
}

final class PreferencesViewState {
  PreferencesViewState({
    required this.preferences,
    required this.draft,
    this.operation = PreferencesOperation.idle,
    this.feedback = PreferencesFeedback.none,
    this.failure = PreferencesFailure.none,
    this.isSoundPreviewing = false,
    Set<PreferencesRepairNeed> repairNeeds = const <PreferencesRepairNeed>{},
  }) : repairNeeds = Set<PreferencesRepairNeed>.unmodifiable(repairNeeds);

  final UserPreferences preferences;
  final RhythmSettingsDraft draft;
  final PreferencesOperation operation;
  final PreferencesFeedback feedback;
  final PreferencesFailure failure;
  final bool isSoundPreviewing;
  final Set<PreferencesRepairNeed> repairNeeds;

  bool get isDirty => draft.isDirtyComparedWith(preferences);

  bool get isBusy => operation != PreferencesOperation.idle;

  PreferencesViewState copyWith({
    UserPreferences? preferences,
    RhythmSettingsDraft? draft,
    PreferencesOperation? operation,
    PreferencesFeedback? feedback,
    PreferencesFailure? failure,
    bool? isSoundPreviewing,
    Set<PreferencesRepairNeed>? repairNeeds,
  }) {
    return PreferencesViewState(
      preferences: preferences ?? this.preferences,
      draft: draft ?? this.draft,
      operation: operation ?? this.operation,
      feedback: feedback ?? this.feedback,
      failure: failure ?? this.failure,
      isSoundPreviewing: isSoundPreviewing ?? this.isSoundPreviewing,
      repairNeeds: repairNeeds ?? this.repairNeeds,
    );
  }
}
