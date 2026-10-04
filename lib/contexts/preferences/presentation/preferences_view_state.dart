import '../application/preferences_command_result.dart';
import '../domain/rhythm_settings_draft.dart';
import '../domain/user_preferences.dart';

import 'preferences_data_controller.dart';
export 'preferences_data_controller.dart'
    show PreferencesOperation, PreferencesFeedback, PreferencesFailure;

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
}
